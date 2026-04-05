library(reticulate)

# -----------------------------------------------------------------------------
# Pull path constants
# -----------------------------------------------------------------------------

paths = import("config.paths", convert = TRUE) 

print(paste0('Project Root: ', paths$ROOT))

