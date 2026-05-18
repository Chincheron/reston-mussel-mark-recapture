library(yaml)
library(purrr)
library(dplyr)
library(here)


load_config = function(){

  config_file = path(here(), "config", "config.yaml")
  config = yaml.load_file(config_file)

  # Add intervals_days to each site
  config$sites <- map(config$sites, function(site) {
    dates <- as.Date(map_chr(site$sampling_occasions, "date"))
    site$intervals_days <- as.numeric(diff(dates))
    return(site)
  })

  return(config)
}

