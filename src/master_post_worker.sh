#!/bin/bash -l
#PBS -A 2022_202
#PBS -l nodes=1:ppn=46
#PBS -l walltime=72:00:00
#PBS -o ../logs/shell/CMOR_sh_SP_10M.out
#PBS -e ../logs/shell/CMOR_sh_SP_10M.err

slurm_account='2022_202'
use_worker='true'
source ./load_env.sh

#Check if all functions are available
funcs=('ncrcat' 'ncks' 'ncap2' 'ncatted')
for f in "${funcs[@]}"; do
    typ=$(type -p $f)
    if [[ -z ${typ} ]]; then
        echo "Necessary function $f is not available! Load respective module. Exiting..."
        exit
    fi
done

TIME1=$(date +%s)

source ./settings.sh

if [[ "${use_worker}" = 'true' ]]; then
    START_DATE=$start_date # Start year and month for processing (if not given in command line YYYYMM)
    STOP_DATE=$end_date  # End year and month for processing (if not given in command line YYYYMM)
fi

#default values
overwrite=false #overwrite output if it exists
n=true #normal printing mode
v=false #verbose printing mode
batch=true #create batch jobs continously always for one year
stopex=false
overwrite_arch=false
args=""
use_raw_data=true # set to true if you want to read immediately from raw output dirs that contain all (unpacked) files of an experiment
eur11_domain_outdir='out02' # declare the name of your output dir that has the EUR11 domain


# paths
EXPPATH=${GCM}/${EXP}
ARCHDIR=${ARCH_BASE}
INDIR1=${INDIR_BASE1}/${EXPPATH}
OUTDIR1=${OUTDIR_BASE1}/${EXPPATH}
INDIR2=${INDIR_BASE2}/${EXPPATH}
OUTDIR2=${OUTDIR_BASE2}/${EXPPATH}

#create logging directory
mkdir -p ${LOGDIR}
mkdir -p ${BASEDIR}/logs/cmorlight

#log base names
CMOR=${LOGDIR}/${GCM}_${EXP}_CMOR_sh
xfer=${LOGDIR}/${GCM}_${EXP}_xfer
delete=${LOGDIR}/${GCM}_${EXP}_delete

#printing modes
function echov {
  if ${v}; then
      echo $1
  fi
}

function echon {
  if ${n}; then
       echo $1
  fi
}

#range for second script
YYA=$(echo ${START_DATE} | cut -c1-4) 
YYE=$(echo ${STOP_DATE} | cut -c1-4)

#initialize first year
if [[ -z ${FIRST} ]]; then
    FIRST=${YYA}
fi

#if only years given: process from January of the year START_DATE to January of the year following STOP_DATE
if [[ ${#START_DATE} -eq 4 ]]; then
    START_DATE="${START_DATE}01"
else
    START_DATE=$(echo ${START_DATE} | cut -c1-6)
fi

if [[ ${#STOP_DATE} -eq 4 ]]; then
    STOP_DATE=$(($STOP_DATE+1))
    STOP_DATE="${STOP_DATE}01"
else
    STOP_DATE=$(echo ${STOP_DATE} | cut -c1-6)
fi


#end year for extracting
YYEext=$(echo ${STOP_DATE} | cut -c1-4)

#if no archives have been extracted in the beginning:
startex=${YYA}
endex=$(($YYA+$num_extract-1))
#limit to extraction to end year

if  [[ ${post_step} -ne 2 ]]; then
    CURRENT_DATE=${START_DATE}
    echo "######################################################"
    echo "First processing step"
    echo "######################################################"  
    echo "Start: " ${START_DATE}
    echo "Stop: " ${STOP_DATE}
    source ${SRCDIR_POST}/first.sh $use_raw_data $eur11_domain_outdir $ARCHDIR

fi


if [[ ${post_step} -ne 1 ]]; then
    echo ""
    echo "######################################################"
    echo "Second processing step"
    echo "######################################################"
    echo "Start: " ${YYA}
    echo "Stop: " ${YYE}
    source ${SRCDIR_POST}/second.sh
fi


echo "######################################################"
TIME2=$(date +%s)
SEC_TOTAL=$(python -c "print(${TIME2}-${TIME1})")
echo "total time for postprocessing: ${SEC_TOTAL} s"

