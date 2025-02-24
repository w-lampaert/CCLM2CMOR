#!/bin/bash -l

#
# Burkhardt Rockel / Helmholtz-Zentrum Geesthacht, modified by Matthias Göbel / ETH Zürich
# Initial Version: 2009/09/02
# Latest Version:  2017/09/15 
#

# command line args
use_raw_data=$1
eur11_domain_outdir=$2
arch_dir=$3

#function to process constant variables
function constVar {
    if [[ ! -f ${OUTDIR1}/$1.nc ]] ||  ${overwrite}; then
        echon "Building file for constant variable $1"
        ncks -h -A -v $1,rotated_pole ${WORKDIR}/${EXPPATH}/cclm_const.nc ${OUTDIR1}/$1.nc
    else
        echov "File for constant variable $1 already exists. Skipping..."
    fi
}

function get_monthly_raw_data {

    # arguments
    local input_dir=$1
    local year=$2
    local month=$3

    local first_file=$(ls ${input_dir}  | head -n 1)
    local file_prefix="${first_file:0:4}${year}${month}"
    input_files="$(ls ${input_dir}/${file_prefix}*[!cpz].nc )"
}


#... functions for building time series
function timeseries {  # building a time series for a given quantity
    
    # arguments
    local var_name=$1
    local out_dir=$2

    if [[ ! -f ${OUTDIR1}/${YYYY_MM}/${var_name}_ts.nc ]] || [[ "${overwrite}" = 'true' ]]; then
        
	echon "Building time series for variable ${var_name}"

	if [[ "${use_raw_data}" = 'true' ]]; then

            get_monthly_raw_data "${arch_dir}/${out_dir}" $YYYY $MM
	    first_day_file=${arch_dir}/${out_dir}/lffd${CURRENT_DATE}01000000.nc

        elif [[ ! $(ls lffd${CURRENT_DATE}*[!cpz].nc | wc -l) -gt 0 ]]; then

            cd ${INDIR1}/${CURRDIR}/${out_dir}
            echo "No files found for variable ${var_name} for current month in  ${INDIR1}/${CURRDIR}/${out_dir}. Skipping month..."
	    
	    input_files="$(ls lffd${CURRENT_DATE}*[!cpz].nc )"

	    if [[ ${MM} -eq 12 ]]; then
                input_files="$(echo ${input_files}) $(ls lffd${NEXT_DATE}0100.nc )"
            fi
	    first_day_file=${INDIR1}/${CURRDIR}/${out_dir}/lffd${CURRENT_DATE}0100.nc
	fi	    

	out_file=${OUTDIR1}/${YYYY_MM}/${var_name}_ts.nc

        ncrcat -h -O -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v ${var_name} ${input_files} ${out_file}
        ncks -h -A -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v lon,lat,rotated_pole ${first_day_file} ${out_file}
    else
        echov "Time series for variable ${var_name} already exists. Skipping..."
    fi
}


