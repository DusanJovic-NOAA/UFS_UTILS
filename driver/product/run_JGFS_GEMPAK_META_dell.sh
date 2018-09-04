#!/bin/sh

#BSUB -J gfs_gempak_meta_00
#BSUB -o /gpfs/dell2/ptmp/Boi.Vuong/output/gfs_gempak_meta_00.o%J
#BSUB -e /gpfs/dell2/ptmp/Boi.Vuong/output/gfs_gempak_meta_00.o%J
#BSUB -q debug
#BSUB -cwd /gpfs/dell2/ptmp/Boi.Vuong/output
#BSUB -W 00:30
#BSUB -P GFS-T2O
#BSUB -n 28                                     # 28 tasks 
#BSUB -R span[ptile=14]                         # 14 task per node
#BSUB -R affinity[core(1):distribute=balance]   # using 14 cores on node and bind to 1
                                                # core per task and distribute across sockets

export KMP_AFFINITY=disabled

export PDY=`date -u +%Y%m%d`

export PDY=20180903

export PDY1=`expr $PDY - 1`

# export cyc=06
export cyc=00
export cycle=t${cyc}z

set -xa
export PS4='$SECONDS + '
date

####################################
##  Load the GRIB Utilities module
#####################################
module load EnvVars/1.0.2
module load ips/18.0.1.163
module load CFP/2.0.1
module load impi/18.0.1
module load lsf/10.1
module load prod_util/1.1.0
module load prod_envir/1.0.2
#
#   This is a test version of GRIB_UTIL.v1.1.0 on DELL
#
module load dev/grib_util/1.1.0
###########################################
# Now set up GEMPAK/NTRANS environment
###########################################
module use -a /gpfs/dell1/nco/ops/nwpara/modulefiles/
module load gempak/7.3.1
module list

##############################################
# Define COM, COMOUTwmo, COMIN  directories
##############################################
# set envir=prod or para to test with data in prod or para
 export envir=para
# export envir=prod

export SENDCOM=YES
export KEEPDATA=YES
export job=gfs_gempak_meta_${cyc}
export pid=${pid:-$$}
export jobid=${job}.${pid}

# Set FAKE DBNET for testing
export SENDDBN=YES
export DBNROOT=/gpfs/hps/nco/ops/nwprod/prod_util.v1.0.24/fakedbn

export DATAROOT=/gpfs/dell2/ptmp/Boi.Vuong/output
export NWROOT=/gpfs/dell2/emc/modeling/noscrub/Boi.Vuong/git
export COMROOT2=/gpfs/dell2/ptmp/Boi.Vuong/com

mkdir -m 775 -p ${COMROOT2} ${COMROOT2}/logs ${COMROOT2}/logs/jlogfiles 
export jlogfile=${COMROOT2}/logs/jlogfiles/jlogfile.${jobid}

#############################################
#set the fcst hrs for all the cycles
#############################################
export fhbeg=00
export fhend=384
export fhinc=12

#############################################################
# Specify versions
#############################################################
export gfs_ver=v15.0.0

##########################################################
# obtain unique process id (pid) and make temp directory
##########################################################
export DATA=${DATA:-${DATAROOT}/${jobid}}
mkdir -p -m 775 $DATA
cd $DATA

################################
# Set up the HOME directory
################################
export HOMEgfs=${HOMEgfs:-${NWROOT}/gfs.${gfs_ver}}
export EXECgfs=${EXECgfs:-$HOMEgfs/exec}
export PARMgfs=${PARMgfs:-$HOMEgfs/parm}
export FIXgfs=${FIXgfs:-$HOMEgfs/gempak/fix}
export USHgfs=${USHgfs:-$HOMEgfs/gempak/ush}
export SRCgfs=${SRCgfs:-$HOMEgfs/scripts}

###################################
# Specify NET and RUN Name and model
####################################
export NET=${NET:-gfs}
export RUN=${RUN:-gfs}
export model=${model:-gfs}

##############################################
# Define COM directories
##############################################
if [ $envir = "prod" ] ; then
#  This setting is for testing with GFS (production)
  export COMIN=/gpfs/hps/nco/ops/com/nawips/prod/gfs.${PDY}
  export COMROOT=/gpfs/hps/nco/ops/com

else
#  export COMIN=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/gfs.${PDY}/${cyc}/nawips   ### EMC PARA Realtime
#  export COMINgempak=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1                          ### EMC PARA Realtime

  export COMIN=/gpfs/dell2/emc/modeling/noscrub/Boi.Vuong/git/${NET}/${envir}/${RUN}.${PDY}/${cyc}/nawips   ### Boi PARA
  export COMINgempak=/gpfs/dell2/emc/modeling/noscrub/Boi.Vuong/git/${NET}/${envir}                         ### Boi PARA
fi

export COMINukmet=${COMINukmet:-$(compath.py nawips/prod/ukmet)}
export COMINecmwf=${COMINecmwf:-$(compath.py nawips/prod/ecmwf)}
export COMINnam=${COMINnam:-$(compath.py nawips/prod/nam)}

export COMOUT=${COMROOT2}/${NET}/${envir}/${RUN}.${PDY}/${cyc}/nawips/meta

if [ ! -f $COMOUT ] ; then
  mkdir -p -m 775 $COMOUT
fi

#############################################
# run the GFS job
#############################################
sh $HOMEgfs/jobs/JGFS_GEMPAK_META
