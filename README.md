# data_analysis_template

Preferred template for a reproducible data analysis workflow using R and Python.

# Overview

*Overview of project goes here*

# Setup

## Minimum Prerequisites

* Python installed and available on PATH
* R installed and available on PATH

## Setup Steps

1. Copy the project folder by either:

   **Option 1: Clone from GitHub**

   ```
   git clone <repository-url> <local-folder>
   ```

   **Option 2: Download manually**

   * From the repository home page, click the green **Code** button
   * Select **Download ZIP**
   * Extract to a desired location on your local machine

2. Navigate to the project root folder and run:

   ```
   setup.bat
   ```

   This will execute `setup.ps1`, which:

   * Verifies that Python and R are installed and available on PATH
   * Installs uv (if needed) and syncs the Python environment
   * Installs renv (if needed) and restores the R environment

## Result

After setup completes:

* All Python dependencies are installed and synced
* The R environment is restored
* The project is ready to run (see 'scripts/run_analysis_example.r' for example of orchestration script)

# Folder Description

## `config/`

Configuration files defining global paths and shared settings used across the project.

## `data/`

Structured storage for all data used and generated in the project.

* `raw/` → immutable source data (tracked in git if appropriate)
* `pipeline/` → outputs used between processing steps
* `interim/` → temporary, diagnostic, or QC outputs
* `final/` → analysis-ready datasets

All non-raw data is generated from scripts and should not be manually edited.

## `doc/`

Project documentation, including:

* methodological notes
* draft reports and supporting materials

## `results/`

Outputs generated from analysis, including:

* figures and tables for reporting
* model outputs and summaries
* publication-ready materials

## `scripts/`

Executable scripts that define and run the analysis workflow.

* includes pipeline steps
* serves as entry points for running analyses

## `src/`

Reusable source code and helper functions used by scripts.

* avoids duplication across scripts

# Notes

* All data processing should be reproducible by running scripts
* Avoid manual edits to generated data or results
* Use `src/` for reusable logic and `scripts/` for execution

# Running the Pipeline (example)

*Add instructions here for running the full pipeline (e.g., via R or Python script).*
