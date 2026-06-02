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

  top_model_name = paste0("S.", s_model, ".p.", p_model, ".r.", r_model)
  

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

# # add initial release numbers of uniquely tagged individuals
# #number of mussels released by species
# release_summary_path = path(global_paths$DATA_RAW, 'release_summary.xlsx')
# release_summary = read_excel(release_summary_path) |> 
#   select(species, facility, total_release, total_unique_tag)
# data = data |>
#   left_join(
#     release_summary |> 
#       rename(total_unique_tag_release = total_unique_tag),
#     by = c('facility', 'species')
#   ) |> 
#   mutate(
#     perc_of_initial = case_when(
#       Parameter == "N_derived" ~ estimate / total_unique_tag_release
#     ),
#     perc_of_initial_lcl = case_when(
#       Parameter == "N_derived" ~ lcl / total_unique_tag_release
#     ),
#     perc_of_initial_ucl = case_when(
#       Parameter == "N_derived" ~ ucl / total_unique_tag_release
#     )
#   )

# convert monthly survival to annual survival
data = data |> 
  mutate(
    estimate = case_when(
      Parameter == 'S' ~ estimate^12,
      .default = estimate
    ),
    s_lcl = case_when(
      Parameter == 'Phi' ~ lcl^12,
      .default = lcl
    ),
    s_ucl = case_when(
      Parameter == 'Phi' ~ ucl^12,
      .default = ucl
    )
  )

return(data)

}
