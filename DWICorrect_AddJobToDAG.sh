#!/bin/bash
dwi=$1
submit=$HOME/uwstrokeproject/DWICorrect.submit

mrtrix=$HOME/mrtrix3
fslinstaller=$HOME/fslinstaller.py
pythontar=$HOME/CHTCPython/python.tar.gz

transferInputFiles="$dwi,$mrtrix,$fslinstaller,$pythontar"

args="$(basename $dwi)"

job=$(basename $dwi .mif)
initialDir=$initroot/${job}Preproc
mkdir -p $initialDir

transferOutputFiles="${job}_dwi_preprocessed.mif,${job}_eddyqcdir,${job}_tmp"

echo "JOB $job $submit"
echo "VARS $job initialDir = \"$initialDir\""
echo "VARS $job logFile = \"${job}.log\""
echo "VARS $job errFile = \"${job}.err\""
echo "VARS $job outFile = \"${job}.out\""
echo ""
echo "VARS $job args = \"$args\""
echo "VARS $job transferInputFiles = \"$transferInputFiles\""
echo "VARS $job transferOutputFiles = \"$transferOutputFiles\""
echo ""
