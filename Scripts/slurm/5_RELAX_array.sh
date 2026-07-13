#!/bin/bash -l
#SBATCH --time=96:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --array=1-4000
#SBATCH --mail-type=ALL
#SBATCH --mail-user=drabe004@umn.edu
#SBATCH -J Relax
#SBATCH -o RELAX_logs/RELAX_logs_%A_%a.out
#SBATCH -e RELAX_logs/RELAX_logs_%A_%a.err
#SBATCH -p mcgaughs_2t

set -euo pipefail

CONFIG=5_RELAX_array.yaml


# ------------------- READ YAML -------------------

WORKDIR=$(yq -r '.working_directory' "$CONFIG")

MODULE_PATH=$(yq -r '.environment.module_path' "$CONFIG")
MODULE=$(yq -r '.environment.module' "$CONFIG")

aln_dir=$(yq -r '.paths.alignment_directory' "$CONFIG")
tree_dir=$(yq -r '.paths.tree_directory' "$CONFIG")
out_dir=$(yq -r '.paths.output_directory' "$CONFIG")
log_dir=$(yq -r '.paths.log_directory' "$CONFIG")

pattern=$(yq -r '.files.alignment_pattern' "$CONFIG")
list_name=$(yq -r '.files.alignment_list' "$CONFIG")

test_branch=$(yq -r '.analysis.test_branch' "$CONFIG")
srv=$(yq -r '.analysis.srv' "$CONFIG")


# ------------------- ENVIRONMENT -------------------

cd "$WORKDIR"

module use "$MODULE_PATH"
module load "$MODULE"

mkdir -p "$out_dir" "$log_dir"


# ------------------- BUILD ALIGNMENT LIST -------------------

list_file="${aln_dir}/${list_name}"

if [[ ! -s "$list_file" ]]; then
    echo "Alignment list not found or empty."
    echo "Creating:"
    echo "$list_file"

    find "$aln_dir" -maxdepth 1 -type f -name "$pattern" | sort > "$list_file"
fi

n=$(wc -l < "$list_file")

echo "Found $n alignments."


# ------------------- ARRAY INDEX CHECK -------------------

task_id="${SLURM_ARRAY_TASK_ID}"

if (( task_id < 1 || task_id > n )); then
    echo "Array task ${task_id} out of range for ${n} alignments."
    exit 0
fi


# ------------------- SELECT ALIGNMENT -------------------

aln=$(sed -n "${task_id}p" "$list_file")

if [[ -z "${aln:-}" || ! -f "$aln" ]]; then
    echo "ERROR: Alignment not found:"
    echo "$aln"
    exit 1
fi


# ------------------- MATCH TREE -------------------

aln_name=$(basename "$aln")
base="${aln_name%.fasta}"

tree_base="${aln_name%.fasta}_FGBG.tre"
tree="${tree_dir}/${tree_base}"

out_txt="${out_dir}/${base}_RELAX.txt"
out_json="${out_dir}/${base}_RELAX.json"


echo "[$(date)] Task ${task_id}/${n} running RELAX"
echo "List file:     $list_file"
echo "Alignment:     $aln_name"
echo "Expected tree: $tree"


if [[ ! -f "$tree" ]]; then
    echo "[$(date)] ERROR: Tree file not found for alignment: ${aln_name}" >&2
    echo "Expected tree:" >&2
    echo "$tree" >&2
    exit 0
fi


echo "Tree:      $(basename "$tree")"
echo "JSON:      $(basename "$out_json")"
echo "TXT:       $(basename "$out_txt")"
echo "CPUs:      ${SLURM_CPUS_PER_TASK}"
echo "Start:     $(date)"


# ------------------- RUN RELAX -------------------

hyphy "CPU=${SLURM_CPUS_PER_TASK}" relax \
    --alignment "$aln" \
    --tree "$tree" \
    --test "$test_branch" \
    --output "$out_json" \
    --srv "$srv" \
    > "$out_txt"


echo "Done: $(date)"