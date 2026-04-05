# Configuration

This directory contains centralized configuration used across the project (e.g., defining file paths, global variables, figure consistency. Config/ folder is importable as a package. 

## Purpose

* Provide a single source of truth for project paths
* Avoid hardcoding file locations in scripts

## Structure

* `paths.py` → Defines the directory structure relative to the project root.

### Root Resolution

The project root is determined dynamically:

* In Python: relative to the location of the config file

This ensures that scripts can be run from any working directory without breaking path resolution.

## Usage

All scripts should import or source these configuration files rather than defining paths manually.

### Python

```python
from config.paths import DATA_PIPELINE
```

### R

```r
library(reticulate)

paths = import("config.paths", convert = TRUE) 
```

## Principles

### 1. No Hardcoded Paths

All file paths in scripts must be constructed using variables from the config files.

### 2. Cross-Language Consistency

R and Python must reference the same directory structure and naming conventions.

### 3. Relative, Not Absolute

Paths are always defined relative to the project root to ensure portability.

### 4. Minimal Logic

Configuration files should remain simple and declarative. Avoid adding processing logic or side effects.

## Extending Configuration

Additional configuration (if needed) can be added here, such as:

* file naming conventions
* environment-specific settings
* external data locations
* settings for analyses

However, keep this directory focused and lightweight.

## Notes

Centralizing paths in this way:

* reduces duplication
* prevents inconsistencies
* makes refactoring directory structures significantly easier

Any changes to folder structure should be made here first and propagate through the rest of the project.
