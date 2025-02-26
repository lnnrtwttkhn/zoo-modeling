get_dt_sub <- function(participant_id) {
  # load behavioral data:
  dt_sub <- data.table::fread(Sys.glob(here::here("inputs", "*.csv"))) %>%
    # select data of the current participant:
    .[id == participant_id,] %>%
    # get trial counter within each participant and session:
    .[, trial_ses := seq(.N), by = .(id, session)] %>%
    # skip first trial of each run (because there is no transition happening):
    .[trial_run > 1, ] %>%
    # add node transition as column:
    .[, transition := paste(node_previous, node, sep = "-")]
 return(dt_sub) 
}

get_dt_main <- function(dt_input) {
  num_runs <- 5
  num_trials_run <- 240
  dt_output <- dt_input %>%
    .[condition == "main", ] %>%
    .[, log_response_time := log(response_time)] %>%
    .[, halfrun := ifelse(trial_run <= num_trials_run / 2, "first", "second")] %>%
    .[, block := as.numeric(factor(paste(run, halfrun, sep = '_')))] %>%
    .[, trial_block := seq(.N), by = .(id, block)] %>%
    .[, graphblock := ifelse(block %in% seq(1, 5), "first graph", "second graph")] %>%
    .[, hand_finger_pressed := paste(hand_pressed, finger_pressed, sep = '_')] %>%
    verify(block %in% seq(1, num_runs * 2)) %>%
    .[accuracy == 1, ] %>%
    # remove data where shannon surprise is NA, NaN, Inf or -Inf:
    .[is.finite(shannon_surprise), ]
  return(dt_output)
}

get_dt_surprise <- function(data, alpha, gamma) {
  dt_surprise <- data %>%
    .[, by = .(id), shannon_surprise := get_successor_representation(
      node_previous = node_previous, node = node, alpha = alpha, gamma = gamma)]
  return(dt_surprise)
}


get_successor_representation <- function(node_previous, node, alpha, gamma){
  num_nodes <- 6
  node_letters = LETTERS[1:num_nodes]
  num_transitions = length(node_previous)
  counter = num_transitions - 1
  # pre-allocate an empty vector to hold the bits:
  bits = rep(NA, counter)
  # pre-allocate the successor matrix with baseline expectation
  # baseline expectation could also be zero
  expectation = 1 / num_nodes ^ 2
  sr = matrix(expectation, num_nodes, num_nodes)
  # add letters to the successor matrix:
  colnames(sr) = rownames(sr) = LETTERS[1:6]
  
  # loop through all trials (transitions):
  for (i in 2:(counter + 1)) {
    
    # determine the previous node and the current node:
    node_x = which(node_previous[i] == node_letters)
    node_y = which(node[i] == node_letters)
    
    # normalize the successor matrix to express it in probabilities:
    sr_norm = sr / matrix(rowSums(sr), num_nodes, num_nodes)
    probability = sr_norm[node_x, node_y]
    bits[i - 1] = calc_bits(probability = probability)
    
    # update the successor representation:
    occupancy = rep(0, num_nodes)
    occupancy[node_y] = 1
    sr[node_x,] = sr[node_x,] + alpha * (occupancy + gamma * sr[node_y,] - sr[node_x,])
  }
  
  bits = c(NA, bits)
  return(bits)
}

calc_bits = function(probability) {
  bits <- -log(probability, base = 2)
  return(bits)
}

get_rt_sim <- function(dt_input, stat_model) {
  coeffs <- coef(stat_model)
  dt_output <- dt_input %>%
    .[, model_intercept := coeffs["(Intercept)"]] %>%
    .[, response_time_simulated := fitted(stat_model)]
  return(dt_output)
}
