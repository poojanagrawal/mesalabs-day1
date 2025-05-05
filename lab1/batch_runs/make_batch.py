#!/usr/bin/env python3
"""
make_batch.py - Python script to create batch inlists from a CSV file of parameters.
Cross-platform replacement for make_batch.sh.
"""

import os
import csv
import re
import shutil
import sys

def create_batch_inlists(csv_file):
    """Create batch inlists from parameters in CSV file"""
    # Define paths
    batch_dir = "batch_inlists"
    template_inlist = os.path.join("..", "inlist_project")
    
    # Create batch directory if it doesn't exist
    os.makedirs(batch_dir, exist_ok=True)
    
    # Read CSV file, skipping header
    with open(csv_file, 'r', newline='') as f:
        reader = csv.reader(f)
        next(reader)  # Skip header row
        
        for row in reader:
            # Unpack row or skip if too short
            if len(row) < 6:
                continue
                
            name = row[0].strip()
            mass = row[1].strip()
            metallicity = row[2].strip()
            scheme = row[3].strip()
            fov = row[4].strip()
            f0 = row[5].strip()
            
            # Skip rows with missing data
            if not mass or not metallicity:
                continue
            
            # Create descriptive filename encoding the parameters
            if scheme.lower() in ["no overshooting", "none", "no overshoot"]:
                outfile = os.path.join(batch_dir, f"inlist_M{mass}_Z{metallicity}_noovs.inp")
                ovs_option = "none"
            else:
                outfile = os.path.join(batch_dir, f"inlist_M{mass}_Z{metallicity}_{scheme}_fov{fov}_f0{f0}.inp")
                ovs_option = scheme
            
            print(f"Creating {outfile}...")
            
            # Copy template
            shutil.copy(template_inlist, outfile)
            
            # Read template content
            with open(outfile, 'r') as f:
                content = f.read()
            
            # Update parameters in the inlist file
            content = re.sub(r'initial_mass = [0-9]*(\.[0-9]*)?', f'initial_mass = {mass}', content)
            content = re.sub(r'initial_z = [0-9]*(\.[0-9]*)?', f'initial_z = {metallicity}', content)
            content = re.sub(r'Zbase = [0-9]*(\.[0-9]*)?', f'Zbase = {metallicity}', content)
            
            # Handle save_model_filename
            model_filename = f"M{mass}_Z{metallicity}"
            if ovs_option != "none":
                model_filename = f"{model_filename}_{scheme}_fov{fov}_f0{f0}"
            else:
                model_filename = f"{model_filename}_noovs"
                
            content = re.sub(r"save_model_filename = '.*'", f"save_model_filename = '{model_filename}.mod'", content)
            
            # Handle overshoot parameters
            if ovs_option == "none":
                # Comment out all overshoot lines
                content = re.sub(r'^(\s*overshoot_scheme)', r'!\1', content, flags=re.MULTILINE)
                content = re.sub(r'^(\s*overshoot_zone_type)', r'!\1', content, flags=re.MULTILINE)
                content = re.sub(r'^(\s*overshoot_zone_loc)', r'!\1', content, flags=re.MULTILINE)
                content = re.sub(r'^(\s*overshoot_bdy_loc)', r'!\1', content, flags=re.MULTILINE)
                content = re.sub(r'^(\s*overshoot_f\()', r'!\1', content, flags=re.MULTILINE)
                content = re.sub(r'^(\s*overshoot_f0\()', r'!\1', content, flags=re.MULTILINE)
            else:
                # Update overshoot parameters
                content = re.sub(r'!*\s*overshoot_scheme\(1\) = .*', f'     overshoot_scheme(1) = \'{scheme}\'', content)
                content = re.sub(r'!*\s*overshoot_zone_type\(1\) = .*', f'     overshoot_zone_type(1) = \'any\'', content)
                content = re.sub(r'!*\s*overshoot_zone_loc\(1\) = .*', f'     overshoot_zone_loc(1) = \'core\'', content)
                content = re.sub(r'!*\s*overshoot_bdy_loc\(1\) = .*', f'     overshoot_bdy_loc(1) = \'top\'', content)
                content = re.sub(r'!*\s*overshoot_f\(1\) = .*', f'     overshoot_f(1) = {fov}', content)
                content = re.sub(r'!*\s*overshoot_f0\(1\) = .*', f'     overshoot_f0(1) = {f0}', content)
            # Write updated content
            with open(outfile, 'w') as f:
                f.write(content)
    
    print("Batch inlist creation completed.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <csv_file>")
        sys.exit(1)
        
    csv_file = sys.argv[1]
    create_batch_inlists(csv_file)
