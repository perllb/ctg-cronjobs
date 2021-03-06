#!/bin/bash

# SCRIPT FOR CRON
# Check every runfolder in /nas-sync/upload/ - if ctg-interop-qc has not been run - run it.

# ctg-qc interop folder
ctgqc="/projects/fs1/shared/ctg-qc/interop"
cronlog="/projects/fs1/shared/ctg-cron/ctg-interop-cron/cron-ctg-interop.log"
touch $cronlog 

# Go to root runfolder 
rootfolder="/projects/fs1/nas-sync/upload"
cd $rootfolder

# Function to run ctg-interop-qc
run_interop_qc(){
    rf=$1
    cd $rf 
    echo "y" | /projects/fs1/shared/ctg-tools/bin/ctg-interop-qc >> $cronlog
    chmod -R 770 $rf/ctg-interop
    echo "$(date): >> executed ctg-interop-qc -> $rf" >> $cronlog
}

# Iterate over all runfolders
# See if ctg-interop (in runfolder) 
#     or multiqc _data/.html in ctg-qc/interop 
# is missing 
for runfolder in $(ls | grep "^2"); do

    cd $rootfolder

    interopdone=1 # set to 0 if one of the files are missing
    
    if [ -f $rootfolder/$runfolder/sync.done ] || [ -f $rootfolder/$runfolder/ctg.sync.done ] ; then

	if [ ! -d $rootfolder/$runfolder/ctg-interop ]; then
	    echo "$(date): $runfolder has no ctg-interop folder " >> $cronlog    
	    interopdone=0
	fi
	
	if [ ! -f $ctgqc/multiqc_ctg_interop_${runfolder}.html ]; then
	    echo "$(date): $runfolder has no ctg-qc/interop multiqc .html " >> $cronlog
	    interopdone=0
	fi
	
	if [ ! -d $ctgqc/multiqc_ctg_interop_${runfolder}_data ]; then
	    echo "$(date): $runfolder has no ctg-qc/interop multiqc _data " >> $cronlog
	    interopdone=0
	fi
	
	if [ $interopdone == 0 ]; then
	    run_interop_qc "$rootfolder/$runfolder"
	fi
    fi
	    
done


