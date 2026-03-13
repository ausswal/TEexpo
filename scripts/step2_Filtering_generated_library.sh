#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Step 2 Filtering generated TE library"

############################################
# CONFIG
############################################

THREADS=3

WORKDIR="$(pwd)"

############################################
# AUTO-DETECT INPUTS FROM STEP 1
############################################

TE_FASTA=$(find "$WORKDIR" -maxdepth 1 -type f -name "*_TEs.fasta" | head -n 1)
GENOME=$(find "$WORKDIR" -maxdepth 1 -type f -name "*.fa" | grep -v "_TEs" | head -n 1)

if [[ -z "$TE_FASTA" ]]; then
    echo "❌ No TE fasta found from Step 1"
    exit 1
fi

if [[ -z "$GENOME" ]]; then
    echo "❌ No genome fasta found"
    exit 1
fi

echo "✔ TE FASTA: $TE_FASTA"
echo "✔ GENOME: $GENOME"

GENOME_NAME=$(basename "$GENOME")
GENOME_NAME=${GENOME_NAME%.fa}
GENOME_NAME=${GENOME_NAME%.fasta}

############################################
# DATABASE FILES (FROM INSTALL DIR)
############################################

DFAM_PEPS="$DB_DIR/RepeatPeps.lib"
SWISSPROT_FASTA="$DB_DIR/uniprot_sprot.fasta"

DFAM_DB="$WORKDIR/Dfam_TE_proteins"
SWISSPROT_DB="$WORKDIR/SwissProt"

############################################
# STEP 1: Dfam BLASTX
############################################

makeblastdb \
  -in "$DFAM_PEPS" \
  -dbtype prot \
  -parse_seqids \
  -out "$DFAM_DB"

mkdir -p blastx_dfam_results

blastx \
  -query "$TE_FASTA" \
  -db "$DFAM_DB" \
  -out blastx_dfam_results/${GENOME_NAME}_vs_Dfam.blastx.tsv \
  -outfmt 6 \
  -num_threads "$THREADS"

############################################
# STEP 2: Extract Dfam-supported TEs
############################################

mkdir -p dfam_supported_TEs

cut -f1 blastx_dfam_results/${GENOME_NAME}_vs_Dfam.blastx.tsv \
| sort -u > dfam_supported_TEs/hit_ids.txt

if [[ -s dfam_supported_TEs/hit_ids.txt ]]; then
    seqkit grep \
      -f dfam_supported_TEs/hit_ids.txt \
      "$TE_FASTA" \
      > dfam_supported_TEs/${GENOME_NAME}_DfamSupported.fasta
else
    echo "⚠️ No Dfam hits — using full TE set"
    cp "$TE_FASTA" dfam_supported_TEs/${GENOME_NAME}_DfamSupported.fasta
fi

############################################
# STEP 3: SwissProt BLASTX (OPTIONAL)
############################################

mkdir -p blastx_swissprot_results
mkdir -p blastx_swissprot_filtered_fasta_and_hits

if [[ -f "$SWISSPROT_FASTA" ]]; then
    makeblastdb -in "$SWISSPROT_FASTA" -dbtype prot -out "$SWISSPROT_DB"

    blastx \
      -query dfam_supported_TEs/${GENOME_NAME}_DfamSupported.fasta \
      -db "$SWISSPROT_DB" \
      -evalue 1e-5 \
      -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen" \
      -num_threads "$THREADS" \
      -out blastx_swissprot_results/${GENOME_NAME}_vs_SwissProt.blastx.tsv

    awk '$3>30 && $11<1e-5 && ($4/$13*100)>50 {print $1}' \
        blastx_swissprot_results/${GENOME_NAME}_vs_SwissProt.blastx.tsv \
        | sort -u \
        > blastx_swissprot_filtered_fasta_and_hits/bad_ids.txt
else
    echo "⚠️ SwissProt not found — skipping filtering"
    touch blastx_swissprot_filtered_fasta_and_hits/bad_ids.txt
fi

############################################
# STEP 4: CREATE CLEAN TE SET
############################################

CLEAN_TE="blastx_swissprot_filtered_fasta_and_hits/${GENOME_NAME}_cleanTEs.fa"

if [[ -s blastx_swissprot_filtered_fasta_and_hits/bad_ids.txt ]]; then
    seqkit grep -v \
      -f blastx_swissprot_filtered_fasta_and_hits/bad_ids.txt \
      dfam_supported_TEs/${GENOME_NAME}_DfamSupported.fasta \
      > "$CLEAN_TE"
else
    cp dfam_supported_TEs/${GENOME_NAME}_DfamSupported.fasta "$CLEAN_TE"
fi

############################################
# STEP 5: tRNAscan-SE
############################################

mkdir -p trnascanse

tRNAscan-SE \
  -E \
  --thread "$THREADS" \
  -o trnascanse/${GENOME_NAME}_trnascan.out \
  "$GENOME"

############################################
# STEP 6: Convert tRNAs → BED
############################################

awk '
NR>3 && $2~/^[0-9]+$/ {
    print $1 "\t" ($2-1) "\t" $3
}' trnascanse/${GENOME_NAME}_trnascan.out \
> trnascanse/${GENOME_NAME}_tRNAs.bed || true

############################################
# STEP 7: FINAL tRNA FILTERING
############################################

mkdir -p FINAL_TE_LIBRARY
FINAL_TE="FINAL_TE_LIBRARY/${GENOME_NAME}_FINAL_TEs.fa"

if [[ -s trnascanse/${GENOME_NAME}_tRNAs.bed ]]; then
    echo "🧬 tRNAs detected — filtering"

    seqkit fx2tab -n "$CLEAN_TE" \
    | awk '{print $1 "\t0\t1000000"}' \
    | bedtools intersect -v \
        -a - \
        -b trnascanse/${GENOME_NAME}_tRNAs.bed \
    | cut -f1 \
    | seqkit grep -f - "$CLEAN_TE" \
    > "$FINAL_TE"
else
    echo "⚠️ No tRNAs found — skipping filtering"
    cp "$CLEAN_TE" "$FINAL_TE"
fi

############################################
# DONE
############################################

echo "✅ Step 2 finished successfully"
echo "📁 FINAL TE LIBRARY:"
echo "   $FINAL_TE"
