#/bin/bash -l

# This script contains functions used in the other scripts, mainly separated for readability


# A function to create new variables from exisiting ones
function create_add_vars {
    
    input_var1=$1   #first input variable
    input_var2=$2   #second input variable
    output_var=$3   #output variable
    formula=$4      #formula how to create output variable
    standard_name=$5

    # definition of formula
    if [[ ${formula} == "add" ]]; then
        formula="${output_var}=${input_var1} ${input_var2}"
    elif [[ ${formula} == "subs" ]]; then
        formula="${output_var}=${input_var1}-${input_var2}"
    elif [[ ${formula} == "add_sqr" ]]; then
        formula="${output_var}=sqrt(${input_var1}^2 ${input_var2}^2)"
    elif [[ ${formula} == "snow_case" ]]; then
        formula="SNOW_flg=float($input_var1>0.0000005);SNOW=float($input_var1/0.015);where(SNOW>1.0)SNOW=1.0f;where(SNOW<0.01)SNOW=0.01f;$output_var=float(SNOW*SNOW_flg)"
    else
        echo "Formula ${formula} not known! Skipping"
        return
    fi

    if [[ ${proc_list} =~ ${output_var} ]] || ${proc_all}; then
        
	file1=$(ls ${OUTDIR2}/${input_var1}/${input_var1}_${YY}${MMA}0100*.nc)
        echo "finding ${file1}"
        
	if [[ ${input_var2} == "" ]]; then
            file2=""
        else
            file2=$(ls ${OUTDIR2}/${input_var2}/${input_var2}_${YY}${MMA}0100*.nc)
        fi
        
	echov "Input files and formula:"
        echov "$file1"
        echov "$file2"
        echov "$formula"

        if [[ -f ${file1} ]]; then #MED<<
            ((c1 = ${#file1} - 23))
            ((c2 = ${#file1} - 3))
            DATE=$(ls ${file1} | cut -c${c1}-${c2})
            file3=${OUTDIR2}/${output_var}/${output_var}_${DATE}.nc
            
	    if [[ ! -f ${file3} ]] || ${overwrite}; then
                
		echon "Create ${output_var}"
                [[ -d ${OUTDIR2}/${output_var} ]] || mkdir ${OUTDIR2}/${output_var}
                cp ${file1} temp1_${YY}.nc
                
		if [[ -f ${file2} ]]; then
                    ncks -h --no_abc -A -v ${input_var2} ${file2} temp1_${YY}.nc
                fi
                
		ncap2 -h -O -s ${formula} temp1_${YY}.nc temp1_${YY}.nc
                ncks -h --no_abc -O -v ${output_var},lat,lon,rotated_pole temp1_${YY}.nc ${file3}
                
		ncatted -h -a long_name,${output_var},d,, ${file3}
                ncatted -h -a standard_name,${output_var},m,c,${standard_name} ${file3}
                chmod ${PERM} ${file3}
                rm temp1_${YY}.nc
            else
                echov "$(basename ${file3})  already exists. Use option -o to overwrite. Skipping..."
            fi
        else
            echo "Input Files for generating ${output_var} are not available"
        fi
    fi
}


function aggregate_vars {

    input_var=$1   #input variable
    output_var=$2  #output variable
    method=$3      
    standard_name=$4

    # definition of formula
    if [[ ${method} == "min" ]]; then
        cdo_method='daymin'
    elif [[ ${method} == "max" ]]; then
        cdo_method='daymax'
    else
        echo "Method ${method} not known (yet)! Skipping"
        return
    fi

    input_file=$(ls ${OUTDIR2}/${input_var}/${input_var}_${YY}${MMA}0100*.nc)
     
    output_dir="${OUTDIR2}/${output_var}"
    mkdir -p ${output_dir}
    date_regex="[0-9]{10}-[0-9]{10}"
    date_string=$(echo $input_file | grep -oP $date_regex)

    output_file="${output_dir}/${output_var}_${date_string}.nc"

    if [[ ${input_file} != '' ]]; then
	if ! [[ -f ${output_file} ]] || [[ ${overwrite} = 'true' ]]; then
	    cdo ${cdo_method} ${input_file} ${output_file}
	    ncatted -h -a standard_name,${output_var},m,c,${standard_name} ${output_file}
	else
            echo "File ${output_file} already exists and overwrite is not true. Skipping."
	fi
    else
	echo "Warning: no input file found for ${input_var} in year ${YY}. Skipping."
	return
    fi
}
