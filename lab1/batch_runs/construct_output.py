import os
import csv
import glob
import re
from mesa_reader import MesaData

def parse_run_name(run_name):
    parts = run_name[7:].split("_")
    mass = float(parts[0][1:])
    z = float(parts[1][1:])
    if "noovs" in run_name:
        scheme = "none"
        fov = 0.0
        f0 = 0.0
    else:
        scheme = parts[2]
        fov = float(parts[3][3:]) if len(parts) > 3 and parts[3].startswith("fov") else 0.0
        f0 = float(parts[4][2:]) if len(parts) > 4 and parts[4].startswith("f0") else 0.0
    return mass, z, scheme, fov, f0

def extract_final_history_values(history):
    """Return last values for key quantities."""
    age_myr = history.star_age[-1] / 1e6
    log_Teff = history.log_Teff[-1]
    log_L = history.log_L[-1]
    he_core_mass = history.he_core_mass[-1]
    return age_myr, log_Teff, log_L, he_core_mass

def extract_final_core_radius(profile):
    """Return convective core radius if available."""
    if hasattr(profile, "conv_mx1_top_r"):
        return profile.conv_mx1_top_r[0]
    return "NA"

def write_summary_csv(output_csv="model_summary.csv", base_dir="runs"):
    fieldnames = [
        "run_name", "mass", "metallicity", "scheme", "fov", "f0",
        "final_age_Myr", "log_Teff", "log_L", "he_core_mass", "core_radius"
    ]
    run_dirs = [d for d in glob.glob(os.path.join(base_dir, "*")) if os.path.isdir(d)]
    with open(output_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for run_dir in run_dirs:
            run_name = os.path.basename(run_dir)
            if not run_name.startswith("inlist_M"):
                continue
            logs_dir = os.path.join(run_dir, "LOGS")
            hist_file = os.path.join(logs_dir, "history.data")
            prof_files = sorted(glob.glob(os.path.join(logs_dir, "profile*.data")),
                                key=lambda x: int(re.search(r"profile(\d+).data", x).group(1)))
            if not os.path.exists(hist_file):
                continue
            try:
                history = MesaData(hist_file)
                final_profile = MesaData(prof_files[-1]) if prof_files else None
                mass, z, scheme, fov, f0 = parse_run_name(run_name)
                age, log_Teff, log_L, he_core_mass = extract_final_history_values(history)
                core_r = extract_final_core_radius(final_profile) if final_profile else "NA"
                writer.writerow({
                    "run_name": run_name,
                    "mass": mass,
                    "metallicity": z,
                    "scheme": scheme,
                    "fov": fov,
                    "f0": f0,
                    "log_Teff": round(log_Teff, 3),
                    "log_L": round(log_L, 3),
                    "he_core_mass": round(he_core_mass, 5),
                    "core_radius": round(core_r, 5) if core_r != "NA" else "NA",
                    "final_age_Myr": round(age, 2)
                })
            except Exception as e:
                print(f"Skipping {run_name}: {e}")

    print(f"CSV summary saved to: {output_csv}")

if __name__ == "__main__":
    write_summary_csv()
