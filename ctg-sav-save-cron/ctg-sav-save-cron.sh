#!/bin/bash

# SCRIPT FOR CRON
# Check every runfolder in /nas-sync/upload/ - if ctg-sav-save has not been run - run it.

# ctg-qc sav-save folder
ctgqc="/projects/fs1/shared/ctg-qc/sav-illumina/"
cronlog="/projects/fs1/shared/ctg-cron/ctg-sav-save-cron/cron-ctg-sav-save.log"
touch $cronlog 

# Go to root runfolder 
rootfolder="/projects/fs1/nas-sync/upload"
cd $rootfolder

# Function to run ctg-interop-qc
run_sav_save(){
    rf=$1
    cd $rf 
    echo "y" | /projects/fs1/shared/ctg-tools/bin/ctg-sav-save >> $cronlog
    echo "$(date): >> executed ctg-sav-save -> $rf" >> $cronlog
}

# Iterate over all runfolders
# See if ctg_SAV_saved_<runfolder>.done exist (in runfolder) 
# See if files in ctg-qc/sav-illumina exist
for runfolder in $(ls | grep "^2"); do

    cd $rootfolder

    savdone=1 # set to 0 if one of the files are missing
    
    if [ -f $rootfolder/$runfolder/sync.done ] || [ -f $rootfolder/$runfolder/ctg.sync.done ] ; then

	# in runfolder
	if [ ! -f $rootfolder/$runfolder/ctg_SAV_saved_$runfolder.done ]; then
	    echo "$(date): $runfolder has no ctg_SAV_saved_${runfolder}.done file " >> $cronlog    
	    savdone=0
	fi
	
	# in ctg-qc/sav-illumina
	currctgqc="$ctgqc/ctg_SAV_$runfolder"
	if [ ! -d $currctgqc ]; then
	    echo "$(date): $runfolder has no ctg-qc/sav-illumina/ctg_SAV_$runfolder folder " >> $cronlog
	    savdone=0
	fi

	if [ ! -f $currctgqc/RunInfo.xml ]; then
	    echo "$(date): $runfolder has no ctg-qc/sav-illumina/ctg_SAV_$runfolder/RunInfo.xml file " >> $cronlog
	    savdone=0
	fi

	if [ ! -f $currctgqc/RunParameters.xml ]; then
	    echo "$(date): $runfolder has no ctg-qc/sav-illumina/ctg_SAV_$runfolder/RunParameters.xml file " >> $cronlog
	    savdone=0
	fi

	if [ ! -d $currctgqc/InterOp ]; then
	    echo "$(date): $runfolder has no ctg-qc/sav-illumina/ctg_SAV_$runfolder/InterOp folder " >> $cronlog
	    savdone=0
	fi

	
	if [ $savdone == 0 ]; then
	    run_sav_save "$rootfolder/$runfolder"
	fi
    fi
	    
done


