#!/bin/bash

# Author: Mikhail Stolpovskiy, mikhail.stolpovsky@gmail.com

if [[ $# -eq 2 ]]
then
    OUTPUTFILE=$1
    INPUTFILE=$2
else
    echo "shadd = super hadd!!!"
    echo ""
    echo "Use it to hadd together large number of root files (> 500)"
    echo ""
    echo "Usage: shadd out.root in.txt"
    echo "   - out.root is the name of the output root file"
    echo "   - in.txt is the name of a text file with the list of the"
    echo "     input root files. Create one with something like"
    echo "     ls myfiles_*.root > in.txt"
    echo "ATTENTION: shadd uses -f -k options by default:"
    echo "     -f recreates the existent output root file"
    echo "     -k ignores corrupted input root files"
    exit 0
fi

# import config variables (user modifiable)
source $HOME/.shadd/shadd.cfg

# calculate the number of jobs to submit
Ntot=($(wc -l $INPUTFILE))
Ntot=${Ntot[0]}
Nmax=$(($Ntot / $Nlines))

# generate random name for the jobs
name=HADD_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)

# create temporary directory to store the intermediate results
TEMPDIR=./temp_shadd_$name
mkdir -p $TEMPDIR

# logs are stored in the TEMPDIR too (by default all removed after execution)
output=$TEMPDIR/job_%j.out                                                                                             
error=$TEMPDIR/job_%j.err

# main sbatch command
echo "Submit job array to hadd the intermediate results..."
sbatch --export=ALL,HADD="$HADD",OUTPUTFILE=$OUTPUTFILE,INPUTFILE=$INPUTFILE,TEMPDIR=$TEMPDIR,Nlines=$Nlines --array=0-$Nmax%$NmaxSimultaneouslyRunning --job-name=$name --output=$output --error=$error $HOME/.shadd/submit_hadd.sh

# Interactive way
progressbar() {
 num=$1
 ntot=$2
 s=($(echo "print('|' + '='*($num - 1) + '>' + '.'*($ntot - $num) + '|')" | python3))
 echo -ne "$s\r"
}

if $interactive
then
    echo "Please wait for all the jobs to complete"
    # check that everything is done
    alldone=false
    until $alldone
    do
	sleep 1
	nrunning=($(squeue --name $name | wc -l))
	nrunning=${nrunning[0]}
	prev_perc=-1
	percentage=($(echo "print(int((${Nmax}-${nrunning}+1)/${Nmax}*${pbar_len}))" | python3))
	if (( percentage > prev_perc ))
	then
	    prev_perc=$percentage
	    progressbar $percentage $pbar_len
	fi
	if (( $nrunning == 1 ))
	then
	    alldone=true
	fi
    done
    progressbar $pbar_len $pbar_len
    echo -e "\nJobs are complete!"

    # Get resulting root file
    echo "Please wait until I hadd the intermediate root files"
    $HADD $OUTPUTFILE $TEMPDIR/*.root

    # remove TEMPDIR (modify the shadd.cfg to disable it)
    echo "Cleaning up..."
    if $rm_temp_dir
    then
	rm -rf $TEMPDIR
    fi
fi

echo "Done!"
