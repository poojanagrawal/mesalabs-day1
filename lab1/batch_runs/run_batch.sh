#!/bin/bash

# MESA Batch Runner for Unix/Linux/macOS
# This script will run MESA for each inlist in batch_runs/batch_inlists

echo "Checking environment..."

# Check if we're in the right directory
if [ ! -f "inlist" ] || [ ! -f "star" ]; then
    echo "WARNING: Moving to working directory."
    cd ../
fi

# Check if we're in the right directory
if [ ! -f "inlist" ] || [ ! -f "star" ]; then
    echo "ERROR: This script must be run from the main MESA work directory OR batch_runs/."
    cd ../
    exit 1
fi

BATCH_DIR="batch_runs/batch_inlists"
OUTPUT_DIR="batch_runs/runs"

# Check if batch inlists exist
if [ ! -d "$BATCH_DIR" ]; then
    echo "Error: Batch directory $BATCH_DIR not found."
    echo "Please create it and add your inlist files."
    exit 1
fi

# Count inlist files
if [ $(ls -1 "$BATCH_DIR"/*.inp 2>/dev/null | wc -l) -eq 0 ]; then
    echo "Error: No inlist files found in $BATCH_DIR"
    exit 1
fi

# Get total number of inlists
TOTAL=$(ls -1 "$BATCH_DIR"/*.inp | wc -l)
echo "Found $TOTAL inlist files in $BATCH_DIR"

# Confirm with user
if [ "$1" != "--force" ]; then
    echo
    echo "You are about to run $TOTAL MESA simulations."
    echo "This might take a significant amount of time and computational resources."
    if [ $TOTAL -gt 10 ]; then
        echo "WARNING: Running $TOTAL simulations could take hours or even days!"
    fi
    echo
    read -p "Do you want to continue? (yes/no): " response
    
    if [[ ! "$response" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        echo "Batch run cancelled."
        exit 0
    fi
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Process each inlist
CURRENT=0
for inlist_file in "$BATCH_DIR"/*.inp; do
    CURRENT=$((CURRENT + 1))
    inlist_name=$(basename "$inlist_file" .inp)
    run_dir="$OUTPUT_DIR/$inlist_name"
    
    echo "[$CURRENT/$TOTAL] Processing $inlist_name..."
    
    # Create run directory and subdirectories
    mkdir -p "$run_dir"
    mkdir -p "$run_dir/LOGS"
    mkdir -p "$run_dir/photos"
    
    # Copy inlist file
    cp -f "$inlist_file" inlist_project
    
    # Run MESA
    echo "Running MESA with $inlist_name parameters..."
    start_time=$(date +%s)
    
    ./star > "$run_dir/run.log" 2>&1
    
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    echo "Run completed in $elapsed seconds."
    
    # Copy results
    if [ -d "LOGS" ]; then
        cp -f LOGS/* "$run_dir/LOGS/" 2>/dev/null
    fi
    
    if [ -d "photos" ]; then
        cp -f photos/* "$run_dir/photos/" 2>/dev/null
    fi
    
    cp -f inlist_project "$run_dir/"
    cp -f inlist "$run_dir/"
    if [ -f "inlist_pgstar" ]; then
        cp -f inlist_pgstar "$run_dir/"
    fi
    
    # Find and copy model file if it exists
    model_file=$(grep "save_model_filename" "$inlist_file" | sed "s/.*save_model_filename = '\([^']*\)'.*//")
    if [ -f "$model_file" ]; then
        cp -f "$model_file" "$run_dir/"
    fi
    
    echo "Completed run for $inlist_name"
    echo "------------------------------------------"
done

echo "All batch runs completed!"
echo