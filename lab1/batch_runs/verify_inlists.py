#!/usr/bin/env python3
"""
verify_inlists.py - Verifies that all entries in a CSV file have corresponding inlist files
"""

import os
import csv
import sys
import glob

def verify_inlists(csv_file, inlist_dir="batch_inlists"):
    """
    Verify that all entries in the CSV file have corresponding inlist files
    
    Parameters:
    csv_file (str): Path to the CSV file with parameter combinations
    inlist_dir (str): Path to the directory containing inlist files
    """
    # Get list of all inlist files
    inlist_files = glob.glob(os.path.join(inlist_dir, "*.inp"))
    inlist_basenames = [os.path.basename(f) for f in inlist_files]
    
    print(f"Found {len(inlist_files)} inlist files in {inlist_dir}")
    
    # Dictionary to track which CSV entries have matching inlist files
    csv_entries = []
    matched_entries = []
    missing_entries = []
    
    # Read CSV file
    with open(csv_file, 'r', newline='') as f:
        reader = csv.reader(f)
        header = next(reader)  # Skip header row
        
        for row_num, row in enumerate(reader, 2):  # Start counting from 2 to account for header
            if len(row) < 6:
                print(f"Warning: Row {row_num} is missing data, skipping")
                continue
                
            name = row[0].strip()
            mass = row[1].strip()
            metallicity = row[2].strip()
            scheme = row[3].strip().lower()
            fov = row[4].strip()
            f0 = row[5].strip()
            
            # Skip rows with missing data
            if not mass or not metallicity:
                print(f"Warning: Row {row_num} is missing mass or metallicity, skipping")
                continue
            
            # Determine expected filename
            if scheme in ["no overshooting", "none", "no overshoot"]:
                expected_file = f"inlist_M{mass}_Z{metallicity}_noovs.inp"
            else:
                expected_file = f"inlist_M{mass}_Z{metallicity}_{scheme}_fov{fov}_f0{f0}.inp"
            
            csv_entries.append((row_num, expected_file))
            
            # Check if file exists
            if expected_file in inlist_basenames:
                matched_entries.append((row_num, expected_file))
            else:
                missing_entries.append((row_num, expected_file))
    
    # Report results
    print(f"\nVerification Summary:")
    print(f"  - Total CSV entries: {len(csv_entries)}")
    print(f"  - Matched inlist files: {len(matched_entries)}")
    print(f"  - Missing inlist files: {len(missing_entries)}")
    
    if missing_entries:
        print("\nMissing inlist files:")
        for row_num, filename in missing_entries:
            print(f"  - Row {row_num}: {filename}")
    
    # Check for extra inlist files not in the CSV
    expected_files = [entry[1] for entry in csv_entries]
    extra_files = [f for f in inlist_basenames if f not in expected_files]
    
    if extra_files:
        print(f"\nFound {len(extra_files)} extra inlist files not in the CSV:")
        for filename in extra_files:
            print(f"  - {filename}")
    
    return len(missing_entries) == 0

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <csv_file> [inlist_dir]")
        sys.exit(1)
        
    csv_file = sys.argv[1]
    inlist_dir = sys.argv[2] if len(sys.argv) > 2 else "batch_inlists"
    
    if not os.path.exists(csv_file):
        print(f"Error: CSV file '{csv_file}' not found")
        sys.exit(1)
        
    if not os.path.exists(inlist_dir):
        print(f"Error: Inlist directory '{inlist_dir}' not found")
        sys.exit(1)
    
    success = verify_inlists(csv_file, inlist_dir)
    sys.exit(0 if success else 1)