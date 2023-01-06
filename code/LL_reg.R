LL_reg = function(x,
                  data,
                  model){
  
  # Source own functions
  source_path = file.path(here::here(), 'code',
                          fsep = .Platform$file.sep)
  source(file.path(source_path, 'Reg_model.R',
                   fsep = .Platform$file.sep))
  
  # Run regression
  res = Reg_model(x = x,
                  data = data,
                  model = model)
  
  # Get -LL of statistical model
  neg_ll = -logLik(res$stat_model)
  
  return(neg_ll)
  
}