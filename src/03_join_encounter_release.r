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

check_presumed_site = function(df){
  df = df |> 
  mutate(
    presume_match = case_when(
      str_to_lower(presumed_site) == str_to_lower(site) ~ TRUE,
      .default = FALSE
    ) 
  ) |> 
  filter(presume_match == FALSE 
    & occasion != 0 
    & !str_starts(`Tag Number`, "O")
    & !(`Tag Number` %in% c("?800", "B44-", "B90-", "B98-", "D03-")) 
    )
  
  return(df)

}

fix_presumed_sites = function(df){
  df = df |> 
  mutate(
    presumed_site = case_when(
      `Tag Number` %in% presume_site_no_match$`Tag Number` &
        !is.na(site)~ site,
      .default = presumed_site
    )  
  ) |> 
  group_by(`Tag Number`) |> 
  mutate(
    presumed_site = first(na.omit(site))
  ) |> 
  ungroup()
  

  return(df)
}

check_multiple_encounters_per_occasion = function(df){
  multiple_encounters_per_occasion = df |> 
    count(`Tag Number`, occasion) |> 
    filter(n>1) |> 
    select(`Tag Number`, occasion)
  duplicate_rows = df |> 
    semi_join(
      multiple_encounters_per_occasion,
      by = c("Tag Number", "occasion")
    )

  return(duplicate_rows)
}

fix_multiple_encounters = function(df){
  rows_to_remove = tibble(
    `Tag Number` = c("C062", "D004", "D005", "O034"),
    `Length (mm)` = c(98.8, 87.5, 65.1, 93.4)
  )
  df = df |> 
    anti_join(
      rows_to_remove,
      by = c("Tag Number", "Length (mm)")
    )
    
}

remove_never_released = function(df){
  remove_list = c(
    "B98-",
    "D03-",
    "O015",
    "O016",
    "O031",
    "O033",
    "C248",
    "O057",
    "D863",
    "B530",
    "D927"
  )

  df = df |> 
    filter(
      !(`Tag Number` %in% remove_list)
    )
  
  return(df)

}

create_ch_col = function(df){
  encounter_cols = c(
    'occasion_0',
    'occasion_1',
    'occasion_2',
    'occasion_3',
    'occasion_4',
    'occasion_5',
    'occasion_6',
    'occasion_7',
    'occasion_8'
  )

  status_cols = c(
    'occasion_1_status',
    'occasion_2_status',
    'occasion_3_status',
    'occasion_4_status',
    'occasion_5_status',
    'occasion_6_status',
    'occasion_7_status',
    'occasion_8_status'
  )

  # Create live encounter ch
  # if occasion_x = 1 and occasion_x_status = 'Alive', then '1', else 0
  live_mat = map2(
    encounter_cols[-1], # -1 is to remove occasion_0 to get matching pair lengths
    status_cols,
    function(encounter, status){
      if_else(
        df[[encounter]] == 1 &
          df[[status]] == "Alive" &
          !is.na(df[[status]]),
        "1",
        "0"
      )
    }
  ) |> 
    do.call(cbind, args = _)

  df = df |> 
    mutate(
      live_ch = paste0(
        occasion_0,
        apply(live_mat, 1, paste0, collapse = "")
      )
    )

  #df$live_ch = apply(capture_history[encounter_cols], 1, paste0, collapse = "" )

  #create dead encounter ch:
  # if occasion_x_status = 'Alive', then interval x = '0', if 'Dead', then '1'
  df = df |> 
    mutate(
      dead_ch = apply(
        pick(all_of(status_cols)),
        1,
        function(x) paste0(
          case_when(
            x == "Dead" ~ "1",
            x == "Alive" ~ "0",
            .default = "0"
          ),
          collapse = ""
        )
      ),
      dead_ch = paste0(dead_ch, "0")
    )
     
  #combine both value alternatingly
  df = df |> 
    mutate(
      ch = map2_chr(
        live_ch, dead_ch, function(live, dead) {
          paste0(
            c(rbind(
              strsplit(live, "")[[1]],
              strsplit(dead, "")[[1]]
            )),
            collapse = ""
          )
        })
    )
  
  return(df)

}

create_capture_history_table = function(df){
  df = df |> 
    mutate(value = 1) |> 
    select(`Tag Number`, presumed_site, occasion, value, Status) |> 
    distinct() |> 
    pivot_wider(
      names_from = occasion,
      values_from = c(value, Status),
      names_glue = "occasion_{occasion}{ifelse(.value == 'Status', '_status', '')}",
      values_fill = list(value = 0)
    )
  
  df = create_ch_col(df)
  return(df)

}


create_ch_qc_cols = function(df){
  df = df |> 
    mutate(
      dead_intervals = sapply(
        gregexpr("1", dead_ch),
        \(x) paste(x[x > 0], collapse = ",")
      )
    ) |> 
    mutate(
      more_than_one_dead = if_else(
        nchar(dead_intervals) > 1, TRUE, FALSE 
      )
    ) |> 
    mutate(
      live_intervals = sapply(
        gregexpr("1", live_ch),
        \(x) paste(x[x > 0], collapse = ",")
      )
    )
  return(df)

}

fix_multiple_dead_occurences = function(df){
  status_cols = c(
    'occasion_1_status',
    'occasion_2_status',
    'occasion_3_status',
    'occasion_4_status',
    'occasion_5_status',
    'occasion_6_status',
    'occasion_7_status',
    'occasion_8_status'
  )

  df = df |> 
    mutate(position_first_dead = str_sub(dead_intervals, 1, 1)) |> 
    mutate(
      across(status_cols, 
        function(x){
          if_else(
            nchar(dead_intervals)>1 &
            str_extract(cur_column(), "(?<=_)\\d+(?=_)") > position_first_dead &
              x == "Dead",
            NA,
            x
          )
        }
      )
    )
  
  return(df)

}