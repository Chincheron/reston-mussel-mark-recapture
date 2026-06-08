library(reticulate)
library(withr)
library(fs)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(writexl)
library(scales)
library(ggh4x)


extract_rmark_model_results = function(data, analysis, model_name) {
  
  real_results = results_list[[analysis]][[model_name]]$results$real

  real_df = as.data.frame(real_results) |>
    tibble::rownames_to_column("Parameter") |>
    separate_wider_regex(Parameter, patterns = c(
      Parameter = "^[^ ]+",
      " ",
      Group = ".*",
      " ",
      Occasion = "a[0-9]+(?:\\.[0-9]+)? t[0-9]+(?:\\.[0-9]+)?$"
    ))
  
  real_df = real_df |> 
    mutate(
      site = analysis
    )

  return(real_df)
}

extract_top_model_results = function(results_list, analysis) {
  #analysis = 'snakeden'
  model_table = results_list[[analysis]]$model.table

  top_model = head(model_table, 1)
  
  #get top model name 
  s_model = top_model[["S"]][1] %>% 
    substring(2, nchar(.)) |> 
    str_to_lower()
  p_model = top_model[["p"]][1] %>% 
    substring(2, nchar(.)) |> 
    str_to_lower()
  r_model = top_model[["r"]][1] %>% 
    substring(2, nchar(.)) |> 
    str_to_lower()

  #Replace 1 with 'dot'
  s_model = if (s_model == "1") "dot" else s_model
  p_model = if (p_model == "1") "dot" else p_model
  r_model = if (r_model == "1") "dot" else r_model

  top_model_name = paste0("S.", s_model, ".p.", p_model, ".r.", r_model, ".F.fixed")
  

  #Set top model name to pull results from marklist object
  top_model_name = gsub("1", "dot", top_model_name)
  #deal with inconsistent naming of interaction models between row names and model names
  top_model_name = str_replace_all(top_model_name, fixed(' + '), 'plus')
  top_model_name = str_replace_all(top_model_name, fixed(' * '), '.')
  
  # TODO Add here if statement for assemblage lefle analysis
  #extract real and derived results from top model
  final_results = extract_rmark_model_results(real_results, analysis, top_model_name) 
  
  return(final_results)
}

process_model_results = function(data) {
# standardize occasion labels
data = data |> 
   mutate(
      Occasion = case_when(
      Parameter == "S" & str_detect(Occasion, "a0")   ~ "Interval 1",
      Parameter == "S" & str_detect(Occasion, "a11") ~ "Interval 2",
      Parameter == "S" & str_detect(Occasion, "a13") ~ "Interval 3",
      Parameter == "S" & str_detect(Occasion, "a14") ~ "Interval 4",
      Parameter == "S" & str_detect(Occasion, "a19")   ~ "Interval 5",
      Parameter == "S" & str_detect(Occasion, "a23")   ~ "Interval 6",
      Parameter == "S" & (str_detect(Occasion, "a25.0") |str_detect(Occasion, "a25.1"))   ~ "Interval 7",
      Parameter == "S" & str_detect(Occasion, "a25.7")   ~ "Interval 8",
      Parameter == "S" & str_detect(Occasion, "a26")   ~ "Interval 9",
      TRUE ~ Occasion
      )
    )

  # add initial release numbers of uniquely tagged individuals by site
  # number of mussels released by site
  data = data |>
    mutate(
      total_release = case_when(
        site == "snakeden" ~ config$sites$snakeden$initial_release,
        site == "glade" ~ config$sites$glade$initial_release
      )
    ) 
  
# convert monthly survival to annual survival
data = data |> 
  mutate(
    estimate = case_when(
      Parameter == 'S' ~ estimate^12,
      .default = estimate
    ),
    s_lcl = case_when(
      Parameter == 'S' ~ lcl^12,
      .default = lcl
    ),
    s_ucl = case_when(
      Parameter == 'S' ~ ucl^12,
      .default = ucl
    )
  )

  
  # calculate abundance on each occasion based on estimated Survival
  interval_lookup <- imap_dfr(config$sites, \(site_cfg, site_name) {
    tibble(
      site = site_name,
      occasion_index = seq_along(site_cfg$intervals_days),
      interval_days = site_cfg$intervals_days
    )
  })
  print(interval_lookup)
  data <- data |>
  mutate(
    occasion_index = readr::parse_number(Occasion)
  )
  data <- data |>
  left_join(
    interval_lookup,
    by = c("site", "occasion_index")
  )
  data <- data |>
  mutate(
    occasion_survival = if_else(
      Parameter == "S",
      estimate^(interval_days / 30.44),
      estimate
    )
  )
    # mutate(
    #   occasion_survival = case_when(
    #     Parameter == "S" ~ estimate
    #   ) 
    # )
  
  abundance = data |> 
  filter(Parameter == "S") %>%
  mutate(
    interval_num = as.numeric(str_extract(Occasion, "\\d+"))
  ) %>%
  arrange(site, interval_num) %>%
  group_by(site) %>%
  mutate(
    estimate = total_release * cumprod(estimate),
    Parameter = "Abundance"
  ) |> 
  mutate(
    Occasion = paste(
      "Occasion", 
      as.numeric(str_extract(Occasion, "\\d+")) + 1
    )
  ) |> 
  ungroup() %>%
  select(-interval_num)
 
  # Create initial occasion abundance rows for each site
  initial_abundance = tibble(
  site = c("snakeden", "glade"),
  Occasion = "Release",
  Parameter = "Abundance",
  estimate = c(
    config$sites$snakeden$initial_release,
    config$sites$glade$initial_release
  )
)


  data = bind_rows(data, abundance, initial_abundance)
return(data)

}

