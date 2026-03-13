#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Step 3: Manual curation"

THREADS=3
WORKDIR="$(pwd)"
TE_DIR="$WORKDIR/FINAL_TE_LIBRARY"

############################################
# CHECK STEP 2 OUTPUT
############################################

shopt -s nullglob
TE_FILES=("$TE_DIR"/*_FINAL_TEs.fa)

if [[ ${#TE_FILES[@]} -eq 0 ]]; then
    echo "❌ No FINAL_TEs.fa found from Step 2"
    exit 1
fi

if [[ ${#TE_FILES[@]} -gt 1 ]]; then
    echo "⚠️ Multiple FINAL_TEs files detected:"
    printf '%s\n' "${TE_FILES[@]}"
    echo "Using first file only."
fi

INPUT_FILE="${TE_FILES[0]}"

echo "✔ Using Step 2 output:"
echo "   $INPUT_FILE"

############################################
# RUN CD-HIT (FINAL REDUNDANCY REMOVAL)
############################################

mkdir -p "$WORKDIR/final_curated_library"

BASENAME=$(basename "$INPUT_FILE")
BASENAME=${BASENAME%.fa}
BASENAME=${BASENAME%.fasta}

OUTPUT_FILE="$WORKDIR/final_curated_library/${BASENAME}_FINAL_CURATED_TE_LIBRARY.fa"

cd-hit-est \
    -i "$INPUT_FILE" \
    -o "$OUTPUT_FILE" \
    -c 0.9 -aS 0.9 -M 16000 -T "$THREADS"

echo "✅ Final curated TE library created:"
echo "   $OUTPUT_FILE"

echo "🏁 Step 3 completed"