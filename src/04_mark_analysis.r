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

  interval_days = config$sites[[site]]$intervals_days
  interval_days = append(interval_days, 1)

  burnham_process = process.data(
    mark_input
    , model = 'Burnham'
    ,time.intervals = interval_days
  )

  burnham_ddl = evalq(make.design.data(burnham_process)
  #parameters=list(pent=pent.0)
  #parameters=list(pent=list(pim.type="time")
  #, N=list(pim.type="constant")
  #), envir = model_env
  )

  # get value of last interval 
  last_occasion = max(as.numeric(as.character(burnham_ddl$r$cohort)))
  
  #Fix last r to zero due to no recapture period after last sampling
  r.last.fixed=list(formula=~1, fixed=list(cohort=c(last_occasion),value=0))

  mark_results = with_dir(
    object_folder,
    mark(burnham_process, ddl = burnham_ddl
      , model.parameters = list(r = r.last.fixed)    
    )
  )
  


  # mark_results = with_dir(object_folder,
  #   mark(mark_input, model = "Burnham", time.intervals = interval_days)
  # )

  return(mark_results)

}