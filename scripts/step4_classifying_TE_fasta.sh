#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Step 4: Final TE processing + RepeatMasker"

############################################
# EXPECT VARIABLES FROM LAUNCHER
############################################
if [[ -z "${SCRIPT_DIR:-}" ]] || [[ -z "${DB_DIR:-}" ]]; then
    echo "❌ ERROR: Run this via the 'teexpo' launcher."
    exit 1
fi

THREADS=3
WORKDIR="$(pwd)"

############################################
# STEP 0: FETCH FINAL CURATED TE LIBRARY
############################################

echo "======================================"
echo "Step 0: Fetching curated TE library"
echo "======================================"

SOURCE_LIB=$(find "$WORKDIR" -type f -name "*FINAL_CURATED_TE_LIBRARY.fa" | head -n 1)
TARGET_LIB="$WORKDIR/PadleriG01_consensus_subfamily.fa"

if [[ -z "$SOURCE_LIB" ]]; then
    echo "❌ ERROR: No curated TE library found!"
    exit 1
fi

echo "✔ Found library: $SOURCE_LIB"

cp "$SOURCE_LIB" "$TARGET_LIB"

############################################
# STEP 1: RENAME FASTA HEADERS
############################################

INPUT_FASTA="$TARGET_LIB"
NUMBERED_FASTA="$WORKDIR/query_numbered.fa"

awk '
BEGIN {count=0}
/^>/ {
    count++
    header=$0
    sub(/^>/,"",header)
    print ">"header"_"count
    next
}
{print}
' "$INPUT_FASTA" > "$NUMBERED_FASTA"

echo "✔ FASTA headers renamed"

############################################
# STEP 2: BLAST DATABASE (USING INTERNAL DB)
############################################

makeblastdb \
  -in "$DB_DIR/RepeatPeps.lib" \
  -dbtype prot \
  -out "$WORKDIR/RepeatPepsDB"

############################################
# STEP 3: BLASTP
############################################

blastx \
  -query "$NUMBERED_FASTA" \
  -db "$WORKDIR/RepeatPepsDB" \
  -out "$WORKDIR/results.tsv" \
  -outfmt "6 qseqid sseqid pident length evalue bitscore"

############################################
# STEP 4: RUN RENAMING SCRIPT
############################################

RENAMED_FASTA="$WORKDIR/final_TEs.fa"
TE_TYPES_FILE="$WORKDIR/te_types.txt"

python3 "$SCRIPT_DIR/Renaming_final_fasta.py" \
    "$WORKDIR/results.tsv" \
    "$NUMBERED_FASTA" \
    "$RENAMED_FASTA" \
    "$TE_TYPES_FILE"

############################################
# STEP 5: FINAL TE LIBRARY + REPEATMASKER
############################################

GENOME="$WORKDIR/P_Genome_1.fa"
CLEAN_GENOME="$WORKDIR/P_Genome_clean.fa"
RAW_TE_LIB="$WORKDIR/final_TEs.fa"
FIXED_TE_LIB="$WORKDIR/final_completed_TEs_library.fa"

############################################
# STEP 5A: CLEAN GENOME HEADERS
############################################

if [[ ! -f "$GENOME" ]]; then
    echo "❌ ERROR: Genome file P_Genome_1.fa not found!"
    exit 1
fi

awk '
/^>/ {
    split($0, a, " ")
    print a[1]
    next
}
{print}
' "$GENOME" > "$CLEAN_GENOME"

echo "✔ Clean genome created"

############################################
# STEP 5B: VALIDATE TE LIBRARY
############################################

if [[ ! -f "$RAW_TE_LIB" ]]; then
    echo "❌ ERROR: final_TEs.fa not found!"
    exit 1
fi

############################################
# STEP 5C: RENAME TE HEADERS ONLY
############################################

awk '
BEGIN {count=0}
/^>/ {
    count++
    header=$0
    sub(/^>/, "", header)

    if (header == "") {
        header="Unknown"
    }

    print ">TE_"count"#"header
    next
}
{print}
' "$RAW_TE_LIB" > "$FIXED_TE_LIB"

echo "✔ TE headers renamed"

############################################
# STEP 5D: VALIDATE OUTPUT
############################################

