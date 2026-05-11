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
custom_lib_3 = path(global_paths$SRC, '03_join_encounter_release.r')
source(custom_lib_1)
source(custom_lib_2)
source(custom_lib_3)

# -----------------------------------------------------------------------------
# Paths and import/export directories
# -----------------------------------------------------------------------------

# Set directories
SCRIPT_NAME = '03_join_encounter_release'
source_folder = path(global_paths$DATA_PIPELINE)
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

encounter_input_file = path(source_folder, "01_encounter_data_validation", "01_encounter_data_validation.csv")
encounter_data = read_csv(encounter_input_file)

#Split untagged data from encounter data

encounter_non_unique = encounter_data |> 
  filter(`Tag Number` %in% c("Untagged", "Shell Piece"))

encounter_unique = encounter_data |> 
  filter(!(`Tag Number` %in% c("Untagged", "Shell Piece")))
  
  
release_data_file = path(source_folder, "02_release_data_validation", "02_release_data_validation.csv")
release_data = read_csv(release_data_file)

# =============================================================================
# 3.Join Release and Encounter Data
# =============================================================================

# Add Status, occasion 0, and date to release before joining
release_data = add_columns_to_release(release_data)

# Need to get unique values of Encounter data

# Join data
combined_data = combine_encounter_release(encounter_unique, release_data)

# Review Data
save_path = path(interim_folder, "qc_combined_data.csv")
write_csv(combined_data, save_path)

# =============================================================================
# 4. QC of combined data
# =============================================================================

# -----------------------------------------------------------------------------
# Check that all encounter data is only found at same site
# -----------------------------------------------------------------------------
different_encounter_sites = check_mismatched_encounter_sites(combined_data)
save_path = path(interim_folder, "qc_different_encounter_sites.csv")
write_csv(different_encounter_sites, save_path)

#Fix issues where same tag was found at different sites in encounter 1-8
combined_data |> 
  filter(`Tag Number` == "B007" & site == "snakeden")
combined_data = fix_mismatched_encounter_sites(combined_data)

# Confirm fixes
different_encounter_sites = check_mismatched_encounter_sites(combined_data)
save_path = path(interim_folder, "qc_different_encounter_sites_confirm.csv")
write_csv(different_encounter_sites, save_path)

# -----------------------------------------------------------------------------
# Check instances where encounter site does not match presumed site
# -----------------------------------------------------------------------------

# Save mismatch for review
presume_site_no_match = check_presumed_site(combined_data) 
save_path = path(interim_folder, "qc_presume_no_match.csv")
write_csv(presume_site_no_match, save_path)

# Fix presumed site mismatches
combined_data = fix_presumed_sites(combined_data)

# Confirm fixes
presume_site_no_match = check_presumed_site(combined_data)
save_path = path(interim_folder, "qc_presume_no_match_confirm.csv")
write_csv(presume_site_no_match, save_path)

# -----------------------------------------------------------------------------
# Confirm each tag only found once per occasion
# -----------------------------------------------------------------------------

# Check for multiple encounters of same tag on the same occasion
multiple_encounters = check_multiple_encounters_per_occasion(combined_data)
save_path = path(interim_folder, "qc_multiple_encounters.csv")
write_csv(multiple_encounters, save_path)

combined_data = fix_multiple_encounters(combined_data)

# Confirm issues resolved
multiple_encounters = check_multiple_encounters_per_occasion(combined_data)
save_path = path(interim_folder, "qc_multiple_encounters_confirm.csv")
write_csv(multiple_encounters, save_path)

# -----------------------------------------------------------------------------
# Fix issue with tags 
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Final review of combined data before MARK prep
# -----------------------------------------------------------------------------
save_path = path(interim_folder, "qc_combined_data_final.csv")
write_csv(combined_data, save_path)

# =============================================================================
# 5. Prepare data for MARK analysis
# =============================================================================

capture_history = combined_data |> 
  mutate(value = 1) |> 
  select(`Tag Number`, presumed_site, occasion, value, Status) |> 
  distinct() |> 
  pivot_wider(
    names_from = occasion,
    values_from = c(value, Status),
    names_glue = "occasion_{occasion}{ifelse(.value == 'Status', '_status', '')}",
    values_fill = list(value = 0)
  )

# Review capture history tables
save_path = path(interim_folder, "qc_capture_history.csv")
write_csv(capture_history, save_path)

#TODO - deal with handful of mismatches compared to release data

#TODO - check only one occurence of each tag

# -----------------------------------------------------------------------------
# Confirm that No individuals are found alive after being found dead
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Create Capture History column
# -----------------------------------------------------------------------------

# Columns to be combined into single encounter history column
encounter_cols = c(
    'occasion_0',
    'occasion_1',
    'occasion_2',
    'occasion_3',
    'occasion_4',
    'occasion_5',
    'occasion_6',
    'occasion_7',
    'occasion_8'
)

status_cols = c(
    'occasion_1_status',
    'occasion_2_status',
    'occasion_3_status',
    'occasion_4_status',
    'occasion_5_status',
    'occasion_6_status',
    'occasion_7_status',
    'occasion_8_status'
)

#logic/flow:
#create live encounter ch
# if occasion_x = 1 and occasion_x_status = 'Alive', then '1', else 0
#create dead encounter ch:
# if occasion_x_status = 'Alive', then interval x = '0', if 'Dead', then '1'
#combine both value alternatingly

# Column title must be 'ch' for later use with RMARK
df = capture_history


df = df |> 
  unite(
    ch,
    all_of(encounter_cols),
    sep = "",
    remove = TRUE
  )

