#!/usr/bin/env python3

import os
import re
import glob
import argparse
import pandas as pd


def parse_filename(fn):
    #
    #Parse filenames like:
#
    #10001_generax-Gene-22__slc29a3__ENSDARG00000077828_OG0005720_Dclean_...json

   # into:
   #   - GeneNumberFull: 10001_generax-Gene-22
   #   - ParsedGeneSymbol: slc29a3
   #   - ParsedEnsemblID: ENSDARG00000077828
   #   - ParsedOrthogroup: OG0005720
#
  #  This is tolerant of extra '__' after the Ensembl ID.
  #  
    base = os.path.basename(str(fn))

    parts = base.split("__")

    gene_number = parts[0] if len(parts) > 0 else None
    gene_symbol = parts[1] if len(parts) > 1 else None

    ensembl_id = None
    orthogroup = None

    # Search the full filename for these, rather than assuming fixed positions
    m_ens = re.search(r"(ENS[A-Z0-9]*G[0-9]+)", base)
    if m_ens:
        ensembl_id = m_ens.group(1)

    m_og = re.search(r"(OG[0-9]+)", base)
    if m_og:
        orthogroup = m_og.group(1)

    return pd.Series({
        "GeneNumberFull": gene_number,
        "ParsedGeneSymbol": gene_symbol,
        "ParsedEnsemblID": ensembl_id,
        "ParsedOrthogroup": orthogroup,
    })


def process_csv(csv_file, filename_col):
    df = pd.read_csv(csv_file)

    if filename_col not in df.columns:
        print(f"Skipping {csv_file}: column '{filename_col}' not found")
        return

    parsed = df[filename_col].apply(parse_filename)
    out = pd.concat([df, parsed], axis=1)

    out_file = os.path.splitext(csv_file)[0] + "_parsed.csv"
    out.to_csv(out_file, index=False)
    print(f"Wrote: {out_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Parse filename metadata from a filename column across many CSVs."
    )
    parser.add_argument(
        "-i", "--input_dir",
        required=True,
        help="Directory containing CSV files"
    )
    parser.add_argument(
        "-c", "--column",
        default="Filename",
        help="Name of the column containing filenames (default: Filename)"
    )
    parser.add_argument(
        "-p", "--pattern",
        default="*.csv",
        help="Glob pattern for CSV files (default: *.csv)"
    )
    args = parser.parse_args()

    csv_files = sorted(glob.glob(os.path.join(args.input_dir, args.pattern)))

    if not csv_files:
        print("No CSV files found.")
        return

    for csv_file in csv_files:
        process_csv(csv_file, args.column)


if __name__ == "__main__":
    main()