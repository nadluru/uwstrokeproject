#!/bin/bash

echo "Setting up environment."
tar -xzf python.tar.gz
export mrtrix3=$(pwd)/mrtrix3
export pythondir=$(pwd)/python
export PATH=$pythondir/bin:$mrtrix3/bin:$PATH

echo "Installing fsl."
python fslinstaller.py -d $(pwd)/fsl -V 5.0.11

export FSLDIR=$(pwd)/fsl
export FSLOUTPUTTYPE=NIFTI_GZ
export PATH=$FSLDIR/bin:$PATH
export OMP_NUM_THREADS=12
chmod -R a=wrx $FSLDIR/bin
chmod -R a=wrx $mrtrix3/bin

echo "Initializing the variables."
dwi=$1

prefix=${dwi%.mif*}
echo "Running dwipreproc."
python $mrtrix3/bin/dwipreproc $dwi ${prefix}_dwi_preprocessed.mif -rpe_none -pe_dir AP -eddy_options "--slm=linear --data_is_shelled" -eddyqc_all ${prefix}_eddyqcdir -tempdir ${prefix}_tmp -force -nocleanup

echo "Cleaning up the compute node."
rm -rf $mrtrix3 $FSLDIR $pythondir
rm -f $dwi python.tar.gz

