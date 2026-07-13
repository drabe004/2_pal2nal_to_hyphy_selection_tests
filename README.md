# PAL2NAL to HyPhy Selection Tests Pipeline

## Overview

This pipeline performs genome-wide codon-based molecular evolution analyses using HyPhy following generation of codon alignments with PAL2NAL. It automates preparation of foreground/background trees, branch annotation, multiple selection analyses, drop-test validation, and extraction of final summary statistics.

The workflow is designed for large comparative genomics datasets and is parallelized using SLURM job arrays for execution on high-performance computing clusters.

---

## Pipeline Overview

```
PAL2NAL codon alignments
          ¦
          ?
1. Generate gene trees
          ¦
          ?
2. Assign foreground/background branches
          ¦
          +---------------------------------+
          ?               ?                 ?
3. BUSTED-E         4. BUSTED-PH       5. RELAX
          ¦
          ?
6. Remove foreground taxa
          ¦
          ?
7. BUSTED-E Drop Test
          ¦
          ?
8–10. Extract results and build summary tables
```

---

# Pipeline Steps

## Step 1 — Generate HyPhy Tree Files

**Scripts**

* `1_write_trees.py`
* `1_write_trees.sh`

Generates the tree files required for HyPhy analyses from the input phylogenetic trees. Output trees are formatted for downstream branch-labeling and selection analyses.

---

## Step 2 — Assign Foreground Branches

**Scripts**

* `2_assign_nodes_with_parsimony.r`
* `2_assign_nodes_with_parsimony.sh`

Uses maximum parsimony to reconstruct foreground/background character states across each phylogeny and labels branches for HyPhy analyses.

The resulting trees contain the branch annotations required by BUSTED-E, BUSTED-PH, and RELAX.

---

## Step 3 — Run BUSTED-E

**Script**

* `3_BUSTED-E_array.sh`

Runs HyPhy BUSTED-E on every codon alignment using the annotated foreground/background trees.
settings -srv Yes; error sink Yes

Purpose:

* detect episodic positive selection on foreground branches

Outputs:

* one JSON result per orthogroup

---

## Step 4 — Run BUSTED-PH

**Script**

* `4_BUSTED-PH_array.sh`

Runs HyPhy BUSTED-PH to test whether adaptive evolution is concentrated within the foreground lineage.
settings -srv Yes; error sink Yes

Outputs:

* one JSON result per orthogroup

---

## Step 5 — Run RELAX

**Script**

* `5_RELAX_array.sh`

Runs HyPhy RELAX to test whether selective pressure has intensified or relaxed on foreground branches.

settings -srv Yes

Outputs:

* one JSON result per orthogroup

---

## Step 6 — Generate Drop-Test Alignments

**Scripts**

* `6_remove_foreground_from_alignments.py`
* `6_remove_cavefish_from_alignments.sh`

Removes all foreground taxa from each codon alignment while preserving background sequences.

These reduced alignments are used to evaluate whether BUSTED-E significance persists after removal of the foreground lineage.
DO NOT FORGET TO GENERATE TREES WITH THIS NEW SET OF ALIGNMENTS

---

## Step 7 — Run BUSTED-E Drop Test

**Script**

* `7_BUSTED-E_DROPTEST_array.sh`

Runs BUSTED-E on the foreground-removed alignments.

Genes that remain significant after removal of the foreground lineage have selection in non-foreground species.

---

## Step 8 — Extract BUSTED Results

**Scripts**

* `8_Extract_Unrounded_pvalues.py`
* `8_Extract_unrounded_pvalues.sh`

Extracts complete statistics from BUSTED-E, BUSTED-PH, and Drop-Test JSON output, including full-precision p-values with FDR correction.

Produces consolidated CSV summary tables.

---

## Step 9 — Extract RELAX Results

**Scripts**

* `9_Extract_Unrounded_pvalues_Relax.py`
* `9_Extract_Unrounded_pvalues_Relax.sh`

Extracts full-precision RELAX statistics from HyPhy output JSON files and writes summary tables with FDR correction.

---

## Step 10 — Parse gene symbol from file names

**Scripts**

* `10_parseCSVs.py`
* `10_parseCSVs.sh`

Combines all intermediate summary tables into a single master results file containing:

* BUSTED-E statistics
* BUSTED-PH statistics
* RELAX statistics
* Drop-test results

This table serves as the primary downstream input for statistical analyses, enrichment analyses, and candidate gene prioritization.

---

# Expected Inputs

* PAL2NAL codon alignments
* Gene trees
* Foreground/background species definitions
* Branch-annotated trees (generated in Step 2)

---

# Expected Outputs

The pipeline generates:

* Branch-labeled HyPhy trees
* BUSTED-E results
* BUSTED-PH results
* RELAX results
* Foreground-removed alignments
* Drop-test BUSTED-E results
* Full-precision result tables
* Final merged summary table

---

# Notes

* All computationally intensive analyses are executed as SLURM job arrays.
* Branch labeling uses maximum parsimony reconstruction.
* The drop-test provides an additional quality-control filter to identify genes whose positive selection is also present in background lineages.
* Final summary tables preserve unrounded p-values for downstream multiple-testing correction and statistical analyses.
