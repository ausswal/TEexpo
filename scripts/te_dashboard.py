#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import os

# ================================
# INPUT
# ================================
RM_OUT = "RepeatMasker_output/P_Genome_clean.fa.out"
OUT_PREFIX = "TE_dashboard"

# ================================
# STEP 1: PARSE RepeatMasker .out
# ================================
print("Reading RepeatMasker output...")

data = []

with open(RM_OUT) as f:
    for line in f:
        if line.startswith(" ") or line.strip() == "":
            parts = line.split()

            if len(parts) < 11:
                continue

            try:
                repeat = parts[10]   # TE name (e.g., LINE/I-Jockey)
                start = int(parts[5])
                end = int(parts[6])

                length = abs(end - start)

                # Split class
                if "/" in repeat:
                    te_class, te_family = repeat.split("/", 1)
                else:
                    te_class = repeat
                    te_family = "Unknown"

                data.append([repeat, te_class, te_family, length])

            except:
                continue

# Convert to DataFrame
df = pd.DataFrame(data, columns=["repeat", "class", "family", "length"])

if df.empty:
    print("❌ No TE data found!")
    exit()

print("✔ Parsed entries:", len(df))

# ================================
# STEP 2: SUMMARY
# ================================
summary = df.groupby("class").size().reset_index(name="count")
summary = summary.sort_values(by="count", ascending=False)

summary.to_csv(f"{OUT_PREFIX}_summary.csv", index=False)
print("✔ Summary saved")

# ================================
# STEP 3: PIE CHART
# ================================
plt.figure()

plt.pie(summary["count"],
        labels=summary["class"],
        autopct="%1.1f%%")

plt.title("TE Composition (Class Level)")
plt.savefig(f"{OUT_PREFIX}_pie.png", dpi=300)
plt.close()

print("✔ Pie chart saved")

# ================================
# STEP 4: BARPLOT
# ================================
plt.figure()

plt.bar(summary["class"], summary["count"])

plt.xticks(rotation=45)
plt.ylabel("Count")
plt.title("TE Class Distribution")

plt.tight_layout()
plt.savefig(f"{OUT_PREFIX}_barplot.png", dpi=300)
plt.close()

print("✔ Barplot saved")

# ================================
# STEP 5: HISTOGRAM (Length)
# ================================
plt.figure()

plt.hist(df["length"], bins=50)

plt.xlabel("TE Length")
plt.ylabel("Frequency")
plt.title("TE Length Distribution")

plt.savefig(f"{OUT_PREFIX}_length_hist.png", dpi=300)
plt.close()

print("✔ Histogram saved")

# ================================
# STEP 6: FAMILY LEVEL (OPTIONAL)
# ================================
family_summary = df.groupby("family").size().reset_index(name="count")
family_summary = family_summary.sort_values(by="count", ascending=False)

family_summary.to_csv(f"{OUT_PREFIX}_family_summary.csv", index=False)

print("✔ Family-level summary saved")

print("\n🎉 Dashboard generation completed!")