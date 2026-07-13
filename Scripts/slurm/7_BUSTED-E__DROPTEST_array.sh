#!/bin/bash -l
#SBATCH --time=96:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --array=1-4000
#SBATCH --mail-type=ALL
#SBATCH --mail-user=drabe004@umn.edu
#SBATCH -J DROP_BRAv9_patch
#SBATCH -o BUSTED_DROP_logs/%x_%A_%a.out
#SBATCH -e BUSTED_DROP_logs/%x_%A_%a.err
#SBATCH -p mcgaughs_2t

set -euo pipefail

CONFIG=7_BUSTED-E_DROPTEST_array.yaml


# ------------------- READ YAML -------------------

WORKDIR=$(yq -r '.working_directory' "$CONFIG")

MODULE=$(yq -r '.environment.module' "$CONFIG")

aln_dir=$(yq -r '.paths.alignment_directory' "$CONFIG")
tree_dir=$(yq -r '.paths.tree_directory' "$CONFIG")
out_dir=$(yq -r '.paths.output_directory' "$CONFIG")
log_dir=$(yq -r '.paths.log_directory' "$CONFIG")

pattern=$(yq -r '.files.alignment_pattern' "$CONFIG")
list_name=$(yq -r '.files.alignment_list' "$CONFIG")

tree_remove=$(yq -r '.tree.suffix_remove' "$CONFIG")
tree_add=$(yq -r '.tree.suffix_add' "$CONFIG")

srv=$(yq -r '.analysis.srv' "$CONFIG")
error_sink=$(yq -r '.analysis.error_sink' "$CONFIG")


# ------------------- ENVIRONMENT -------------------

cd "$WORKDIR"

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

tree_base="${aln_name%.fasta}.tre"
tree="${tree_dir}/${tree_base}"

out="${out_dir}/${base}_BUSTEDE_DROP.txt"
json="${out_dir}/${base}_BUSTEDE_DROP.json"


echo "Task ID:       $task_id"
echo "List file:     $list_file"
echo "Alignment:     $aln_name"
echo "Expected tree: $tree"


if [[ ! -f "$tree" ]]; then
    echo "ERROR: Tree file not found for alignment: ${aln_name}" >&2
    echo "Expected tree:" >&2
    echo "$tree" >&2
    exit 0
fi


echo "Tree:   $(basename "$tree")"
echo "Output: $(basename "$json")"
echo "Start:  $(date)"


# ------------------- RUN BUSTED DROP -------------------

hyphy "CPU=${SLURM_CPUS_PER_TASK}" busted \
    --alignment "$aln" \
    --tree "$tree" \
    --srv "$srv" \
    --error-sink "$error_sink" \
    --output "$json" \
    > "$out"


echo "Done: $(date)"