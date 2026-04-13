# =============================================================================
# 1. Setup
# =============================================================================

# -----------------------------------------------------------------------------
# Import libraries
# -----------------------------------------------------------------------------

library(reticulate)
library(yaml)
library(fs)
library(tidyverse)
library(dplyr)
library(readxl)
library(glue)

# -----------------------------------------------------------------------------
# Load project paths and config.yaml
# -----------------------------------------------------------------------------

global_paths = import("config.paths", convert = TRUE) 

config_file = as.character(global_paths$CONFIG / 'config.yaml')
config = yaml.load_file(config_file)

# Custom library
custom_path = path(global_paths$SRC, '01_data_validation.r')
source(custom_path)

# -----------------------------------------------------------------------------
# Paths and import/export directories
# -----------------------------------------------------------------------------

# Set directories
SCRIPT_NAME = '01_data_validation'
source_folder = path(global_paths$DATA_RAW)
pipeline_folder = path(global_paths$DATA_PIPELINE, SCRIPT_NAME)
interim_folder = path(global_paths$DATA_INTERIM, SCRIPT_NAME)

# Make directories
dir_create(c(
  pipeline_folder,
  interim_folder
  )
)

# =============================================================================
# 2. Load and validate encounter data
# =============================================================================

# -----------------------------------------------------------------------------
# Load data
# -----------------------------------------------------------------------------

# --- Create lookup table for adding site/occasion columns to loaded data ---
occasions_lookup = build_occasions_lookup(config)

# --- Read encounter data in long format ---
input_file = path(source_folder, '2024 and 2025 MR Summary - 1.xlsx')
encounter_data = read_encounter_data(occasions_lookup, input_file)

