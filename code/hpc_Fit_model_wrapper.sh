#!/usr/bin/bash

# ===
# Define paths
# ===

# define repo directory
PATH_BASE="${HOME}/zoo-modeling"
# data directory
PATH_DATA="${PATH_BASE}/inputs/zoo_sourcedata_behavioral_data.csv"
# output directory
PATH_OUT="${PATH_BASE}/outputs/modeling"
# directory to save logs of HPC
PATH_LOG="${PATH_BASE}/logs/hpc_Fit_model_wrapper/$(date '+%Y%m%d_%H%M')"
# Path to script to run
PATH_CODE="${PATH_BASE}/code"
# current path
PATH_RETURN=$(pwd)


# ===
# Create directories
# ===
# create output directory:
if [ ! -d ${PATH_OUT} ]; then
	mkdir -p ${PATH_OUT}
fi
# create directory for log files:
if [ ! -d ${PATH_LOG} ]; then
	mkdir -p ${PATH_LOG}
fi


# ===
# Get data
# ===
# User-defined data list
PARTICIPANTS=$1
# Get List of participants from data sheet
# Read first column of data file (make path to file relative)
PARTICIPANTS=$(csvtool col 1 ${PATH_DATA})
# Reduce to unique content
PARTICIPANTS=$(echo ${SUB_LIST} | tr ' ' '\n' | sort -u)
# Convert to aray
PARTICIPANTS=(${SUB_LIST})
# Delete first entry (name of column)
unset PARTICIPANTS[0]


# ===
# Define job parameters for cluster
# ===
# maximum number of cpus per process:
N_CPUS=1
# maximum number of threads per process:
N_THREADS=1
# memory demand in *GB*
MEM_MB=10000
# memory demand in *MB*
#MEM_MB="$((${MEM_GB} * 1000))"

# ===
# Set fitting process parameters
# ===
ALGORITHM="NLOPT_GN_DIRECT_L"
XTOL_REL=0.00001
MAXEVAL=10000
N_ITERATIONS=3

# ===
# Set modelling parameters
# ===
MODEL="sr"
RANDOM_STARTING_VALUES="TRUE"
X0="0.5,0.5"
LB="0.01,0.01"
UB="1,1"

# ===
# Run model fitting
# ===
# loop over all subjects:
for ID in ${PARTICIPANTS}; do

	# Get job name
	JOB_NAME="fit-${ID}_model-${MODEL}_randsv-${RANDOM_STARTING_VALUES}"

	# Create job file
	echo "#!/bin/bash" > job.slurm
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

	# Load R module
	echo "module unload R" >> job.slurm
	echo "module load R/4.2.2" >> job.slurm
  echo "Rscript -e 'renv::activate()' >> job.slurm
	echo "Rscript -e 'renv::rebuild()'" >> job.slurm
	echo "Rscript ${PATH_CODE}/Fit_model_wrapper.R" \
	--participant_id ${ID} \
  --model ${MODEL}
	--algorithm ${ALGORITHM} \
	--xtol_rel ${XTOL_REL} \
	--maxeval ${MAXEVAL} \
  --random_starting_values ${RANDOM_STARTING_VALUES} \
  --x0 ${X0} \
  --lb ${LB} \
  --ub ${UB} \
	--n_iterations ${N_ITERATIONS} >> job.slurm

	# submit job to cluster queue and remove it to avoid confusion:
	sbatch job.slurm
	rm -f job.slurm

done
