# Scripts

This directory contains executable scripts used in the project, including the data processing pipeline.

## Purpose

* Define and execute the analysis workflow
* Orchestrate data processing steps
* Serve as entry points for running code

## Types of Scripts

### 1. Pipeline Scripts

These scripts define the ordered steps of the data pipeline.

Characteristics:

* Typically numbered to indicate execution order
* Read from `data/raw/` or `data/pipeline/`
* Write outputs to `data/pipeline/` and optionally `data/interim/`

### 2. Standalone / Utility Scripts

Scripts that perform specific tasks but are not part of the main pipeline.

Examples:

* One-off data fixes
* Data exports
* Ad hoc analyses

## Guidelines

* Scripts should be executable independently where possible
* Avoid duplicating logic. Use `src/` for reusable functionality
* Keep scripts focused on orchestration rather than implementation details

## Relationship to Other Directories

* `src/` → contains reusable logic imported by scripts
* `data/` → scripts read from and write to structured data directories
* `results/` → scripts generate outputs for reporting

## Notes

This directory represents the execution layer of the project. All major workflows, including the full pipeline, should be runnable from scripts defined here.
