get_global_fig_config = function() {
  all_plot_config <- list(
  labels = list(
    mark_analysis_level = "Analysis Level",
    Occasion = "Sampling Occasion",
    facility = "Facility",
    site = "Site",
    species = "Species",
    perc_of_initial = "Percentage of Initial Release",
    model = 'Model Type'
   ),
  palettes = list(
    analysis_level = c(
      assemblage = "steelblue",
      species    = "darkorange"
    ),
    site_level = c(
      snakeden = "deepskyblue",
      glade = "darkred"
    ),
    model_level = c(
      reduced_from_top = 'darkorange',
      top = 'steelblue'
    )
  ),
  column_mapping = list(
    analysis_level = "mark_analysis_level",
    species = "species",
    site = "site",
    mark_parameter = "Parameter",
    sampling_occasion = "Occasion",
    parameter_estimate = "estimate",
    standard_error = "se",
    lower_ci = "lcl",
    upper_ci = "ucl",
    initial_release = 'initial_release',
    perc_of_initial = "perc_of_initial",
    perc_of_initial_lcl = "perc_of_initial_lcl",
    perc_of_initial_ucl = "perc_of_initial_ucl",
    model = 'model',
    s_lower_ci = 's_lcl',
    s_upper_ci = 's_ucl',
    abundance_release = 'abundance_total_release'
  ),
  category_order = list(
    sampling_occasion = c('Release', 'Occasion 1', 'Occasion 2', 'Occasion 3', 'Occasion 4', 
      'Occasion 5', 'Occasion 6', 'Occasion 7', 'Occasion 8'),
    sampling_occasion_s = c('Interval 1',
      'Interval 2', 
      'Interval 3', 
      'Interval 4',
      'Interval 5',
      'Interval 6',
      'Interval 7',
      'Interval 8',
      'Interval 9'
    ),
    reduced_model_order = c('top', 'reduced_from_top')
  ),
  theme = theme_bw(base_size = 12)
)
  return(all_plot_config)
}