fit_model_wrapper <- function(opt) {
  
  opt <- create_random_starting_values(opt)
  print_model_summary(opt)
  dt_sub <- get_dt_sub(opt$participant_id)
  
  # allocate output file to combine fits over multiple iterations:
  fit <- data.table()
  fit_data <- data.table()
  
  for (iter in seq(opt$n_iterations)) {
    message(paste("iter:\t", iter, "...", sep = ''))
    # fit model (returns fit and data the fit is based on)
    opt$formula <- "response_time ~ shannon_surprise + trial_ses + block + hand_finger_pressed"
    temp <- fit_model(data = dt_sub, opt = opt)
    temp$fit[, process := "model_fitting"]
    # create new random starting values for the parameter recovery:
    opt <- create_random_starting_values(opt)
    # run parameter recovery:
    opt$formula <- "response_time ~ shannon_surprise"
    recov <- parameter_recovery(fit = temp$fit, data = dt_sub, opt = opt)
    recov$fit[, process := "parameter_recovery"]
    # append results across iterations
    fit <- rbindlist(list(fit, temp$fit, recov$fit))
    fit_data <- rbindlist(list(fit_data, temp$data, recov$fit_data))
    # add iteration identifier to model fit and data:
    fit[, iter := iter]
    fit_data[, iter := iter]
  }
  
  # create output path and directory:
  path_output <- here::here("outputs", "modeling")
  if (!dir.exists(path_output)) dir.create(path_output, recursive = TRUE)
  
  fit_file <- here::here(path_output, paste0(opt$participant_id, "_model-", opt$model, ".csv"))
  data.table::fwrite(fit, file = fit_file, sep = ",", na = "n/a")
  
  fit_data_file <- here::here(path_output, paste0(opt$participant_id, "_model-", opt$model, "_fit-data.csv"))
  data.table::fwrite(fit_data, file = fit_data_file, sep = ",", na = "n/a")
}

parameter_recovery <- function(fit, data, opt) {
  message("running parameter recovery ...")
  # get the best fitting parameters:
  parameters <- fit %>%
    .[variable %in% c("alpha", "gamma"), ] %>%
    .[, by = .(id, variable), .(
      value = as.numeric(unique(value))
    )] %>%
    # check if each parameter per participant only has one value:
    verify(.[, by = .(id, variable), .(num_values = .N)]$num_values == 1) %>%
    .$value
  # run the regression model based on the fitted parameters:
  results <- get_regression_model(parameters = parameters, data = data, opt = opt)
  # get the beta coefficients of the regression model based on fitted parameters:
  coeffs <- coef(results$stat_model)
  # get shannon surprise based on fitted parameters:
  data_res <- get_dt_surprise(data = data, alpha = parameters[[1]], gamma = parameters[[1]])
  # simulate response times based on beta coefficients and shannon surprise:
  data_sub_reconv <- data_res %>%
    .[, response_time := (coeffs["(Intercept)"] + coeffs["shannon_surprise"] * shannon_surprise)]
  recov <- fit_model(data = data_sub_reconv, opt = opt)
  return(recov)
}

fit_model <- function(data, opt) {
  # send status message
  message("running model fitting ...")
  # define fitting parameters:
  opts = list("algorithm" = opt$algorithm, "xtol_rel" = opt$xtol_rel, "maxeval" = opt$maxeval)
  # fit model (minimize the negative log likelihood of the statistical model):
  min <- nloptr::nloptr(x0 = opt$x0, eval_f = get_negative_log_likelihood,
                        lb = opt$lb, ub = opt$ub, opts = opts, data = data, opt = opt)
  parameters <- min$solution
  # run regression model with best fitting parameters:
  results <- get_regression_model(parameters = parameters, data = data, opt = opt)
  # Get parameter names for each model
  if(opt$model == 'sr'){
    parameter_names = c('alpha', 'gamma')
  } else if(opt$model == 'sr_base'){
    parameter_names = c('alpha')
  }
  # construct output for model data:
  # get names of parameters and add identifiers
  prefixes <- c('', 'x0_', 'lb_', 'ub_')
  values <- list(parameters, opt$x0, opt$lb, opt$ub)
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

get_regression_model <- function(parameters, data, opt) {
  # inputs:
  # parameters: list of parameters. the minimization function adjusts x to get lowest negative log likelihood
  # data: behavioral data used for model
  # model: specified model. different models required different list entries in x (e.g., for additional parameters)
  parameters <- check_parameters(parameters = parameters, model = opt$model)
  alpha <- parameters[[1]]
  gamma <- parameters[[2]]
  # get shannon surprise based on successor representation:
  data_res <- get_dt_surprise(data, alpha, gamma)
  # reduce data to main task condition only:
  data_res_main <- get_dt_main(dt_input = data_res)
  # run statistical model:
  stat_model <- get_stat_model(data = data_res_main, formula = opt$formula)
  # add predicted response times based on the stat model:
  data_res_main[, response_time_simulated := fitted(stat_model)]
  # return parameters, data and results of statistical model:
  output <- list(parameters = parameters, data = data_res_main, stat_model = stat_model)
  return(output)
}

get_stat_model <- function(data, formula) {
  stat_model <- glm(formula = as.formula(formula), family = Gamma(link = 'inverse'), data = data)
  return(stat_model)
}

get_negative_log_likelihood <- function(parameters, data, opt) {
  results <- get_regression_model(parameters, data, opt)
  negative_log_likelihood <- -logLik(results$stat_model)
  return(negative_log_likelihood)
}

check_parameters <- function(parameters, model) {
  if(opt$model == 'sr'){
    # Check if parameters fit specified model
    if(length(parameters) != 2){
      stop(paste('Number of parameters does not match specified model "',
                 opt$model,
                 '"',
                 sep = ''))
    } else{
      # Translate parameters for easier coding
      parameters <- list(
        "alpha" = parameters[[1]],
        "gamma" = parameters[[2]]
      )
    }
  } else if (opt$model == 'sr_base') {
    parameters <- list(
      "alpha" = parameters[[1]],
      "gamma" = 0
    )
  }
  return(parameters)
}
