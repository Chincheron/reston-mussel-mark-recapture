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

## File Description

* 2024 and 2025 MR Summary - 1.xlsx
    * Processed data for each year/site mark-recapture sampling?
    * Summary/combination of Reston Mark Recapture Survyes (first set and New Jan 2026)
* Reston Mark Recapture Surveys (first set).xlsx
    * Data/Summary from 2024
    * Includes Raw and processed data?
* Reston Mark Recapture Surveys 2025 (New Jan 2026).xlsx
    * Data/Summary from 2025
    * Includes Raw and processed data?
* Sacrificed & Random Dead Mussels 2023-2025.xlsx
    * List of dead mussels found and removed from population
    * Exhaustive?
