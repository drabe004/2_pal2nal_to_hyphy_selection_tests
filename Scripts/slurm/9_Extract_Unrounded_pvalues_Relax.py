import os
import re
import csv
import sys

def extract_gene_symbol(filename):
    m = re.search(r'__([^_]+?)__', filename)
    return m.group(1) if m else "NA"

def extract_og_id(filename):
    m = re.search(r'(OG\d+)', filename)
    return m.group(1) if m else "NA"

def extract_prefix_id(filename):
    m = re.match(r'^(\d+)_', filename)
    return m.group(1) if m else "NA"

def bh_fdr(pvals):
    eps = 1e-300

    indexed = []
    for i, p in enumerate(pvals):
        try:
            pf = float(p)
        except:
            continue
        if pf <= 0:
            pf = eps
        indexed.append((i, pf))

    m = len(indexed)
    adj = [None] * len(pvals)

    indexed.sort(key=lambda x: x[1])
    bh_vals = [0]*m

    for rank,(idx,p) in enumerate(indexed,start=1):
        bh_vals[rank-1] = p*m/rank

    for j in range(m-2,-1,-1):
        bh_vals[j] = min(bh_vals[j], bh_vals[j+1])

    for j,(idx,p) in enumerate(indexed):
        adj[idx] = min(bh_vals[j],1.0)

    return adj

if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python Extract_Unrounded_pvalues_Relax.py <directory> <output_csv>")
        sys.exit(1)

    input_directory = sys.argv[1]
    output_file = sys.argv[2]

    data = []

    p_value_pattern = re.compile(r'p\s*=\s*([0-9.eE+-]+)')

    for filename in sorted(os.listdir(input_directory)):

        file_path = os.path.join(input_directory, filename)

        if not os.path.isfile(file_path):
            continue

        prefix_id = extract_prefix_id(filename)
        gene_symbol = extract_gene_symbol(filename)
        og_id = extract_og_id(filename)

        p_value = None
        sentence = None

        with open(file_path) as f:
            for line in f:

                if line.startswith(">"):
                    sentence = line.strip()

                p_match = p_value_pattern.search(line)
                if p_match:
                    p_value = p_match.group(1)

        if p_value is not None:
            data.append([prefix_id, gene_symbol, og_id, p_value, sentence, filename])

    fdrs = bh_fdr([row[3] for row in data])

    with open(output_file,"w",newline="") as outfile:

        writer = csv.writer(outfile)

        writer.writerow(["PrefixID","GeneSymbol","OG_ID","PValue","FDR_BH","Sentence","Filename"])

        for row,fdr in zip(data,fdrs):
            writer.writerow([row[0],row[1],row[2],row[3],fdr,row[4],row[5]])

    print("Wrote",len(data),"rows to",output_file)