if (!requireNamespace("pacman")) install.packages("pacman")
packages_cran = c("here", "data.table", "magrittr", "assertr",
                  "dplyr", "tidyr", "gtools", "lme4", "ggplot2")
pacman::p_load(char = packages_cran)

Fit_model = function(data,
                     model,
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
  
  # Get parameter names for each model
  if(model == 'sr'){
    parameter_names = c('alpha', 'gamma')
  } else if(model == 'sr_base'){
    parameter_names = c('alpha')
  }
  
  # Define fitting parameters
  opts = list('algorithm' = algorithm,
              'xtol_rel' = xtol_rel,
              'maxeval'= maxeval)
  
  # Fit model (minimize LL of statistical model)
  min = nloptr::nloptr(x0 = x0,
                       eval_f = LL_reg,
                       lb = lb,
                       ub = ub,
                       opts = opts,
                       data = data,
                       model = model)
  
  # Run reg model with best fitting parameters (minimized LL)
  res = Reg_model(x = min$solution,
                  data = data,
                  model = model)
  
  # Construct output
  # Model data
  # Get names of parameters and add identifiers for starting values, lower-, and upper bound
  parameter_names_x0 = paste('x0_', parameter_names, sep = '')
  parameter_val_x0 = x0
  parameter_names_lb = paste('lb_', parameter_names, sep = '')
  parameter_val_lb = lb
  parameter_names_ub = paste('ub_', parameter_names, sep = '')
  parameter_val_ub = ub
  parameter_names = c(parameter_names,
                      parameter_names_x0,
                      parameter_names_lb,
                      parameter_names_ub)
  # Gather values in same format as names
  parameter_vals = c(min$solution,
                     x0,
                     lb,
                     ub)
  # Fuse names and values of modelling
  out_model = data.table::data.table(cbind(parameter_names,
                                           parameter_vals))
  colnames(out_model) = c('variable', 'value')
  out_model$mod = 'model'
  out_model$aic = AIC(res)
  out_model$bic = BIC(res)
  # Regression data
  # Get names of regressors (remove brackets from names and add prefix)
  reg_names = names(res$stat_model$coefficients)
  reg_names = gsub('[()]', '', reg_names)
  reg_names_beta = paste('beta_', reg_names, sep = '')
  # Get beta values
  reg_beta = res$stat_model$coefficients
  # Add regressor-specific p-values 
  reg_names_p = paste('p_', reg_names, sep = '')
  reg_p = summary(res$stat_model)$coefficients[,4]
  reg_names = c(reg_names_beta, reg_names_p)
  reg_vals = c(reg_beta, reg_p)
  # Fuse names and values of regression model
  out_reg = data.table::data.table(cbind(reg_names,
                                         reg_vals))
  colnames(out_reg) = c('variable', 'value')
  out_reg$mod = 'reg_model'
  
  # Combine to output file
  fit = rbind(out_model, out_reg)
  # Add identifiers to output file
  fit$id = unique(data$id)
  fit$order = unique(data$order)
  fit$neg_ll = min$objective
  fit$nloptr_status = min$status
  fit$nloptr_message = min$message
  # Sort columns
  data.table::setcolorder(fit, neworder = c('id',
                                            'order',
                                            'nloptr_status',
                                            'nloptr_message',
                                            'neg_ll',
                                            'mod',
                                            'variable',
                                            'value',
                                            'aic',
                                            'bic'))
  
  # Return modeling results
  return(list(fit = fit,
              data = res$data))
  
  
}