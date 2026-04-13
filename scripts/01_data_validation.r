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

sampling_dates = config$sites$snakeden$sampling_occasions

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

# --- Create lookup table for loading data ---
# Intermediate table of project level sampling info
occasion_info <- imap_dfr(config$sites, function(site_data, site_key) {
  tibble(
    site_key  = site_key,                          # "snakeden", "glade"
    site_name = site_data$name,                    # "Snakeden Run", "Glade Run"
    occasion  = map_int(site_data$sampling_occasions, "occasion"),
    date      = map_chr(site_data$sampling_occasions, "date") |> as.Date()
  )
})
# Lookup sheets/ranges for pulling data
sheet_ranges = imap_dfr(config$sheet_ranges, function(occasions, site_key){
  bind_rows(occasions) |> 
    mutate(site_key = site_key)
})
# Join occasion info and sheet ranges for final lookup table
occasions = sheet_ranges |> 
  left_join(occasion_info, by = c('site_key', 'occasion'))

# --- Read encounter data in long format ---
input_file = path(source_folder, '2024 and 2025 MR Summary - 1.xlsx')
data = occasions |> 
  pmap(function(occasion, sheet, range, expected_rows, site_key, site_name, date, ...){
    df = read_excel(input_file, sheet = sheet, range = range, col_types = 'text') |> 
      mutate(
        site = site_key,
        occasion = occasion,
        date = date
      )
    
    # Confirm that the correct number of rows is imported 
    message(glue(" {site_key} | {occasion} | {nrow(df)} rows imported"))
    
    
    if (nrow(df) != expected_rows) {
      warning(glue("  Row count mismatch for {site_name} occasion {occasion}: got {nrow(df)}, expected {expected_rows}"))
    }

    return(df)
  }) |> 
  list_rbind()

