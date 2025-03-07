#!/bin/bash -l
#SBATCH --account=2022_202
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=10
#SBATCH --time=08:00:00
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

START=197901 #fill in
STOP=197912  #fill in

cores=1 #number of computing cores, set to >1 with -M option
batch=false # run several jobs simultaneously
args=""

# Python script runs $cores years at once -> create one job out of $cores years
(( START_NEW=START+cores ))

if [[ -z ${START} ]]; then
  echo "Please provide start year for processing with -s YYYY. Exiting..."
  exit
fi

if [[ -z ${STOP} ]]; then
  echo "Please provide end year for processing with -e YYYY. Exiting..."
  exit
fi

if [[ ${START_NEW} -le ${STOP} ]] && ${batch}; then
  (( STOP_NEW=START_NEW+cores-1 )) #STOP year for this batch
  if [[ ${STOP_NEW} -gt ${STOP} ]]; then
    STOP_NEW=${STOP}
  fi
  sbatch --job-name=master_py --error=${dirlog}_${START_NEW}_${STOP_NEW}.err --output=${dirlog}_${START_NEW}_${STOP_NEW}.out master_cmor.sh ${args} -b -s ${START_NEW} -e ${STOP}
  (( STOP=START+cores-1 )) #STOP year for this batch
fi

cd ${script_folder}
echo "Starting Python script for years ${START} to ${STOP}..."
${python} ${python_script} ${args} -s ${START} -e ${STOP}
echo "finished"
