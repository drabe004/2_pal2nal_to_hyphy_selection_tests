import os
import json
import csv
import sys
import re

def extract_gene_symbol(filename):
    m = re.search(r'__([^_]+?)__', filename)
    return m.group(1) if m else "NA"

def extract_og_id(filename):
    m = re.search(r'(OG\d+)', filename)
    return m.group(1) if m else "NA"

def extract_prefix_id(filename):
    m = re.match(r'^(\d+)_', filename)
    return m.group(1) if m else "NA"

def find_p_value(obj):
    if isinstance(obj, dict):
        if "test results" in obj and isinstance(obj["test results"], dict):
            if "p-value" in obj["test results"]:
                return obj["test results"]["p-value"]
        if "p-value" in obj:
            return obj["p-value"]
        for v in obj.values():
            pv = find_p_value(v)
            if pv is not None:
                return pv
    elif isinstance(obj, list):
        for item in obj:
            pv = find_p_value(item)
            if pv is not None:
                return pv
    return None

def bh_fdr(pvals):
    # Benjamini-Hochberg FDR, returns adjusted p-values in original order.
    # Treat literal 0 as extremely small to avoid weird behavior in downstream use.
    eps = 1e-300

    indexed = []
    for i, p in enumerate(pvals):
        if p is None:
            continue
        try:
            pf = float(p)
        except (TypeError, ValueError):
            continue
        if pf <= 0.0:
            pf = eps
        indexed.append((i, pf))

    m = len(indexed)
    adj = [None] * len(pvals)
    if m == 0:
        return adj

    indexed.sort(key=lambda x: x[1])  # sort by p
    bh_vals = [0.0] * m

    for rank, (idx, p) in enumerate(indexed, start=1):
        bh_vals[rank - 1] = p * m / rank

    # enforce monotonicity from bottom
    for j in range(m - 2, -1, -1):
        if bh_vals[j] > bh_vals[j + 1]:
            bh_vals[j] = bh_vals[j + 1]

    # cap at 1 and put back in original order
    for j, (idx, p) in enumerate(indexed):
        val = bh_vals[j]
        if val > 1.0:
            val = 1.0
        adj[idx] = val

    return adj

def extract_pvalues(directory):
    extracted_data = []

    for fname in sorted(os.listdir(directory)):
        if not fname.endswith(".json"):
            continue

        fpath = os.path.join(directory, fname)

        try:
            with open(fpath, "r") as jf:
                data = json.load(jf)
        except json.JSONDecodeError:
            print("Could not decode JSON:", fpath)
            continue
        except OSError as e:
            print("Could not read file:", fpath, "-", str(e))
            continue

        p_value = find_p_value(data)

        prefix_id = extract_prefix_id(fname)
        gene_symbol = extract_gene_symbol(fname)
        og_id = extract_og_id(fname)

        extracted_data.append([prefix_id, gene_symbol, og_id, p_value, fname])

    return extracted_data

def write_csv(data, output_file):
    # compute BH-FDR over the p-values we have in this run
    pvals = [row[3] for row in data]
    fdrs = bh_fdr(pvals)

    with open(output_file, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["PrefixID", "GeneSymbol", "OG_ID", "PValue", "FDR_BH", "Filename"])
        for row, fdr in zip(data, fdrs):
            writer.writerow([row[0], row[1], row[2], row[3], fdr, row[4]])

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <directory_path> <output_file>")
        sys.exit(1)

    directory_path, output_file = sys.argv[1:3]
    extracted_data = extract_pvalues(directory_path)
    write_csv(extracted_data, output_file)

    print("Wrote", len(extracted_data), "rows to", output_file)
