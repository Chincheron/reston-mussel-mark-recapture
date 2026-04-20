# Functions used in 01_data_validation.r

build_occasions_lookup = function(config){

  # Intermediate table of project level sampling info
  occasion_info <- imap_dfr(config$sites, function(site_data, site_key) {
    tibble(
      site_key  = site_key,                          # "snakeden", "glade"
      site_name = site_data$name,                    # "Snakeden Run", "Glade Run"
      occasion  = map_int(site_data$sampling_occasions, "occasion"),
      date      = map_chr(site_data$sampling_occasions, "date") |> as.Date()
    )
  })
  # Lookup sheets/ranges for pulling data
  sheet_ranges = imap_dfr(config$sheet_ranges, function(occasions, site_key){
    bind_rows(occasions) |> 
      mutate(site_key = site_key)
  })
  # Join occasion info and sheet ranges for final lookup table
  occasions = sheet_ranges |> 
    left_join(occasion_info, by = c('site_key', 'occasion'))
}

read_encounter_data = function(occasions_lookup, input_file){
occasions_lookup |> 
  pmap(function(occasion, sheet, range, expected_rows, site_key, site_name, date, ...){
    df = read_excel(input_file, sheet = sheet, range = range, col_types = 'text') |> 
      mutate(
        site = site_key,
        occasion = occasion,
        date = date
      )
    
    # Confirm that the correct number of rows is imported 
    message(glue(" {site_key} | {occasion} | {nrow(df)} rows imported"))
    
    
    if (nrow(df) != expected_rows) {
      warning(glue("  Row count mismatch for {site_name} occasion {occasion}: got {nrow(df)}, expected {expected_rows}"))
    }

    return(df)
  }) |> 
  list_rbind()
  
}

remove_missing_tags = function(df) {

  total_rows = nrow(df)

  df = encounter_data |> 
    filter(!is.na(`Tag Number`))
  # Confirm expected rows
  removed_rows = 13
  expected_rows = total_rows - removed_rows 
    if (nrow(df) != expected_rows) {
      warning(glue("Unexpected Row Count: got {nrow(df)}, expected {expected_rows}"))
    } else {
      total_rows = nrow(df)
      message(glue("Removed {removed_rows} rows. New row count is {total_rows}"))
    }
  
  return(df)

}

remove_tag_duplicates = function(df) {
  total_rows = nrow(df)
  removed_rows = 6
  expected_rows = total_rows - removed_rows 

  df = df |> 
    filter(!(`Tag Number` == 'B013' & occasion == '6' & `Length (mm)` == 92.4)) |> 
    filter(!(`Tag Number` == 'B083' & occasion == '7' & `Length (mm)` == 72.2)) |> 
    filter(!(`Tag Number` == 'B444' & occasion == '5' & `Length (mm)` == 88.8)) |> 
    filter(!(`Tag Number` == 'C167' & occasion == '5' & `Length (mm)` == 109.1)) |>
    #TODO Confirm which C891 tag to remove
    filter(!(`Tag Number` == 'C891' & `Location Found` == 'Riffle 3')) |> 
    filter(!(`Tag Number` == 'O062' & occasion == '6' & `Length (mm)` == 91.5))

  # Confirm correct number of rows
  if (nrow(df) != expected_rows) {
    warning(glue("Unexpected Row Count: got {nrow(df)}, expected {expected_rows}"))
  } else {
    total_rows = nrow(df)
    message(glue("Removed {removed_rows} rows. New row count is {total_rows}"))
  }

  return(df)

}