#!/bin/bash

cd /study/utaut2/T1WIAnalysisNA/Utah/dwi

# CSD calculations =======
dwidenoise -noise Noise.nii.gz -datatype float64 dwi.nii.gz DWIDenoised.nii.gz -force
mrdegibbs DWIDenoised.nii.gz DWIDenoisedDeGibbs.nii.gz -force
dwifslpreproc DWIDenoisedDeGibbs.nii.gz DWIDenoisedDeGibbsEddyTopup.mif -pe_dir AP -rpe_all -readout_time 0.110088 -eddyqc_all EddyQCDir -fslgrad bvecs.bvec bvals.bval -scratch EddyTopupScratch -force -nocleanup -nthreads 24
dwibiascorrect ants DWIDenoisedDeGibbsEddyTopup.mif DWIDenoisedDeGibbsEddyTopupB1BC.mif -force
mrcalc -force Noise.nii.gz -finite Noise.nii.gz 0 -if NoiseLowb.mif -force
mrcalc DWIDenoisedDeGibbsEddyTopupB1BC.mif 2 -pow NoiseLowb.mif 2 -pow -sub -abs -sqrt - | mrcalc - -finite - 0 -if DWIDenoisedDeGibbsEddyTopupB1BCRC.mif -force
dwiextract DWIDenoisedDeGibbsEddyTopupB1BCRC.mif -bzero - | mrmath - mean MeanB0.nii.gz -axis 3
bet MeanB0 MeanB0BET -f 0.3 -R -m
dwi2response -mask MeanB0BET_mask.nii.gz dhollander DWIDenoisedDeGibbsEddyTopupB1BCRC.mif sfwm.txt gm.txt csf.txt -force
dwi2fod -mask MeanB0BET_mask.nii.gz -lmax 10,0,0 msmt_csd DWIDenoisedDeGibbsEddyTopupB1BCRC.mif sfwm.txt FOD_WM.mif gm.txt FOD_GM.mif csf.txt FOD_CSF.mif -force
mtnormalise FOD_WM.mif FODNorm_WM.mif FOD_GM.mif FODNorm_GM.mif FOD_CSF.mif FODNorm_CSF.mif -mask MeanB0BET_mask.nii.gz -force
tckgen FODNorm_WM.mif Tractogram.tck -backtrack -maxlength 250 -power 0.33 -select 5M -seed_dynamic FODNorm_WM.mif -force -nthreads 24

# region Tensor calculations =========
dwi2tensor -mask MeanB0BET_mask.nii.gz DWIDenoisedDeGibbsEddyTopupB1BCRC.mif Tensor.mif -force
tensor2metric Tensor.mif -fa FA.nii.gz -adc ADC.nii.gz -rd RD.nii.gz -force
# endregion