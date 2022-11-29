all: modeling

.PHONY: modeling
modeling: inputs/zoo_sourcedata_behavioral_data.csv
	Rscript -e 'renv::run("code/sr-modeling.R")'
	
inputs/zoo_sourcedata_behavioral_data.csv:
	datalad get $<