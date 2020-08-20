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

source $HOME/.shadd/shadd.cfg

Ntot=($(wc -l $INPUTFILE))
Ntot=${Ntot[0]}
Nmax=$(($Ntot / $Nlines))

name=HADD

TEMPDIR=./temp_shadd_$name
mkdir -p $TEMPDIR

output=$TEMPDIR/job_%j.out                                                                                             
error=$TEMPDIR/job_%j.err

sbatch --export=ALL,OUTPUTFILE=$OUTPUTFILE,INPUTFILE=$INPUTFILE,TEMPDIR=$TEMPDIR,Nlines=$Nlines --array=0-$Nmax%$NmaxSimultaneouslyRunning --job-name=$name --output=$output --error=$error $HOME/.shadd/submit_hadd.sh

alldone=false

until $alldone
do
     sleep 1
     nrunning=($(squeue --name $name | wc -l))
     nrunning=${nrunning[0]}
     if (( $nrunning == 1 ))
     then
	 alldone=true
     fi
done

hadd -f -k $OUTPUTFILE $TEMPDIR/*.root

if $rm_temp_dir
then
    rm -rf $TEMPDIR
fi
