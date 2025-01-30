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


# command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
      -h|--help)
      source ./help 
      exit
      ;;    
      -g|--gcm)
      GCM=$2
      args="${args} -g $2"
      shift
      ;;
      -x|--exp)
      EXP=$2
      args="${args} -x $2"
      shift
      ;;
       -s|--start)
      START_DATE=$2
      shift
      ;;
      -e|--end)
      STOP_DATE=$2
      args="${args} -e $2"
      shift
      ;;
      -F|--first_year) #only needed internally
      FIRST=$2
      shift
      ;;
      --first)
      post_step=1
      args="${args} --first"
      ;;
      --second)
      post_step=2
      args="${args} --second"
      ;;
      -S|--silent)
      n=false
      args="${args} -S"
      ;;
      -V|--verbose)
      v=true
      args="${args} -V"
      ;;
      -O|--overwrite)
      overwrite=true
      args="${args} -O"
      ;;
      --no_batch)
      batch=false
      args="${args} --no_batch"
      ;;
      --stopex)
      stopex=true
      ;;
      --overwrite_arch)
      overwrite_arch=true
      args="${args} --overwrite_arch"
      ;;
      *)
      echo "unknown option!"
      ;;
  esac
  shift
done

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
if [[ ${endex} -gt ${YYEext} ]]; then
    endex=${YYEext}
fi

if [[ ${post_step} -ne 2 ]] && [[ ${batch} = 'true' ]] && [[ ${stopex} != 'true' ]] && [[ ${use_raw_data} != 'true' ]]; then
    while [[ ${startex} -le ${endex} ]]; do
    
    if [[ ! -d ${INDIR1}/${startex} ]] || [[ ${overwrite_arch} = 'true' ]] ; then
        echon "Extracting years ${startex} to ${endex} \n\n"
        sbatch -A $slurm_account --job-name=CMOR_sh_${GCM}_${EXP} --error=${xfer}.${startex}.err --output=${xfer}.${startex}.out \
	       ${SRCDIR_POST}/xfer.sh -s ${startex} -e ${endex} -o ${INDIR1} -a ${ARCHDIR} -S ${SRCDIR_POST} -l ${xfer} -g ${GCM} -x ${EXP} --untarred_and_packed_input

        #abort running job and restart it after extraction is done
        sbatch -A $slurm_account --dependency=singleton --job-name=CMOR_sh_${GCM}_${EXP} --error=${CMOR}.${YYA}.err --output=${CMOR}.${YYA}.out \
	       master_post.sh ${args} -s ${START_DATE} -F ${FIRST} --stopex 
        exit
    fi

    startex=$(($startex+1))
  done
fi

NEXTYEAR=$(($YYA+1))
#for batch processing: process only one year per job
if [[ ${NEXTYEAR} -le ${YYE} ]] && [[ ${batch} = 'true' ]] && [[ ${use_raw_data} != 'true' ]]; then
  
    # Extract archived years every 10 years
    d=$(($YYA-$FIRST))
    mod=$(($d%$num_extract))
  
    if [[ $mod -eq 0 ]] && [[ ${post_step} -ne 2 ]]; then
        
	startex=$(($YYA+$num_extract))
	endex=$(($YYA+2*$num_extract-1))

        #limit to extraction to end year
        if [[ ${endex} -gt ${YYEext} ]]; then
            endex=${YYEext}
        fi
      
        if [[ ${startex} -le ${YYEext} ]]; then
            while [[ ${startex} -le ${endex} ]]; do
            
                if [[ ! -d ${INDIR1}/${startex} ]] || [[ ${overwrite_arch} = 'true' ]]; then
  
                    echon "Extracting years from ${startex} to  ${endex} \n\n"
                    sbatch  -A $slurm_account --job-name=CMOR_sh_${GCM}_${EXP} --error=${xfer}.${startex}.err --output=${xfer}.${startex}.out \
			    ${SRCDIR_POST}/xfer.sh -s ${startex} -e ${endex} -o ${INDIR1} -a ${ARCHDIR} -S ${SRCDIR_POST}  -l ${xfer} -g ${GCM} -x ${EXP}  --untarred_and_packed_input
                    #Submit job for the following year when all other jobs (to wait for extraction) are finished
                    sbatch -A $slurm_account --dependency=singleton --job-name=CMOR_sh_${GCM}_${EXP} --error=${CMOR}.${NEXTYEAR}.err --output=${CMOR}.${NEXTYEAR}.out \
			    master_post.sh ${args} -s ${NEXTYEAR} -F ${FIRST} 
		    startex=$(($endex+1))
                fi
		startex=$(($startex+1))
            done
        else
            #Submit job for the following year without waiting
            sbatch -A $slurm_account --job-name=CMOR_sh_${GCM}_${EXP} --error=${CMOR}.${NEXTYEAR}.err --output=${CMOR}.${NEXTYEAR}.out \
		    master_post.sh ${args} -s ${NEXTYEAR} -F ${FIRST} 
        fi
    else
        #Submit job for the following year without waiting
        sbatch -A $slurm_account --job-name=CMOR_sh_${GCM}_${EXP} --error=${CMOR}.${NEXTYEAR}.err --output=${CMOR}.${NEXTYEAR}.out \
		master_post.sh ${args} -s ${NEXTYEAR} -F ${FIRST} 
    fi
  
    #Set stop years to start years to process only one year per job
    YYE=${YYA}
    STOP_DATE="${NEXTYEAR}01"
fi


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

#Delete input data
if [[ ${post_step} -ne 2 ]] && [[ "${use_raw_data}" != 'true' ]] ; then
    if ${batch}; then 
        echo "deleting input data"
        sbatch -A $slurm_account --job-name=delete --error=${delete}.${YYA}.err --output=${delete}.${YYA}.out \
	        ${SRCDIR_POST}/delete.sh -s ${YYA} -e ${YYE} -g ${GCM} -x ${EXP} -I ${INDIR1}
    else
        while [[ ${YYA} -le ${YYE} ]]; do
            echo "Deleting ${INDIR1}/${YYA}" 
            rm -r  ${INDIR1}/${YYA} 
	    YYA=$((YYA+1))
        done
    fi
fi

echo "######################################################"
TIME2=$(date +%s)
SEC_TOTAL=$(python -c "print(${TIME2}-${TIME1})")
echo "total time for postprocessing: ${SEC_TOTAL} s"

