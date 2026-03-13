#!/usr/bin/env bash
set -euo pipefail

############################################
# EXPECT VARIABLES FROM LAUNCHER
############################################

if [[ -z "${DB_DIR:-}" ]] || [[ -z "${SCRIPT_DIR:-}" ]]; then
    echo "❌ ERROR: Environment variables not set."
    echo "Run this script via the 'teexpo' launcher."
    exit 1
fi

echo "🔍 STEP 0: Checking environment & dependencies..."
echo "📅 $(date)"

############################################
# REQUIRED TOOLS
############################################

REQUIRED_TOOLS=(
  RepeatModeler
  RepeatMasker
  RepeatClassifier
  BuildDatabase
  blastn
  blastx
  makeblastdb
  bedtools
  seqkit
  tRNAscan-SE
  gt
  mafft
  trimal
  cd-hit-est
  vsearch
  samtools
  python3
  awk
  sed
)

echo "======================================"
echo "🔧 Checking tools..."
echo "======================================"

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "❌ ERROR: $tool not found in PATH"
        exit 1
    else
        echo "✔ $tool found: $(command -v "$tool")"
    fi
done

############################################
# TOOL VERSIONS
############################################

echo "======================================"
echo "📦 Tool versions"
echo "======================================"

RepeatMasker -version 2>/dev/null || true
RepeatModeler -version 2>/dev/null || true
blastn -version | head -n 1 || true
mafft --version 2>/dev/null || true
cd-hit-est -h | head -n 1 || true
vsearch --version || true

############################################
# DATABASE CHECKS
############################################

echo "======================================"
echo "🧬 Checking databases..."
echo "======================================"

# Pfam
if [[ -f "$DB_DIR/Pfam-A.hmm" ]]; then
    echo "✔ Pfam-A.hmm found"
else
    echo "❌ ERROR: Pfam-A.hmm missing in $DB_DIR"
    exit 1
fi

# RepeatPeps
if [[ -f "$DB_DIR/RepeatPeps.lib" ]]; then
    echo "✔ RepeatPeps.lib found"
else
    echo "❌ ERROR: RepeatPeps.lib missing in $DB_DIR"
    exit 1
fi

############################################
# PYTHON SCRIPT CHECK
############################################

echo "======================================"
echo "🐍 Checking required scripts..."
echo "======================================"

REQUIRED_SCRIPTS=(
  "$SCRIPT_DIR/LTRdigest_parse_new.py"
  "$SCRIPT_DIR/Renaming_final_fasta.py"
  "$SCRIPT_DIR/te_dashboard.py"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -f "$script" ]]; then
        echo "❌ ERROR: Missing script → $script"
        exit 1
    else
        echo "✔ Found script: $script"
    fi
done

echo "======================================"
echo "✅ Environment check PASSED"
echo "🚀 TEexpo is ready to run"
echo "======================================"
