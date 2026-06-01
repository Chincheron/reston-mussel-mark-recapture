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
custom_lib_1 = path(global_paths$SRC, '04_mark_analysis.r')
source(custom_lib_1)

# -----------------------------------------------------------------------------
# Paths and import/export directories
# -----------------------------------------------------------------------------

# Set directories
SCRIPT_NAME = '04_mark_analysis'
source_folder = path(global_paths$DATA_PIPELINE)
pipeline_folder = path(global_paths$DATA_PIPELINE, SCRIPT_NAME)
interim_folder = path(global_paths$DATA_INTERIM, SCRIPT_NAME)
mark_obj_folder = path(interim_folder, "rmark_analysis")

# Make directories
dir_create(c(
  pipeline_folder,
  interim_folder,
  mark_obj_folder
  )
)

# =============================================================================
# 2. Load and transform data
# =============================================================================

mark_input_path = path(source_folder, "03_join_encounter_release", "03_mark_input.csv")
load_cols = c("Tag Number", "presumed_site", "ch")
mark_input = read_csv(mark_input_path, col_select = all_of(load_cols))


#TODO - check NA values and misspellings of site names

# Remove all 0 capture histories
mark_input = mark_input |> 
  filter(ch != "000000000000000000")

site_input = split(mark_input, mark_input$presumed_site)

# =============================================================================
# 3. Run Burnham Joint model in RMARK
# =============================================================================

# Define hypotheses to be tested for each model parameter
# Used further down to construct a candidate model set of all possible combinations
model_def = list(
#phi
S.dot=list(formula=~1),
S.time = list(formula=~time),
#p
p.dot=list(formula=~1),
p.time=list(formula=~time),
#r
r.dot=list(formula=~1),
r.time = list(formula=~time),
#F
f.fixed = list(formula=~1, fixed = 1)
)

#Testing
#results = run_burnham_model_2("glade", mark_input, mark_obj_folder, model_def, config)
#results = run_burnham_model_2("snakeden", mark_input, mark_obj_folder, config)

results_list = list() 
# Run both sites
sites = c("snakeden", "glade")
for(site in sites){
  site_results = run_burnham_model_2(site, mark_input, mark_obj_folder, model_def, config)
  results_list[[site]] = site_results
} 

#TODO Goodness of fit testing (same model as live encounters model - which is?)

