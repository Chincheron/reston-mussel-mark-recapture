library(reticulate)

paths = import("config.paths", convert = TRUE) 

python_scripts = c(
  '00_example.py'
)

for (script in python_scripts) {
  script_path = file.path(paths$SCRIPTS, script)
  message('Running Python script: ', script)
  system2('uv', c('run', 'python', script_path))
}

r_scripts = c(
  '00_example.r'
)

for (script in r_scripts) {
  script_path = file.path(paths$SCRIPTS, script)
  message('Running R Script: ', script)
  source(script_path, local = TRUE)
} 