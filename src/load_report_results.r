# =============================================================================
# Script: load_report_results.r
#
# Purpose: Load created tables, figures, and other data to be included in the report
# and creates tables for rendering to word document 
#
# Inputs:
# -  Various
# =============================================================================


library(tidyverse)
library(readxl)
library(flextable)
library(fs)
#library(purr)

set_flextable_defaults(fonts_ignore = TRUE)

SCRIPT_NAME = '05a_alt_model_results'
TABLE_PATH = path(global_paths$RESULTS_TABLES, SCRIPT_NAME)

# -----------------------------------------------------------------------------
# Define functions for calculating various report variables
# -----------------------------------------------------------------------------
max_site_abundance = function(site, table){
  #columns to use for max/min for abundance
  stat_columns = c('Abundance Estimate')
  
  max_abundance = table |> 
  filter(.data$Site == .env$site) |> 
  select(all_of(stat_columns)) |> 
  unlist() |> 
  max()
  return(max_abundance)
} 

min_site_abundance = function(site, table){
  #columns to use for max/min for abundance
  stat_columns = c('Abundance Estimate')
  
  min_abundance = table |> 
  filter(.data$Site == .env$site) |> 
  select(all_of(stat_columns)) |> 
  unlist() |> 
  min()
  return(min_abundance)
} 

max_site_monthly_survival = function(site, table){
  #columns to use for max/min for survival
  stat_columns = c('Monthly Survival')
  
  max_survival = table |> 
  filter(.data$Site == .env$site) |> 
  select(all_of(stat_columns)) |> 
  unlist() |> 
  max()
  return(max_survival)
} 

min_site_monthly_survival = function(site, table){
  #columns to use for max/min for survival
  stat_columns = c('Monthly Survival')


  min_survival = table |> 
  filter(.data$Site == .env$site) |> 
  select(all_of(stat_columns)) |> 
  unlist() |> 
  min()
} 

max_site_interval_survival = function(site, table){
  #columns to use for max/min for survival
  stat_columns = c('Occasion Survival')
  
  max_survival = table |> 
  filter(.data$Site == .env$site) |> 
  select(all_of(stat_columns)) |> 
  unlist() |> 
  max()
  return(max_survival)
} 

min_site_interval_survival = function(site, table){
  #columns to use for max/min for survival
  stat_columns = c('Occasion Survival')


  min_survival = table |> 
  filter(.data$Site == .env$site) |> 
  select(all_of(stat_columns)) |> 
  unlist() |> 
  min()
} 

# -----------------------------------------------------------------------------
# Calculate various report variables
# -----------------------------------------------------------------------------
# Import survival table and generate summary variables 
path = path(TABLE_PATH, 'survival_summary.csv')
tbl_survival_summary = read_csv(path)  
# Monthly survival estimates
stat_site = 'Glade'
max_monthly_survival_glade = max_site_monthly_survival(stat_site, tbl_survival_summary)
min_monthly_survival_glade = min_site_monthly_survival(stat_site, tbl_survival_summary)
stat_site = 'Snakeden'
max_monthly_survival_snakeden = max_site_monthly_survival(stat_site, tbl_survival_summary)
min_monthly_survival_snakeden = min_site_monthly_survival(stat_site, tbl_survival_summary)
# Occasion survival estimates
stat_site = 'Glade'
max_interval_survival_glade = max_site_interval_survival(stat_site, tbl_survival_summary)
min_interval_survival_glade = min_site_interval_survival(stat_site, tbl_survival_summary)
stat_site = 'Snakeden'
max_interval_survival_snakeden = max_site_interval_survival(stat_site, tbl_survival_summary)
min_interval_survival_snakeden = min_site_interval_survival(stat_site, tbl_survival_summary)

# Import abundance table and generate summary variables
path = path(TABLE_PATH, 'abundance_summary.csv')
tbl_abundance_summary = read_csv(path)  
stat_site = 'Glade'
max_abundance_glade = max_site_abundance(stat_site, tbl_abundance_summary)
min_abundance_glade = min_site_abundance(stat_site, tbl_abundance_summary)
stat_site = 'Snakeden'
max_abundance_snakeden = max_site_abundance(stat_site, tbl_abundance_summary)
min_abundance_snakeden = min_site_abundance(stat_site, tbl_abundance_summary)

# --- Other report variables ---
# Total released at each site
n_glade_release = config$sites$glade$initial_release
n_snakeden_release = config$sites$snakeden$initial_release
# Site coordinates
coord_glade = config$sites$glade$coord
coord_snakeden = config$sites$snakeden$coord
# Survival from release to last occasion (based on mark estimate)
total_survival_glade = min_abundance_glade / max_abundance_glade *100
total_survival_snakeden = min_abundance_snakeden / max_abundance_snakeden * 100
#Live observation from report Figure 2
final_live_observation_glade = 258
final_live_observation_snakeden = 43
# detectability assuming mark estimates are true
final_detectability_glade = final_live_observation_glade / min_abundance_glade *100
final_detectability_snakeden = final_live_observation_snakeden / min_abundance_snakeden *100
# total observed/not observed (based on mark input file)
observed_live_dead_glade = 890
observed_live_dead_snakeden = 698
not_observed_glade = n_glade_release - observed_live_dead_glade
not_observed_snakeden = n_snakeden_release = observed_live_dead_snakeden
#Retags (based on mark input file)
retag_glade = 47
retag_snakeden = 37
retag_total = retag_glade + retag_snakeden
retag_proportion_glade = retag_glade / observed_live_dead_glade * 100
retag_proportion_snakeden = retag_snakeden / observed_live_dead_snakeden * 100


