#!/usr/bin/env python3
"""
make_batch.py - Python script to create batch inlists from a CSV file of parameters.
Cross-platform replacement for make_batch.sh with improved robustness.
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
    
    # Ask user about pgstar settings
    enable_pgstar = input("Do you want to enable pgstar for batch runs? (yes/no): ").lower()
    pgstar_setting = "pgstar_flag = .true." if enable_pgstar.startswith('y') else "pgstar_flag = .false."
    
    # Read CSV file, skipping header
    with open(csv_file, 'r', newline='') as f:
        reader = csv.reader(f)
        next(reader)  # Skip header row
        
        for row in reader:
            # Unpack row or skip if too short
            if len(row) < 6:
                continue
                
            name = row[0].strip()
            mass = int(float(row[1].strip()))
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
            
            # Handle parameters that might not exist
            # For initial_mass
            if re.search(r'initial_mass\s*=', content):
                content = re.sub(r'initial_mass\s*=\s*[0-9]*(\.[0-9]*)?', f'initial_mass = {mass}', content)
            else:
                # Add it to the starting specifications section if it exists
                if '! starting specifications' in content:
                    content = re.sub(r'! starting specifications\n', f'! starting specifications\n    initial_mass = {mass} ! in Msun units\n', content)
                else:
                    # Otherwise add it at the beginning of the &controls section
                    content = re.sub(r'&controls', f'&controls\n\n    ! starting specifications\n    initial_mass = {mass} ! in Msun units', content)
            
            # For initial_z
            if re.search(r'initial_z\s*=', content):
                content = re.sub(r'initial_z\s*=\s*[0-9]*(\.[0-9]*)?', f'initial_z = {metallicity}', content)
            else:
                # Add it after initial_mass if it exists
                if re.search(r'initial_mass\s*=', content):
                    content = re.sub(r'(initial_mass\s*=.+)', f'\\1\n    initial_z = {metallicity} ! initial metal mass fraction', content)
                else:
                    # Otherwise add it at the beginning of the &controls section
                    content = re.sub(r'&controls', f'&controls\n\n    ! starting specifications\n    initial_z = {metallicity} ! initial metal mass fraction', content)
            
            # For Zbase in the &kap section
            if re.search(r'Zbase\s*=', content):
                content = re.sub(r'Zbase\s*=\s*[0-9]*(\.[0-9]*)?', f'Zbase = {metallicity}', content)
            else:
                # Add it to the &kap section if it exists
                if '&kap' in content:
                    content = re.sub(r'&kap\n', f'&kap\n    Zbase = {metallicity}\n', content)
                else:
                    # Otherwise add a new &kap section before &controls
                    content = re.sub(r'&controls', f'&kap\n    ! kap options\n    Zbase = {metallicity}\n/ ! end of kap namelist\n\n&controls', content)
            
            # For pgstar_flag
            if re.search(r'pgstar_flag\s*=\s*\.', content):
                content = re.sub(r'pgstar_flag\s*=\s*\.(true|false)\.', pgstar_setting, content)
            else:
                # Add it to the &star_job section if it exists
                if '&star_job' in content:
                    content = re.sub(r'&star_job\n', f'&star_job\n    {pgstar_setting}\n', content)
                else:
                    # Otherwise add a new &star_job section at the beginning of the file
                    content = f'&star_job\n    {pgstar_setting}\n/ ! end of star_job namelist\n\n' + content
            
            # Handle save_model_filename
            model_filename = f"M{mass}_Z{metallicity}"
            if ovs_option != "none":
                model_filename = f"{model_filename}_{scheme}_fov{fov}_f0{f0}"
            else:
                model_filename = f"{model_filename}_noovs"
                
            if re.search(r'save_model_filename\s*=', content):
                content = re.sub(r"save_model_filename\s*=\s*'.*'", f"save_model_filename = '{model_filename}.mod'", content)
            else:
                # Add save model options to &star_job
                save_model_options = f"    save_model_when_terminate = .true.\n    save_model_filename = '{model_filename}.mod'"
                if '&star_job' in content:
                    content = re.sub(r'(&star_job\n)', f'\\1{save_model_options}\n', content)
                else:
                    # Otherwise add a new &star_job section at the beginning of the file
                    content = f'&star_job\n{save_model_options}\n/ ! end of star_job namelist\n\n' + content
            
            # Handle overshoot parameters
            overshoot_section = ""
            if ovs_option == "none":
                # No overshoot parameters needed
                pass
            else:
                # Create overshoot parameters section
                overshoot_section = f"""
    ! mixing
    overshoot_scheme(1) = '{scheme}'
    overshoot_zone_type(1) = 'any'
    overshoot_zone_loc(1) = 'core'
    overshoot_bdy_loc(1) = 'top'
    overshoot_f(1) = {fov}
    overshoot_f0(1) = {f0}
