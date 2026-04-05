# Raw Data

This folder contains the original, immutable data sources for the project.

## Purpose

* Serve as the source of truth
* Provide reproducible inputs to the pipeline

## Rules

* Do not modify files in this directory

* Do not overwrite existing files

* Do not save generated data here

* Only read from this directory

* Add new data with clear naming and documentation

## Examples

* Original CSV exports
* Database extracts
* External data downloads

## Notes

If preprocessing is required, it should be done in a pipeline script and written to `data/pipeline/`, not here.
