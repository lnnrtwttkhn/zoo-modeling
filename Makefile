all: modeling

.PHONY: modeling
modeling: inputs/zoo_sourcedata_behavioral_data.csv
	Rscript -e 'renv::activate()'
	Rscript code/Fit_model_wrapper.R --participant_id 'sub-01' --model 'sr' --algorithm 'NLOPT_GN_DIRECT_L' --xtol_rel 0.00001 --maxeval 100 --random_starting_values 'TRUE' --x0 0.5,0.5 --lb 0.01,0.01 --ub 1,1 --n_iterations 3

inputs/zoo_sourcedata_behavioral_data.csv:
	datalad get $<