"""
            
            # Check if mixing section exists
            if '! mixing' in content:
                # If overshoot parameters already exist, update them
                if re.search(r'overshoot_scheme\(1\)', content) or re.search(r'!+\s*overshoot_scheme\(1\)', content):
                    if ovs_option == "none":
                        # Comment out all overshoot lines
                        content = re.sub(r'^(\s*overshoot_scheme)', r'!\1', content, flags=re.MULTILINE)
                        content = re.sub(r'^(\s*overshoot_zone_type)', r'!\1', content, flags=re.MULTILINE)
                        content = re.sub(r'^(\s*overshoot_zone_loc)', r'!\1', content, flags=re.MULTILINE)
                        content = re.sub(r'^(\s*overshoot_bdy_loc)', r'!\1', content, flags=re.MULTILINE)
                        content = re.sub(r'^(\s*overshoot_f\()', r'!\1', content, flags=re.MULTILINE)
                        content = re.sub(r'^(\s*overshoot_f0\()', r'!\1', content, flags=re.MULTILINE)
                    else:
                        # Update existing overshoot parameters
                        content = re.sub(r'!*\s*overshoot_scheme\(1\)\s*=\s*.*', f'     overshoot_scheme(1) = \'{scheme}\'', content)
                        content = re.sub(r'!*\s*overshoot_zone_type\(1\)\s*=\s*.*', f'     overshoot_zone_type(1) = \'any\'', content)
                        content = re.sub(r'!*\s*overshoot_zone_loc\(1\)\s*=\s*.*', f'     overshoot_zone_loc(1) = \'core\'', content)
                        content = re.sub(r'!*\s*overshoot_bdy_loc\(1\)\s*=\s*.*', f'     overshoot_bdy_loc(1) = \'top\'', content)
                        content = re.sub(r'!*\s*overshoot_f\(1\)\s*=\s*.*', f'     overshoot_f(1) = {fov}', content)
                        content = re.sub(r'!*\s*overshoot_f0\(1\)\s*=\s*.*', f'     overshoot_f0(1) = {f0}', content)
                else:
                    # Add new overshoot parameters to existing mixing section
                    if ovs_option != "none":
                        content = re.sub(r'! mixing\n', f'! mixing\n{overshoot_section}', content)
            else:
                # Add new mixing section with overshoot parameters if needed
                if ovs_option != "none":
                    # Find a good place to add it in &controls section
                    if re.search(r'! timesteps', content):
                        content = re.sub(r'! timesteps', f'! mixing\n{overshoot_section}\n\n  ! timesteps', content)
                    elif re.search(r'! mesh', content):
                        content = re.sub(r'! mesh', f'! mixing\n{overshoot_section}\n\n  ! mesh', content)
                    elif re.search(r'! solver', content):
                        content = re.sub(r'! solver', f'! mixing\n{overshoot_section}\n\n  ! solver', content)
                    else:
                        # Add before end of controls
                        content = re.sub(r'/ ! end of controls namelist', f'  ! mixing\n{overshoot_section}\n\n/ ! end of controls namelist', content)
            
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