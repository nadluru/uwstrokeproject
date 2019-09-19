#!/bin/bash
dwi=$1
jobnum=$2
total=$3
submit=$HOME/StrokeAndDiffusionProject/uwstrokeproject/DWICorrectLocal.submit
executable=$HOME/StrokeAndDiffusionProject/uwstrokeproject/DWICorrectLocal.sh

args="$(basename $dwi)"
job=$(basename $dwi .mif)
initialDir=$initroot/${job}Preproc
mkdir -p $initialDir

echo "#JOB $jobnum/$total"
echo "JOB $job $submit"
#echo "VARS $job executable = \"$executable\""
echo "VARS $job initialDir = \"$initialDir\""
echo "VARS $job logFile = \"${job}.log\""
echo "VARS $job errFile = \"${job}.err\""
echo "VARS $job outFile = \"${job}.out\""
echo ""
echo "VARS $job args = \"$dwi\""
echo ""
