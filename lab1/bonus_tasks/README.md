# MESA Lab Bonus Tasks

This directory contains enhanced tools to analyze your MESA models and automate running multiple models with different parameters. These tools are organized into two main categories:

1. **Python Analysis** - Tools to create plots and analyze a single MESA run
2. **Batch Runs** - Tools to automate running multiple MESA models with different parameters

## 1. Python Analysis for Single Models

After completing your first MESA model run, you can use these Python scripts to create publication-quality plots and analyze your results without needing to run multiple models.

### Quick Start

```bash
cd bonus_tasks/python_analysis
python hr_plot.py           # Creates HR diagram from your MESA run
python conv_core_plot.py    # Plots core mass evolution
python composition_plot.py  # Shows composition profiles
```

These scripts will automatically detect your MESA model in the `../../LOGS` directory and create appropriate plots. All plots are saved to a `plots/` directory for easy access.

### Available Analysis Scripts

| Script | Description |
|--------|-------------|
| `hr_plot.py` | Creates HR diagrams (both standard and 3D with age as z-axis) |
| `conv_core_plot.py` | Plots convective core mass evolution over time |
| `composition_plot.py` | Shows composition profiles for different elements |

These scripts work "out of the box" with any standard MESA run that includes the necessary history and profile columns (which you set up during the main lab).

---

## 2. Batch Running MESA (Sequentially)

The batch run system allows you to explore how different physical parameters (like overshooting) affect stellar evolution by automating the creation and execution of multiple MESA models.

### Directory Structure

```
batch_runs/
├── 0_dependency_check.py/.sh   # Verify your environment is correctly set up
├── 1_make_batch.py/.sh         # Generate inlists from CSV parameter file
├── 2_verify_inlists.py         # Verify inlists were generated correctly
├── 3_run_batch.py/.sh          # Run all inlists sequentially
├── 4_verify_outlists.py        # Verify runs completed successfully
└── 5_construct_output.py       # Extract results into CSV
```

### Workflow for Batch Runs

The typical workflow follows these steps:

1. **Check dependencies** to ensure your environment is properly set up
   ```bash
   python 0_dependency_check.py
   ```

2. **Generate inlists** using a CSV file of parameter combinations
   ```bash
   python 1_make_batch.py MESA_Lab.csv
   ```
   This creates a separate inlist for each parameter set in the `../batch_inlists/` directory.

3. **Run the models** (this may take several hours)
   ```bash
   python 3_run_batch.py
   ```
   Each model is run sequentially with results saved to `../runs/`

4. **Analyze the results** collectively
   ```bash
   python 5_construct_output.py         # Creates a summary CSV
   cd ../python_analysis/batch          # Go to batch analysis directory
   python plot_hr.py                    # Creates combined HR diagram
   python plot_ccore_mass.py            # Plots all core masses
   python plot_composition.py           # Shows composition profiles
   ```

### Understanding the Parameter Space

The provided `MESA_Lab.csv` file contains parameter combinations to explore:

- **Initial mass**: 2, 5, 15, 30 M☉
- **Metallicity**: Z = 0.014, 0.0014
- **Overshooting schemes**: None, Exponential, Step
- **Overshooting parameters (f_ov)**: 0.01-0.3
- **Penetration depths (f0)**: 0.001-0.01

You can select a subset of these parameters or create your own parameter combinations.

## Technical Requirements

To run these scripts, you'll need:

- **Python 3.6+** with the following packages:
  - `numpy`
  - `matplotlib`
  - `mesa_reader` (for parsing MESA output)
  - `pandas` (for data manipulation)

- **MESA environment variables** properly set:
  - `MESA_DIR`
  - `MESASDK_ROOT`

The dependency check script will verify these requirements for you.

## Troubleshooting

- If plots don't appear, check if your MESA run generated the required history and profile files
- For batch runs, examine individual log files in `../runs/[model_name]/run.log`
- Ensure your CSV file has the correct format (see `MESA_Lab.csv` as an example)
- For Python errors, verify you have all required packages installed

## Further Customisation

These scripts are designed to be easily modified for your specific research needs:

- Edit plotting styles in the Python files
- Add new parameters to the CSV file
- Modify inlist generation in `make_batch.py`
- Create your own analysis scripts based on the provided examples

---

