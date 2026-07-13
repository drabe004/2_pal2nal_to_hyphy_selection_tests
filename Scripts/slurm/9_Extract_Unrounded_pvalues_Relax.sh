#!/bin/bash -l
#SBATCH --time=1:00:00
#SBATCH --ntasks=1
#SBATCH --mem=4g
#SBATCH --tmp=5g
#SBATCH --mail-type=ALL
#SBATCH --mail-user=drabe004@umn.edu
#SBATCH -p mcgaughs_2t

set -euo pipefail

CONFIG=9_Extract_Unrounded_pvalues_Relax.yaml


# ------------------- READ YAML -------------------

WORKDIR=$(yq -r '.working_directory' "$CONFIG")

MODULE=$(yq -r '.environment.module' "$CONFIG")

input_dir=$(yq -r '.paths.input_directory' "$CONFIG")
output_file=$(yq -r '.paths.output_file' "$CONFIG")

script=$(yq -r '.script.python_script' "$CONFIG")


# ------------------- ENVIRONMENT -------------------

cd "$WORKDIR"

module load "$MODULE"


# ------------------- RUN EXTRACTION -------------------

python "$script" \
    "$input_dir" \
    "$output_file"