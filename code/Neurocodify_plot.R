library(ggplot2)
library(ggh4x)

Neurocodify_plot = function(input_plot){
  
  # res = input_plot +
  #   theme(panel.border=element_blank(), axis.line=element_line()) +
  #   # Use capped coordinate system (line will not touch extremes)
  #   lemon::coord_capped_cart(left = 'both',
  #                            bottom = 'both',
  #                            expand = TRUE) +
  #   # Set theme for plot
  #   theme(panel.border=element_blank(),
  #         axis.line=element_line(),
  #         panel.background = element_rect(fill = 'white'),
  #         panel.grid = element_line(color = '#f5f5f5'),
  #         strip.background = element_rect(fill = 'transparent',
  #                                         color = 'transparent'),
  #         strip.text = element_text(face = 'bold'))
  
  res = input_plot +
    theme(panel.border=element_blank(), axis.line=element_line()) +
    # Use capped coordinate system (line will not touch extremes) using ggh4x
    guides(x = 'axis_truncated',
           y = 'axis_truncated') +
    # Set theme for plot
    theme(panel.border=element_blank(),
          axis.line=element_line(),
          panel.background = element_rect(fill = 'white'),
          panel.grid = element_line(color = '#f5f5f5'),
          strip.background = element_rect(fill = 'transparent',
                                          color = 'transparent'),
          strip.text = element_text(face = 'bold'))
  
  return(res)
  
}