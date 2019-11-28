#!/bin/bash

# command line args
t1w=$1
alm=$2
outdir=$3

# variable names
pre=$outdir/$(basename $t1w .nii.gz)
alminmni=${pre}_ALM_in_MNI
almcontra=${alminmni}_swapx_in_native
refimg=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz

# actual work
mkdir -p $outdir
applywarp --ref=$refimg --in=$alm --warp=${pre}_nonlinear_transf --out=$alminmni --interp=nn
fslswapdim $alminmni -x y z ${alminmni}_swapx
applywarp --ref=$t1w --in=${alminmni}_swapx --warp=${pre}_nonlinear_transf_inv --out=$almcontra --interp=nn
