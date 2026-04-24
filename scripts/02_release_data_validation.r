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
custom_lib_1 = path(global_paths$SRC, '02_release_data_validation.r')
custom_lib_2 = path(global_paths$SRC, '01_encounter_data_validation.r')
source(custom_lib_1)
source(custom_lib_2)

# -----------------------------------------------------------------------------
# Paths and import/export directories
# -----------------------------------------------------------------------------

# Set directories
SCRIPT_NAME = '02_release_data_validation'
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
# 2. Load release data
# =============================================================================
input_file = path(source_folder, "2024 and 2025 MR Summary - 1.xlsx")
input_sheet = "2025 Where Found Snakeden"
input_range = "A4:B2805"
release_data = read_excel(input_file, sheet = input_sheet, range = input_range,
  col_names = c("Tag Number", "presumed_site")
)
names(release_data)

# =============================================================================
# 3. Validate Release Data
# =============================================================================

# -----------------------------------------------------------------------------
# Check for Null/missing values
# -----------------------------------------------------------------------------

total_rows = nrow(release_data)

# Summarize missing values by column
missing_summary = colSums(is.na(release_data))
# No missing values

# -----------------------------------------------------------------------------
# Check for duplicate values
# -----------------------------------------------------------------------------

# --- Find Exact duplicates ---
dup_exact = release_data |> 
  group_by_all() |> 
  filter(n() > 1) |> 
  ungroup()
# Manual review
dup_exact_path = path(interim_folder, 'qc_dup_exact.csv')
write_csv(dup_exact, dup_exact_path)
# Two exact duplicates - Removed
release_data = remove_exact_duplicates(release_data)

# -----------------------------------------------------------------------------
# Validate Tag Format
# -----------------------------------------------------------------------------

error_path = path(interim_folder, "error_validate_tag_format.csv")
validate_tag_format(release_data, error_path)

# -----------------------------------------------------------------------------
# Assess Completeness/Consistency
# -----------------------------------------------------------------------------

# --- Crosscheck against report numbers ---
release_data |> 
  count(presumed_site)

# 1131/1669 at glade/snakeden from data
# 1224/1578 at glade/snakeden from report
# Baskets for Pool 10 at Glade possibly released at snakeden instead on site?

# =============================================================================
# 4. Final export
# =============================================================================

# -----------------------------------------------------------------------------
# Export for final qc review
# -----------------------------------------------------------------------------
final_qc_path = path(interim_folder, 'qc_final.csv')
write_csv(release_data, final_qc_path)

# -----------------------------------------------------------------------------
# Export for pipeline
# -----------------------------------------------------------------------------
pipeline_path = path(pipeline_folder, "02_release_data_validation.csv")
write_csv(release_data, pipeline_path)