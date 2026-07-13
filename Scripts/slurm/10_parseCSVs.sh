#!/bin/bash -l
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --mem=4g
#SBATCH --tmp=5g
#SBATCH --mail-type=ALL
#SBATCH --mail-user=drabe004@umn.edu
#SBATCH -p mcgaughs_2t

set -euo pipefail

CONFIG=10_parseCSVs.yaml


# ------------------- READ YAML -------------------

WORKDIR=$(yq -r '.working_directory' "$CONFIG")

MODULE=$(yq -r '.environment.module' "$CONFIG")
CONDA_ENV=$(yq -r '.environment.conda_env' "$CONFIG")

input_dir=$(yq -r '.paths.input_directory' "$CONFIG")

script=$(yq -r '.script.python_script' "$CONFIG")


# ------------------- ENVIRONMENT -------------------

cd "$WORKDIR"

module load "$MODULE"
source activate "$CONDA_ENV"


# ------------------- RUN PARSER -------------------

python "$script" \
    -i "$input_dir"