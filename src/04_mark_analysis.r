library(withr)

run_burnham_model = function(input, object_folder, config){
  
  dir_create(object_folder)

  interval_days = 

  with_dir(object_folder,
    mark(snakeden_input, model = "Burnham")
  )


}

run_burnham_model_2 = function(site, mark_input, object_folder, config){

  # Filter to site:
  mark_input = mark_input |> 
    filter(presumed_site == site)

  # Create folder for mark_output
  object_folder = path(object_folder, paste0(site, "_outputs"))
  dir_create(object_folder)

  interval_days = config$sites[[site]]

  mark_results = with_dir(object_folder,
    mark(mark_input, model = "Burnham")
  )

  return(mark_results)

}