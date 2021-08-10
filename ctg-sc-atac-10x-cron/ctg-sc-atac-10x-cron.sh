#!/bin/bash

# SCRIPT FOR CRON TO START SC-ATAC-10x analysis from runfolders
# Check every runfolder in /nas-sync/upload/ 
# - if CTG_SampleSheet.sc-atac-10x.csv exists
# - and no ctg.sc-atac.10x.start OR no ctg.sc-atac.10x.done exists in runfolder
# Start sc-atac-10x-driver

# ctg-qc interop folder
cronlog="/projects/fs1/shared/ctg-cron/ctg-sc-atac-10x-cron/log.ctg-sc-atac-10x.log"

# Go to root runfolder 
rootfolder="/projects/fs1/nas-sync/upload"
cd $rootfolder

# sc-atac-10x-driver
scdriver="/projects/fs1/shared/ctg-cron/ctg-sc-atac-10x-cron/sc-atac-10x-crondriver"

# Function to run ctg-sc-atac-10x-driver
run_scatac10x(){
    rf=$1
    cd $rf 
    touch $rf/ctg.sc-atac-10x.start
    $scdriver >> $cronlog
    echo "**CRON** $(date): >> started ctg-sc-atac-10x -> $rf" >> $cronlog
}

# Iterate over all runfolders
# - Check if current files exist in runfolder:
# - ctg.sync.done 
# - ctg.sc-atac-10x.start 
# - ctg.sc-atac-10x.done
# - CTG_SampleSheet.sc-atac-10x.csv
 

for runfolder in $(ls | grep "^2"); do

    cd $rootfolder

    runpipe=0 # set to 1 if all the following files exist
    
    # If CTG_SampleSheet.sc-atac-10x.csv
    if [ -f $rootfolder/$runfolder/CTG_SampleSheet.sc-atac-10x.csv ]; then
	#echo "$(date): $runfolder : CTG_SampleSheet.sc-atac-10x.csv exist.." 
	runpipe=0
	# If sync is complete
	if [ -f $rootfolder/$runfolder/sync.done ] || [ -f $rootfolder/$runfolder/ctg.sync.done ] ; then
	 #   echo "$(date): $runfolder: sync done" 
	    runpipe=0
	    # If sc-atac-10x is not run or started
	    if [ -f $rootfolder/$runfolder/ctg.sc-atac-10x.start ] || [ -f $rootfolder/$runfolder/ctg.sc-atac-10x.done ] ;  then
	#	echo "$(date): $runfolder : has already sc-atac-10x started / is done " 
		runpipe=0
	    # If sc-atac-10x is not started / run - set to run
	    else 
		echo "**CRON** $(date): $runfolder : sc-atac-10x is not yet run -> start!" >> $cronlog
		runpipe=1
	    fi
	fi
    fi

    if [ $runpipe == 1 ]
    then
	run_scatac10x "$rootfolder/$runfolder"
    fi
	    
done


