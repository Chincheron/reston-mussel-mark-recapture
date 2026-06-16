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
library(writexl)
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
custom_lib_2 = path(global_paths$CONFIG, 'global_figure_config.r')
source(custom_lib_1)
source(custom_lib_2)

# -----------------------------------------------------------------------------
# Paths and import/export directories
# -----------------------------------------------------------------------------

# Set directories
SCRIPT_NAME = '05_top_model_results'
source_folder = path(global_paths$DATA_PIPELINE)
pipeline_folder = path(global_paths$DATA_PIPELINE, SCRIPT_NAME)
interim_folder = path(global_paths$DATA_INTERIM, SCRIPT_NAME)
figure_folder = path(global_paths$RESULTS_FIGURES, SCRIPT_NAME)

# Make directories
dir_create(c(
  pipeline_folder,
  interim_folder,
  figure_folder
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

results_list$snakeden$S.year.p.year.r.time.F.fixed
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
top_model_results <- purrr::map_dfr(
  analysis_names,
  ~ extract_top_model_results(results_list, .x)
)

# Final processing of top model results
# e.g., standardize labels, add initial release numbers, convert daily to annual survival
#   , create estimates for 'combined' facility
source(custom_lib_1)
top_model_results = process_model_results(top_model_results)

#TODO calculate derived population size

# =============================================================================
# 3. Export top model results 
# =============================================================================

# -----------------------------------------------------------------------------
# Export to data folder 
# ----------------------------------------------------------------------------- 

# Export top model results to file for manual review/use
data_save_path = path(interim_folder, '05_top_model_results.xlsx')
write_xlsx(top_model_results, data_save_path)

# Export R object for later use
data_objects_path = path(interim_folder, '05_top_model_results.rds')
saveRDS(results_list, data_objects_path, ascii = TRUE)

# =============================================================================
# 4. Plot top model results
# =============================================================================

# All figures are exported to the specified figure_folder

# -----------------------------------------------------------------------------
# Get global plot variables and settings
# -----------------------------------------------------------------------------

# Filter out last interval (post sampling recovery period)
top_model_results = top_model_results |> 
  filter(!Occasion %in% c("Interval 9", "Occasion 10"))

source(custom_lib_2)
# Specifies settings for visual aspects of all figures
all_plot_config <- get_global_fig_config()
# Pull column mapping for ease of reading function later
cm = all_plot_config$column_mapping

# Define initial settings for group of figures
survival_plot_config <- list(
  parameter = "S",
  y_factor = cm$parameter_estimate,
  y_label   = "Estimated Survival",
  y_variance_upper = cm$s_upper_ci,
  y_variance_lower = cm$s_lower_ci,
  x_factor = cm$sampling_occasion,
  x_factor_label = all_plot_config$labels$Occasion,
  x_order = all_plot_config$category_order$sampling_occasion_s,
  x_order_label = all_plot_config$category_labels$sampling_occasion_s,
  grouping = cm$site,
  grouping_label = all_plot_config$labels$site,
  grouping_order = c('glade', 'snakeden'),
  grouping_order_label = all_plot_config$category_labels$grouping_order_labels,
  grouping_palette = "site_level",
  #NULL if 0 facets, 1 if single. If 2, then first will be rows and second columns
  #facet_vars = c(cm$species),
  title = NULL,
  subtitle = NULL,
  caption = NULL,
  save_folder = figure_folder,
  save_file_name = NULL,
  aggregate_flag = FALSE,
  variance_flag = TRUE
)

# --- Survival ---
config_override = list(
  save_file_name = 'Figure_1_survival_top_model.jpg',
    x_factor_label = "Interval"
)
build_base_plot(top_model_results, all_plot_config, survival_plot_config, config_override)

# Define initial settings for Abundance group of figures
abundance_plot_config <- list(
  parameter = "Abundance",
  y_factor = cm$abundance,
  y_label   = "Estimated Abundance",
  y_variance_upper = cm$abundance_upper_ci,
  y_variance_lower = cm$abundance_lower_ci,
  x_factor = cm$sampling_occasion,
  x_factor_label = all_plot_config$labels$Occasion,
  x_order = all_plot_config$category_order$sampling_occasion,
  x_order_label = all_plot_config$category_labels$sampling_occasion,
  grouping = cm$site,
  grouping_label = all_plot_config$labels$site,
  grouping_order = c('glade', 'snakeden'),
  grouping_order_label = all_plot_config$category_labels$grouping_order_labels,
  grouping_palette = "site_level",
  #NULL if 0 facets, 1 if single. If 2, then first will be rows and second columns
  #facet_vars = c(cm$species),
  title = NULL,
  subtitle = NULL,
  caption = NULL,
  save_folder = figure_folder,
  save_file_name = NULL,
  aggregate_flag = FALSE,
  variance_flag = TRUE
)

source(custom_lib_1)
# --- Survival ---
config_override = list(
  save_file_name = 'Figure_2_abundance_top_model.jpg' 
)
build_base_plot(top_model_results, all_plot_config, abundance_plot_config, config_override)

