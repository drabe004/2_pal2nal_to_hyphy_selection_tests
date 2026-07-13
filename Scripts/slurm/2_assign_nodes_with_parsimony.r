
library(phytools)
library(maps)
library(ape)
library(phangorn)
library(castor)

args <- commandArgs(trailingOnly = TRUE)

tree_directory  <- args[1]
foreground_file <- args[2]
r_library_path  <- args[3]

.libPaths(new = r_library_path)

# ------------------- READ FOREGROUND LIST ONCE -------------------
foreground_taxa <- readLines(foreground_file)
foreground_taxa <- gsub("^\\s+|\\s+$", "", foreground_taxa)
foreground_taxa <- foreground_taxa[foreground_taxa != ""]

# ------------------- FIND TREES -------------------
tree_files <- list.files(tree_directory, pattern = "\\.tre$", full.names = TRUE)

# Output folder (single place for all results)
output_directory <- file.path(tree_directory, "FGBGTrees")
dir.create(output_directory, showWarnings = FALSE)

# ------------------- LOOP THROUGH TREES -------------------
for (tree_file in tree_files) {

  tree <- read.tree(tree_file)

  # Use the tree filename stem for outputs
  filename <- basename(tree_file)
  filename <- gsub("\\.tre$", "", filename)

  # Create trait states for this tree
  all_taxa <- tree$tip.label
  trait_states <- data.frame(Species = all_taxa, TraitState = "Background", stringsAsFactors = FALSE)
  trait_states$TraitState[trait_states$Species %in% foreground_taxa] <- "Foreground"

  # Save trait states (optional but nice for debugging)
  trait_csv_file <- file.path(output_directory, paste0(filename, "_Species_TraitStates.csv"))
  write.csv(trait_states, file = trait_csv_file, row.names = FALSE)

  # Convert to numeric states for castor
  trait_states$TraitState <- as.integer(trait_states$TraitState == "Background") + 1
  tip_states <- trait_states$TraitState

  # Parsimony ASR
  asr_result <- asr_max_parsimony(
    tree,
    tip_states,
    Nstates = 2,
    transition_costs = "all_equal",
    edge_exponent = 0,
    weight_by_scenarios = TRUE,
    check_input = TRUE
  )

  # Write ancestral likelihoods
  likelihoods_csv_file <- file.path(output_directory, paste0(filename, "_Ancestral_Likelihoods.csv"))
  write.csv(asr_result$ancestral_likelihoods, file = likelihoods_csv_file, row.names = FALSE)

  # Label nodes
  tree$node.label <- rep("", tree$Nnode)
  for (i in seq_along(asr_result$ancestral_states)) {
    if (asr_result$ancestral_states[i] == 1) tree$node.label[i] <- "{Foreground}"
    if (asr_result$ancestral_states[i] == 2) tree$node.label[i] <- ""  # hide background
  }

  # Re-tag foreground tips for clarity
  for (i in seq_along(tree$tip.label)) {
    if (tree$tip.label[i] %in% foreground_taxa) {
      tree$tip.label[i] <- paste0(tree$tip.label[i], "{Foreground}")
    }
  }

  # Write modified tree
  output_tree_file <- file.path(output_directory, paste0(filename, "_FGBG.tre"))
  write.tree(tree, file = output_tree_file)
}