NUM_SEQ=$(grep -c "^>" "$FIXED_TE_LIB")

if [[ "$NUM_SEQ" -eq 0 ]]; then
    echo "❌ ERROR: No valid TE sequences found!"
    exit 1
fi

echo "✔ Valid sequences: $NUM_SEQ"

############################################
# STEP 5E: RUN REPEATMASKER
############################################

mkdir -p "$WORKDIR/RepeatMasker_output"

RepeatMasker \
  -pa "$THREADS" \
  -lib "$FIXED_TE_LIB" \
  -dir "$WORKDIR/RepeatMasker_output" \
  -gff \
  "$CLEAN_GENOME"

############################################
# DONE
############################################

echo "======================================"
echo "✅ RepeatMasker completed successfully"
echo "======================================"

############################################
# STEP 6: GENERATE DASHBOARD
############################################

echo "======================================"
echo "Generating TE dashboard..."
echo "======================================"

python3 "$SCRIPT_DIR/te_dashboard.py"

echo "✔ Dashboard completed"

############################################
# STEP 7: ORGANIZE FINAL OUTPUT
############################################

echo "======================================"
echo "Organizing final outputs..."
echo "======================================"

FINAL_DIR="$WORKDIR/final_output"
mkdir -p "$FINAL_DIR"

# ✅ Keep ONLY the real final TE library
cp "$FIXED_TE_LIB" "$FINAL_DIR/Final_TE_Library.fa"

# Keep classification table
cp "$WORKDIR/te_types.txt" "$FINAL_DIR/" 2>/dev/null || true

# Keep dashboard outputs
cp "$WORKDIR"/TE_dashboard_* "$FINAL_DIR/" 2>/dev/null || true

# Keep RepeatMasker results
cp -r "$WORKDIR/RepeatMasker_output" "$FINAL_DIR/"

############################################
# STEP 8: CLEAN INTERMEDIATE FILES
############################################

echo "Cleaning intermediate files..."

# Remove intermediate files
rm -f \
    final_TEs.fa \
    filtered_TEs.fa \
    combined_TE_candidates.fa \
    query_numbered.fa \
    results.tsv \
    PadleriG01_consensus_subfamily.fa \
    P_Genome_clean.fa \
    *-rmod.log \
    *-rmod.txt \
    *-families.stk \
    *-families.fa \
    *_TEs.fasta \
    TE_dashboard_family_summary.csv \
    TE_dashboard_summary.csv \
    TE_dashboard_length_hist.png \
    TE_dashboard_barplot.png \
    TE_dashboard_pie.png \
    te_types.txt \
    step2_* \
    tmpConsensi.fa* \
    *.translation \
    *.nhr *.nin *.njs *.nnd *.nni *.nog *.nsq \
    formatdb.log \
    run_repeatmodeler.log \
    final_completed_TEs_library.fa \
    genome_clean.fa \
    P_Genome_1.fa 2>/dev/null || true

# Remove BLAST/DFAM/SwissProt databases
rm -f dfam_prot_db.* RepeatPepsDB.* Repbase_TE_proteins.* SwissProt.* Dfam_TE_proteins.* 2>/dev/null || true

# Remove unwanted directories
rm -rf \
    te_headers_parsed \
    fasta_lengths \
    final_library \
    final_master_table \
    FINAL_TE_LIBRARY \
    final_curated_library \
    alignments_final \
    blast_results \
    genome_db \
    ltrdigest_output \
    ltrharvest_final_output \
    transposonpsi_output \
    transposonpsi_result \
    RepeatModeler_output \
    blastx_repbase_results \
    blastx_swissprot_filtered_fasta_and_hits \
    blastx_swissprot_results \
    blastx_dfam_results \
    repbase_supported_TEs \
    dfam_supported_TEs \
    trnascanse \
    RM_[0-9]*.* \
    RM_* \
    RepeatMasker_output \
    Testing_in_other_genomes 2>/dev/null || true

echo "======================================"
echo "✅ Cleanup complete"
echo "======================================"
echo "Final results available in:"
echo "  final_output/"
echo "Genome retained as:"
echo "  $GENOME"
echo "======================================"