build_base_plot = function(data, global_config, family_config, figure_config = list()){

  #overide family_config with figure specific settings, if provided
  config = modifyList(family_config, figure_config)

  #TODO modify so that names are unique, right now some are being overridden
  #set default save name if one is not provided
  if (is.null(config$save_file_name)) {
    facet_name = if (!is.null(config$facet_vars)) {
      paste(config$facet_vars, collapse = "_")
    } else {
      'no_facet'
    }
    
    config$save_file_name = sprintf(
      '%s_%s_%s.png',
      config$parameter,
      config$y_label,
      facet_name
    )
  }

  #create save directory if needed
  dir_create(config$save_folder)

  #for readability
  cm = global_config$column_mapping

  #set dodge to make sure groups and error bars are on same alignment
  dodge = position_dodge(width=0.9)

  #filter to parameter of interest
  p = data |> 
  filter(.data[[cm$mark_parameter]]  == 
    config$parameter) |> 
  #base plot
  ggplot(
    aes(
      x = factor(
        .data[[config$x_factor]],
        levels = config$x_order
      ), #pull to global or family config?
      y = .data[[config$y_factor]],
      fill = factor(
        .data[[config$grouping]],
        levels = config$grouping_order
      )
    )
  ) +
  geom_col(position = dodge) +
  labs(
    x = config$x_factor_label,
    y = config$y_label,
    fill = config$grouping_label,
    title = config$title,
    subtitle = config$subtitle,
    caption = config$caption
  ) +
  scale_fill_manual(
    values = global_config$palettes[[config$grouping_palette]]
  ) + 
  global_config$theme
  
  # faceting logic
  if (length(config$facet_vars) == 0) {
    #do nothing to alter plot
  } else if
    (length(config$facet_vars) == 1) {
    p = p +
      facet_wrap(vars(.data[[config$facet_vars]]), scales = config$y_axis_scale)
  } else if (length(config$facet_vars) == 2){
    scales_setting = if (config$y_axis_scale == "free_full_y") "free_y" else config$y_axis_scale

    independent_axis = if (config$y_axis_scale == "free_full_y") "y" else "none" 
    p = p +
      facet_grid2(
        rows = vars(.data[[config$facet_vars[1]]]),
        cols = vars(.data[[config$facet_vars[2]]]),
        scales = scales_setting,
        independent = independent_axis
      )
  } else {
    stop(("facet_vars in family config file must have either 1, 2, or 0 variables"))
  }

  # add error bars if config flag is TRUE
  if (config$variance_flag == TRUE) {
    p = p +  
      geom_errorbar(
      aes(ymin = .data[[config$y_variance_lower]], ymax = .data[[config$y_variance_upper]]),
      width = 0.2,
      position = dodge
      ) 
    } else {
  }


  ggsave(
  filename =  config$save_file_name,
  plot = p,
  path = config$save_folder,  
  width = 8,
  height = 5,
  dpi = 300
  )  

  return(p)
}
