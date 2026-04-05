# Source Code

This directory contains reusable, structured code that supports the project. src/ folder is importable as a package.

## Purpose

* Encapsulate core logic and functionality
* Promote code reuse across scripts
* Improve maintainability and testability

## Examples

* Data processing functions
* Utility modules
* Helper functions shared across scripts

## Usage

Scripts in `scripts/` should import functionality from `src/` rather than reimplementing logic.

## Notes

This separation helps:

* reduce duplication
* improve clarity
* make the pipeline easier to extend and maintain
