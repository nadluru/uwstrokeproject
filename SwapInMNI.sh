#!/bin/bash

# command line args
t1w=$1
alm=$2

# variable names
outdir=/study/utaut2/T1WIAnalysisNA/RSNA2019FinalSetForAnalysis/tomni
pre=$outdir/$(basename $t1w .nii.gz)
alminmni=${pre}_ALM_in_MNI
almcontra=${alminmni}_swapx_in_native
refimg=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz

# actual work
flirt -ref $refimg -in $t1w -omat ${pre}_affine_transf.mat
fnirt --in=$t1w --aff=${pre}_affine_transf.mat --cout=${pre}_nonlinear_transf --config=T1_2_MNI152_1mm
applywarp --ref=$refimg --in=$t1w --warp=${pre}_nonlinear_transf --out=${pre}_warped_structural
applywarp --ref=$refimg --in=$alm --warp=${pre}_nonlinear_transf --out=$alminmni --interp=nn
invwarp --ref=$t1w --warp=${pre}_nonlinear_transf --out=${pre}_nonlinear_transf_inv
fslswapdim $alminmni -x y z ${alminmni}_swapx
applywarp --ref=$t1w --in=${alminmni}_swapx --warp=${pre}_nonlinear_transf_inv --out=$almcontra --interp=nn
