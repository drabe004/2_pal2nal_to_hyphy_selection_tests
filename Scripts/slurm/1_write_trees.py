from Bio import Phylo
from Bio import SeqIO
import os
import argparse
import copy
import subprocess

### Prune tree to keep only species present in the FASTA
def prune_tree(tree, species_list):
    keep = set(species_list)

    ### Iterate over a copy since pruning mutates the tree
    for leaf in list(tree.get_terminals()):
        if leaf.name not in keep:
            tree.prune(leaf)

def main():
    parser = argparse.ArgumentParser(
        description="Generate pruned tree files based on species in FASTA alignments."
    )
    parser.add_argument("master_tree", help="Path to the master tree file (in Newick format)")
    parser.add_argument("fasta_directory", help="Path to the directory containing FASTA alignment files")
    parser.add_argument(
        "--outdir",
        help="Output directory for pruned tree files (default: same as fasta_directory)",
        default=None
    )
    args = parser.parse_args()

    master_tree_file = args.master_tree
    fasta_directory = args.fasta_directory
    outdir = args.outdir if args.outdir else fasta_directory
    os.makedirs(outdir, exist_ok=True)

    ### Read the master tree
    master_tree = Phylo.read(master_tree_file, "newick")

    ### List all FASTA files in the directory
    fasta_files = [f for f in os.listdir(fasta_directory) if f.endswith(".fasta")]

    for fasta_file in fasta_files:
        fasta_path = os.path.join(fasta_directory, fasta_file)
        tree_output_path = os.path.join(outdir, f"{os.path.splitext(fasta_file)[0]}.tre")

        ### Parse FASTA and extract species name BEFORE first underscore
        species_list = [
            record.id.split("_", 1)[0]
            for record in SeqIO.parse(fasta_path, "fasta")
        ]

        ### Prune the master tree
        pruned_tree = copy.deepcopy(master_tree)
        prune_tree(pruned_tree, species_list)

        ### Write the pruned tree
        Phylo.write(pruned_tree, tree_output_path, "newick")

        ### Remove branch lengths
        subprocess.run(
            ["sed", "-i", "-E", r"s/:[0-9]+\.?[0-9]*//g", tree_output_path]
        )

if __name__ == "__main__":
    main()