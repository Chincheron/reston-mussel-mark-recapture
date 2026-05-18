library(yaml)
library(purrr)
library(dplyr)
library(here)


load_config = function(){

  #config_file = as.character(global_paths$CONFIG / 'config.yaml')
  config_file = path(here(), "config", "config.yaml")
  config = yaml.load_file(config_file)

  config$sites$snakeden$sampling_occasions

  return(config)
}

