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
# 2. Load encounter data
# =============================================================================

# --- Create lookup table for adding site/occasion columns to loaded data ---
occasions_lookup = build_occasions_lookup(config)

# --- Read encounter data in long format ---
input_file = path(source_folder, '2024 and 2025 MR Summary - 1.xlsx')
encounter_data = read_encounter_data(occasions_lookup, input_file)

# --- Export for review ---
occasions_path = path(interim_folder, 'qc_occasions_lookup.csv')
long_encounter_data_path = path(interim_folder, 'qc_encounter_long.csv')
write_csv(occasions_lookup, occasions_path)
write_csv(encounter_data, long_encounter_data_path)

# rm(occasions_lookup, occasions_path, input_file, long_encounter_data_path)

# =============================================================================
# 3. Validate data
# =============================================================================

# -----------------------------------------------------------------------------
# Check for Null/missing values
# -----------------------------------------------------------------------------

total_rows = nrow(encounter_data)

# Summarize missing values by column
missing_summary = colSums(is.na(encounter_data))

# Remove 13 rows where tag number is null (blank lines in imported data)
encounter_data = remove_missing_tags(encounter_data)

# -----------------------------------------------------------------------------
# Check for duplicate values
# -----------------------------------------------------------------------------

# --- Find Exact duplicates ---
dup_exact = encounter_data |> 
  group_by_all() |> 
  filter(n() > 1) |> 
  ungroup()
# Manual review
dup_exact_path = path(interim_folder, 'qc_dup_exact.csv')
write_csv(dup_exact, dup_exact_path)
# All exact duplicates are due to unknown/untagged which are dealt with later

# --- Find Tag Duplicates (grouped by Tag/occasion/site) ---
dup_tag = encounter_data |> 
  group_by(`Tag Number`, occasion, site) |> 
  filter(n() > 1) |> 
  ungroup()
# Manual review
dup_tag_path = path(interim_folder, 'qc_dup_tag.csv')
write_csv(dup_tag, dup_tag_path)

# --- Handle tag duplicates ---
# Most are due to untagged/unknown 
# But six are actual tag duplicates
# Remove these six tag duplicates (see docs for detailed decisions)
encounter_data = remove_tag_duplicates(encounter_data)

# --- Confirm all tag duplicates handled ---
dup_tag = encounter_data |> 
  group_by(`Tag Number`, occasion, site) |> 
  filter(n() > 1) |> 
  ungroup()
# Manual review
dup_tag_path = path(interim_folder, 'qc_dup_tag_confirm.csv')
write_csv(dup_tag, dup_tag_path)
