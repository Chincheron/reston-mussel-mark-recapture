# Data Directory

This directory contains all data used and generated in the project. It is structured to clearly separate raw inputs, pipeline objects, intermediate outputs, and final datasets.

## Structure

* `raw/` → immutable source data
* `pipeline/` → deterministic step-to-step pipeline outputs
* `interim/` → QC, diagnostics, and temporary files
* `final/` → analysis-ready datasets

## Principles

### 1. Reproducibility

All files in `pipeline/` must be reproducible from upstream data and scripts. The full pipeline should run from start to finish without manual intervention.

### 2. Immutability of Raw Data

Files in `raw/` are the source of truth and must never be modified.

### 3. Clear Separation of Concerns

* `pipeline/` contains only required inputs/outputs between scripts
* `interim/` contains optional or exploratory outputs
* `final/` contains cleaned, analysis-ready data

### 4. Deterministic Pipeline

Each step in the pipeline:

* reads from `raw/` or `pipeline/`

## Guiding Rule

> If deleting a file breaks the pipeline, it belongs in `pipeline/`, not `interim/`.

## Notes

* File formats (e.g., `.csv`, `.xlsx`, `.rds`) do not determine where a file belongs. Its role does.
* Avoid manual edits to any generated data.
