#!/bin/bash -l
#-------------------------------------------------------------------------
# Concatenats monthly time series files produced by CCLM chain script post
# to annual file for a given time period of years and creates additional 
# fields required by CORDEX
# 
# K. Keuler, Matthias Göbel 
#latest version: 15.09.2017
#-------------------------------------------------------------------------
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/functions.sh

PERM=755 #Permission settings for output files

#variables
# all CCLM variables representing a time interval (min, max, average, accumulated)
accu_list=" AEVAP_S ALHFL_BS ALHFL_PL ALHFL_S ALWD_S ALWU_S APAB_S ASHFL_S ASOB_S ASOB_T ASOD_T ASODIFD_S ASWDIFU_S ASODIR_S ATHB_S ATHD_S ATHU_S ATHB_T AUMFL_S AUSTRSSO AVDISSSO AVMFL_S AVSTRSSO DURSUN DURSUN_M DURSUN_R GRAU_GSP HAIL_GSP RAIN_CON RAIN_GSP RUNOFF_G RUNOFF_S SNOW_CON SNOW_GSP SNOW_MELT T_2M_AV TD_2M_AV TDIV_HUM TOT_PREC U_10M_AV V_10M_AV VABSMX_10M VGUST_CON VGUST_DYN VMAX_10M "
  
#all instantaneous variables
inst_list=" AER_BC AER_DUST AER_ORG AER_SO4 AER_SS ALB_DIF ALB_DRY ALB_RAD ALB_SAT BAS_CON BRN C_T_LK CAPE_3KM CAPE_CON CAPE_ML CAPE_MU CEILING CIN_ML CIN_MU CLC CLC_CON CLC_SGS CLCH CLCL CLCM CLCT CLCT_MOD CLDEPTH CLW_CON DBZ DBZ_850 DBZ_CMAX DD_ANAI DEPTH_LK DP_BS_LK DPSDT DQC_CON DQI_CON DQV_CON DQVDT DT_CON DT_SSO DTKE_CON DTKE_HSH DTKE_SSO DU_CON DU_SSO DV_CON DV_SSO EDR EMIS_RAD EVATRA_SUM FC FETCH_LK FF_ANAI FI FI_ANAI FIS FOR_D FOR_E FR_ICE FR_LAKE FRESHSNW GAMSO_LK H_B1_LK H_ICE H_ML_LK H_SNOW H_SNOW_M HBAS_CON HBAS_SC HHL HMO3 HORIZON HPBL HTOP_CON HTOP_DC HTOP_SC HZEROCL LAI LAI_MN LAI_MX LCL_ML LFC_ML LHFL_S LWD_S LWU_S MFLX_CON MSG_RAD MSG_RADC MSG_TB MSG_TBC O3 OMEGA P P_ANAI PABS_RAD PLCOV PLCOV_MN PLCOV_MX PMSL PMSL_ANAI POT_VORTIC PP PRG_GSP PRH_GSP PRR_CON PRR_GSP PRS_CON PRS_GSP PS Q_SEDIM QC QC_ANAI QC_RAD QCVG_CON QG QH QI QI_RAD QNCLOUD QNGRAUPEL QNHAIL QNICE QNRAIN QNSNOW QR QRS QS QV QV_2M QV_ANAI QV_S QVSFLX RCLD RELHUM RELHUM_2M RESID_WSO RHO_SNOW RHO_SNOW_M RLAT RLON ROOTDP RSMIN RSTOM SDI_1 SDI_2 SHFL_S SI SKYVIEW SLI SLO_ANG SLO_ASP SNOWLMT SOBS_RAD SOBT_RAD SOD_T SOHR_RAD SOILTYP SSO_GAMMA SSO_SIGMA SSO_STDH SSO_THETA SWDIFD_S SWDIFU_S SWDIR_COR SWDIR_S SWISS00 SWISS12 SYNME5 SYNME6 SYNME7 SYNMSG T T_2M T_ANAI T_B1_LK T_BOT_LK T_BS_LK T_CL T_G T_ICE T_M T_MNW_LK T_S T_SNOW T_SNOW_M T_SO T_WML_LK TCH TCM TD_2M THBS_RAD THBT_RAD THHR_RAD TINC_LH TKE TKE_CON TKETENS TKVH TKVM TO3 TOP_CON TOT_PR TOTFORCE_S TQC TQC_ANAI TQG TQH TQI TQR TQS TQV TQV_ANAI TRA_SUM TWATER U U_10M UMFL_S USTR_SSO V V_10M VDIS_SSO VIO3 VMFL_S VORTIC_U VORTIC_V VORTIC_W VSTR_SSO W W_CL W_G1 W_G2 W_G3 W_I W_SNOW W_SNOW_M W_SO W_SO_ICE WLIQ_SNOW Z0 ZHD ZTD ZWD "

