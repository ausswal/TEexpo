# TEexpo v1.0

# TEexpo v1.0

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19046077.svg)](https://doi.org/10.5281/zenodo.19046077) 
[![Bioconda](https://img.shields.io/conda/vn/bioconda/teexpo.svg)](https://anaconda.org/bioconda/teexpo) 
[![Downloads](https://img.shields.io/conda/dn/bioconda/teexpo.svg)](https://anaconda.org/bioconda/teexpo)

TEexpo is an automated and modular pipeline for genome-wide identification, classification, and curation of transposable elements (TEs).  
The pipeline integrates multiple widely used bioinformatics tools into a unified framework, enabling reproducible TE discovery and annotation with minimal manual intervention.

TEexpo is designed to simplify TE analysis while producing curated TE libraries and publication-ready outputs suitable for downstream genomic and evolutionary studies.

---

## Overview

Transposable elements (TEs) are mobile genetic elements that significantly influence genome evolution, structural variation, and gene regulation. However, comprehensive TE discovery often requires combining several tools and manual curation steps.

TEexpo provides a unified, automated workflow that streamlines TE identification, classification, and genome-wide annotation.

After each run, the workspace is automatically organized so that only the input genome and a single `final_output/` directory remain, ensuring a clean and reproducible analysis environment.

---

## Features

- Single-command execution  
  Run the entire TE discovery pipeline using a single command.

- Automated TE library generation  
  Constructs high-confidence TE libraries directly from genomic sequences.

- Integrated TE classification  
  Combines multiple classification strategies to improve annotation accuracy.

- Genome-wide annotation  
  Produces RepeatMasker-based TE annotations for downstream analysis.

- Automated database management  
  Downloads and configures required TE databases automatically.

- Reproducible workflow  
  Designed to generate consistent results across computing environments.

- Clean workspace structure  
  After completion, only the genome file and `final_output/` directory remain.

---

## Installation

TEexpo can be installed using Conda.

```bash
conda install -c bioconda teexpo

## Database Setup
teexpo download-db

## Verify that all databases are installed correctly
teexpo check-db

- This step downloads and configures required resources such as:

- Pfam protein domain database

- RepeatPeps TE protein database

- SwissProt protein database

## Usage

Run TEexpo by providing a genome FASTA file:
teexpo genome.fa

Example:
teexpo Plasmodium_genome.fa

## Output

After the pipeline finishes, all results will be stored in:
final_output/

Typical output structure:
final_output/
├── Final_TE_Library
├── RepeatMasker_output/
├── TE_dashboard_barplot.png
├── TE_dashboard_family_summary.csv
├── TE_dashboard_length_hist.png
├── TE_dashboard_pie.png
├── TE_dashboard_summary.csv
└── te_types.txt


These outputs can be used for:

1. transposable element landscape analysis

2. genome annotation

3. evolutionary studies

4. comparative genomics

## Requirements

TEexpo integrates several established bioinformatics tools, including:

RepeatModeler

RepeatMasker

BLAST+

HMMER

RECON

RepeatScout

These dependencies are automatically handled through the Conda environment.

## Tested Genomes

TEexpo has been tested on several Plasmodium genomes, including:

Plasmodium falciparum

Plasmodium vivax 

Plasmodium berghei

Plasmodium knowlesi

## Authors

Swarup Das¹
Subarna Thakur¹*

¹ Department of Bioinformatics
University of North Bengal
Darjeeling, West Bengal 734013, India

Correspondence:
subarna.thakur@nbu.ac.in 

## Citation

If you use TEexpo in your research, please cite:

Das S, Thakur S. 2026.  
TEexpo: Transposable element annotation pipeline.  
Zenodo. https://doi.org/10.5281/zenodo.19046077

## License

This project is licensed under the MIT License.

See the LICENSE file for details.

## Contact

For questions, suggestions, or bug reports, please contact:

rs_swarup@nbu.ac.in

or open an issue on the GitHub repository.
