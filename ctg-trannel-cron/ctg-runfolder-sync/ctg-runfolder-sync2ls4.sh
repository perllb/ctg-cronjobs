#!/bin/bash

# SCRIPT FOR CRON
# Check every runfolder on hopper:
# Use mounted /trannel/ctg/fs1mnt/seqdata/
# - NovaSeq/
# - NextSeq1/
# - NextSeq2/ 
#
# 1. Check for 'CTG_SampleSheet.*' in runfolder
# 2. Check for absence of ctg.sync.done / '*sync.done'
# 3. sync

# root mount folder
fs1seq="/trannel/ctg/fs1mnt/seqdata"

# root cron folder
crondir="/trannel/ctg/cronjobs/ctg-runfolder-sync-ls4"
cronlog="${crondir}/log.ctg.runfolder.snc.ls4"

# Check if /fs1/ is mounted
if [ ! -d $fs1seq ]
then
    echo "$(date) : $fs1seq is not mounted! Mounting again" >> $cronlog
    echo "$(date) :  > sshfs -ro rs-fs1:/fs1/ /trannel/ctg/fs1mnt" >> $cronlog
    sshfs -o ro rs-fs1:/fs1/ /trannel/ctg/fs1mnt 
fi

Novadir="${fs1seq}/NovaSeq/"
Next1dir="${fs1seq}/NextSeq1/"
Next2dir="${fs1seq}/NextSeq2/"

# folder to store ctg-rsnc-ls4 logs
synclogs="${crondir}/synclogs/"

# Function to sync runfolder
sync_run(){
    rf=$1
    machine=$2
    # remove trailing / from runfolder
    newrf=$(echo $rf | sed 's/\/$//')
    baserf=$(basename $newrf)

    # Add ctg.sync.start to runfolder
    ssh rs-fs1 touch /fs1/seqdata/$machine/$baserf/ctg.sync.start

    # Sync
    RC=1
    while [[ $RC -ne 0 ]]
    do
	rsync -avz --chmod=770 --perms=770 --info=progress2 $newrf lsens-sync:/projects/fs1/nas-sync/upload/ >> $synclogs/snc.$baserf.log
	RC=$? 
    done

    # Add ctg.sync.done to runfolder and sync it to ls4
    ssh rs-fs1 touch /fs1/seqdata/$machine/$baserf/ctg.sync.done
    
    rsync -av $rf/ctg.sync.done lsens-sync:/projects/fs1/nas-sync/upload/$baserf/ >> $synclogs/snc.$baserf.log

    echo "$(date): >> $newrf: Synced to aurora-ls4.lunarc.lu.se" >> $cronlog
}

# SCAN FOR NOVA runs
cd $Novadir

scanSeqDir(){

    seqdir=$1
    cd $seqdir
    #echo "Sequence machine dir: $seqdir"
    # Get name of seqdir (Nova / NextSeq etc)
    machine=$(basename $seqdir)
    #echo "Machine: $machine"
    
    # Iterate over all runfolders in the given seqdata folder (Nova / NextSeq1 etc)
    # 1. see if "CTG_SampleSheet.*" is in runfolder (sync if it is there)
    # 2. see if "*sync.done" or "*sync.start" exist (the skip)

    for runfolder in $(ls | grep "^2"); do
	
	syncrun=0 # set to 1 if should be synced
	#echo "Runfolder: $runfolder"
	# 1. Check if "CTG_SampleSheet.*" is in runfolder
	if [ -f "$seqdir/$runfolder/CTG_SampleSheet.csv" ]
	then
	    #echo "$(date): $runfolder ($machine) has CTG_SampleSheet.csv" 
	    # If *sync.done exist
	    if [ -f "$seqdir/$runfolder/sync.done" ] || [ -f "$seqdir/$runfolder/ctg.sync.done" ]
	    then
		syncrun=0
		#echo "$(date): $runfolder ($machine) has *sync.done - Don't sync!"
	    elif [ -f "$seqdir/$runfolder/sync.start" ] || [ -f "$seqdir/$runfolder/ctg.sync.start" ]
	    then
		syncrun=0
		#echo "$(date): $runfolder ($machine) has *sync.start - Don't sync!"
	    else
		#echo "$(date): $runfolder ($machine) should be synced: CTG_SampleSheet.csv AND no sync.done/start."
		syncrun=1
	    fi

	fi

	if [ $syncrun == 1 ]
	then
	    sync_run $seqdir/$runfolder $machine
	fi
	
    done
}

scanSeqDir $Novadir
scanSeqDir $Next1dir
scanSeqDir $Next2dir


