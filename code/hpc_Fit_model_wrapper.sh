#!/usr/bin/bash
# ==============================================================================
# DEFINE PATHS:
# ==============================================================================
# define path to script being run:
PATH_SCRIPT="$( dirname "$(readlink -f -- "$0")" )"
# Base of repo is one level above script location
PATH_BASE="${PATH_SCRIPT%/*}"
# define path to data file:
PATH_DATA="${PATH_BASE}/inputs/zoo_sourcedata_behavioral_data.csv"
# output directory
PATH_OUT_DATALAD="${PATH_BASE}/outputs/modeling"
PATH_OUT="${PATH_OUT_DATALAD}/modeling"
# directory to save logs of HPC
PATH_LOG="${PATH_BASE}/logs/hpc_Fit_model_wrapper/$(date '+%Y%m%d_%H%M')"
# Path to script to run
PATH_CODE="${PATH_BASE}/code"
# path to singularity / apptainer file:
PATH_SIF="${PATH_BASE}/modeling.sif"
# ==============================================================================
# CREATE DIRECTORIES
# ==============================================================================
# create output directory (if it does not exist):
if [ ! -d ${PATH_OUT} ]; then
	mkdir -p ${PATH_OUT}
else
	# If exists, allow overwriting of files (since its probably a datalad repo)
	datalad unlock ${PATH_OUT_DATALAD}
fi
# create directory for log files:
if [ ! -d ${PATH_LOG} ]; then
	mkdir -p ${PATH_LOG}
fi
# ==============================================================================
# DEFINE JOB PARAMETERS
# ==============================================================================
# maximum number of cpus per process:
N_CPUS=1
# maximum number of threads per process:
N_THREADS=1
# memory demand in *MB*
MEM_MB=500
# ==============================================================================
# Set fitting process parameters
# ==============================================================================
ALGORITHM="NLOPT_GN_DIRECT_L"
XTOL_REL=0.00001
MAXEVAL=10000
N_ITERATIONS=3
# ==============================================================================
# Set modelling parameters
# ==============================================================================
declare -a MODELS=("sr", "sr_base")
RANDOM_STARTING_VALUES="TRUE"
X0="0.5,0.5"
LB="0.01,0.01"
UB="1,1"
# ==============================================================================
# Run model fitting
# ==============================================================================
# loop over all subjects:
for i in {1..44}; do
  for MODEL in "${MODELS[@]}"; do
    # turn the subject id into a zero-padded number and add "sub"
  	SUB="sub-$(printf "%02d\n" ${i})"
  	# Get job name
  	JOB_NAME="fit-${SUB}_model-${MODEL}_randsv-${RANDOM_STARTING_VALUES}"
  	# Create job file
  	echo '#!/bin/bash' > job.slurm
  	# name of the job
  	echo "#SBATCH --job-name ${JOB_NAME}" >> job.slurm
  	# set the expected maximum running time for the job:
  	echo "#SBATCH --time 23:59:00" >> job.slurm
  	# determine how much RAM your operation needs:
  	echo "#SBATCH --mem ${MEM_MB}MB" >> job.slurm
  	# determine number of CPUs
  	echo "#SBATCH --cpus-per-task ${N_CPUS}" >> job.slurm
  	# write to log folder
  	echo "#SBATCH --output ${PATH_LOG}/slurm-${JOB_NAME}.%j.out" >> job.slurm
  	# add singularity command:
  	echo "apptainer exec --pwd mnt --cleanenv --contain --bind ${PATH_BASE}:/mnt:rw ${PATH_SIF} \
  	Rscript code/Fit_model_wrapper.R \
    --participant_id ${SUB} \
    --model ${MODEL} \
    --algorithm ${ALGORITHM} \
    --xtol_rel ${XTOL_REL} \
    --maxeval ${MAXEVAL} \
    --random_starting_values ${RANDOM_STARTING_VALUES} \
    --x0 ${X0} \
    --lb ${LB} \
    --ub ${UB} \
    --n_iterations ${N_ITERATIONS}" >> job.slurm
  	# submit job to cluster queue and remove it to avoid confusion:
  	sbatch job.slurm
  	rm -f job.slurm
	done
done
