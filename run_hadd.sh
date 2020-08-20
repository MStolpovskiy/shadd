#!/bin/bash

# Author: Mikhail Stolpovskiy, mikhail.stolpovsky@gmail.com
#

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

Nlines=200 # FIX IT!
NmaxSimultaneouslyRunning=200 # FIX IT!
Ntot=($(wc -l $INPUTFILE))
Ntot=${Ntot[0]}
Nmax=$(($Ntot / $Nlines))

TEMPDIR=./temp_shadd
mkdir -p $TEMPDIR

output=$TEMPDIR/job_%j.out                                                                                             
error=$TEMPDIR/job_%j.err 

sbatch --export=ALL,OUTPUTFILE=$OUTPUTFILE,INPUTFILE=$INPUTFILE,TEMPDIR=$TEMPDIR,Nlines=$Nlines --array=0-$Nmax%$NmaxSimultaneouslyRunning --output=$output --error=$error $HOME/.shadd/submit_hadd.sh
