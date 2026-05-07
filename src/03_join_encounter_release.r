add_columns_to_release = function(df){
  df = df |> 
    mutate(
      Status = "Alive",
      occasion = 0, 
      date = case_when(
        presumed_site == "Glade" ~ as.Date("2023-07-26"),
        presumed_site == "Snakeden" ~ as.Date("2023-07-27")
      )
    )
}

combine_encounter_release = function(encounter_df, release_df){
  combined_data = bind_rows(encounter_df, release_df) |> 
  group_by(`Tag Number`) |> 
  fill(presumed_site, .direction = "downup") |> 
  ungroup()
  
  return(combined_data)
}

check_mismatched_encounter_sites = function(df){
  problem_tags = df |> 
    group_by(`Tag Number`) |> 
    summarise(n_sites = n_distinct(site, na.rm = TRUE)) |> 
    filter(n_sites > 1) |> 
    pull(`Tag Number`)
  different_encounter_sites = df |> 
    filter(`Tag Number` %in% problem_tags) |>
    filter(occasion != 0) |> 
    arrange(`Tag Number`, occasion)
  return(different_encounter_sites)
}

fix_mismatched_encounter_sites = function(df){
  
  # Fix single mismatched site for tags with >2 encounters
  # Define lookup table for corrections
  site_lookup = tribble(
    ~`Tag Number`, ~wrong_site, ~correct_site,
    "B007", "snakeden", "glade",
    "B934", "snakeden", "glade",
    "C062", "glade", "snakeden",
    "C143", "glade", "snakeden",
    "C567", "snakeden", "glade",
    "C906", "snakeden", "glade"
  )
  #Join and correct
  df = df |>
    left_join(site_lookup,
      by = c("Tag Number", "site" = "wrong_site")) |>
    mutate(
      site = coalesce(correct_site, site)
    ) |>
    select(-correct_site)

  # Fix when tag encounter only twice and one is mismatched 
  # (assume presumed site is correct)
  problem_tags = list("B073", "B455", "C240", "C315", "C423", "C607", "C745", 
    "D004", "D005", "D036", "D041")
  df = df |> 
    mutate(
      site = (
        case_when(
          `Tag Number` %in% problem_tags & occasion != 0 ~ presumed_site,
          .default = site
        )
      )
    )
  
  # Remove occurences where tag was encountered 'Dead' on occasion before encountered 'Alive'
  remove_tags = c(
  "B062", "B193", "B357", "B667", "C012", "C293", "C449",
  "C546", "C573", "C588", "C918", "D104", "D393"
  )
  df = df |> 
    filter(
      !(`Tag Number` %in% remove_tags & Status == "Dead")
    )

  # When multiple dead encounters, remove one that does not match presumed site
  df = df |> 
    filter(!(
      (`Tag Number` == "B932" & Status == "Dead" & site == "glade") | 
      (`Tag Number` == "D333" & Status == "Dead" & site == "snakeden")
    )
    )
  
  # Misc. - see docs for details
  df = df |> 
    filter(
      !(`Tag Number` == "D860" | `Tag Number` == "O060")
  )
  
  return(df)
}