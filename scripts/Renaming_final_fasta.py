#!/usr/bin/env python3

import pandas as pd
from Bio import SeqIO

# ----------------------------
# Input files
# ----------------------------
import sys

results_file = sys.argv[1]
fasta_file = sys.argv[2]
output_fasta = sys.argv[3]
output_te_types = sys.argv[4]

# ----------------------------
# Load BLAST results
# ----------------------------
print("Loading BLAST results...")

cols = ["qseqid", "sseqid", "pident", "length", "evalue", "bitscore"]
df = pd.read_csv(results_file, sep="\t", header=None, names=cols)

# Clean columns
df["qseqid"] = df["qseqid"].astype(str).str.strip()
df["sseqid"] = df["sseqid"].astype(str).str.strip()
df["evalue"] = pd.to_numeric(df["evalue"], errors="coerce")
df["bitscore"] = pd.to_numeric(df["bitscore"], errors="coerce")

# ----------------------------
# Select best hit per query
# ----------------------------
df_best = (
    df.sort_values(["qseqid", "evalue", "bitscore"],
                   ascending=[True, True, False])
      .drop_duplicates("qseqid")
)

# Extract TE class (text after '#')
df_best["te_class"] = df_best["sseqid"].str.split("#").str[-1]

# Create mapping dictionary
id_to_class = dict(zip(df_best["qseqid"], df_best["te_class"]))

print(f"Unique BLAST hits found: {len(id_to_class)}")

# ----------------------------
# Rename FASTA headers
# ----------------------------
renamed = 0
unknown = 0
records = []
te_types_set = set()

for rec in SeqIO.parse(fasta_file, "fasta"):
    qid = rec.id.strip()

    if qid in id_to_class:
        te_class = id_to_class[qid]
        renamed += 1
    else:
        te_class = "Unknown"
        unknown += 1

    # Remove '#' and keep only class name
    rec.id = te_class
    rec.description = ""
    records.append(rec)

    te_types_set.add(te_class)

# Write renamed FASTA
SeqIO.write(records, output_fasta, "fasta")

# ----------------------------
# Write TE types file
# ----------------------------
with open(output_te_types, "w") as out:
    for te in sorted(te_types_set):
        out.write(te + "\n")

# ----------------------------
# Summary
# ----------------------------
print("\n=== SUMMARY ===")
print(f"Renamed using BLAST: {renamed}")
print(f"Assigned as Unknown: {unknown}")
print(f"Total sequences processed: {renamed + unknown}")
print(f"Unique TE types found: {len(te_types_set)}")
print(f"Renamed FASTA written to: {output_fasta}")
print(f"TE types list written to: {output_te_types}")
