#!/usr/bin/env python3
from pathlib import Path
import argparse
import sys

FASTA_EXTS = {".fa", ".fna", ".faa", ".fasta", ".fas", ".aln"}

def read_species_list(path: Path) -> set[str]:
    keep = set()
    with path.open() as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            keep.add(line)
    return keep

def species_from_header(header_line: str) -> str:
    # header_line includes leading '>'
    # Default: species is first token after '>'
    return header_line[1:].strip().split()[0]

def iter_fasta_records(fp: Path):
    header = None
    seq_chunks = []
    with fp.open() as f:
        for line in f:
            if line.startswith(">"):
                if header is not None:
                    yield header, "".join(seq_chunks)
                header = line.rstrip("\n")
                seq_chunks = []
            else:
                seq_chunks.append(line.strip())
        if header is not None:
            yield header, "".join(seq_chunks)

def write_fasta_records(out_fp: Path, records):
    out_fp.parent.mkdir(parents=True, exist_ok=True)
    with out_fp.open("w") as out:
        for h, s in records:
            out.write(h + "\n")
            # wrap 60 chars/line
            for i in range(0, len(s), 60):
                out.write(s[i:i+60] + "\n")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--aln_dir", required=True, help="Directory with input FASTA codon alignments")
    ap.add_argument("--species_list", required=True, help="File with species IDs to REMOVE (one per line)")
    ap.add_argument("--out_dir", required=True, help="Output directory for filtered copies")
    ap.add_argument("--dry_run", action="store_true", help="Scan and report only; do not write outputs")
    args = ap.parse_args()

    aln_dir = Path(args.aln_dir)
    out_dir = Path(args.out_dir)
    species_list_fp = Path(args.species_list)

    if not aln_dir.is_dir():
        sys.exit(f"ERROR: aln_dir not found: {aln_dir}")
    if not species_list_fp.is_file():
        sys.exit(f"ERROR: species_list not found: {species_list_fp}")

    remove_species = read_species_list(species_list_fp)

    # collect candidate files
    files = [p for p in aln_dir.rglob("*") if p.is_file() and (p.suffix.lower() in FASTA_EXTS)]
    if not files:
        sys.exit(f"ERROR: No FASTA-like files found under {aln_dir}")

    n_files = 0
    n_written = 0
    n_records_removed = 0
    n_records_total = 0

    for fp in files:
        n_files += 1
        kept_records = []
        removed_here = 0
        total_here = 0

        for header, seq in iter_fasta_records(fp):
            total_here += 1
            sp = species_from_header(header)
            if sp in remove_species:
                removed_here += 1
            else:
                kept_records.append((header, seq))

        n_records_total += total_here
        n_records_removed += removed_here

        rel = fp.relative_to(aln_dir)
        out_fp = out_dir / rel
        if args.dry_run:
            continue

        # Always write an output copy (even if unchanged) to keep 1:1 structure
        write_fasta_records(out_fp, kept_records)
        n_written += 1

    print(f"Scanned files: {n_files}")
    print(f"Total records: {n_records_total}")
    print(f"Removed records: {n_records_removed}")
    if args.dry_run:
        print("Dry-run: no outputs written.")
    else:
        print(f"Outputs written: {n_written}")
        print(f"Output dir: {out_dir}")

if __name__ == "__main__":
    main()