# constant variables
const_list=('FR_LAND' 'HSURF')

#additional variables
add_list="SP_10M ASWD_S ASOU_T FR_SNOW RUNOFF_T PREC_CON TOT_SNOW TQW"

aggregate_list="TMAX_2M TMIN_2M"

#-----------------------------------------------------------------------

# create subdirectory for full time series
mkdir -p ${OUTDIR2}
#Create and change to WORKDIR
mkdir -p ${WORKDIR} 
cd ${WORKDIR}
#################################################
YY=$YYA

#copy constant variables
for constVar in "${const_list[@]}"; do
    if [[ ! -f ${OUTDIR2}/${constVar}/${constVar}.nc ]] || ${overwrite}; then
      if [[ -f ${INDIR2}/${constVar}.nc ]]; then
          echon "Copy constant variable ${constVar}.nc to output folder"
          mkdir -p ${OUTDIR2}/${constVar}
          cp ${INDIR2}/${constVar}.nc ${OUTDIR2}/${constVar}/
      else
          echo "Required constant variable file ${constVar}.nc is not in input folder ${INDIR2}! Skipping this variable..."
      fi
    fi
done


while [[ ${YY} -le ${YYE} ]]; do      # year loop
  echo ""
  echo "####################"
  echo ${YY}
  echo "####################"
  DATE1=$(date +%s)
	
  #check if directories for all months exist
  MMA=1 #first month of each yearly time-series
  MME=12 #last month of each yearly time-series
  MM=${MMA}
  start=true
  endmonth=${MME}
  
  while [[ ${MM} -le ${endmonth} ]]; do

      if [[ $MM -lt 10 ]]; then
	  date_dir="${INDIR2}/${YY}_0${MM}"
      else
	  date_dir="${INDIR2}/${YY}_${MM}"
      fi

      if [[ ! -d $date_dir ]]; then 
          echo "Directory ${date_dir} does not exist!"

	  if ${start}; then
              MMA=$(($MMA+1))
          else
	      MME=$(($MMA-1))
          fi
      else
          start=false
      fi
      
      MM=$(($MM+1))
  done

  if [[ $MMA -lt 10 ]]; then
      MMA="0${MMA}"
  else
      MMA="${MMA}"
  fi


  if [[ "${proc_all}" != 'true' ]]; then 
      FILES=${proc_list} 
  else
      FILES=$(ls ${INDIR2}/${YY}_${MMA}/*_ts.nc)
  fi
  

  if [[ ${LFILE} -ne 2 ]]; then 
  # concatenate monthly files to annual file
    for FILE in ${FILES}; do        # var name loop
      FILEIN=$(basename ${FILE})
      
      if  ${proc_all}; then  
	  c2=$((${#FILEIN}-6))
          FILEOUT=$(echo ${FILEIN} | cut -c1-${c2}) # cut off "_ts.nc"
      else
          FILEOUT=${FILE} 
      fi
      
      varname=${FILEOUT} 
      
      #process variable if in proc_list or if proc_all is set
      if [[ ${proc_list} =~ ${varname} ]] || ${proc_all}; then
        if ls ${OUTDIR2}/${FILEOUT}/${FILEOUT}_${YY}* 1> /dev/null 2>&1; then
          if ${overwrite}; then
            echon ""
            echon ${FILEOUT}
            echon "File for variable ${FILEOUT} and year ${YY} already exists. Overwriting..."
          else
            echov ""
            echov "File for variable ${FILEOUT} and year ${YY} already exists. Skipping..."
            continue
          fi
        else
          echon ""
          echon ${FILEOUT}
        fi

      else
        continue
      fi
      
      #cut off pressure level information from FILEOUT to find it in acc_list or inst_list
      #MED 20/05/19>>
      #and cut off height level information from FILEOUT to find it in acc_list or inst_list
      if [[ "${FILEOUT: -1}" == "p" || "${FILEOUT: -1}" == "z" ]]; then
        if [[ ${FILEOUT} == *1000* ]]; then
          (( c2 = ${#FILEOUT}-5 ))
        else
          (( c2 = ${#FILEOUT}-4 ))
        fi
        varname=$(echo ${FILEOUT} | cut -c1-${c2})
      fi
      #MED<<

      # determine if current variable is an accumulated or instantaneous quantity
      if [[ ${accu_list} =~ ${varname} ]]; then
          LACCU=1
          echon "${varname} is accumulated variable"
      elif [[ ${inst_list} =~ ${varname} ]]; then
          LACCU=0
          echon "${varname} is an instantaneous variable"
      elif [[ ${add_list} =~ ${varname} ]]; then
          continue
      elif [[ ${aggregate_list} =~ ${varname} ]]; then
	  continue
      else
          echo "Error for ${varname}: neither contained in accu_list nor in inst_list! Skipping..."
          continue
      fi

      FILELIST=""
      MA=${MMA}
      ME=${MME}
      MM=${MA}
       
      while [[ ${MM} -le ${ME} ]]; do
	
	if [[ $MM -lt 10 ]] && [[ ${#MM} -lt 2 ]]; then
	    ts_file="${INDIR2}/${YY}_0${MM}/${FILEOUT}_ts.nc"
	else
            ts_file="${INDIR2}/${YY}_${MM}/${FILEOUT}_ts.nc"
	fi

        if [[ ! -f $ts_file ]]; then
            echo "WARNING: File ${ts_file} does not exist! Continue anyway..."
            #continue 2
        fi
        FILELIST="$(echo ${FILELIST}) $(ls $ts_file)"
        (( MM=MM+1 ))
      done

      echon "Concatenate files"
      echov "${FILELIST}"
      
      # concatenate monthly files to yearly file
      if [[ $MA -lt 10 ]] && [[ ${#MA} -lt 2 ]]; then
          MA_string="0${MA}"
      else
	  MA_string="${MA}"
      fi

      if [[ $ME -lt 10 ]] && [[ ${#ME} -lt 2 ]]; then
          ME_string="0${ME}"
      else
          ME_string="${ME}"
      fi

      FILEIN=${FILEOUT}_${YY}${MA_string}-${YY}${ME_string}.nc
      ncrcat -O -h ${FILELIST} ${FILEIN}
      
      # extract attribute units from variable time -> REFTIME in seconds since XX-XX-XX ...
      #MED>>RT=$(ncks -m -v time ${FILEIN} | grep -E 'time '|grep -E 'seconds since' | cut -f 13- -d ' ')
      RT=$(ncks -m -v time  ${FILEIN} | grep -E 'time:units' | cut -d '"' -f 2 | cut -d ' ' -f 3-4)
      #MED<<
      REFTIME="days since "${RT}
      
      # extract number of timesteps and timestamps
      NT=$(cdo -s ntime ${FILEIN})
      VT=($(cdo -s showtimestamp ${FILEIN}))
      TYA=$(echo ${VT[0]} | cut -c1-4)
      TMA=$(echo ${VT[0]} | cut -c6-7)
      TDA=$(echo ${VT[0]} | cut -c9-10)
      THA=$(echo ${VT[0]} | cut -c12-13)
      TDN=$(echo ${VT[1]} | cut -c9-10)
      THN=$(echo ${VT[1]} | cut -c12-13)
      TYE=$(echo ${VT[-1]} | cut -c1-4)
      TME=$(echo ${VT[-1]} | cut -c6-7)
      TDE=$(echo ${VT[-1]} | cut -c9-10)
      THE=$(echo ${VT[-1]} | cut -c12-13)
      (( DHH=(TDN-TDA)*24+THN-THA ))
      (( EHH=24-DHH ))
      (( DTS=DHH*1800 ))
      echov "First date: ${VT[0]} "
      echov "Last date: ${VT[-1]} "
      echov "Number of timesteps: $NT"
      echov "Time step: $DHH h"
      echov "New reference time: ${REFTIME}"
      
      #create output directory
      mkdir -p ${OUTDIR2}/${FILEOUT}
      
      if [[ ${LACCU} -eq 1 ]]; then
      # Check dates in files for accumulated variables
      # if necessary: delete first date apend first date of next year
        if [[ ${TDA} -eq 01 && ${THA} -eq 00 ]]; then
            echov "Eliminating first time step from tmp1-File"
            ncks -O -h -d time,1, ${FILEIN} ${FILEOUT}_tmp1_${YY}.nc
        elif [[ ${TDA} -eq 01 &&  ${THA} -eq ${DHH} ]]; then
            echov "Number of timesteps in tmp1-File is OK"
            cp ${FILEIN} ${FILEOUT}_tmp1_${YY}.nc
        else
            echo "Error: Start date  ${TDA} ${THA}"
            echo in "${FILEIN} "
            echo "is not correct! Exiting..."
            continue
        fi
        if [[ ${TDE} -ge 28 && ${THE} -eq ${EHH} ]]; then
          YP=${YY}
          (( MP=TME+1 ))

          if [[ ${MP} -gt 12 ]]; then
            MP=01
            (( YP=YP+1 ))
          fi
          FILENEXT=${INDIR2}/${YP}_${MP}/${FILEOUT}_ts.nc

          if [[ -f ${FILENEXT} ]]; then
            echov "Append first date from next month's file to the end of current month"
            ncks -O -h -d time,0 ${FILENEXT} ${FILEOUT}_tmp2_${YY}.nc
            ncrcat -O -h  ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp2_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
          else
            echo "ERROR: Tried to append first date from next month's file but"
            echo "${FILENEXT} does not exist. Skip year for this variable..."
            continue
          fi
        elif [[ ${TDE} -eq 01 &&  ${THE} -eq 00 ]]; then

          (( MP=TME ))
          (( YP=TYE ))
          echov "Last timestep in tmp3-File is OK"
          mv ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
        else
          
	  echo "ERROR: END date  ${TDE} ${THE}"
          echo in "${FILEIN} "
          echo "is not correct. Skip year for this variable..."
          continue
        fi
        
	ENDFILE=${OUTDIR2}/${FILEOUT}/${FILEOUT}_${TYA}${TMA}${TDA}00-${YP}${MP}0100.nc
        
	# shift time variable by DHH/2*3600 and transfer time from seconds in days       
        echov "Modifying time and time_bnds values and attributes"
        ncap2 -O -h -s "time_bnds=time_bnds/86400" -s "time=(time-${DTS})/86400" ${FILEOUT}_tmp3_${YY}.nc ${ENDFILE}
        ncatted -O -h -a units,time,o,c,"${REFTIME}" -a units,time_bnds,o,c,"${REFTIME}" ${ENDFILE}
      
      else
        # Check dates in files for instantaneous variables
        if [[ ${TDA} -eq 01 && ${THA} -eq 00 ]]; then
          echov "First date of instantaneous file is OK"
          cp ${FILEIN} ${FILEOUT}_tmp1_${YY}.nc          
        else
          echo "ERROR: Start date " ${TDA} ${THA}
          echo in "${FILEIN} "
          echo "is not correct.  Skip year for this variable..."
          continue       
        fi

        if [[ ${TDE} -ge 28  && ${THE} -eq ${EHH} ]]; then
          echov "Last date of instantaneous file is OK"
          mv ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
        elif  [[ ${TDE} -eq 01 && ${THE} -eq 00 ]]; then
          (( NTM=NT-2 )) 
          echov "Last date of instantaneous file is removed"
          ncks -O -h -d time,0,${NTM} ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc 
          #change TDE
          VT=($(cdo -s showtimestamp ${FILEOUT}_tmp3_${YY}.nc))
          TDE=$(echo ${VT[-1]} | cut -c9-10)
        else
          echo "ERROR: END date " ${TDE} ${THE}
          echo in "${FILEIN} "
          echo "is not correct.  Skip year for this variable..."
          echo ${EHH}
          continue       
        fi

        ENDFILE=${OUTDIR2}/${FILEOUT}/${FILEOUT}_${TYA}${TMA}${TDA}00-${YY}${ME_string}${TDE}${EHH}.nc
        # transfer time from seconds in days and remove time_bnds from instantaneous fields
        echov "Modifying time values and attributes"
        ncap2 -O -h  -s "time=time/86400" ${FILEOUT}_tmp3_${YY}.nc ${ENDFILE}
        ncks -O -C -h -x -v time_bnds ${ENDFILE} ${ENDFILE}
        ncatted -O -h -a units,time,o,c,"${REFTIME}" -a bounds,time,d,, ${ENDFILE}    
      fi


      echov "Output to $ENDFILE"
      # change permission of final file
      chmod ${PERM} ${ENDFILE}
      # clean temporary files
      rm -f ${FILEOUT}_tmp?_${YY}.nc
      rm ${FILEIN}

    done                    # var name loopend
#
  fi                              #concatenate part


  if [[ ${LFILE} -ne 1 ]]; then
    
    echon ""
    echon " Create additional fields for CORDEX"

    # Mean wind spdeed at 10m height: SP_10M
    create_add_vars "U_10M" "V_10M" "SP_10M" "add_sqr" "wind_speed"
    
    # Total downward global shortwave radiation at the surface: ASWD_S
    create_add_vars "ASODIR_S" "ASODIFD_S" "ASWD_S" "add" "surface_downwelling_shortwave_flux_in_air" 

    # Total downward global longwave radiation at the surface:
    create_add_vars "ATHB_S" "ATHU_S" "ATHD_S" "add" "surface_downwelling_longwave_flux_in_air"

    # TMAX_2M
    aggregate_vars "T_2M" "TMIN_2M" "min" "air_temperature"

    # TMIN_2M
    aggregate_vars "T_2M" "TMAX_2M" "max" "air_temperature"
    
    # upward solar radiation at TOA: ASOU_T
    # create_add_vars "ASOD_T" "ASOB_T" "ASOU_T" "subs" "averaged_solar_upward_radiation_top" 
    
    # Total runoff: RUNOFF_T
    # create_add_vars "RUNOFF_S" "RUNOFF_G" "RUNOFF_T" "add" "total_runoff_amount"
    
    # Total convective precipitation: PREC_CON
    # create_add_vars "RAIN_CON" "SNOW_CON" "PREC_CON" "add" "convective_precipitation_amount"
    
    # Total snow: TOT_SNOW
    # create_add_vars "SNOW_GSP" "SNOW_CON" "TOT_SNOW" "add" "total_snowfall_amount"
    
    # cloud condensed water content TQW
    # create_add_vars "TQC" "TQI" "TQW" "add" "atmosphere_cloud_condensed_water_content"  

    #MED>>
    # Mean snow fraction: FR_SNOW
    # create_add_vars "W_SNOW" "" "FR_SNOW" "snow_case" "surface_snow_area_fraction" 
    #MED<<
  fi
  
  (( YY=YY+1 ))
  DATE2=$(date +%s)
	SEC_TOTAL=$(python -c "print(${DATE2}-${DATE1})")
	echon "Time for postprocessing: ${SEC_TOTAL} s"
  done                                      # year loopend



  # Remove monthly subdirs YYYY_MM
  #YY=${YYA}
  #MM=${MMA}
  #while [[ ${YY}${MM} -le ${YYE}${MME} ]]      # year loop
  #do
  #  Remove the input files if you are shure that they are no longer needed:
  #  Files with monthly time series of single variables generated by subchain-script "post.job"
  #
  #  rm -rf ${YY}_${MM}
   # (( MM=MM+1 ))
    #if [[ ${MM} -gt 12 ]] 
    #then
    #  (( YY=YY+1 ))
     # MM=1
    #fi
  #done


