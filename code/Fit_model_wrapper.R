Fit_model_wrapper = function(participant_id,
                             model,
                             algorithm,
                             xtol_rel,
                             maxeval,
                             random_starting_values,
                             x0,
                             lb,
                             ub,
                             n_iterations){
  
  # # Examples for inputs
  # participant_id = 'sub-01'
  # model = 'sr'
  # algorithm = 'NLOPT_GN_DIRECT_L'
  # xtol_rel = 1.0e-5
  # maxeval = 10
  # random_starting_values = TRUE
  # x0 = c(0.1,
  #        0.3)
  # lb = c(0.01,
  #        0.01)
  # ub = c(1,
  #        1)
  # n_iterations = 3
  
  # Basic checks
  # Same number of parameters in all specifying inputs?
  if(!(length(x0) == length(lb) &
       length(x0) == length(ub) &
       length(lb) == length(ub))){
    stop('Number of parameters differs between x0, lb, or ub')
  }
  
  # If specified: set random starting values between bounds
  if(random_starting_values){
    # Empty specified starting values
    x0 = c()
    # For each parameter create random value between respective bounds
    for(count in seq(length(lb))){
      rand_val = round(runif(1, lb[count], ub[count]), 2)
      x0 = c(x0, rand_val)
    }
  }
 
  # Source own functions
  source_path = file.path(here::here(), 'code',
                          fsep = .Platform$file.sep)
  source(file.path(source_path, 'Fit_model.R',
                   fsep = .Platform$file.sep))
  
  # Give message to user:
  message('#####')
  message(paste('Starting model fitting for\t', participant_id, '...', sep = ''))
  message('#####')
  message(paste('   random_starting_values:\t', random_starting_values, sep = ''))
  message(paste('   n_iterations:\t\t', n_iterations, sep = ''))
  message('- - - - - - - - - - - - -')
  message(paste('   model:\t', model, sep = ''))
  message(paste('   algorithm:\t', algorithm, sep = ''))
  message(paste('   xtol_rel:\t', xtol_rel, sep = ''))
  message(paste('   maxeval:\t', maxeval, sep = ''))
  message(paste('   x0:\t\t', paste(x0, collapse = '\t'), sep = ''))
  message(paste('   lb:\t\t', paste(lb, collapse = '\t'), sep = ''))
  message(paste('   ub:\t\t', paste(ub, collapse = '\t'), sep = ''))
  message('- - - - - - - - - - - - -')
  
  
  # Load behav data
  data = data.table::fread(Sys.glob(here::here("inputs", "*.csv"))) %>%
    .[id == participant_id,]
  
  # Allocate output file to combine fits over multiple iterations
  out = data.table::data.table()
  
  # Repeat fitting as often as specified
  for(iter in seq(n_iterations)){
    
    # Give message to user
    message(paste('iter:\t', iter, '...', sep = ''))
    
    # Fit model
    temp = Fit_model(data = data,
                     model = model,
                     algorithm = algorithm,
                     xtol_rel = xtol_rel,
                     maxeval = maxeval,
                     x0 = x0,
                     lb = lb,
                     ub = ub)
    
    # Add iteration identifier to results
    temp$iter = iter
    
    # Append results across iterations
    out = rbind(out, temp)
  }
  
  
  # Export data
  save_dir = file.path(here::here(), 'outputs', 'modeling',
                       fsep = .Platform$file.sep)
  # Create save folder if it does not exist already
  if(!dir.exists(save_dir)){
    dir.create(save_dir, recursive = TRUE)
  }
  # Construct file name and combine with target directory
  file_name = paste(participant_id, '_model-', model, '.csv',
                    sep = '')
  file = file.path(save_dir, file_name,
                   fsep = .Platform$file.sep)
  # Save output
  data.table::fwrite(x = out,
                     file = file,
                     sep = ',',
                     na = 'n/a')
}

# Function to split list inputs (used as callback function during argument parsing)
split_list = function(object,
                      flag,
                      value,
                      parser){
  x = as.numeric(unlist(strsplit(value, ',')))
  return(x)
}

# Create options to pass to script
option_list = list(
 optparse::make_option(c('-p', '--participant_id'),
              type='character',
              default = NULL,
              help = 'ID of participant',
              metavar = 'PARTICIPANT_ID'),
  optparse::make_option(c('-m', '--model'),
              type='character',
              default = NULL,
              help = 'model to use for fitting, e.g. "sr',
              metavar = 'MODEL'),
  optparse::make_option(c('-a', '--algorithm'),
              type='character',
              default = NULL,
              help = 'nloptr algorithm. Example: NLOPT_GN_DIRECT_L',
              metavar = 'ALGORITHM'),
  optparse::make_option(c('-t', '--xtol_rel'),
              type='numeric',
              default = NULL,
              help = 'Int giving tolerance for fitting. Example: 0.00001',
              metavar = 'XTOL_REL'),
  optparse::make_option(c('-e', '--maxeval'),
              type='numeric',
              default = NULL,
              help = 'Maximum number of evaluations before fitting terminates. Example: 1000',
              metavar = 'MAXEVAL'),
  optparse::make_option(c('-r', '--random_starting_values'),
              type='logical',
              default = NULL,
              help = 'If TRUE, random starting values will be used. If FALSE, x0 will be used for starting values',
              metavar = 'RANDOM_STARTING_VALUES'),
  optparse::make_option(c('-x', '--x0'),
              action = 'callback',
              callback = split_list,
              type='character',
              default = NULL,
              help = 'List of starting values for parameters. Example: 0.1 0.3',
              metavar = 'X0'),
  optparse::make_option(c('-l', '--lb'),
              action = 'callback',
              callback = split_list,
              type='character',
              default = NULL,
              help = 'List of lower bound values for parameters. Example: 0.1 0.3',
              metavar = 'LB'),
  optparse::make_option(c('-u', '--ub'),
              action = 'callback',
              callback = split_list,
              type='character',
              default = NULL,
              help = 'List of upper bound values for parameters. Example: 0.1 0.3',
              metavar = 'UB'),
  optparse::make_option(c('-i', '--n_iterations'),
              type='numeric',
              default = NULL,
              help = 'Int giving number of iterations fitting is repeated. Random starting values will be different each iteration',
              metavar = 'N_ITERATIONS'))

# provide options in list to be callable by script
opt_parser = optparse::OptionParser(option_list = option_list)
opt = optparse::parse_args(opt_parser)


# Call wrapper with command line inputs
Fit_model_wrapper(participant_id = opt$participant_id,
                  model = opt$model,
                  algorithm = opt$algorithm,
                  xtol_rel = opt$xtol_rel,
                  maxeval = opt$maxeval,
                  random_starting_values = opt$random_starting_values,
                  x0 = opt$x0,
                  lb = opt$lb,
                  ub = opt$ub,
                  n_iterations = opt$n_iterations)

# Example command:
# Rscript Fit_model_wrapper.R --participant_id 'sub-02' --model 'sr' --algorithm 'NLOPT_GN_DIRECT_L' --xtol_rel 0.00001 --maxeval 1000 --random_starting_values 'TRUE' --x0 0.5,0.5 --lb 0.01,0.01 --ub 1,1 --n_iterations 3

