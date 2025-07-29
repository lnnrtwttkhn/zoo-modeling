get_opt_parser <- function() {
  option_list <- list(
    optparse::make_option(c("-p", "--participant_id"),
                          type = "character",
                          default = NULL,
                          help = "ID of participant",
                          metavar = "PARTICIPANT_ID"),
    optparse::make_option(c("-m", "--model"),
                          type = "character",
                          default = NULL,
                          help = "Model to use for fitting, e.g. 'sr'",
                          metavar = "MODEL"),
    optparse::make_option(c("-a", "--algorithm"),
                          type = "character",
                          default = NULL,
                          help = "nloptr algorithm. Example: NLOPT_GN_DIRECT_L",
                          metavar = "ALGORITHM"),
    optparse::make_option(c("-t", "--xtol_rel"),
                          type = "numeric",
                          default = NULL,
                          help = "Int giving tolerance for fitting. Example: 0.00001",
                          metavar = "XTOL_REL"),
    optparse::make_option(c("-e", "--maxeval"),
                          type = "numeric",
                          default = NULL,
                          help = "Maximum number of evaluations before fitting terminates. Example: 1000",
                          metavar = "MAXEVAL"),
    optparse::make_option(c("-r", "--random_starting_values"),
                          type = "logical",
                          default = NULL,
                          help = "If TRUE, random starting values will be used. If FALSE, x0 will be used for starting values",
                          metavar = "RANDOM_STARTING_VALUES"),
    optparse::make_option(c("-x", "--x0"),
                          action = "callback",
                          callback = split_list,
                          type = "character",
                          default = NULL,
                          help = "List of starting values for parameters. Example: 0.1 0.3",
                          metavar = "X0"),
    optparse::make_option(c("-l", "--lb"),
                          action = "callback",
                          callback = split_list,
                          type = "character",
                          default = NULL,
                          help = "List of lower bound values for parameters. Example: 0.1 0.3",
                          metavar = "LB"),
    optparse::make_option(c("-u", "--ub"),
                          action = "callback",
                          callback = split_list,
                          type = "character",
                          default = NULL,
                          help = "List of upper bound values for parameters. Example: 0.1 0.3",
                          metavar = "UB"),
    optparse::make_option(c("-i", "--n_iterations"),
                          type = "numeric",
                          default = NULL,
                          help = "Int giving number of iterations fitting is repeated. Random starting values will be different each iteration",
                          metavar = "N_ITERATIONS")
  )
  # simulate example command-line arguments for testing
  args_example <- c(
    "--participant_id", "sub-01",
    "--model", "sr",
    "--algorithm", "NLOPT_GN_DIRECT_L",
    "--xtol_rel", "0.00001",
    "--maxeval", "10000",
    "--random_starting_values", "TRUE",
    "--x0", "0.5,0.5",
    "--lb", "0.01,0.01",
    "--ub", "1,1",
    "--n_iterations", "3"
  ) 
  # provide options in list to be callable by script:
  parser <- optparse::OptionParser(option_list = option_list)
  # check if there are any command line arguments:
  if (length(commandArgs(trailingOnly = TRUE)) > 0) {
    # parse the CLI arguments
    opt <- optparse::parse_args(parser)
  } else {
    # use the example arguments for testing
    opt <- optparse::parse_args(parser, args = args_example)
  }
  return(opt)
}

split_list <- function(object, flag, value, parser) {
  # function to split list inputs (used as callback function during argument parsing)
  x <- as.numeric(unlist(strsplit(value, ',')))
  return(x)
}

check_opt <- function(opt) {
  # list of required input names
  required_inputs <- c("participant_id", "model", "algorithm", "xtol_rel", 
                       "maxeval", "random_starting_values", "x0", "lb", "ub", "n_iterations")
  # check if all required inputs are present in the parsed options
  missing_inputs <- setdiff(required_inputs, names(opt))
  # if there are any missing inputs, print them out
  if (length(missing_inputs) > 0) {
    message("error: missing required inputs:\n")
    message(paste(missing_inputs, collapse = "\n"), "\n")
  } else {
    message("all required inputs are present.\n")
  }
  
  # modify input values depending on the model:
  if(opt$model == 'sr' || opt$model == 'sr_onestep'){
  } else if(opt$model == 'sr_base'){
    opt$x0 <- opt$x0[[1]]
    opt$lb <- opt$lb[[1]]
    opt$ub <- opt$ub[[1]]
  }
  
  # basic checks: check if x0, lb, and ub have the same number of parameters
  x0 <- as.numeric(opt$x0)
  lb <- as.numeric(opt$lb)
  ub <- as.numeric(opt$ub)
  
  if (!(length(x0) == length(lb) &
        length(x0) == length(ub) &
        length(lb) == length(ub))) {
    stop("number of parameters differs between x0, lb, or ub")
  }
  return(opt)
}

create_random_starting_values <- function(opt) {
  # check if random_starting_values is TRUE
  if (opt$random_starting_values) {
    # initialize an empty vector for x0
    opt$x0 <- c()
    # for each parameter, create a random value between the respective bounds
    for (count in seq_along(opt$lb)) {
      rand_val <- round(runif(1, opt$lb[count], opt$ub[count]), 2)  # random value rounded to 2 decimal places
      opt$x0 <- c(opt$x0, rand_val)  # append the random value to x0
    }
  }
  return(opt)
}

print_model_summary <- function(opt) {
  message('#####')
  message(sprintf('Starting model fitting for %s ...', opt$participant_id))
  message('#####')
  message(sprintf('   random_starting_values: %s', opt$random_starting_values))
  message(sprintf('   n_iterations: %d', opt$n_iterations))
  message('- - - - - - - - - - - - -')
  message(sprintf('   model: %s', opt$model))
  message(sprintf('   algorithm: %s', opt$algorithm))
  message(sprintf('   xtol_rel: %.2e', opt$xtol_rel))
  message(sprintf('   maxeval: %d', opt$maxeval))
  message(sprintf('   x0: %s', paste(round(opt$x0, 2), collapse = '\t')))
  message(sprintf('   lb: %s', paste(round(opt$lb, 2), collapse = '\t')))
  message(sprintf('   ub: %s', paste(round(opt$ub, 2), collapse = '\t')))
  message('- - - - - - - - - - - - -')
}
