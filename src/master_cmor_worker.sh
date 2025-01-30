#!/bin/bash -l
#PBS -A 2022_202
#PBS -l nodes=3:ppn=12
#PBS -l pmem=10gb
#PBS -l walltime=72:00:00
#PBS -o ../logs/cmorlight/CMOR.out
#PBS -e ../logs/cmorlight/CMOR.err

source ./settings.sh
source ./load_env.sh

script_folder="${BASEDIR}/src/CMORlight"
python_script="${script_folder}/cmorlight.py"
dirlog="${BASEDIR}/logs/cmorlight/master_py"
python="python3" #python command (e.g. python or python3)
worker='true'

#necessary for derotation
export IGNORE_ATT_COORDINATES=1


# variables
if [[ "${worker}" = 'true' ]]; then
    START=$start_date
    STOP=$end_date
else
    START=197901 #fill in
    STOP=202401  #fill in
fi
cores=1 #number of computing cores, set to >1 with -M option
batch=false # run several jobs simultaneously
args=""

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
       -s|--start)
      START=$2
      shift
      ;;
      -e|--end)
      STOP=$2
      shift
      ;;
      -b|--batch)
      batch=true
      ;;
      -M|--multi)
      cores=$2
      args="$args $1 $2"
      shift
      ;;
      *)
      args="$args $1"
      ;;
  esac
  shift
done



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



