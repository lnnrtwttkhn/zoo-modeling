fit_model_wrapper <- function(opt) {
  
  x0 <- create_random_starting_values(opt)
  print_model_summary(opt, x0)
  dt_sub <- get_dt_sub(opt$participant_id)
  
  # allocate output file to combine fits over multiple iterations:
  fit <- data.table()
  fit_data <- data.table()
  
  for (iter in seq(opt$n_iterations)) {
    message(paste("iter:\t", iter, "...", sep = ''))
    # fit model (returns fit and data the fit is based on)
    temp <- fit_model(dt_sub, opt, x0)
    # add iteration identifier to model fit and data:
    temp$fit[, iter := iter]
    temp$data[, iter := iter]
    # append results across iterations
    fit <- rbindlist(list(fit, temp$fit))
    fit_data <- rbindlist(list(fit_data, temp$data))
  }
  
  # create output path and directory:
  path_output <- here::here("outputs", "modeling")
  if (!dir.exists(path_output)) dir.create(path_output, recursive = TRUE)
  
  fit_file <- here::here(path_output, paste0(opt$participant_id, "_model-", opt$model, ".csv"))
  data.table::fwrite(fit, file = fit_file, sep = ",", na = "n/a")
  
  fit_data_file <- here::here(path_output, paste0(opt$participant_id, "_model-", opt$model, "_fit-data.csv"))
  data.table::fwrite(fit_data, file = fit_data_file, sep = ",", na = "n/a")
}

fit_model <- function(data, opt, x0) {
  # define fitting parameters:
  opts = list("algorithm" = opt$algorithm, "xtol_rel" = opt$xtol_rel, "maxeval" = opt$maxeval)
  # fit model (minimize the negative log likelihood of the statistical model):
  min <- nloptr::nloptr(x0 = x0, eval_f = get_negative_log_likelihood,
                        lb = opt$lb, ub = opt$ub, opts = opts, data = data, model = opt$model)
  # run regression model with best fitting parameters:
  results <- get_regression_model(parameters = min$solution, data = data, model = opt$model)

  # Get parameter names for each model
  if(opt$model == 'sr'){
    parameter_names = c('alpha', 'gamma')
  } else if(opt$model == 'sr_base'){
    parameter_names = c('alpha')
  }
  
  # construct output for model data:
  # get names of parameters and add identifiers
  prefixes <- c('', 'x0_', 'lb_', 'ub_')
  values <- list(min$solution, opt$x0, opt$lb, opt$ub)
  parameter_names <- unlist(lapply(prefixes, function(prefix) paste(prefix, parameter_names, sep = '')))
  parameter_vals <- unlist(values)
  out_model <- data.table(variable = parameter_names, value = parameter_vals)
  out_model[, mod := 'model']
  
  # construct output for regression data:
  
  # clean and prefix regressor names:
  reg_names <- gsub('[()]', '', names(results$stat_model$coefficients))
  reg_names_beta <- paste('beta_', reg_names, sep = '')
  reg_names_p <- paste('p_', reg_names, sep = '')
  reg_names_model_comp <- c('aic', 'bic')
  
  # get regression values:
  reg_beta <- results$stat_model$coefficients
  reg_p <- summary(results$stat_model)$coefficients[, 4]
  reg_aic <- AIC(results$stat_model)
  reg_bic <- BIC(results$stat_model)
  
  reg_names <- c(reg_names_beta, reg_names_p, reg_names_model_comp)
  reg_values <- c(reg_beta, reg_p, reg_aic, reg_bic)
  out_reg <- data.table(variable = reg_names, value = reg_values)
  out_reg[, mod := 'reg_model']
  
  # combine model and regression outputs into a single data table:
  dt_fit <- rbindlist(list(out_model, out_reg), use.names = TRUE, fill = TRUE)
  # add identifiers and metadata to the combined output:
  dt_fit[, `:=`(
    id = unique(data$id),
    order = unique(data$order),
    neg_ll = min$objective,
    nloptr_status = min$status,
    nloptr_message = min$message
  )]
  # sort columns:
  column_order <- c("id", "order", "nloptr_status", "nloptr_message", "neg_ll", "mod", "variable", "value")
  setcolorder(dt_fit, neworder = column_order)
  output <- list(fit = dt_fit, data = results$data)
  return(output)
}

get_regression_model <- function(parameters, data, model) {
  # inputs:
  # parameters: list of parameters. the minimization function adjusts x to get lowest negative log likelihood
  # data: behavioral data used for model
  # model: specified model. different models required different list entries in x (e.g., for additional parameters)
  alpha <- parameters[[1]]
  gamma <- alpha <- parameters[[2]]
  data_res <- get_dt_surprise(data, alpha, gamma)
  data_res_main <- get_dt_main(dt_input = data_res)
  stat_model <- get_stat_model(data = data_res_main)
  output <- list(parameters = parameters, data = data, stat_model = stat_model)
  return(output)
}

get_stat_model <- function(data) {
  formula <- "response_time ~ shannon_surprise + trial_ses + block + hand_finger_pressed"
  stat_model <- glm(formula = as.formula(formula), family = Gamma(link = 'inverse'), data = data)
  return(stat_model)
}

get_negative_log_likelihood <- function(parameters, data, model) {
  results <- get_regression_model(parameters, data, model)
  negative_log_likelihood <- -logLik(results$stat_model)
  return(negative_log_likelihood)
}
