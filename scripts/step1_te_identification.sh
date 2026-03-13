#!/bin/bash
set -e

pyfiglet TEexpo1.0 || echo "=== TEexpo 1.0 ==="
echo "Pipeline started at $(date)"

############################################
# EXPECT VARIABLES FROM LAUNCHER
############################################
if [[ -z "${SCRIPT_DIR:-}" ]] || [[ -z "${DB_DIR:-}" ]]; then
    echo "❌ ERROR: Run this via the 'teexpo' launcher."
    exit 1
fi

############################################
# INPUT GENOME HANDLING
############################################
# Launcher passes the genome filename as $GENOME
GENOME="${GENOME:-}"

if [[ -z "$GENOME" ]]; then
    echo "❌ ERROR: No genome file provided"
    exit 1
fi

# Normalize extension and basename
BASENAME=$(basename "$GENOME")
PREFIX="${BASENAME%.*}"

echo "Preparing genome: $GENOME"

TARGET="${PREFIX}.fa"

if [ "$(realpath "$GENOME")" != "$(realpath "$TARGET" 2>/dev/null || echo '')" ]; then
    cp -f "$GENOME" "$TARGET"
fi

############################################
# STEP 2: REPEATMODELER
############################################
echo "Running RepeatModeler..."
BuildDatabase -name "$PREFIX" "${PREFIX}.fa"
RepeatModeler -database "$PREFIX" -threads 3 > run_repeatmodeler.log

mkdir -p RepeatModeler_output
cp RM_*/consensi.fa.classified RepeatModeler_output/ 2>/dev/null || true

############################################
# STEP 3: TRANSPOSONPSI
############################################
echo "Running TransposonPSI..."
transposonPSI.pl "${PREFIX}.fa" nuc

mkdir -p transposonpsi_result
mv "${PREFIX}.fa".TPSI.allHits* transposonpsi_result/ 2>/dev/null || true
cp "${PREFIX}.fa" transposonpsi_result/ || true

cd transposonpsi_result || exit 0
samtools faidx "${PREFIX}.fa" || true
bedtools getfasta -fo "${PREFIX}.fa.TPSI.best.fasta" \
  -s -fi "${PREFIX}.fa" \
  -bed "${PREFIX}.fa.TPSI.allHits.chains.bestPerLocus.gff3" || true

BuildDatabase -name "${PREFIX}.TPSI.best" "${PREFIX}.fa.TPSI.best.fasta" || true
RepeatClassifier -consensi "${PREFIX}.fa.TPSI.best.fasta" || true
cd ..

mkdir -p transposonpsi_output
cp transposonpsi_result/*classified transposonpsi_output/ 2>/dev/null || true

############################################
# STEP 4: FILTERING SHORT SEQUENCES
############################################
cd transposonpsi_output || exit 0
seqkit stat "${PREFIX}.fa.TPSI.best.fasta.classified" || true
seqkit seq -m 50 "${PREFIX}.fa.TPSI.best.fasta.classified" \
  > "${PREFIX}.fa.TPSI.best.fasta.classified.filtered" || true
cd ..

############################################
# STEP 5: LTRHARVEST + LTRDIGEST
############################################
echo "Running LTRharvest + LTRdigest..."
mkdir -p ltrdigest_output
cp "${PREFIX}.fa" ltrdigest_output/ || true
cd ltrdigest_output || exit 0

gt suffixerator -db "${PREFIX}.fa" -indexname "${PREFIX}.fsa" -tis -suf -lcp -des -ssp -sds -dna || true
gt ltrharvest -index "${PREFIX}.fsa" -v -out pred-"${PREFIX}.fsa" -outinner pred-inner-"${PREFIX}.fsa" -gff3 pred-"${PREFIX}.gff" || true
gt gff3 -sort pred-"${PREFIX}.gff" > sorted_pred-"${PREFIX}.gff" || true

gt ltrdigest -hmms "$DB_DIR/Pfam-A.hmm" -outfileprefix "${PREFIX}-ltrs" \
  sorted_pred-"${PREFIX}.gff" "${PREFIX}.fsa" > "${PREFIX}-ltrs_ltrdigest.gff3" || true

python3 "$SCRIPT_DIR/LTRdigest_parse_new.py" \
  -f "${PREFIX}-ltrs_complete.fas" \
  -g "${PREFIX}-ltrs_ltrdigest.gff3" \
  -o "${PREFIX}-ltrs_ltrdigest_filtered.tsv" || true

mv "${PREFIX}-ltrs_ltrdigest_filtered.tsv.fasta" "${PREFIX}-ltrs_ltrdigest_filtered.fasta" 2>/dev/null || true
BuildDatabase -name "${PREFIX}-ltrs" "${PREFIX}-ltrs_ltrdigest_filtered.fasta" || true
RepeatClassifier -consensi "${PREFIX}-ltrs_ltrdigest_filtered.fasta" || true
cd ..

mkdir -p ltrharvest_final_output
mv ltrdigest_output/"${PREFIX}-ltrs_ltrdigest_filtered.fasta.classified" ltrharvest_final_output/ 2>/dev/null || true

############################################
# STEP 6: MERGING LIBRARIES
############################################
mkdir -p final_library
cp RepeatModeler_output/consensi.fa.classified final_library/ 2>/dev/null || true
cp transposonpsi_output/*.classified final_library/ 2>/dev/null || true
cp ltrharvest_final_output/*.classified final_library/ 2>/dev/null || true

awk '/^>/ {printf("\n%s\n",$0);next;} {printf("%s",$0);} END {printf("\n");}' \
  final_library/*.classified > final_library/merged.fasta || true
awk 'NF' final_library/merged.fasta > final_library/merged.fa || true
sed -i 's/>* .*$//' final_library/merged.fa || true

############################################
# STEP 7: CLUSTERING (VSEARCH)
############################################
vsearch --sortbylength final_library/merged.fa \
  --output final_library/merged.sorted.fa \
  --log final_library/vsearch_sort.log || true

vsearch --cluster_fast final_library/merged.sorted.fa \
  --id 0.8 --iddef 1 --threads 3 \
  --centroids final_library/my_centroids.fa \
  --uc final_library/result.uc \
  --consout final_library/final.nr.consensus.fa \
  --msaout final_library/aligned.fasta \
  --log final_library/vsearch_cluster.log || true

############################################
# STEP 8: FINAL CLASSIFICATION
############################################
BuildDatabase -name "${PREFIX}_TEs-combined" final_library/final.nr.consensus.fa || true
RepeatClassifier -consensi final_library/final.nr.consensus.fa || true

grep ">" final_library/final.nr.consensus.fa.classified | \
awk -F"#" '{print $2}' | sort | uniq -c > final_library/final_types_count.txt || true

mv final_library/final.nr.consensus.fa.classified "${PREFIX}_TEs.fasta" 2>/dev/null || true
cp "${PREFIX}_TEs.fasta" combined_TE_candidates.fa

############################################
# STEP COMPLETE
############################################
echo "Step 1 finished successfully"


