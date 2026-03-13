#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo "TEexpo Database Installer"
echo "======================================"

DB_DIR="$HOME/.teexpo/databases"
mkdir -p "$DB_DIR"

############################################
# 1️⃣ PFAM (HMMER database)
############################################

echo ""
echo "📦 Installing Pfam..."

PFAM_URL="https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz"
PFAM_HMM="$DB_DIR/Pfam-A.hmm"

if [ ! -f "$PFAM_HMM" ]; then
    curl -L "$PFAM_URL" -o "$DB_DIR/Pfam-A.hmm.gz"
    gunzip -f "$DB_DIR/Pfam-A.hmm.gz"

    echo "Running hmmpress..."
    hmmpress "$PFAM_HMM"

    echo "✔ Pfam installed and hmmpressed."
else
    echo "✔ Pfam already exists. Skipping."
fi

############################################
# 2️⃣ RepeatPeps
############################################

echo ""
echo "📦 Installing RepeatPeps..."

REPEATPEPS_URL="https://raw.githubusercontent.com/Dfam-consortium/RepeatMasker/master/Libraries/RepeatPeps.lib"
REPEATPEPS_FA="$DB_DIR/RepeatPeps.fa"

if [ ! -f "$REPEATPEPS_FA" ]; then
    curl -L "$REPEATPEPS_URL" -o "$DB_DIR/RepeatPeps.lib"

    # Convert to FASTA format
    grep -v "^#" "$DB_DIR/RepeatPeps.lib" > "$REPEATPEPS_FA"
    rm "$DB_DIR/RepeatPeps.lib"

    echo "Building BLAST DB for RepeatPeps..."
    makeblastdb -in "$REPEATPEPS_FA" -dbtype prot

    echo "✔ RepeatPeps installed."
else
    echo "✔ RepeatPeps already exists. Skipping."
fi

############################################
# 3️⃣ SwissProt (Reviewed proteins)
############################################

echo ""
echo "📦 Installing SwissProt..."

SWISSPROT_URL="https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz"
SWISSPROT_FA="$DB_DIR/uniprot_sprot.fasta"

if [ ! -f "$SWISSPROT_FA" ]; then
    curl -L "$SWISSPROT_URL" -o "$DB_DIR/uniprot_sprot.fasta.gz"
    gunzip -f "$DB_DIR/uniprot_sprot.fasta.gz"

    echo "Building BLAST DB for SwissProt..."
    makeblastdb -in "$SWISSPROT_FA" -dbtype prot

    echo "✔ SwissProt installed."
else
    echo "✔ SwissProt already exists. Skipping."
fi

############################################
# FINISHED
############################################

echo ""
echo "======================================"
echo "✅ All databases installed successfully."
echo "Location: $DB_DIR"
echo "======================================"