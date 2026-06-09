library(withr)

run_burnham_model = function(input, object_folder, config){
  
  dir_create(object_folder)

  interval_days = 

  with_dir(object_folder,
    mark(snakeden_input, model = "Burnham")
  )


}

run_burnham_model_2 = function(site, mark_input, object_folder, model_def, config){

  # Filter to site:
  mark_input = mark_input |> 
    filter(presumed_site == site)

  # Create folder for mark_output
  object_folder = path(object_folder, paste0(site, "_outputs"))
  dir_create(object_folder)

  # Create folder for results Output
  results_folder = path(object_folder, site)

  interval_days = config$sites[[site]]$intervals_days
  interval_days = append(interval_days, 1)

  # issues with convergence for S(t) models
  # Likely caused by daily survival rates being close to 1
  # Rescale to monthly
  interval_monthly = interval_days / 30.44 

  burnham_process = process.data(
    mark_input
    , model = 'Burnham'
    ,time.intervals = interval_monthly
  )

  burnham_ddl = evalq(make.design.data(burnham_process)
  #parameters=list(pent=pent.0)
  #parameters=list(pent=list(pim.type="time")
  #, N=list(pim.type="constant")
  #), envir = model_env
  )

  #burnham_ddl$S$S_group=0
  #burnham_ddl$S$S_group[burnham_ddl$S$time==1] = 1
  interval_bins = c(0, 12, 16, 24, 27, 30)
  occasion_bins = c(0, 24, 30)
  burnham_ddl = add.design.data(burnham_process, burnham_ddl, 
    parameter = "S", type = "time", bins = interval_bins , name = "year"
  )
  burnham_ddl = add.design.data(burnham_process, burnham_ddl, 
    parameter = "r", type = "time", bins = interval_bins, name = "year"
  )
  burnham_ddl = add.design.data(burnham_process, burnham_ddl, 
    parameter = "p", type = "time", bins = occasion_bins, name = "year"
  )


  # get value of last interval 
  last_occasion = max(as.numeric(as.character(burnham_ddl$r$cohort)))
  
  # #Fix last r to zero due to no recapture period after last sampling
  # r.last.fixed=list(formula=~1, fixed=list(cohort=c(last_occasion),value=0))

  # #Fix all fidelity to 1 because dead and live recoveries are in same sampling area
  # f.fixed = list(formula=~1, fixed = 1)

  # Update definitions for all r parameters so that last occasion is fixed to to 0
  r_models = startsWith(names(model_def), "r.")
  model_def[r_models] = lapply(
    model_def[r_models], 
    function(x)
    append(
      x,
      list(
        fixed=list(
          cohort=c(last_occasion),
          value=0
        )
      ) 
    )
  )

  # Must create a environment then inject parameter definitions and assign other variables to be used (e.g. fixing pent to 0)
  model_env = new.env(parent=environment())
  list2env(model_def, envir = model_env)

  # Create model list
  model_list = evalq(create.model.list("Burnham"), model_env)
  print(model_list)

  mark_results = evalq(
    with_dir(
      object_folder,
      mark.wrapper(
        model_list, data=burnham_process, ddl = burnham_ddl
      )
    )
    , envir =  model_env
  )
  


  # mark_results = with_dir(object_folder,
  #   mark(mark_input, model = "Burnham", time.intervals = interval_days)
  # )

  # export for easier exploration of results
  with_dir(object_folder, {
        export.MARK(burnham_process, site,  mark_results, replace = TRUE
      )
      })

  return(mark_results)

}