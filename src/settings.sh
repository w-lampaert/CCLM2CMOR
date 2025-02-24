#!/bin/bash -l

#-------------------------------------------------------------------------
# Settings for the first step of the CMOR process
# 
# Matthias Göbel 
#
#-------------------------------------------------------------------------

post_step=2 # to limit post processing to step 1 or 2, for all other values both steps are executed

# Simulation details used for creating a directory structure 
GCM=ERA5 # driving GCM
EXP=CB2_CCLM_EUR11_ERA5_evaluation   # driving experiment name

#-------------------------------------------
# Time settings

# processing range for step 1:
START_DATE=197901 # Start year and month for processing (if not given in command line YYYYMM)
STOP_DATE=202401  # End year and month for processing (if not given in command line YYYYMM)

# for step 2 (if different from step 1:
YYA= # Start year for processing YYYY
YYE= # End year for processing YYYY

#-------------------------------------------
# Directory path settings

export BASEDIR=${VSC_DATA}/RCS/CCLM2CMOR      # directory where the scripts are placed 
export DATADIR=/dodrio/scratch/projects/2022_200/project_output/rcs/CORDEXBE2/wouterl/cmorization_tests             # directory where all the data will be placed (typically at /scratch/)
ARCH_BASE=/dodrio/scratch/projects/2022_200/project_output/rcs/CORDEXBE2/fiens/CB2_CCLM_EUR11_ERA5_evaluation/cclm/out # directory where the raw data of the simulations are archived

# scripts directory
SRCDIR=${BASEDIR}/src                # directory where the post processing scripts are stored
SRCDIR_POST=${BASEDIR}/src/cclm_post # directory where the subscripts are stored

WORKDIR=${DATADIR}/work/post         # work directory, CAUTION: WITH OPTION "--clean" ALL FILES IN THIS FOLDER WILL BE DELETED AFTER PROCESSING!
LOGDIR=${BASEDIR}/logs/shell         # logging directory

# input/output directory for first step
INDIR_BASE1=${DATADIR}/input            # directory to where the raw data archives are extracted
OUTDIR_BASE1=${DATADIR}/work/outputpost # output directory of the first step

# input/output directory for second step
INDIR_BASE2=${OUTDIR_BASE1}
OUTDIR_BASE2=${DATADIR}/work/input_CMORlight

#-------------------------------------------
# Special settings for first step

num_extract=1 # number of archived years to extract/move at once (depends e.g. on the file number limit you have on your working director (scratch))
NBOUNDCUT=13   # number of boundary lines to be cut off in the time series data 
IE_TOT=446     # number of gridpoints in longitudinal direction?
JE_TOT=434     # number of gridpoints in latitudinal direction
PLEVS=(200 250 300 400 500 600 700 850 925 1000) # list of pressure levels to output IF NOT set in timeseries.sh. The list must be the same as or a subset	of the list in the specific GRIBOUT. 
ZLEVS=(50 100 150) # list of height levels to output IF NOT set in timeseries.sh.

#-------------------------------------------
# Special settings for second step
proc_list="TMAX_2M TMIN_2M" # which variables to process (set proc_all=false for this to take effect); separated by spaces
proc_all=false     # process all available variables (not only those in proc_list)
LFILE=0             # set LFILE=1 IF ONLY primary fields (given out by COSMO) should be created and =2 for only secondary fields (additionally calculated for CORDEX); for any other number both types of fields are calculated
