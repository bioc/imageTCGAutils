#!/bin/bash

# h5ad File Compression Script (Parallel Version)
# Compresses all .h5ad files in a directory using h5repack with GZIP
# 
# System dependencies:
#   sudo apt install hdf5-tools parallel
#
# Usage: ./compress_h5ad.sh [directory] [compression_level] [num_jobs]
#   directory: Path to folder containing h5ad files (default: current directory)
#   compression_level: GZIP compression level 1-9 (default: 5)
#   num_jobs: Number of parallel jobs (default: number of CPU cores)

set -e  # Exit on error

# Configuration
INPUT_DIR="${1:-.}"
COMPRESSION_LEVEL="${2:-5}"
NUM_JOBS="${3:-0}"  # 0 means use number of CPU cores
OUTPUT_SUFFIX=".gz"

# Validate compression level
if ! [[ "$COMPRESSION_LEVEL" =~ ^[1-9]$ ]]; then
    echo "Error: Compression level must be between 1 and 9"
    exit 1
fi

# Check if h5repack is available
if ! command -v h5repack &> /dev/null; then
    echo "Error: h5repack not found. Please install hdf5-tools:"
    echo "  sudo apt install hdf5-tools"
    exit 1
fi

# Check if parallel is available
if ! command -v parallel &> /dev/null; then
    echo "Error: GNU Parallel not found. Please install it:"
    echo "  sudo apt install parallel"
    echo ""
    echo "Alternatively, run with xargs (slower, less features):"
    echo "  find . -name '*.h5ad' ! -name '*.h5ad.gz' | xargs -P 4 -I {} bash -c 'h5repack -i {} -o {}.gz -f GZIP=5'"
    exit 1
fi

# Check if directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Directory '$INPUT_DIR' does not exist"
    exit 1
fi

# Change to input directory
cd "$INPUT_DIR"
WORK_DIR="$(pwd)"

# Find all .h5ad files
mapfile -t h5ad_files < <(find . -maxdepth 1 -type f -name "*.h5ad" ! -name "*.h5ad.gz")

# Check if any files found
if [ ${#h5ad_files[@]} -eq 0 ]; then
    echo "No .h5ad files found in $WORK_DIR"
    exit 0
fi

echo "Found ${#h5ad_files[@]} h5ad file(s) to compress"
echo "Compression level: GZIP=$COMPRESSION_LEVEL"
echo "Working directory: $WORK_DIR"
if [ "$NUM_JOBS" -eq 0 ]; then
    echo "Parallel jobs: auto ($(nproc) CPU cores)"
else
    echo "Parallel jobs: $NUM_JOBS"
fi
echo ""

# Function to compress a single file
compress_file() {
    local input_file="$1"
    local compression_level="$2"
    local output_suffix="$3"
    
    # Remove leading ./
    input_file="${input_file#./}"
    local output_file="${input_file}${output_suffix}"
    
    # Check if output already exists
    if [ -f "$output_file" ]; then
        echo "Skipping: $input_file (compressed version already exists)"
        return 0
    fi
    
    echo "Processing: $input_file"
    
    # Run h5repack
    if h5repack -i "$input_file" -o "$output_file" -f GZIP="$compression_level" 2>&1; then
        # Get file sizes
        local original_size=$(du -h "$input_file" | cut -f1)
        local compressed_size=$(du -h "$output_file" | cut -f1)
        echo "Success: $input_file ($original_size → $compressed_size)"
        return 0
    else
        echo "Error: Failed to compress $input_file"
        # Remove partial output file if it exists
        [ -f "$output_file" ] && rm "$output_file"
        return 1
    fi
}

# Export function and variables for parallel
export -f compress_file
export COMPRESSION_LEVEL
export OUTPUT_SUFFIX

# Run compression in parallel
printf '%s\n' "${h5ad_files[@]}" | \
    parallel --will-cite -j "$NUM_JOBS" --line-buffer \
    compress_file {} "$COMPRESSION_LEVEL" "$OUTPUT_SUFFIX"

exit_code=$?

echo ""
echo "=========================================="
if [ $exit_code -eq 0 ]; then
    echo "All compressions completed successfully!"
else
    echo "Some compressions failed (see errors above)"
fi
echo "=========================================="

exit $exit_code