library(yaml)
library(purrr)
library(dplyr)
library(here)
library(rprojroot)


load_config = function(){

  root = find_root(has_file("pyproject.toml"))
  config_file = path(root, "config", "config.yaml")
  config = yaml.load_file(config_file)

  # Add intervals_days to each site
  config$sites <- map(config$sites, function(site) {
    dates <- as.Date(map_chr(site$sampling_occasions, "date"))
    site$intervals_days <- as.numeric(diff(dates))
    return(site)
  })

  return(config)
}

