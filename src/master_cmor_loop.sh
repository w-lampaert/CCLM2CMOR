#!/bin/bash -l
#SBATCH --account=2022_202
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=10G
#SBATCH --time=24:00:00
#SBATCH --output=../logs/cmorlight/master_py_%j.out
#SBATCH --error=../logs/cmorlight/master_py_%j.err
#SBATCH --job-name="master_py"

source ./settings.sh
source ./load_env.sh

script_folder="${BASEDIR}/src/CMORlight"
python_script="${script_folder}/cmorlight.py"
dirlog="${BASEDIR}/logs/cmorlight/master_py"
python="python3" #python command (e.g. python or python3)

#necessary for derotation
export IGNORE_ATT_COORDINATES=1

START=$1 #fill in
STOP=$2  #fill in

cores=1 #number of computing cores, set to >1 with -M option
batch=false # run several jobs simultaneously
args=""


# Python script runs $cores years at once -> create one job out of $cores years
if [[ -z ${START} ]]; then
  echo "Please provide start year for processing with -s YYYY. Exiting..."
  exit
fi

if [[ -z ${STOP} ]]; then
  echo "Please provide end year for processing with -e YYYY. Exiting..."
  exit
fi

cd ${script_folder}
echo "Starting Python script for years ${START} to ${STOP}..."
${python} ${python_script} ${args} -s ${START} -e ${STOP}
echo "finished"



