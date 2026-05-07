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

presume_site_no_match = combined_data |> 
  mutate(
    presume_match = case_when(
      str_to_lower(presumed_site) == str_to_lower(site) ~ TRUE,
      .default = FALSE
    ) 
  ) |> 
  filter(presume_match == FALSE & occasion != 0)

save_path = path(interim_folder, "qc_presume_no_match.csv")
write_csv(presume_site_no_match, save_path)

#TODO - FIX issues where presumed sites doesn't match encounter site

# -----------------------------------------------------------------------------
# Confirm each tag only found once per occasion
# -----------------------------------------------------------------------------

# =============================================================================
# 5. Prepare data for MARK analysis
# =============================================================================

# Create a final site column based on presumed and encounter sites
combined_data = combined_data |> 
  mutate(
    final_site = case_when(
      occasion == 0 ~ str_to_lower(presumed_site),
      .default = str_to_lower(site)
    )
  )

capture_history = combined_data |> 
  mutate(value = 1) |> 
  select(`Tag Number`, final_site, occasion, value, Status) |> 
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

# -----------------------------------------------------------------------------
# Confirm that No individuals are found alive after being found dead
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Create Capture History column
# -----------------------------------------------------------------------------