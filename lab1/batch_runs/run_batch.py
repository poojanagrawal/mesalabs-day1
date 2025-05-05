#!/usr/bin/env python3
"""
run_batch.py - Python script to run MESA with each inlist in the batch directory
Cross-platform replacement for run_batch.sh
"""

import os
import sys
import glob
import shutil
import subprocess
import re

def run_batch():
    """Run MESA with each inlist in the batch directory"""
    # Change to main MESA work directory
    os.chdir("..")
    
    # Check if we're in the right directory
    if not os.path.isfile("inlist") or not os.path.isfile("star"):
        print("Error: This script must be run from the main MESA work directory.")
        sys.exit(1)
    
    batch_dir = os.path.join("batch_runs", "batch_inlists")
    output_dir = os.path.join("batch_runs", "runs")
    
    # Check if batch inlists exist
    inlist_files = glob.glob(os.path.join(batch_dir, "*.inp"))
    if not os.path.isdir(batch_dir) or not inlist_files:
        print(f"Error: No batch inlists found in {batch_dir}.")
        print("Please run make_batch.py first to create the inlists.")
        sys.exit(1)
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Count total number of inlists to process
    total = len(inlist_files)
    current = 0
    
    # Process each inlist
    for inlist_file in inlist_files:
        current += 1
        inlist_name = os.path.basename(inlist_file).rsplit('.', 1)[0]
        run_dir = os.path.join(output_dir, inlist_name)
        
        print(f"[{current}/{total}] Processing {inlist_name}...")
        
        # Create run directory and subdirectories
        os.makedirs(run_dir, exist_ok=True)
        os.makedirs(os.path.join(run_dir, "LOGS"), exist_ok=True)
        os.makedirs(os.path.join(run_dir, "photos"), exist_ok=True)
        
        # Copy necessary files
        shutil.copy(inlist_file, "inlist_project")
        
        # Run MESA
        print(f"Running MESA with {inlist_name} parameters...")
        with open(os.path.join(run_dir, "run.log"), 'w') as log_file:
            result = subprocess.run(["./star"], stdout=log_file, stderr=log_file)
        
        if result.returncode != 0:
            print(f"Warning: MESA run for {inlist_name} may have encountered an error.")
        
        # Copy results
        if os.path.isdir("LOGS"):
            for item in os.listdir("LOGS"):
                s = os.path.join("LOGS", item)
                d = os.path.join(run_dir, "LOGS", item)
                if os.path.isfile(s):
                    shutil.copy2(s, d)
        
        if os.path.isdir("photos"):
            for item in os.listdir("photos"):
                s = os.path.join("photos", item)
                d = os.path.join(run_dir, "photos", item)
                if os.path.isfile(s):
                    shutil.copy2(s, d)
        
        shutil.copy("inlist_project", run_dir)
        shutil.copy("inlist", run_dir)
        shutil.copy("inlist_pgstar", run_dir)
        
        # Copy model file if it exists
        # Extract model filename from inlist
        with open(inlist_file, 'r') as f:
            content = f.read()
            model_file_match = re.search(r"save_model_filename\s*=\s*'([^']*)'", content)
            if model_file_match:
                model_file = model_file_match.group(1)
                if os.path.isfile(model_file):
                    shutil.copy2(model_file, run_dir)
        
        print(f"Completed run for {inlist_name}")
        print("------------------------------------------")
    
    print("All batch runs completed!")

if __name__ == "__main__":
    run_batch()