# --- Create table with sampling dates ---
tbl_occasion_info <- config$sites |>
  imap(
    \(site_info, site_name) {
      tibble(
        Site = str_to_title(site_name),
        Occasion = map_int(site_info$sampling_occasions, "occasion"),
        `Sampling Date` = as.Date(map_chr(site_info$sampling_occasions, "date"))
      )
    }
  ) |>
  list_rbind()
  

# -----------------------------------------------------------------------------
# Functions for generating tables in main report document
# -----------------------------------------------------------------------------

# Called in main document

# Called in main document
make_occasion_table = function(test_load) {
  ft = flextable(test_load) |> 
  # Style
  theme_vanilla() |>
  merge_v(j = "Site") |> 
  valign(j = "Site", valign = "top") |>
  fix_border_issues() |> 
  align(align = "center", part = "header") |>
  align(align = 'center', part = 'body') |> 
  align(j = 1, align = "left", part = "all") |>
  fontsize(size = 8, part = "all") |> 
  padding(padding.top = 2, padding.bottom = 2, 
          padding.left = 3, padding.right = 3, part = "all") |> 
  autofit() |> 
  fit_to_width(max_width = 6.5) 
  
  ft
}

make_survival_table = function(test_load) {
  ft = flextable(test_load) |> 
     set_header_labels(
      `Site` = "Site",
      `Occasion` = "Occasion",
      `Monthly Survival` = "Survival",
      `Monthly Survival SE` = "SE",
      `Monthly Survival LCL` = "LCL",
      `Monthly Survival UCL` = "UCL",
      `Occasion Survival` = "Survival",
      `Occasion Survival SE` = "SE",
      `Occasion Survival LCL` = "LCL",
      `Occasion Survival UCL` = "UCL"
  ) |>
  # Add spanning top header row for occasions
  add_header_row(
    values    = c("", "Monthly Survival", "Interval Survival"),
    colwidths = c(2, 4, 4)
  ) |>
  # Style
  theme_vanilla() |>
  merge_v(j = "Site") |> 
  valign(j = "Site", valign = "top") |>
  align(align = "center", part = "header") |>
  align(align = 'center', part = 'body') |> 
  align(j = 1, align = "left", part = "all") |>
  fontsize(size = 8, part = "all") |> 
  padding(padding.top = 2, padding.bottom = 2, 
          padding.left = 3, padding.right = 3, part = "all") |> 
  autofit() |> 
  fit_to_width(max_width = 6)
  
  ft
}

# function for making table object out of abundance tables for rendering 
# Called in main document
make_abundance_table = function(test_load) {
  ft = flextable(test_load) |> 
  # Style
  theme_vanilla() |>
  merge_v(j = "Site") |> 
  valign(j = "Site", valign = "top") |>
  align(align = "center", part = "header") |>
  align(align = 'center', part = 'body') |> 
  align(j = 1, align = "left", part = "all") |>
  fontsize(size = 8, part = "all") |> 
  padding(padding.top = 2, padding.bottom = 2, 
          padding.left = 3, padding.right = 3, part = "all") |> 
  autofit() |> 
  fit_to_width(max_width = 5.5)
  
  ft
}



# # function for making table object out of two abundance tables for rendering 
# # Called in main document
# make_abundance_table = function(test_load) {
#   occasions = c('Release', 'MR 1', 'MR 2', 'MR 3', 'MR 4')
#   test_load = test_load |>
#     pivot_wider(
#       names_from = 'facility',
#       values_from = all_of(occasions),
#       names_glue = '{.value}_{facility}'
#     ) |> 
#     select(species, 
#          map(occasions, ~ paste0(.x, "_", c("FMCC", "Harrison Lake"))) |> unlist()
#   )

#   ft = flextable(test_load) |> 
#      set_header_labels(
#       `species` = "Species",
#       `Release_FMCC` = "FMCC",
#       `Release_Harrison Lake` = "Harrison Lake",
#       `MR 1_FMCC` = "FMCC",
#       `MR 1_Harrison Lake` = "Harrison Lake",
#       `MR 2_FMCC` = "FMCC",
#       `MR 2_Harrison Lake` = "Harrison Lake",
#       `MR 3_FMCC` = "FMCC",
#       `MR 3_Harrison Lake` = "Harrison Lake",
#       `MR 4_FMCC` = "FMCC",
#       `MR 4_Harrison Lake` = "Harrison Lake"
#   ) |>
#   # Add spanning top header row for occasions
#   add_header_row(
#     values    = c("", occasions),
#     colwidths = c(1, rep(2, 5))
#   ) |>
#   # Style
#   theme_vanilla() |>
#   align(align = "center", part = "header") |>
#   align(align = 'center', part = 'body') |> 
#   align(j = 1, align = "left", part = "all") |>
#   fontsize(size = 8, part = "all") |> 
#   padding(padding.top = 2, padding.bottom = 2, 
#           padding.left = 3, padding.right = 3, part = "all") |> 
#   width(j = 2:ncol(test_load), width = (6.5 - .8) / 10) |>  # distribute remaining width evenly across data cols
#   width(j = 1, width = .8) 
#     # autofit() |> 
#   # fit_to_width(max_width = 6.5) |> 
#   # set_table_properties(
#   #   layout= 'fixed',
#   #   width = 1,
#   #   align = 'left'
#   # )

# ft
# }
