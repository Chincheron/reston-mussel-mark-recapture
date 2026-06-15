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
# Remove tags never found alive
# -----------------------------------------------------------------------------
# Some tags were found dead bu missing data on release timing
# RMARK cannot handle these cases so removed
# TODO - examine these closer if time permits
combined_data = remove_never_released(combined_data)

# -----------------------------------------------------------------------------
# Final review of combined data before MARK prep
# -----------------------------------------------------------------------------
save_path = path(interim_folder, "qc_combined_data_final.csv")
write_csv(combined_data, save_path)

# =============================================================================
# 5. Prepare data for MARK analysis
# =============================================================================

# -----------------------------------------------------------------------------
# Create capture history columns for each unique tag
# -----------------------------------------------------------------------------
  
capture_history = create_capture_history_table(combined_data)

# -----------------------------------------------------------------------------
# QC of capture history columns
# -----------------------------------------------------------------------------

capture_history = create_ch_qc_cols(capture_history)
# Review capture history tables
save_path = path(interim_folder, "qc_capture_history_v1.csv")
write_csv(capture_history, save_path)

# --- For tags found dead on >1 occasion, include only the first occurence ---

capture_history = fix_multiple_dead_occurences(capture_history)    

# Manual Review 
save_path = path(interim_folder, "qc_multiple_dead.csv")
write_csv(capture_history, save_path)

# Recalculate capture history and qc cols and Review
capture_history = create_ch_col(capture_history) |> 
  create_ch_qc_cols()
save_path = path(interim_folder, "qc_capture_history_v2.csv")
write_csv(capture_history, save_path)


# --- Check and remove tags where found alive after dead (remove alive) ---
# Initial check of all alive after dead tags
alive_after_dead  = check_alive_after_dead(capture_history)

#Review
save_path = path(interim_folder, "qc_alive_after_dead.csv")
write_csv(alive_after_dead, save_path)

# For more than 1 Alive occurences after Dead, Remove Dead occurrence 
source(custom_lib_3)
capture_history = fix_multiple_alive_after_dead(capture_history)

#Review
alive_after_dead =check_alive_after_dead(capture_history)
save_path = path(interim_folder, "qc_alive_after_dead_v2.csv")
write_csv(alive_after_dead, save_path)


# Remove any 'Alive' occurences after 'Dead'
# Except for tag O014, which would result in no release occurences before death
  # For this tag, remove the 'Dead' occurrence
capture_history = fix_alive_after_dead(capture_history)

# Confirm fix
alive_after_dead = check_alive_after_dead(capture_history)
save_path = path(interim_folder, "qc_alive_after_dead_confirm.csv")
write_csv(alive_after_dead, save_path)

# Recalculate capture history and qc cols and Review
capture_history = create_ch_col(capture_history) |> 
  create_ch_qc_cols()
save_path = path(interim_folder, "qc_capture_history_v3.csv")
write_csv(capture_history, save_path)

# -----------------------------------------------------------------------------
# Final hard coded fixes
# -----------------------------------------------------------------------------

# --- Code mussels removed for Chester Experiments ---
capture_history = remove_experiment_mussels(capture_history, config)

# --- Update ch for mussels found by Brennan and Donya ---
capture_history = remove_b_and_d_mussels(capture_history, config)


#TODO - Confirm that encounter histories were built correctly

#TODO - deal with handful of mismatches compared to release data

#TODO - check only one occurence of each tag

# -----------------------------------------------------------------------------
# TODO Confirm that No individuals are found alive after being found dead
# -----------------------------------------------------------------------------

# =============================================================================
# 6. Export for MARK analysis
# =============================================================================

save_path = path(pipeline_folder, "03_mark_input.csv")
write_csv(capture_history, save_path)