function timeseriesp {  # building a time series for a given quantity on pressure levels
    NPLEV=0
    cd ${INDIR1}/${CURRDIR}/$2
    
    if [[ ! -f lffd${CURRENT_DATE}*p.nc ]]; then
        echo "No files found for variable $1 for current month in  ${INDIR1}/${CURRDIR}/$2. Skipping month..."
    else
        while [[ ${NPLEV} -lt ${#PLEVS[@]} ]]; do
            PASCAL=$(python -c "print(${PLEVS[$NPLEV]} * 100.)")
            PLEV=$(python -c "print(int(${PLEVS[$NPLEV]}))")
            FILES="$(ls lffd${CURRENT_DATE}*p.nc )"
            
	    if [[ ${MM} -eq 12 ]]; then
                FILES="$(echo ${FILES}) $(ls lffd${NEXT_DATE}0100p.nc )"
            fi

            if [[ ! -f ${OUTDIR1}/${YYYY_MM}/${1}${PLEV}p_ts.nc ]] ||  ${overwrite}; then
                echon "Building time series at pressure level ${PLEV} hPa for variable $1"
                ncrcat -h -O -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -d pressure,${PASCAL},${PASCAL} -v $1 ${FILES} ${OUTDIR1}/${YYYY_MM}/${1}${PLEV}p_ts.nc
                ncks -h -A -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v lon,lat,rotated_pole \
			${INDIR1}/${CURRDIR}/$2/lffd${CURRENT_DATE}0100p.nc ${OUTDIR1}/${YYYY_MM}/${1}${PLEV}p_ts.nc
            else
                echov "Time series for variable $1 at pressure level ${PLEV}  already exists. Skipping..."
            fi
            let "NPLEV = NPLEV + 1"
       done
    fi
}


function timeseriesz {  # building a time series for a given quantity on height levels
    #MED 20/05/19 NZLEV=1
    NZLEV=0
    cd ${INDIR1}/${CURRDIR}/$2
  
    if [[ ! -f lffd${CURRENT_DATE}*z.nc ]]; then
        echo "No files for current month found. Skipping month..."
    else
  
        #MED 20/05/19 while [ ${NZLEV} -le ${#ZLEVS[@]} ]
        while [[ ${NZLEV} -lt ${#ZLEVS[@]} ]]; do
            ZLEV=$(python -c "print(int(${ZLEVS[$NZLEV]}))")
            FILES="$(ls lffd${CURRENT_DATE}*z.nc )"
            
	    if [[ ${MM} -eq 12 ]]; then
                FILES="$(echo ${FILES}) $(ls lffd${NEXT_DATE}0100z.nc )"
            fi

            if [[ ! -f ${OUTDIR1}/${YYYY_MM}/${1}${ZLEV}z_ts.nc ]] ||  ${overwrite}; then
                echon "Building time series at height level ${ZLEV} m for variable $1"
                #MED 20/05/19: ncrcat -h -O -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -d altitude,${ZLEV}.,${ZLEV}. -v $1 ${FILES} ${OUTDIR1}/${YYYY_MM}/${1}${ZLEV}z_ts.nc
                ncrcat -h -O -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -d height,${ZLEV}.,${ZLEV}. -v $1 ${FILES} ${OUTDIR1}/${YYYY_MM}/${1}${ZLEV}z_ts.nc
                ncks -h -A -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v lon,lat,rotated_pole ${INDIR1}/${CURRDIR}/$2/lffd${CURRENT_DATE}0100z.nc \
	             ${OUTDIR1}/${YYYY_MM}/${1}${ZLEV}z_ts.nc
            else
                echov "Time series for variable $1 at height level ${ZLEV} m  already exists. Skipping..."
            fi
            let "NZLEV = NZLEV + 1"
        done
    fi
}

###################################################
mkdir -p ${WORKDIR}/${EXPPATH}
mkdir -p ${INDIR1}

YYYY=$(echo ${CURRENT_DATE} | cut -c1-4)
MM=$(echo ${CURRENT_DATE} | cut -c5-6)
MMint=${MM}
if [[ $(echo ${MM} | cut -c1) -eq 0 ]]; then
  MMint=$(echo ${MMint} | cut -c2  )
fi

#################################################
# Post-processing loop
#################################################


#... set number of boundary lines to be cut off in the time series data
let "IESPONGE = ${IE_TOT} - NBOUNDCUT - 1"
let "JESPONGE = ${JE_TOT} - NBOUNDCUT - 1"

while [[ ${CURRENT_DATE} -le ${STOP_DATE} ]]; do
    YYYY_MM=${YYYY}_${MM}
    CURRDIR=${YYYY}/output
    echon "################################"
    echon "# Processing time ${YYYY_MM}"
    echon "################################"

    skip=false

    if [[ ! -d ${INDIR1}/${YYYY} ]] && [[ "${use_raw_data}" != 'true' ]]; then
        if [[ "${batch}" = 'true' ]]; then
            echo "Cannot find input directory for year ${YYYY} in ${INDIR1}. Skipping..."
            skip=true
        else
            echo "Cannot find input directory for year ${YYYY}. Transfering from ${ARCHDIR}..."
            if [[ -d ${ARCHDIR}/*${YYYY} ]] ; then
		# changed from mv to cp to avoid losing essential data
                cp ${ARCHDIR}/*${YYYY} ${INDIR1}
            elif [[ -f ${ARCHDIR}/*${YYYY}.tar ]]; then
                tar -xf ${ARCHDIR}/*${YYYY}.tar -C ${INDIR1}
            else
                echo "Cannot find .tar file or extracted archive in archive directory! Exiting..."
                skip=true 
            fi      
        fi
    fi
    
    # step ahead in time
    MMint=$(python -c "print(int("${MMint}")+1)")
    if [[ ${MMint} -ge 13 ]]; then
        MMint=1
        YYYY_next=$(python -c "print(int("${YYYY}")+1)")
    else
        YYYY_next=${YYYY}
    fi

    if [[ ${MMint} -le 9 ]]; then
        MM_next=0${MMint}
    else
        MM_next=${MMint}
    fi

    NEXT_DATE=${YYYY_next}${MM_next}
    NEXT_DATE2=${YYYY_next}_${MM_next}

    if [[ "${skip}" != 'true' ]]; then
        mkdir -p ${OUTDIR1}/${YYYY_MM}
       
       	DATE_START=$(date +%s)
        DATE1=${DATE_START}

        ##################################################################################################
        # build time series
        ##################################################################################################

        export IGNORE_ATT_COORDINATES=1  # setting for better rotated coordinate handling in CDO

        #... cut of the boundary lines from the constant data file and copy it
        if [[ ! -f ${WORKDIR}/${EXPPATH}/cclm_const.nc ]]; then
	    echon "Copy constant file"
	    if [[ "${use_raw_data}" = 'true' ]]; then
                input_dir=$arch_dir
	    else
		input_dir=${INDIR1}/${YYYY}/output
            fi
            ncks -h -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} ${input_dir}/${eur11_domain_outdir}/lffd*c.nc ${WORKDIR}/${EXPPATH}/cclm_const.nc
        fi
  
        #start timing
        DATE_START=$(date +%s)

        #process constant variables
        constVar FR_LAND
        constVar HSURF
        constDone=true

        #build time series for selected variables
        source ${SRCDIR_POST}/timeseries.sh

        #stop timing and print information
        DATE2=$(date +%s)
        SEC_TOTAL=$(python -c "print(${DATE2}-${DATE_START})")
        echon "Time for postprocessing: ${SEC_TOTAL} s"
  
    fi

    #if [[ ! "$(ls -A ${OUTDIR1}/${YYYY_MM})" ]] ; then
    #    rmdir ${OUTDIR1}/${YYYY_MM}
    #fi

    CURRENT_DATE=${NEXT_DATE}
    YYYY=${YYYY_next}
    MM=${MM_next}
done
