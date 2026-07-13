#!/bin/bash -l
#SBATCH --time=96:00:00
#SBATCH --ntasks=120
#SBATCH --mem=500g
#SBATCH --tmp=250g
#SBATCH -p mcgaughs_2t
#SBATCH --mail-type=ALL
#SBATCH --mail-user=drabe004@umn.edu

CONFIG=2_assign_nodes_with_parsimony.yaml

WORKDIR=$(yq -r '.working_directory' "$CONFIG")
MODULE=$(yq -r '.environment.module' "$CONFIG")
TREE_DIR=$(yq -r '.paths.tree_directory' "$CONFIG")
FG_FILE=$(yq -r '.paths.foreground_file' "$CONFIG")
R_LIB=$(yq -r '.r.library_path' "$CONFIG")

cd "$WORKDIR"

module load "$MODULE"

Rscript 9PARSIMONY_LOOPED_AF.r \
    "$TREE_DIR" \
    "$FG_FILE" \
    "$R_LIB"