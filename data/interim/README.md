# Interim Data

This folder contains intermediate, diagnostic, and exploratory outputs generated during the analysis process.

## Purpose

* Support debugging and validation
* Store QC outputs and temporary files
* Enable exploratory analysis without affecting the pipeline

## Examples

* Data quality checks
* Summary tables
* Debugging subsets
* Temporary joins
* Validation outputs

## Rules

* Do not rely on files here for pipeline execution

* Do not treat files here as permanent

* Safe to delete at any time

* May contain exploratory outputs

## Key Principle

Files in this directory must NOT be required for the pipeline to run.

> If deleting a file breaks the pipeline, it belongs in `pipeline/`, not `interim/`.

## Notes

This directory is intentionally flexible but should remain organized to avoid clutter.
