if (!requireNamespace("pacman")) install.packages("pacman")
packages_cran = c("here", "data.table", "magrittr", "assertr",
                  "dplyr", "tidyr", "gtools", "lme4", "ggplot2")
pacman::p_load(char = packages_cran)

Reg_model = function(x,
                     data,
                     model){
  
  # Inputs:
  # x : list of parameters, minimization function adjusts x to get lowest -LL
  # data : Behavioral data used for model
  # model : Specified model, different models require different list entries in x (e.g. for additional parameters)
  
  if(model == 'sr'){
    # Check if parameters fit specified model
    if(length(x) != 2){
      stop(paste('Number of parameters does not match specified model "',
                 model,
                 '"',
                 sep = ''))
    } else{
      # Translate parameters for easier coding
      alpha = x[[1]]
      gamma = x[[2]]
    }
  } else if (model == 'sr_base') {
    # Translate parameters for easier coding
    alpha = x[[1]]
    gamma = 0
  }
  
  # Source own functions
  source_path = file.path(here::here(), 'code',
                          fsep = .Platform$file.sep)
  source(file.path(source_path, 'Calc_bits.R',
                   fsep = .Platform$file.sep))
  source(file.path(source_path, 'Sr_fun.R',
                   fsep = .Platform$file.sep))
  
  # Get shannon-surprise of each trial given model
  if(model == 'sr' | model == 'sr_base'){
    data_res = data %>%
      data.table::setDT(.) %>%
      # Get trial within session
      .[, trial_ses := seq(.N),
        by = .(id, session)] %>%
      # Skip first trial of each run (because there is no transition happening)
      .[trial_run > 1, ] %>%
      # Add node transition as column
      .[, transition := paste(node_previous, node, sep = "-")] %>%
      # Get surprise in response of displayed node based on SR model
      .[, by = .(id), shannon_surprise := Sr_fun(node_previous = node_previous,
                                                 node = node,
                                                 alpha = alpha,
                                                 gamma = gamma)]
  }
  
  # Specify targeted number of runs and trials after data transformation
  num_runs = 5
  num_trials_run = 240
  
  # Transform data
  data_res_main = data_res %>%
    data.table::setDT() %>%
    # Exclude training block
    .[condition == "main",] %>%
    # Potential way to include also recall phase: .[condition %in% c('main', 'recall')] %>%
    # Add log-transformed RT
    .[, log_response_time := log(response_time)] %>%
    # Add column for first and second half of run
    .[, halfrun := ifelse(trial_run <= num_trials_run / 2, "first", "second")] %>%
    # Specify block (combination of run and halfrun)
    .[, block := as.numeric(factor(paste(run, halfrun, sep = '_')))] %>%
    # Get trial within block
    .[, trial_block := seq(.N),
      by = .(id, block)] %>%
    # Column for graph used
    .[, graphblock := ifelse(block %in% seq(1, 5), "first graph", "second graph")] %>%
    # Get which finger on which hand was used for response
    .[, hand_finger_pressed := paste(hand_pressed, finger_pressed, sep = '_')] %>%
    # Check if any data is missing
    assertr::verify(block %in% seq(1, num_runs * 2)) %>%
    # Exclude error trials
    .[accuracy == 1,]

  # Mean?
  # column_names = c("log_response_time", "dist_uni", "prob_uni")
  # dt_sr_main_mean = data_res_main %>%
  #   group_by(id, transition, block, graph, order) %>%
  #   summarise(across(all_of(column_names) | starts_with("SR"),
  #                    list(mean = ~ mean(.x, na.rm = TRUE)),
  #                    .names = "{.col}_{.fn}")) %>%
  #   setorder(., id, block, transition, dist_uni_mean)
  
  # Define statistical model
  # Detail: Predicting RT (not transformed!) by SR-related surprise.
  # Control for:
  #   - getting faster across experiment (over trials in a session, and over blocks in general)
  #   - faster/slower response depending on hand and finger.
  # Untransformed RTs are Gamma-distributed, using GLM with inverse link function to avoid transformation
  stat_model = glm(formula = response_time ~ shannon_surprise + trial_ses + block + hand_finger_pressed,
                   family = Gamma(link = 'inverse'),
                   data = data_res_main)

  # Debug: Visualize best fit
  # ggplot2::ggplot(data = data_res_main,
  #                 aes(x = shannon_surprise,
  #                     y = response_time)) +
  #   geom_point()
  
  return(list(stat_model = stat_model,
              data = data_res_main,
              x = x))
  
}