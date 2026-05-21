#!/bin/bash

# JSON File Compression Script (Parallel Version)
# Compresses all .json files in a directory that do not already have a matching
# .json.gz file
#
# System dependencies:
#   sudo apt install parallel gzip
#
# Usage: ./compress_json.sh [directory] [num_jobs]
#   directory: Path to folder containing JSON files (default: current directory)
#   num_jobs: Number of parallel jobs (default: number of CPU cores)

set -euo pipefail  # Exit on error, unset variables are errors, pipeline failures propagate

INPUT_DIR="${1:-.}"
NUM_JOBS="${2:-0}"  # 0 means use number of CPU cores
OUTPUT_SUFFIX=".gz"

if ! command -v gzip >/dev/null 2>&1; then
    echo "Error: gzip not found"
    exit 1
fi

if ! command -v parallel >/dev/null 2>&1; then
    echo "Error: GNU Parallel not found. Please install it:"
    echo "  sudo apt install parallel"
    exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Directory '$INPUT_DIR' does not exist"
    exit 1
fi

cd "$INPUT_DIR"

mapfile -d '' json_files < <(
    find . -maxdepth 1 -type f -name '*.json' ! -name '*.json.gz' -print0
)

if [ ${#json_files[@]} -eq 0 ]; then
    echo "No .json files found in $(pwd)"
    exit 0
fi

jobs="$NUM_JOBS"
if [ "$jobs" -eq 0 ]; then
    jobs="$(nproc)"
fi

compress_file() {
    local input_file="$1"
    local output_file="${input_file}${OUTPUT_SUFFIX}"

    # Skip files that already have a compressed version.
    if [ -f "$output_file" ]; then
        echo "Skipping: $input_file (compressed version already exists)"
        return 0
    fi

    echo "Processing: $input_file"

    # gzip -k keeps the original file and writes the compressed copy alongside it.
    gzip -k "$input_file"
}

export -f compress_file
export OUTPUT_SUFFIX

printf '%s\0' "${json_files[@]}" | parallel -0 --will-cite -j "$jobs" --line-buffer compress_file {}

