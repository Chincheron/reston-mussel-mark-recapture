# =============================================================================
# 1. Setup
# =============================================================================

# -----------------------------------------------------------------------------
# Import libraries
# -----------------------------------------------------------------------------

library(reticulate)
library(yaml)
library(fs)
library(RMark)
library(tidyverse)
library(dplyr)
library(readxl)
library(glue)

# -----------------------------------------------------------------------------
# Load project paths and config.yaml
# -----------------------------------------------------------------------------

global_paths = import("config.paths", convert = TRUE) 

config_file = as.character(global_paths$CONFIG / 'config.R')
source(config_file)
config = load_config()

# Custom library
custom_lib_1 = path(global_paths$SRC, '05_top_model_results.r')
source(custom_lib_1)

# -----------------------------------------------------------------------------
# Paths and import/export directories
# -----------------------------------------------------------------------------

# Set directories
SCRIPT_NAME = '05_top_model_results'
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
# 2. Load and transform data
# =============================================================================

# -----------------------------------------------------------------------------
# Load ALL results from MARK analysis
# ----------------------------------------------------------------------------- 

results_file = path(source_folder, '04_mark_analysis', '04_mark_results.rds')
results_list = readRDS(results_file)

# =============================================================================
# Examine model rankings
# =============================================================================
model_comparison_snakeden = results_list$snakeden$model.table
model_comparison_glade = results_list$glade$model.table

model_file_snakeden = path(interim_folder, "model_comparison_snakeden.csv")
model_file_glade = path(interim_folder, "model_comparison_glade.csv")

write_csv(model_comparison_snakeden, model_file_snakeden)
write_csv(model_comparison_glade, model_file_glade)

# -----------------------------------------------------------------------------
# Extract results from the top model
# -----------------------------------------------------------------------------

analysis_names <- names(results_list)

# Create dataframe with parameter estimates of from the top model of each analysis
source(custom_lib_1)
top_model_results <- purrr::map_dfr(
  analysis_names,
  ~ extract_top_model_results(results_list, .x)
)
