library(reticulate)

# -----------------------------------------------------------------------------
# Pull path constants
# -----------------------------------------------------------------------------

paths = import("config.paths", convert = TRUE) 

print(paste0('Project Root: ', paths$ROOT))

# -----------------------------------------------------------------------------
# Import config.yaml
# -----------------------------------------------------------------------------

library(yaml)

config_file = as.character(paths$CONFIG / 'config.yaml')
config = yaml.load_file(config_file)

sampling_dates = config$sites$snakeden$sampling_occasions
