all: modeling

.PHONY: modeling
modeling: inputs/zoo_sourcedata_behavioral_data.csv
	Rscript -e 'renv::activate()'
	Rscript -e 'renv::rebuild()'
	Rscript code/Fit_model_wrapper.R --participant_id 'sub-01' --model 'sr' --algorithm 'NLOPT_GN_DIRECT_L' --xtol_rel 0.00001 --maxeval 100 --random_starting_values 'TRUE' --x0 0.5,0.5 --lb 0.01,0.01 --ub 1,1 --n_iterations 3
	Rscript code/Fit_model_wrapper.R --participant_id 'sub-02' --model 'sr' --algorithm 'NLOPT_GN_DIRECT_L' --xtol_rel 0.00001 --maxeval 100 --random_starting_values 'TRUE' --x0 0.5,0.5 --lb 0.01,0.01 --ub 1,1 --n_iterations 3
	Rscript code/Fit_model_wrapper.R --participant_id 'sub-03' --model 'sr' --algorithm 'NLOPT_GN_DIRECT_L' --xtol_rel 0.00001 --maxeval 100 --random_starting_values 'TRUE' --x0 0.5,0.5 --lb 0.01,0.01 --ub 1,1 --n_iterations 3

inputs/zoo_sourcedata_behavioral_data.csv:
	datalad get $<

# version of the docker container:
DOCKER_VERSION = 0.1
# platform of the docker container:
DOCKER_PLATFORM = linux/amd64

# login to the MPIB container registry:
.PHONY: docker-login
	docker login registry.git.mpib-berlin.mpg.de

# build docker container:
.PHONY: docker-build
docker-build:
	docker build --platform $(DOCKER_PLATFORM) -t registry.git.mpib-berlin.mpg.de/wittkuhn/zoo-modeling/modeling:$(DOCKER_VERSION) .docker/modeling

# push the docker container to the registry	
.PHONY: docker-push
docker-push:
	docker push registry.git.mpib-berlin.mpg.de/wittkuhn/zoo-modeling/modeling:$(DOCKER_VERSION)

# pull singularity version of the container:
.PHONY: singularity pull
singularity-pull:
	singularity pull --docker-login --force "modeling.sif" docker://registry.git.mpib-berlin.mpg.de/wittkuhn/zoo-modeling/modeling:$(DOCKER_VERSION)

.PHONY: apptainer-pull
apptainer-pull:
	apptainer pull --docker-login --force "modeling.sif" docker://registry.git.mpib-berlin.mpg.de/wittkuhn/zoo-modeling/modeling:$(DOCKER_VERSION)

modeling.sif:
	apptainer pull --docker-login --force "modeling.sif" docker://registry.git.mpib-berlin.mpg.de/wittkuhn/zoo-modeling/modeling:$(DOCKER_VERSION)

.PHONY: apptainer-shell
apptainer-shell:
	apptainer shell --contain --bind $(pwd):/mnt:rw modeling.sif

