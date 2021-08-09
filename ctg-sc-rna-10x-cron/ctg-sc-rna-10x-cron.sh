#!/bin/bash

# SCRIPT FOR CRON TO START SC-RNA-10x analysis from runfolders
# Check every runfolder in /nas-sync/upload/ 
# - if CTG_SampleSheet.sc-rna-10x.csv exists
# - and no ctg.sc-rna.10x.start OR no ctg.sc-rna.10x.done exists in runfolder
# Start sc-rna-10x-driver

# ctg-qc interop folder
cronlog="/projects/fs1/shared/ctg-cron/ctg-sc-rna-10x-cron/log.ctg-sc-rna-10x.log"

# Go to root runfolder 
rootfolder="/projects/fs1/nas-sync/upload"
cd $rootfolder

# sc-rna-10x-driver
scdriver="/projects/fs1/shared/ctg-cron/ctg-sc-rna-10x-cron/sc-rna-10x-crondriver"

# Function to run ctg-sc-rna-10x-driver
run_scrna10x(){
    rf=$1
    cd $rf 
    touch $rf/ctg.sc-rna-10x.start
    echo "y" | $scdriver >> $cronlog
    echo "$(date): >> started ctg-sc-rna-10x -> $rf" >> $cronlog
}

# Iterate over all runfolders
# - Check if current files exist in runfolder:
# - ctg.sync.done 
# - ctg.sc-rna-10x.start 
# - ctg.sc-rna-10x.done
# - CTG_SampleSheet.sc-rna-10x.csv
 

for runfolder in $(ls | grep "^2"); do

    cd $rootfolder

    runpipe=0 # set to 1 if all the following files exist
    
    # If CTG_SampleSheet.sc-rna-10x.csv
    if [ -f $rootfolder/$runfolder/CTG_SampleSheet.sc-rna-10x.csv ]; then
	echo "$(date): $runfolder : CTG_SampleSheet.sc-rna-10x.csv exist.." 

	# If sync is complete
	if [ -f $rootfolder/$runfolder/sync.done ] || [ -f $rootfolder/$runfolder/ctg.sync.done ] ; then
	    echo "$(date): $runfolder: sync done" 

	    # If sc-rna-10x is not run or started
	    if [ -f $rootfolder/$runfolder/ctg.sc-rna-10x.start ] || [ -f $rootfolder/$runfolder/ctg.sc-rna-10x.done ] ;  then
		echo "$(date): $runfolder : has already sc-rna-10x started / is done " 

	    # If sc-rna-10x is not started / run - set to run
	    else 
		echo "$(date): $runfolder : sc-rna-10x is not yet run -> start!" >> $cronlog
		runpipe=1
	    fi
	fi
    fi

    if [ $runpipe == 1 ]
    then
	run_scrna10x "$rootfolder/$runfolder"
    fi
	    
done


