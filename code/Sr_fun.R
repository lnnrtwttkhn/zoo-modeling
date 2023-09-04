library(here)

Sr_fun = function(node_previous,
                  node,
                  alpha,
                  gamma,
                  fig = FALSE){
  
  # Source own functions
  source_path = file.path(here::here(), 'code',
                          fsep = .Platform$file.sep)
  source(file.path(source_path, 'Calc_bits.R',
                   fsep = .Platform$file.sep))
  
  num_nodes = 6
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
    bits[i - 1] = Calc_bits(probability = probability)
    
    # update the successor representation:
    occupancy = rep(0, num_nodes)
    occupancy[node_y] = 1
    sr[node_x,] = sr[node_x,] + alpha * (occupancy + gamma * sr[node_y,] - sr[node_x,])
    
    # If specified, plot
    if (fig == TRUE) {
      dev.set(dev.prev())
      image(sr, main = i, zlim = c(0, 1))
      Sys.sleep(0.005)
    }
    
  }
  
  bits = c(NA, bits)
  return(bits)
}