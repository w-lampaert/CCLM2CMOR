#!/bin/bash
# add -l to /bin/bash (or --login) to execute commands from file /etc/profile
#SBATCH --nodes=1
#SBATCH --partition=xfer
#SBATCH --time=4:00:00
#SBATCH --output=${BASEDIR}/logs/shell/xfer_%j.out
#SBATCH --error=${BASEDIR}/logs/shell/xfer_%j.err
#SBATCH --job-name="xfer_sh"

overwrite_arch=false
args=""
outstream='out01 out02 out03 out04 out05 out06'

# commandline arguments
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
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
      startyear=$2
      shift
      ;;
      -e|--end)
      endyear=$2
      args="${args} -e $2"
      shift
      ;;
      -o|--out)
      OUTDIR=$2
      args="${args} -o $2"
      shift
      ;;
      -a|--arch)
      ARCHDIR=$2
      args="${args} -a $2"
      shift
      ;;
      -l|--log)
      xfer=$2
      args="${args} -l $2"
      shift
      ;;
      -S|--src)
      SRCDIR=$2
      args="${args} -S $2"
      shift
      ;;
      --overwrite_arch)
      overwrite_arch=true
      args="${args} --overwrite_arch"
      ;;
      --untarred_and_packed_input)
      untarred_and_packed_input=true
      args="${args} --untarred_and_packed_input"
      ;;
      *)
      echo "unknown option!"
      ;;
  esac
  shift
done

# check if necessary cmdline args are provided
if [[ -z $startyear || -z $endyear || -z $OUTDIR || -z $ARCHDIR || -z $xfer || -z $SRCDIR ]]; then
    echo "Please provide all necessary arguments! Exiting..."
    exit
fi


# copy/unpack raw data
mkdir -p ${OUTDIR}

all_years=($(seq $startyear $endyear))

for year in "${all_years[@]}"; do

    if [[ ! -d ${OUTDIR}/${startyear} ]] || [[ ${overwrite_arch} = 'true' ]]; then
        
	if [[ ${untarred_and_packed_input} = 'true' ]]; then
	    echo "Copying raw data for year ${year} to  ${OUTDIR}"

	    for stream in ${outstream}; do

		mkdir -p ${OUTDIR}/${startyear}/output/${stream}
	        first_file=$(ls ${ARCHDIR}/${stream} | head -n 1)
		file_prefix="${first_file:0:4}${year}"

		cp ${ARCHDIR}/${stream}/${file_prefix}* ${OUTDIR}/${startyear}/output/${stream}
	    done
	
	elif [[ -d ${ARCHDIR}/*${startyear} ]]; then
	    echo "Moving input directory for year ${startyear} to ${OUTDIR} "
            mv ${ARCHDIR}/${startyear} ${OUTDIR}
	
	elif [[ -f ${ARCHDIR}/*${startyear}.tar ]]; then
	    echo "Extracting archive for year ${startyear} to ${OUTDIR}"
            mkdir ${OUTDIR}/${startyear}
            mkdir ${OUTDIR}/${startyear}/output

            for stream in ${outstream}; do
                mkdir  ${OUTDIR}/${startyear}/output/${stream}
                tar -xf ${ARCHDIR}/*${startyear}.tar -C ${OUTDIR}/${startyear}/output/${stream} --strip-components=3 output/${stream}/${startyear}
            done

	else
	    echo "No raw input files or tar files found for year ${year} in the archive directory ${ARCHDIR}! Skipping year..."
	fi
    else
        echo "Input files for year ${startyear} are already at ${OUTDIR}. Skipping..."
    fi
done
