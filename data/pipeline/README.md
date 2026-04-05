# Pipeline Data

This folder contains deterministic, step-by-step outputs of the data processing pipeline.

## Purpose

* Store inputs and outputs between pipeline steps
* Represent the full state of the pipeline at each stage

## Characteristics

* Each file is:
  * produced by one script
  * consumed by a downstream script 
* Files are reproducible and must not be manually edited

## Naming Convention

Files should be ordered and descriptive:

```
01_load_raw_data.py
02_data_cleanup.py
03_analysis.r
```

## Rules

* No manual edits

* No exploratory or temporary files

* No unused outputs

* Files should be safe to delete and regenerate

## Pipeline Workflow

Each script:

* reads from `raw/` or previous `pipeline/` outputs
* writes one or more outputs to `pipeline/`
* may optionally write diagnostics to `interim/`

## Notes

This directory represents the reproducible backbone of the project. If any file here is missing, the pipeline should be rerun, and not manually repaired.
