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
custom_path = path(global_paths$SRC, '01_encounter_data_validation.r')
source(custom_path)

# -----------------------------------------------------------------------------
# Paths and import/export directories
# -----------------------------------------------------------------------------

# Set directories
SCRIPT_NAME = '01_encounter_data_validation'
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

# -----------------------------------------------------------------------------
# Validate data types and formats
# -----------------------------------------------------------------------------

#validate_encounter_data_types(encounter_data)

# --- Fix data type mismatch ---
# Length not numeric due to several non-numeric values
# Fix values before converting to numeric data type

# Find length values that cannot be converted to numeric data type
encounter_data |> 
  filter(is.na(as.numeric(`Length (mm)`))) |> 
  count(`Length (mm)`)

# Handle length mismatches and convert to numeric
encounter_data = handle_length_mismatch(encounter_data) 

# Final validation of data types
validate_encounter_data_types(encounter_data)

# Manual review
data_type_validation = path(interim_folder, 'qc_data_type_confirm.csv')
write_csv(encounter_data, data_type_validation)

# -----------------------------------------------------------------------------
# Validate value ranges and categories
# -----------------------------------------------------------------------------

# Check length, occasions, and dates for unreasonable/impossible values
# This is NOT an assessment of outliers
validate_values(encounter_data)

# Create distinct values for determining standard categories and finding typos
unique_locations = encounter_data |> 
  count(`Location Found`, site)
unique_status = encounter_data |> 
  count(Status)
unique_where_found = encounter_data |> 
  count(`Where Found`)
unique_site = encounter_data |> 
  count(site)

# Standardize status; locations and where found not required at this time (4/24/26)
encounter_data = standardize_categories(encounter_data)
#TODO - Low - Review unique_locations and unique_where_found for standardizing. 
# Only needed if we do something with these columns in MARK analysis 

# Final validation of categories
validate_categories(encounter_data)

# -----------------------------------------------------------------------------
# Validate Tag Format
# -----------------------------------------------------------------------------
source(custom_path)
# Check for any tags not fitting the format X000 and export for review
error_path = path(interim_folder, "error_validate_tag_format.csv")
validate_tag_format(encounter_data, error_path)

# Fix appropriate issues - see docs for details
source(custom_path)
encounter_data = fix_tag_format(encounter_data)
confirm_error_path = path(interim_folder, "error_validate_tag_format_confirm.csv")
validate_tag_format(encounter_data, confirm_error_path)
# -----------------------------------------------------------------------------
# Assess Completeness/Consistency
# -----------------------------------------------------------------------------

# --- Crosscheck against report numbers ---

# Check number of alive/dead at each site/occasion against Figure 2 from report
status_found_by_occasion = encounter_data |> 
  count(site, occasion, Status, )
status_found_path = path(interim_folder, 'qc_report_comp_Fig_2.csv')
write_csv(status_found_by_occasion, status_found_path)
# Manual comparison to Figure 2 from report 
# Fix inconsistencies - see Docs for details

# =============================================================================
# 4. Final export
# =============================================================================

# -----------------------------------------------------------------------------
# Export for final qc review
# -----------------------------------------------------------------------------
final_qc_path = path(interim_folder, 'qc_final.csv')
write_csv(encounter_data, final_qc_path)

# -----------------------------------------------------------------------------
# Export for pipeline
# -----------------------------------------------------------------------------
pipeline_path = path(pipeline_folder, "01_encounter_data_validation.csv")
write_csv(encounter_data, pipeline_path)