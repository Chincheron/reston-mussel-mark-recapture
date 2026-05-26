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

source(custom_lib_1)
results = run_burnham_model_2("glade", mark_input, mark_obj_folder, config)


results_list = list() 
# Run both sites
sites = c("snakeden", "glade")
for(site in sites){
  site_results = run_burnham_model_2(site, mark_input, mark_obj_folder, config)
  results_list[[site]] = site_results
} 

#TODO incorrect number of intervals? Last recovery interval after  last sampling maybe?
#TODO Goodness of fit testing (same model as live encounters model - which is?)
#TODO determine how to fix parameters
#TODO candidate model set




# Must create a environment then inject parameter definitions and assign other variables to be used (e.g. fixing pent to 0)
model_env = new.env(parent=environment())
list2env(model_def, envir = model_env)
assign("pent.0", list(formula=~1, fixed=0), envir = model_env)
ls(model_env)

mark_input = input_file
#setup common analysis variables
time_interval = c(246,35, 29, 69) #TODO setup formula for calculating for each species automaically}

begin_time = 2024 # must be a number and not a string


  
#Create processed dataframe for specific model
popan_process = process.data(mark_input, 
  model = 'POPAN'
  ,begin.time = begin_time
  ,time.intervals = time_interval
  , groups = analy_groups
)
popan_process$group.covariates

#Create design data for analysis
#fix pent to 0 because we are following one release cohort with no new entries or births
#pent.0 = list(formula=~1, fixed=0)
popan_ddl = evalq(make.design.data(popan_process,
  parameters=list(pent=pent.0)
  #parameters=list(pent=list(pim.type="time")
  #, N=list(pim.type="constant")
  ), envir = model_env)
  head(popan_ddl$pent)

#Auto create all possible models to be run based on model list of individual parameters
  ls(model_env)
popan_model_list = evalq(create.model.list("POPAN"), envir = model_env)
popan_results = evalq(with_dir(save_directory, {
    mark.wrapper(popan_model_list, data=popan_process, ddl=popan_ddl
    )
    })
    , envir = model_env)

# export for easier exploration of results
with_dir(save_directory, {
      export.MARK(popan_process, analysis_name,  popan_results
    )
    })

return(popan_results)


