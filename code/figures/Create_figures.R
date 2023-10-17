library(here)
library(data.table)
library(magrittr)
library(latex2exp)
library(cowplot)

Create_figures = function(){
  
  # Get repo root as path base
  base_path = here::here()
  # Get dir to save figures to
  save_dir = file.path(base_path, 'outputs', 'figures',
                       fsep = .Platform$file.sep)
  # Create save dir in case it does not exist
  if(!file.exists(save_dir)){
    dir.create(save_dir, recursive = TRUE)
  }
  
  # Source own functions
  source_path = file.path(base_path,
                          'code',
                          fsep = .Platform$file.sep)
  source(file.path(source_path, 'Exclude_participants.R', fsep = .Platform$file.sep))
  source(file.path(source_path, 'Neurocodify_plot.R', fsep = .Platform$file.sep))
  
  # Load model data
  data_dir = file.path(base_path, 'outputs', 'modeling', 'sub-*sr.csv',
                       fsep = .Platform$file.sep)
  data_files = Sys.glob(data_dir)
  data = data.table::data.table()
  for(file in data_files){
    data = rbind(data,
                 data.table::fread(file))
  }
  # Exclude participants
  data = data %>%
    Exclude_participants(.)
  
  # load behavioral data
  data_files = file.path(base_path, 'inputs', 'zoo_sourcedata_behavioral_data.csv',
                         fsep = .Platform$file.sep)
  data_behav = data.table::fread(data_files) %>%
    # Exclude participants
    Exclude_participants(.)
  
  # Plot: Regressor p-values
  data_p_ss = data %>%
    # Restrict to first iteration
    .[iter == 1, ] %>%
    # Look at p-values of regressors used in regression model
    .[mod == 'reg_model',] %>%
    .[substr(variable, start = 0, stop = 2) == 'p_',] %>%
    # convert id variable to factor
    .[, variable := factor(variable,
                           levels = c('p_Intercept',
                                      'p_shannon_surprise',
                                      'p_trial_ses',
                                      'p_block',
                                      'p_hand_finger_pressedleft_middle',
                                      'p_hand_finger_pressedleft_ring',
                                      'p_hand_finger_pressedright_index',
                                      'p_hand_finger_pressedright_middle',
                                      'p_hand_finger_pressedright_ring'))]
  
  # Plot distribution of p-values for each regressor
  p_ss = ggplot(data = data_p_ss[variable == 'p_shannon_surprise'],
             aes(x = variable,
                 y = value)) +
    geom_hline(yintercept = 0.05,
               linetype = 'dashed',
               linewidth = 0.3) +
    # geom_boxplot(width = 0.2,
    #              outlier.shape = NA) +
    geom_point(size = 1,
               alpha = 0.5,
               position = position_jitter(width = 0.3,
                                          height = 0,
                                          seed = 666)) +
    labs(y = 'p-value',
         x = latex2exp::TeX(r'(\textit{$\beta_{\textit{SS}}$})')) +
    scale_y_continuous(breaks = seq(0,0.2, by = 0.05),
                       labels = substr(format(seq(0,0.2, by = 0.05),digits = 4),
                                       start = 2,
                                       stop = 4))
  p_ss = Neurocodify_plot(p_ss) +
    theme(axis.title.x = element_text(size = 15,
                                      face = 'plain',
                                      margin = margin()),
          axis.ticks.x = element_blank(),
          axis.text.x = element_blank(),
          axis.title.y = element_text(size = 15,
                                      face = 'plain',
                                      margin = margin(0,10,0,0,'pt')),
          axis.text.y = element_text(size = 12,
                                     margin = margin(0,5,0,0,'pt')), 
          panel.grid = element_blank())
  
  # Save figure
  out_file = file.path(save_dir, 'zoo_figure_model_p_regressor_ss.pdf')
  ggplot2::ggsave(filename = out_file,
                  plot = p_ss,
                  width = 1.5,
                  height = 3)
  
  
  # Plot: Avg. parameter values
  data_p_params = data %>%
    Exclude_participants(.) %>%
    # Only select first iteration (because of deterministic fitting process)
    .[iter == 1,] %>%
    # Select only fitted parameter values
    .[mod == 'model' & variable %in% c('alpha', 'gamma'),] %>%
    .[, variable := factor(variable)] %>%
    # Sort group factor for plotting order (uni-bi first)
    .[, order := factor(order, levels = c('uni - bi', 'bi - uni'))]
  
  # Subplot: Across groups
  p_params_all = ggplot(data = data_p_params,
                        aes(x = variable,
                            y = value)) +
    geom_point(position = position_jitter(width = 0.2,
                                          height = 0,
                                          seed = 666),
               alpha = 0.5,
               size = 1.5) +
    geom_boxplot(width = 0.2,
                 outlier.shape = NA) +
    stat_summary(geom = 'point',
                 fun = 'mean',
                 shape = 23,
                 size = 3,
                 stroke = 1.5) +
    labs(x = 'Parameter',
         y = 'Fitted value') +
    scale_x_discrete(labels = c(latex2exp::TeX(r'($\alpha$)'),
                                latex2exp::TeX(r'(\textit{$\gamma$})')))
  p_params_all = Neurocodify_plot(p_params_all) +
    theme(axis.title.x = element_text(size = 15,
                                      face = 'plain'),
          axis.text.x = element_text(size = 15,
                                     margin = margin(5,0,0,0,'pt')),
          axis.title.y = element_text(size = 15,
                                      face = 'plain',
                                      margin = margin(0,10,0,0,'pt')),
          axis.text.y = element_text(size = 12), 
          panel.grid = element_blank())
  
  # Subplot: Within groups
  p_params_group = ggplot(data = data_p_params,
                          aes(x = variable,
                              y = value)) +
    geom_point(position = position_jitter(width = 0.2,
                                          height = 0,
                                          seed = 666),
               alpha = 0.5,
               size = 1.5) +
    geom_boxplot(width = 0.2,
                 outlier.shape = NA,
                 fill = 'grey') +
    stat_summary(geom = 'point',
                 fun = 'mean',
                 shape = 23,
                 size = 3,
                 stroke = 1.5,
                 fill = 'white') +
    labs(x = 'Parameter',
         y = 'Fitted value') +
    scale_x_discrete(labels = c(latex2exp::TeX(r'($\alpha$)'),
                                latex2exp::TeX(r'(\textit{$\gamma$})'))) +
    facet_grid(.~order)
  p_params_group = Neurocodify_plot(p_params_group) +
    theme(axis.title.x = element_text(size = 15,
                                      face = 'plain'),
          axis.text.x = element_text(size = 15,
                                     margin = margin(5,0,0,0,'pt')),
          # In case y-axis should be displayed (with name and y-axis values)
          # axis.text.y = element_text(size = 12),
          # axis.title.y = element_text(size = 15,
          #                             face = 'plain'),
          # In case no y-axis text/title is needed
          axis.text.y = element_blank(),
          axis.title.y = element_blank(),
          panel.grid = element_blank(),
          strip.background = element_rect(fill = 'lightgrey'),
          strip.text = element_text(face = 'plain',
                                    size = 12),
          plot.margin = margin(5,5,5,10,'pt'))
  
  # Combine subplots
  p_params = cowplot::plot_grid(p_params_all, NULL, p_params_group,
                                nrow = 1,
                                axis = 'bt',
                                align = 'h',
                                rel_widths = c(1,0.1,1.3),
                                labels = c('a','', 'b'),
                                label_size = 20,
                                label_x = -0.07,
                                label_y = 1.015) +
    theme(plot.margin = margin(0,0,0,7.5,'pt'))
  
  # Save figure
  out_file = file.path(save_dir, 'zoo_figure_model_parameter.pdf')
  ggplot2::ggsave(filename = out_file,
                  plot = p_params,
                  width = 5,
                  height = 3)
  
  
}