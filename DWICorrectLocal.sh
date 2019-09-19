#!/bin/bash
echo "Initializing the variables."
export OMP_NUM_THREADS=6
dwi=$1

prefix=${dwi%.mif*}
echo "Running dwipreproc."
dwipreproc $dwi ${prefix}_dwi_preprocessed.mif -rpe_none -pe_dir AP -eddy_options "--slm=linear --data_is_shelled" -eddyqc_all ${prefix}_eddyqcdir -tempdir ${prefix}_tmp -force -nocleanup

