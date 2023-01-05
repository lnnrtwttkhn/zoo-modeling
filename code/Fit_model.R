if (!requireNamespace("pacman")) install.packages("pacman")
packages_cran = c("here", "data.table", "magrittr", "assertr",
                  "dplyr", "tidyr", "gtools", "lme4", "ggplot2")
pacman::p_load(char = packages_cran)
paths_figures = here::here("outputs/figures")
dir.create(paths_figures, recursive = TRUE)

Fit_model = function(data,
                     algorithm,
                     xtol_rel,
                     maxeval,
                     x0,
                     lb,
                     ub){
  
  # Source own functions
  source_path = file.path(here::here(), 'code',
                          fsep = .Platform$file.sep)
  source(file.path(source_path, 'LL_reg.R',
                   fsep = .Platform$file.sep))
  source(file.path(source_path, 'Reg_model.R',
                   fsep = .Platform$file.sep))
  
  # Placeholder variables (will be passed to function)
  data = data.table::fread(Sys.glob(here::here("inputs", "*.csv"))) %>%
    .[id == 'sub-01']
  algorithm = 'NLOPT_GN_DIRECT_L'
  xtol_rel = 1.0e-5
  maxeval = 10
  x0 = c(0.1,
            0.3)
  lb = c(0.01,
            0.01)
  ub = c(1,
            1)
  model = 'sr'

  # Define fitting parameters
  opts = list('algorithm' = algorithm,
               'xtol_rel' = xtol_rel,
               'maxeval'= maxeval)
  
  # Fit model (minimize LL of statistical model)
  cmod = nloptr::nloptr(x0 = x0,
                        eval_f = LL_reg,
                        lb = lb,
                        ub = ub,
                        opts = opts,
                        data = data,
                        model = model)
  
  # Run reg model with output coeffs (minimized LL)
  
  
  
}