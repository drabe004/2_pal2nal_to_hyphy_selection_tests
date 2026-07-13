#!/bin/bash -l
#SBATCH --time=9:00:00
#SBATCH --ntasks=1
#SBATCH --mem=8g
#SBATCH --tmp=50g
#SBATCH --mail-type=ALL
#SBATCH --mail-user=drabe004@umn.edu
#SBATCH -p mcgaughs_2t

CONFIG=1_write_trees.yaml

WORKDIR=$(yq -r '.working_directory' "$CONFIG")
MODULE=$(yq -r '.environment.module' "$CONFIG")
CONDA_ENV=$(yq -r '.environment.conda_env' "$CONFIG")

MASTERTREE=$(yq -r '.paths.master_tree' "$CONFIG")
CODONALNS=$(yq -r '.paths.codon_alignments' "$CONFIG")
OUTDIR=$(yq -r '.paths.output_directory' "$CONFIG")

cd "$WORKDIR"

module load "$MODULE"
source activate "$CONDA_ENV"

python 1_write_trees.py \
    "$MASTERTREE" \
    "$CODONALNS" \
    --outdir "$OUTDIR"