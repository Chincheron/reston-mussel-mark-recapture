remove_exact_duplicates = function(df){
  total_rows = nrow(df)
  removed_rows = 2
  expected_rows = total_rows - removed_rows 

  df = df |> 
    distinct()
    
  # Confirm correct number of rows
  if (nrow(df) != expected_rows) {
    warning(glue("Unexpected Row Count: got {nrow(df)}, expected {expected_rows}"))
  } else {
    total_rows = nrow(df)
    message(glue("Removed {removed_rows} rows. New row count is {total_rows}"))
  }

  return(df)


} 