library(here)
library(data.table)

Exclude_participants = function(data){
  
  # Set list of participants to exclude
  exclude_list = c("sub-08",
                   "sub-09",
                   "sub-13",
                   "sub-14",
                   "sub-17")
  
  # Convert to data table
  res = data.table::setDT(data) %>%
    # Exclude all specified participants
    .[!id %in% exclude_list,]
  
  # Return data table without excluded participants
  return(res)
  
}