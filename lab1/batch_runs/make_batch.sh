#!/bin/bash
# make_batch.sh - Script to create batch inlists from a CSV file of parameters

# Check if CSV file is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

CSV_FILE=$1
BATCH_DIR="batch_inlists"
TEMPLATE_INLIST="../inlist_project"

# Create batch directory if it doesn't exist
mkdir -p "$BATCH_DIR"

# Skip header line and process each row
tail -n +2 "$CSV_FILE" | while IFS=, read -r name mass metallicity scheme fov f0 rest; do
    # Skip empty lines or lines with missing data
    if [ -z "$mass" ] || [ -z "$metallicity" ]; then
        continue
    fi

    # Clean up input values by trimming whitespace
    mass=$(echo "$mass" | xargs)
    metallicity=$(echo "$metallicity" | xargs)
    scheme=$(echo "$scheme" | xargs)
    fov=$(echo "$fov" | xargs)
    f0=$(echo "$f0" | xargs)

    # Create a descriptive filename encoding the parameters
    if [ "$scheme" == "no overshooting" ] || [ "$scheme" == "none" ] || [ "$scheme" == "no overshoot" ]; then
        OUTFILE="${BATCH_DIR}/inlist_M${mass}_Z${metallicity}_noovs.inp"
        ovs_option="none"
    else
        OUTFILE="${BATCH_DIR}/inlist_M${mass}_Z${metallicity}_${scheme}_fov${fov}_f0${f0}.inp"
        ovs_option="$scheme"
    fi

    echo "Creating $OUTFILE..."

    # Copy template and modify
    cp "$TEMPLATE_INLIST" "$OUTFILE"

    # Update the parameters in the inlist file
    sed -i "s/initial_mass = [0-9]*\(\.[0-9]*\)\{0,1\}/initial_mass = $mass/" "$OUTFILE"
    sed -i "s/initial_z = [0-9]*\(\.[0-9]*\)\{0,1\}/initial_z = $metallicity/" "$OUTFILE"
    sed -i "s/Zbase = [0-9]*\(\.[0-9]*\)\{0,1\}/Zbase = $metallicity/" "$OUTFILE"
    
    # Handle save_model_filename
    model_filename="M${mass}_Z${metallicity}"
    if [ "$ovs_option" != "none" ]; then
        model_filename="${model_filename}_${scheme}_fov${fov}_f0${f0}"
    else
        model_filename="${model_filename}_noovs"
    fi
    sed -i "s/save_model_filename = '.*'/save_model_filename = '${model_filename}.mod'/" "$OUTFILE"

    # Handle overshoot parameters
    if [ "$ovs_option" == "none" ]; then
        # For 'none', ensure overshoot lines are commented out
        sed -i 's/^[[:space:]]*overshoot_scheme/!     overshoot_scheme/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*overshoot_zone_type/!     overshoot_zone_type/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*overshoot_zone_loc/!     overshoot_zone_loc/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*overshoot_bdy_loc/!     overshoot_bdy_loc/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*overshoot_f(/!     overshoot_f(/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*overshoot_f0(/!     overshoot_f0(/g' "$OUTFILE"
    else
        # For other schemes, uncomment the lines and update parameters
        # First, remove any comment characters from overshoot lines
        sed -i 's/^[[:space:]]*![[:space:]]*overshoot_scheme/     overshoot_scheme/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*![[:space:]]*overshoot_zone_type/     overshoot_zone_type/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*![[:space:]]*overshoot_zone_loc/     overshoot_zone_loc/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*![[:space:]]*overshoot_bdy_loc/     overshoot_bdy_loc/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*![[:space:]]*overshoot_f(/     overshoot_f(/g' "$OUTFILE"
        sed -i 's/^[[:space:]]*![[:space:]]*overshoot_f0(/     overshoot_f0(/g' "$OUTFILE"
        
        # Now update the actual parameter values
        sed -i "s/overshoot_scheme(1) = '.*'/overshoot_scheme(1) = '$scheme'/" "$OUTFILE"
        sed -i "s/overshoot_f(1) = [0-9]*\(\.[0-9]*\)\{0,1\}/overshoot_f(1) = $fov/" "$OUTFILE"
        sed -i "s/overshoot_f0(1) = [0-9]*\(\.[0-9]*\)\{0,1\}/overshoot_f0(1) = $f0/" "$OUTFILE"
    fi
done

echo "Batch inlist creation completed."