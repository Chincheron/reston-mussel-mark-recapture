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
SCRIPT_NAME = '05a_alt_model_results'
source_folder = path(global_paths$DATA_PIPELINE)
pipeline_folder = path(global_paths$DATA_PIPELINE, SCRIPT_NAME)
interim_folder = path(global_paths$DATA_INTERIM, SCRIPT_NAME)
figure_folder = path(global_paths$RESULTS_FIGURES, SCRIPT_NAME)
table_folder = path(global_paths$RESULTS_TABLES, SCRIPT_NAME)

# Make directories
dir_create(c(
  pipeline_folder,
  interim_folder,
  figure_folder,
  table_folder
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

snakeden_selected_model = extract_rmark_model_results(results_list, "snakeden", 
  "S.time.p.dot.r.dot.F.fixed")

glade_selected_model = extract_rmark_model_results(results_list, "glade", 
  "S.time.p.year.r.dot.F.fixed")

selected_model_results = bind_rows(snakeden_selected_model, glade_selected_model)

# Final processing of top model results
# e.g., standardize labels, add initial release numbers, convert daily to annual survival
#   , create estimates for 'combined' facility
source(custom_lib_1)
selected_model_results = process_model_results(selected_model_results)

#TODO calculate derived population size

# =============================================================================
# 3. Export top model results 
# =============================================================================

# -----------------------------------------------------------------------------
# Export to data folder 
# ----------------------------------------------------------------------------- 

# Export top model results to file for manual review/use
data_save_path = path(interim_folder, '05_selected_model_results.xlsx')
write_xlsx(selected_model_results, data_save_path)

# Export R object for later use
data_objects_path = path(interim_folder, '05_selected_model_results.rds')
saveRDS(results_list, data_objects_path, ascii = TRUE)

# =============================================================================
# 4. Plot top model results
# =============================================================================

# All figures are exported to the specified figure_folder

# -----------------------------------------------------------------------------
# Get global plot variables and settings
# -----------------------------------------------------------------------------

# Filter out last interval (post sampling recovery period)
selected_model_results = selected_model_results |> 
  filter(!Occasion %in% c("Interval 9", "Occasion 10"))

source(custom_lib_2)
# Specifies settings for visual aspects of all figures
all_plot_config <- get_global_fig_config()
# Pull column mapping for ease of reading function later
cm = all_plot_config$column_mapping

# Define initial settings for group of figures
survival_plot_config <- list(
  parameter = "S",
  y_factor = cm$occasion_survival,
  y_label   = "Estimated Survival Between Occasions",
  y_variance_upper = cm$occasion_upper_ci,
  y_variance_lower = cm$occasion_lower_ci,
  x_factor = cm$sampling_occasion,
  x_factor_label = all_plot_config$labels$Occasion,
  x_order = all_plot_config$category_order$sampling_occasion_s,
  x_order_label = all_plot_config$category_labels$sampling_occasion_s,
  x_order_label_dodge = 2,
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
  save_file_name = 'Figure_1_survival_selected_model.jpg',
    x_factor_label = "Interval"
)
source(custom_lib_1)
build_base_plot(selected_model_results, all_plot_config, survival_plot_config, config_override)

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
  x_order_label_dodge = 1,
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
  save_file_name = 'Figure_2_abundance_selected_model.jpg' 
)
build_base_plot(selected_model_results, all_plot_config, abundance_plot_config, config_override)

# =============================================================================
# 5. Generate corresponding tables for report
# =============================================================================

# All tables are exported to the specified figure_folder

# --- Survival Table ---

interval_rename_map = all_plot_config$category_labels$sampling_occasion_s

tbl_survival_summary = selected_model_results |> 
  filter(Parameter == 'S') |> 
  group_by(site, Occasion) |> 
  summarize(
    `Monthly Survival` = mean(estimate),
    `Monthly Survival SE` = mean(se),
    `Monthly Survival LCL` = mean(lcl),
    `Monthly Survival UCL` = mean(ucl),
    `Occasion Survival` = mean(occasion_survival),
    `Occasion Survival SE` = mean(occasion_survival_se),
    `Occasion Survival LCL` = mean(occasion_survival_lcl),
    `Occasion Survival UCL` = mean(occasion_survival_ucl)
  ) |> 
  mutate(
    site = str_to_title(site),
    Occasion = recode(Occasion, !!!interval_rename_map),
    #Round all numbers and truncate after 2nd decimal place
    `Monthly Survival` =  `Monthly Survival`**(1/12),
    across(where(is.numeric), ~format(round(., 3), nsmall = 2)),
  ) |> 
  rename(
    Site = site
  )
tbl_save_object = tbl_survival_summary
# Save csv to results folder (for report)
object_path = path(table_folder, 'survival_summary.csv')
write_csv(tbl_save_object, object_path)

occasion_rename_map = all_plot_config$category_labels$sampling_occasion

tbl_abundance_summary = selected_model_results |>  
  filter(Parameter == 'Abundance') |> 
  group_by(site, Occasion, occasion_index) |> 
  summarize(
    `Abundance Estimate` = mean(abundance),
    #`Abundance Survival SE` = mean(se),
    `Abundance LCL` = mean(abundance_lcl),
    `Abundance UCL` = mean(abundance_ucl)
  ) |> 
  mutate(
    site = str_to_title(site),
    Occasion = recode(Occasion, !!!occasion_rename_map),
    #Round all numbers and truncate after 2nd decimal place
    across(where(is.numeric), ~format(round(., 0), nsmall = 0))
  ) |> 
  rename(
    Site = site
  ) |> 
  arrange(Site, occasion_index) |> 
  select(-occasion_index)
tbl_save_object = tbl_abundance_summary
# Save csv to results folder (for report)
object_path = path(table_folder, 'abundance_summary.csv')
write_csv(tbl_save_object, object_path)

