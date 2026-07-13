#!/bin/bash -l
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --mem=8g
#SBATCH --tmp=5g
#SBATCH --mail-type=ALL
#SBATCH --mail-user=drabe004@umn.edu
#SBATCH -p mcgaughs_2t

set -euo pipefail

CONFIG=6_remove_cavefish_from_alignments.yaml


# ------------------- READ YAML -------------------

WORKDIR=$(yq -r '.working_directory' "$CONFIG")

MODULE=$(yq -r '.environment.module' "$CONFIG")
CONDA_ENV=$(yq -r '.environment.conda_env' "$CONFIG")

species_list=$(yq -r '.paths.species_list' "$CONFIG")
aln_dir=$(yq -r '.paths.alignment_directory' "$CONFIG")
out_dir=$(yq -r '.paths.output_directory' "$CONFIG")


# ------------------- ENVIRONMENT -------------------

cd "$WORKDIR"

module load "$MODULE"
source activate "$CONDA_ENV"


# ------------------- RUN SCRIPT -------------------

python3 remove_cavefish_from_alignments.py \
    --species_list "$species_list" \
    --aln_dir "$aln_dir" \
    --out_dir "$out_dir"