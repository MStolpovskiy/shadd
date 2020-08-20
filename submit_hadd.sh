#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --partition=centos7
#SBATCH --export=ALL

echo "INPUTFILE = $INPUTFILE"
echo "Nlines = $Nlines"

# Extract Nlines from the file list to a temporary file
FILETOANALYSE=$TEMPDIR/$(basename -- $INPUTFILE .txt)_$SLURM_ARRAY_TASK_ID.txt
sed -n $(($SLURM_ARRAY_TASK_ID * $Nlines + 1)),$(($SLURM_ARRAY_TASK_ID * $Nlines + $Nlines))p $INPUTFILE > $FILETOANALYSE

echo "FILETOANALYSE = $FILETOANALYSE"

TEMPOUTPUTFILE="$TEMPDIR/$(basename -- $FILETOANALYSE .txt).root"

COMMAND="hadd -f -k $TEMPOUTPUTFILE `cat $FILETOANALYSE`"

echo $PATH

echo $COMMAND

$COMMAND

