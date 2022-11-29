if (!requireNamespace("pacman")) install.packages("pacman")
packages_cran = c("here", "data.table", "magrittr", "assertr",
                  "dplyr", "tidyr", "gtools", "lme4", "ggplot2")
pacman::p_load(char = packages_cran)
paths_figures = here::here("outputs/figures")

calc_bits = function(probability) {
  bits = -log(probability, base = 2)
  return(bits)
}

sr_fun = function(node_previous, node, alpha, gamma, fig = FALSE){
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
    bits[i - 1] = calc_bits(probability = probability)
    # update the successor representation:
    occupancy = rep(0, num_nodes)
    occupancy[node_y] = 1
    sr[node_x,] = sr[node_x,] + alpha * (occupancy + gamma * sr[node_y,] - sr[node_x,])
    if (fig == TRUE) {
      dev.set(dev.prev())
      image(sr, main = i, zlim = c(0, 1))
      Sys.sleep(0.005)
    }
  }
  bits = c(NA, bits)
  return(bits)
}

data = data.table::fread(Sys.glob(here::here("inputs", "*.csv")))

alpha = 0.1
gammas = seq(0, 19, by = 1)
colnames = paste0("SR", gammas)
dt_sr = data %>%
  .[trial_run > 1, ] %>%
  .[, transition := paste(node_previous, node, sep = "-")] %>%
  .[, by = .(id), (colnames) := (
    lapply(gammas / 20, function(x) sr_fun(node_previous, node, alpha = 0.1, gamma = x))
  )]

num_runs = 5
num_trials_run = 240
dt_sr_main = dt_sr %>%
  .[condition == "main",] %>%
  .[, log_response_time := log(response_time)] %>%
  .[, halfrun := ifelse(trial_run <= num_trials_run / 2, "first", "second")] %>%
  .[, block := group_indices(., run, halfrun)] %>%
  .[, graphblock := ifelse(block %in% seq(1, 5), "first graph", "second graph")] %>%
  verify(block %in% seq(1, num_runs * 2)) %>%
  .[accuracy == 1,]

column_names = c("log_response_time", "dist_uni", "prob_uni")
dt_sr_main_mean = dt_sr_main %>%
  group_by(id, transition, block, graph, order) %>%
  summarise(across(all_of(column_names) | starts_with("SR"),
                   list(mean = ~ mean(.x, na.rm = TRUE)),
                   .names = "{.col}_{.fn}")) %>%
  setorder(., id, block, transition, dist_uni_mean)

formula_text = "log_response_time ~ block + bites * order * graph + (block + graph + bites | id)"

# code to generate data for figure 3d in Wittkuhn et al., 2022, bioRxiv (https://www.biorxiv.org/content/10.1101/2022.02.02.478787v1):

dt_sr_main_lmer = dt_sr_main %>%
  pivot_longer(cols = starts_with("SR"), names_to = "SR_GAMMA", values_to = "bites") %>%
  setDT(.) %>%
  .[, by = .(SR_GAMMA), {
    N = .N
    model = lme4::lmer(
      formula = as.formula(formula_text),
      data = .SD,
      subset = NULL,
      weights = NULL,
      REML = TRUE,
      na.action = na.omit,
      offset = NULL,
      control = lme4::lmerControl(
        optimizer = c('bobyqa'),
        optCtrl = list(maxfun = 100000),
        calc.derivs = FALSE
      )
    )
    model_attributes = attributes(model)
    aic = AIC(model)
    optinfo_optimizer = model_attributes$optinfo$optimizer
    optinfo_message = model_attributes$optinfo$message
    optinfo_warnings = ifelse(length(model_attributes$optinfo$warnings) == 0, "none", model_attributes$optinfo$warnings)
    list(aic, N, optinfo_optimizer, optinfo_message, optinfo_warnings)
  }] %>%
  .[, ":="(
    SR_GAMMA = factor(SR_GAMMA, levels = gtools::mixedsort(SR_GAMMA)),
    gamma = seq(0, 19)/20,
    ranking = rank(as.numeric(aic))
  )]

theme_zoo = function() {
  theme_font = "Helvetica"
  theme_color = "black"
  theme_out = theme(panel.grid.major = element_blank()) +
    theme(panel.grid.minor = element_blank()) +
    theme(panel.background = element_blank()) +
    theme(axis.title = element_text(family = theme_font, color = theme_color)) +
    theme(axis.text = element_text(family = theme_font, color = theme_color)) +
    theme(axis.ticks = element_line(color = theme_color)) +
    theme(axis.line = element_line(color = theme_color)) +
    theme(strip.text = element_text(margin = margin(b = 3, t = 3, r = 3, l = 3))) +
    theme(legend.margin = margin(t = 0, r = 0, b = 0, l = 0))
  return(theme_out)
}

save_figure <- function(plot, filename, width, height) {
  ggsave(filename = paste0("zoo_figure_", filename, ".pdf"),
         plot = plot, device = cairo_pdf, path = paths_figures,
         scale = 1, dpi = "retina", width = width, height = height)
  ggsave(filename = paste0("zoo_figure_", filename, ".png"),
         plot = plot, device = "png", path = paths_figures,
         scale = 1, dpi = "retina", width = width, height = height)
  return(plot)
}

dt = dt_sr_main_lmer
sr_colors = hcl.colors(20, "Inferno")
figure = ggplot(data = dt, aes(x = as.factor(gamma), y = aic)) +
  geom_vline(aes(xintercept = as.factor(gamma)),
             data = dt %>% .[ranking == 1, ], color = "gray") +
  geom_line(aes(group = 1)) +
  geom_point(aes(color = as.factor(gamma))) +
  scale_color_manual(values = sr_colors) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme_zoo() +
  theme(legend.position = "none") +
  xlab(expression(gamma)) +
  ylab("AIC")

filename = "3d"
save_figure(plot = figure, filename = "3d", width = 4, height = 3)
