#!/bin/bash

# region pre-RSNA (n=16)
dataroot=/mounts/data/preprocessed/modalities/dti/Strk/
export bvecs=$dataroot/diff.bvec
export bvals=$dataroot/diff.bval

parallel -j12 --bar --plus 'mrresize -scale 0.5,0.5,1 {} - -datatype int16le -interp sinc | mrconvert - {..}_nozfi.mif -fslgrad $bvecs $bvals -force' ::: $dataroot/dti/*.nii.gz

# On cochiti.
cd /bitest/adluru/
parallel -j1 --bar 'dwipreproc {} {.}_dwi_preproc.mif -rpe_none -pe_dir AP -eddy_options "--slm=linear --data_is_shelled" -eddyqc_all ./{.}_qcdir -tempdir ./{.}_tmp/ -nocleanup -force' ::: *V1_nozfi.mif

parallel -j3 --bar dwibiascorrect {.}.mif {.}_bc.mif -ants -bias {.}_bf.mif -tempdir {.}_bc -nocleanup -force ::: *V1_nozfi_dwi_preproc.mif

parallel -j12 --bar dwi2mask {} {.}_mask.mif -force ::: *V1_nozfi_dwi_preproc_bc.mif

parallel -j12 --bar 'dwi2tensor -mask {.}_mask.mif {} - | tensor2metric - -fa {.}_fa.nii.gz -adc {.}_md.nii.gz -ad {.}_ad.nii.gz -rd {.}_rd.nii.gz -force' ::: *V1_nozfi_dwi_preproc_bc.mif

parallel -j12 --bar 'mrcalc {} 0 -ge {} 0 -if - | mrcalc - 1 -le - 0 -if {} -force' ::: *V1_nozfi_dwi_preproc_bc_fa.nii.gz

parallel -j12 --bar 'mrcalc {} 0 -ge {} 0 -if - | mrcalc - 1E3 -mul - | mrcalc - 10 -le - 0 -if {} -force' ::: *V1_nozfi_dwi_preproc_bc_?d.nii.gz

# T1 and epi_reg
cd /bitest/adluru/Strk
parallel -j12 cp {}/BRAVO*.nii /bitest/adluru/{}_BRAVO_uniform.nii ::: *V1
parallel -j12 cp {}/Acute*.nii /bitest/adluru/{}_Acute_Lesion_Mask.nii ::: *V1

cd /bitest/adluru/
parallel -j12 --bar bet {} {.}_bet -m -f 0.3 -R ::: *BRAVO_uniform.nii

parallel -j12 --bar 'dwiextract {} - -shells 0 | mrmath -axis 3 - mean {.}_b0mean.nii.gz -force' ::: *V1_nozfi_dwi_preproc_bc.mif

parallel -j4 --link epi_reg -v --epi={1} --t1={2} --t1brain={2.}_bet.nii.gz --out={2.}_epi_reg --noclean ::: *V1*_b0mean.nii.gz ::: *V1_*_uniform.nii

parallel -j12 --bar --plus 'id={};id=${id%_nozfi*};flirt -in {} -ref ${id}_BRAVO_uniform.nii -applyxfm -init ${id}_BRAVO_uniform_epi_reg.mat -out {..}_in_bravo.nii.gz' ::: *V1*_bc_??.nii.gz

# 4/3/2019. 10:38 p.m.
# On cochiti.
cd /bitest/adluru
parallel -j12 --bar fslswapdim {} -x y z {.}_Swapx.nii.gz ::: *Acute*_Mask.nii
parallel 'id={};id=${id%_nozfi*};WriteVoxelwiseCSV {} ${id}_Acute_Lesion_Mask.nii ${id}_Acute_Lesion_Swapx.nii.gz;' ::: SS*_nozfi*_bc_??_in_bravo.nii.gz

parallel -j12 --bar 'roipre={};roipre=${roipre%_nozfi*}_Acute_Lesion_Mask;WriteVoxelwiseCSV ${roipre}.nii ${roipre}_Swapx.nii.gz {}' ::: SS*_nozfi*_bc_??_in_bravo.nii.gz

WriteVoxelwiseCSV() {
    roi1=$1
    roi2=$2
    export img=$3
    pre=${img%.nii*}
    export pre=${pre##*/}

    parallel -j2 --plus '
    roi={/..}
    vals=${pre}_${roi}_vals.csv
    ids=${pre}_${roi}_idx.csv
    final=${pre}_${roi}_final.csv

    ImageMath 3 $vals ConvertImageSetToMatrix 0 {} $img
    sed -i "1s/^/Voxel,Value\n/" $vals

    echo "ID,ROI" > $ids
    yes $pre,$roi | head -n $(sed 1d $vals | wc -l) >> $ids
    paste $ids -d "," $vals > $final
    rm -f $vals $ids
    cat $final' ::: $roi1 $roi2
}
export -f WriteVoxelwiseCSV

csvstack *final.csv >StrokeVoxelwiseDTI.csv
# endregion

# region alm swapx nudge info (11/25/2019)
SS001 
SS004 translate y -17
SS014
SS015
SS019
SS035
SS036
# endregion

# region (test run) flirt => fnirt => mni => flip => inv (11/25/2019)
t1w=t1w/SS001V1.anat_stdorientation_normalized_BFC_brain.nii.gz
alm=alm/SS001V1_Acute_Lesion_Mask_size_thr.nii.gz
pre=tomni/$(basename $t1w .nii.gz)
refimg=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz
flirt -ref $refimg -in $t1w -omat ${pre}_affine_transf.mat
fnirt --in=$t1w --aff=${pre}_affine_transf.mat --cout=${pre}_nonlinear_transf --config=T1_2_MNI152_1mm
applywarp --ref=$refimg --in=$t1w --warp=${pre}_nonlinear_transf --out=${pre}_warped_structural
applywarp --ref=$refimg --in=$alm --warp=${pre}_nonlinear_transf --out=${pre}_ALM_in_MNI --interp=nn
invwarp --ref=$t1w --warp=${pre}_nonlinear_transf --out=${pre}_nonlinear_transf_inv
fslswapdim ${pre}_ALM_in_MNI -x y z ${pre}_ALM_in_MNI_swapx
applywarp --ref=$t1w --in=${pre}_ALM_in_MNI_swapx --warp=${pre}_nonlinear_transf_inv --out=${pre}_ALM_in_MNI_swapx_in_native --interp=nn
# endregion

# region (batch) flirt => fnirt => mni => flip => inv (11/25/2019)
parallel --dry-run -j24 --bar bash SwapInMNI.sh {1} {2} ::: t1w/SS*.nii.gz :::+ alm/SS*thr.nii.gz
# endregion
# region decided to use n=27 with JIM alm masks (11/14/2019)
cd /scratch/adluru/sp_adluru/RSNA2019FinalSetForAnalysis/alm
ls *thr.nii.gz | parallel --plus fslswapdim {} -x y z {..}_swapx.nii.gz
ls dti/*.gz | parallel -j24 --bar --dry-run --rpl '{_} s/_nozfi.*/_Acute_Lesion_Mask_size_thr/;s/.*dti\//alm\//' WriteVoxelwiseCSV {_}.nii.gz {_}_swapx.nii.gz {}
~/.linuxbrew/bin/csvstack *final.csv > StrokeVoxelwiseDTI.csv
# endregion

# region post rsna acceptance (n=65)
# 9/17/2019. 9:26 p.m.
dataroot=/mounts/data/preprocessed/modalities/dti/sp_adluru/LargerDataset # gru
dataroot=/scratch/adluru/sp_adluru                                        # medusa
export bvecs=$dataroot/diff.bvec
export bvals=$dataroot/diff.bval
export initroot=$dataroot/CHTC
export initroot=$dataroot/Local

parallel --dry-run -j12 --bar --plus 'mrresize -scale 0.5,0.5,1 {} - -datatype int16le -interp sinc | mrconvert - {..}_nozfi.mif -fslgrad $bvecs $bvals -force' ::: $dataroot/dti/*.nii.gz

parallel --dry-run -j12 --bar 'dwi2mask {} {.}_mask.mif -force;
dwidenoise {} {.}_denoised.mif -mask {.}_mask.mif -noise {.}_noise.mif -force;
mrcalc -force {.}_noise.mif -finite {.}_noise.mif 0 -if {.}_noise_lowb.mif;
mrdegibbs {.}_denoised.mif {.}_deringed.mif -force' ::: $dataroot/dti/*_nozfi.mif

parallel -j1 ./DWICorrect_AddJobToDAG.sh {} {#} {= '$_=total_jobs()' =} ::: $dataroot/dti/*_deringed.mif >DWICorrect_September182019_V2.dag

parallel -j1 ./DWICorrect_AddJobToDAG_Local.sh {} {#} {= '$_=total_jobs()' =} ::: $dataroot/dti/*_deringed.mif >DWICorrect_September182019_V3.dag
# the one below worked from guero.
parallel -j1 ./DWICorrect_AddJobToDAG_Local.sh {} {#} {= '$_=total_jobs()' =} ::: $dataroot/dti/*_deringed.mif >DWICorrect_September192019_V4.dag

parallel --dry-run -j12 --bar dwibiascorrect {.}_deringed_dwi_preprocessed.mif {.}_b1bc.mif -mask {.}_mask.mif -ants -bias {.}_bf.mif -tempdir {.}_bc -nocleanup -force ::: $dataroot/dti/*_nozfi.mif

parallel --dry-run -j12 --bar -k 'mrcalc -force {.}_b1bc.mif 2 -pow {.}_noise_lowb.mif 2 -pow -sub -abs -sqrt - | mrcalc - -finite - 0 -if {.}_b1bc_rc.mif -force' ::: $dataroot/dti/*_nozfi.mif

parallel -j12 --bar -k mrinfo {} -export_grad_mrtrix {.}.grad -force ::: $dataroot/dti/*b1bc.mif
parallel --dry-run -j12 --bar -k mrconvert {.}_rc.mif -grad {.}.grad {.}_rc_withgrad.mif -force ::: $dataroot/dti/*b1bc.mif
parallel -j12 --bar -k 'dwi2mask {} {.}_mask.mif -force;
dwi2tensor -mask {.}_mask.mif {} {.}_tensor.mif;
tensor2metric {.}_tensor.mif -fa {.}_fa.nii.gz -adc {.}_md.nii.gz -ad {.}_ad.nii.gz -rd {.}_rd.nii.gz -force' ::: $dataroot/dti/*_b1bc_rc_withgrad.mif

parallel --dry-run -j12 --bar -k 'mrcalc {} 0 -ge {} 0 -if - | mrcalc - 1 -le - 0 -if {} -force' ::: $dataroot/dti/*_fa.nii.gz
parallel --dry-run -j12 --bar -k 'mrcalc {} 0 -ge {} 0 -if - | mrcalc - 1E3 -mul - | mrcalc - 10 -le - 0 -if {} -force' ::: $dataroot/dti/*_?d.nii.gz
# endregion

# https://github.com/deepmedic/deepmedic
# region atlas data processing
cd /scratch/adluru/ATLAS_R1.1/
parallel --plus --bar -k -j20 bet {} Processed/{/..}_brain -f 0.3 -R -m ::: Site*/*/t01/*t1w*gz
# parallel --plus -j30 --bar -k ImageMath 3 {..}_normalized.nii.gz Normalize {} ::: Processed/*brain.nii.gz
parallel -j30 -k --plus --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz' ::: Processed/*brain.nii.gz
parallel -j30 --plus --bar -k fslmaths {} -bin Processed/GTLabels/{/..}.nii.gz ::: Site*/*/t01/*Smooth_stx*.gz
# endregion

# region atlas data processing take 2
parallel --dry-run --plus -j30 --bar -k ImageMath 3 ATLASData/{/..}_normalized.nii.gz Normalize {} ::: ATLAS_R1.1/Site*/*/t01/*t1w*gz
parallel --dry-run --bar --plus -j30 -k N4BiasFieldCorrection -d 3 -i {} -o [{..}_BFC.nii.gz,{..}_BF.nii.gz] -r -s 2 ::: ATLASData/*_normalized.nii.gz
parallel --dry-run --bar -j30 --plus -k bet {} {..}_brain -f 0.3 -R -m -S ::: ATLASData/*_BFC.nii.gz
parallel --dry-run -j30 -k --plus --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz' ::: ATLASData/*_BFC_brain.nii.gz
parallel --dry-run -j30 --plus --bar -k fslmaths {} -bin ATLASData/GTLabels/{/..}.nii.gz :::  ATLAS_R1.1/Site*/*/t01/*Smooth_stx*.gz
# endregion

# region quick log of file organization
(venv) [adluru@cochiti ATLASData]$ mkdir T1WImages
(venv) [adluru@cochiti ATLASData]$ mv *brain_demean_destd.nii.gz ./T1WImages/
(venv) [adluru@cochiti ATLASData]$ ls T1WImages|wc
    220     220   13860
(venv) [adluru@cochiti ATLASData]$ mkdir T1WBrainMasks
(venv) [adluru@cochiti ATLASData]$ mv *brain_mask.nii.gz ./T1WBrainMasks/
(venv) [adluru@cochiti ATLASData]$ ls T1WBrainMasks/|wc
    220     220   12100
(venv) [adluru@cochiti ATLASData]$ ls GTLabels/|wc
    220     220    6820
(venv) [adluru@cochiti ATLASData]$

(venv) [adluru@cochiti JIMData]$ mv *brain_demean_destd.nii.gz ./T1WImages/
(venv) [adluru@cochiti JIMData]$ mv *brain_mask.nii.gz ./T1WBrainMasks/
(venv) [adluru@cochiti JIMData]$ ls T1WImages/|wc
     38      38    2394
(venv) [adluru@cochiti JIMData]$ ls T1WBrainMasks/|wc
     38      38    2090
(venv) [adluru@cochiti JIMData]$ ls GTLabels/|wc
     38      38     950
(venv) [adluru@cochiti JIMData]$

# endregion

# region deepmedic config files
# training
parallel -j1 -k echo $(pwd)/{} ::: Processed/T1WImages/*demean_destd.nii.gz >~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainChannels_t1c.cfg
parallel -j1 -k echo $(pwd)/{} ::: Processed/GTLabels/*Smooth_stx.nii.gz >~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainGtLabels.cfg
parallel -j1 -k echo $(pwd)/{} ::: Processed/T1WBrainMasks/*.gz >~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainRoiMasks.cfg

tail -n5 trainChannels_t1c.cfg >./validation/validationChannels_t1c.cfg
tail -n5 trainGtLabels.cfg >./validation/validationGtLabels.cfg
tail -n5 trainRoiMasks.cfg >./validation/validationRoiMasks.cfg
tail -n5 trainGtLabels.cfg | parallel --plus echo Pred_{/} >./validation/validationNamesOfPredictions.cfg
parallel 'sed -i "$(($(wc -l < {})-4)),\$d" {}' ::: trainGtLabels.cfg trainChannels_t1c.cfg trainRoiMasks.cfg
# endregion

# region deepmedic config files take 2
parallel -j1 -k echo $(pwd)/{} ::: ATLASData/T1WImages/*demean_destd.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainChannels_t1c_v2.cfg
parallel -j1 -k echo $(pwd)/{} ::: ATLASData/GTLabels/*Smooth_stx.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainGtLabels_v2.cfg
parallel -j1 -k echo $(pwd)/{} ::: ATLASData/T1WBrainMasks/*brain_mask.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainRoiMasks_v2.cfg

parallel -j1 -k echo $(pwd)/{} ::: JIMData/T1WImages/*demean_destd.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/validation/validationChannels_t1c_v2.cfg
parallel -j1 -k echo $(pwd)/{} ::: JIMData/GTLabels/*.nii > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/validation/validationGtLabels_v2.cfg
parallel -j1 -k echo $(pwd)/{} ::: JIMData/T1WBrainMasks/*brain_mask.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/validation/validationRoiMasks_v2.cfg
cat ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/validation/validationGtLabels_v2.cfg | parallel -j1 -k echo Pred_{/} > validationNamesOfPredictions_v2.cfg
# endregion

# region training
./deepMedicRun -model ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/models/modelConfig.cfg -train ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainConfig.cfg -dev cuda0
# endregion

# region training take 2
model=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/models/modelConfig_uw.cfg
train=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainConfig_uw.cfg
./deepMedicRun -model $model -train $train -dev cuda2
# endregion

# region training take 3
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
model=$configdir/models/modelConfig_uw_v2.cfg
train=$configdir/train/trainConfig_uw_v2.cfg
./deepMedicRun -model $model -train $train -dev cuda1
# endregion

# region training take 3 closeop
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
model=$configdir/models/modelConfig_uw_v2_closeop.cfg
train=$configdir/train/trainConfig_uw_v2_closeop.cfg
./deepMedicRun -model $model -train $train -dev cuda1
# endregion

# region training take 4
cd /scratch/adluru/sp_adluru/JIMData/GTLabels
parallel -j1 -k echo $(pwd)/{} ::: *closeop.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/validation/validationGtLabels_v3.cfg
cd ~/StrokeAndDiffusionProject/uwstrokeproject/deepmedic
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
model=$configdir/models/modelConfig_uw.cfg
train=$configdir/train/trainConfig_uw_v3.cfg
./deepMedicRun -model $model -train $train -dev cuda0
# endregion

# region testing n=65 using modelConfig_uw take 4
outdir=/scratch/adluru/sp_adluru/DMOrigOutputUWV4
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
./deepMedicRun -model $configdir/models/modelConfig_uw.cfg \
    -test $configdir/test/testConfig_take4.cfg \
    -load $outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-10-12.01.30.45.140821.model.ckpt \
    -dev cuda0
# endregion

# region tracking training progress
python plotTrainingProgress.py /scratch/adluru/sp_adluru/DMOrigOutput/logs/trainSessionDmOriginal.txt -d -m 20 -c 1
# endregion

# region testing on the validation set
outdir=/scratch/adluru/sp_adluru/DMOrigOutput
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
./deepMedicRun -model $configdir/models/modelConfig.cfg \
    -test $configdir/test/testConfig.cfg \
    -load $outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-09-28.11.30.47.245868.model.ckpt
-dev cuda0
# endregion

# region processing JIM data for deepmedic
parallel --dry-run --bar -j30 -k ImageMath 3 JIMData/{//}_{/.}_normalized.nii.gz Normalize {} ::: SS0*V1/*BRAVO_uniform.nii
parallel --dry-run --bar --plus -j30 -k N4BiasFieldCorrection -d 3 -i {} -o [{..}_BFC.nii.gz,{..}_BF.nii.gz] -r -s 2 ::: JIMData/*_normalized.nii.gz
parallel --dry-run --bar -j30 --plus -k bet {} {..}_brain -f 0.3 -R -m -S ::: JIMData/*_BFC.nii.gz
parallel --dry-run -j30 -k --plus --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz' ::: JIMData/*_BFC_brain.nii.gz
parallel -j1 -k echo $(pwd)/{} ::: T1WImages/*.gz >~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testChannels_t1c_uw.cfg
parallel -j1 -k echo $(pwd)/{} ::: T1WBrainMasks/*.gz >~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testRoiMasks_uw.cfg
parallel -j1 -k echo Pred_{/} ::: T1WImages/*gz >~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testNamesOfPredictions_uw.cfg
# endregion

# region processing the n=65 set of UW BRAVO scans
cd /scratch/adluru/sp_adluru/T1
parallel --dry-run -j30 -k --bar fslreorient2std {} {.}_stdorientation ::: *.nii
parallel --dry-run --plus -j30 -k --bar ImageMath 3 {..}_normalized.nii.gz Normalize {} ::: *_stdorientation.nii.gz
parallel --dry-run --bar --plus -j30 -k N4BiasFieldCorrection -d 3 -i {} -o [{..}_BFC.nii.gz,{..}_BF.nii.gz] -r -s 2 ::: *_normalized.nii.gz
parallel --dry-run --bar -j30 --plus -k bet {} {..}_brain -f 0.3 -R -m -S ::: *_BFC.nii.gz
parallel --dry-run -j30 -k --plus --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz' ::: *_BFC_brain.nii.gz
# endregion

# region testing on the n=65 set of UW BRAVO scans
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
parallel -j1 -k echo $(pwd)/{} ::: T1WImages/*.gz > $configdir/test/testChannels_t1c_v2.cfg
parallel -j1 -k echo $(pwd)/{} ::: T1WBrainMasks/*.gz > $configdir/test/testRoiMasks_v2.cfg
parallel -j1 -k echo Pred_{/} ::: T1WImages/*gz > $configdir/test/testNamesOfPredictions_v2.cfg
# endregion

# region testing n=65 using modelConfig_uw
outdir=/scratch/adluru/sp_adluru/DMOrigOutputUW
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
./deepMedicRun -model $configdir/models/modelConfig_uw.cfg \
    -test $configdir/test/testConfig_v2.cfg \
    -load $outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-10-08.19.39.31.776015.model.ckpt \
    -dev cuda0
# endregion

# region testing n=65 using modelConfig_uw_v2
outdir=/scratch/adluru/sp_adluru/DMOrigOutputUWV2
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
modelcfg=$configdir/models/modelConfig_uw_v2.cfg
testcfg=$configdir/test/testConfig_uw_V2_LM.cfg
finalmodel=$outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-10-14.05.51.50.008796.model.ckpt
./deepMedicRun -model $modelcfg \
    -test $testcfg \
    -load $finalmodel \
    -dev cuda0
# endregion

# region testing n=65 using modelConfig_uw_v2_closeop
outdir=/scratch/adluru/sp_adluru/DMOrigOutputUWV2Closeop
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
modelcfg=$configdir/models/modelConfig_uw_v2_closeop.cfg
testcfg=$configdir/test/testConfig_uw_V2_LM_closeop.cfg
finalmodel=$outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-10-18.08.15.09.645128.model.ckpt
./deepMedicRun -model $modelcfg \
    -test $testcfg \
    -load $finalmodel \
    -dev cuda2
# endregion


# region testing on the JIM data
outdir=/scratch/adluru/sp_adluru/DMOrigOutput
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
./deepMedicRun -model $configdir/models/modelConfig.cfg \
    -test $configdir/test/testConfig_uw.cfg \
    -load $outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-09-28.11.30.47.245868.model.ckpt \
    -dev cuda0
# endregion

# region using the UW data as the validation set for the training with ATLAS data
parallel -j30 --bar cp {} JIMData/GTLabels/{//}_{/} ::: SS*V1/L*Mask.nii
parallel -j1 -k echo $(pwd)/{} ::: JIMData/GTLabels/*.nii > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/validation/validationGtLabels_uw.cfg
cd ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train
cat trainChannels_t1c.cfg ./validation/validationChannels_t1c.cfg >trainChannels_t1c_uw.cfg
cat trainGtLabels.cfg ./validation/validationGtLabels.cfg >trainGtLabels_uw.cfg
cat trainRoiMasks.cfg ./validation/validationRoiMasks.cfg >trainRoiMasks_uw.cfg
# endregion

# region training
./deepMedicRun -model ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/models/modelConfig_uw.cfg -train ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainConfig_uw.cfg -dev cuda1
# endregion

# region post-processing the deepmedic predictions
parallel -j30 -k --bar --plus cluster -i {} -t 1 -o {..}_index.nii.gz --osize={..}_size.nii.gz ::: *Segm.nii.gz
parallel -j30 --bar -k --plus 'fslmaths {} -thr $(fslstats {} -P 80) {..}_size_thr.nii.gz' ::: *_size.nii.gz
# endregion

# region pre-processing the labels in JIMData
parallel --dry-run -j30 -k --bar --plus cluster -i {} -t 1 -o {..}_index.nii.gz --osize={..}_size.nii.gz ::: *Mask.nii
parallel --dry-run -j30 --bar -k --plus 'fslmaths {} -thr $(fslstats {} -P 80) -bin {..}_size_thr.nii.gz' ::: *_size.nii.gz
parallel --dry-run -j30 --bar -k --plus 'fslmaths {} -dilM -ero -bin -dilM -ero -bin {..}_closeop.nii.gz' ::: *_size_thr.nii.gz
# endregion

# region prepping to train with ALMs (acute lesion masks)
cd /scratch/adluru/sp_adluru/JIMData/GTLabels_ALM
parallel --bar 'arr=($(fslstats {} -V));[[ ${arr[0]} -eq 0 ]] && rm {};' ::: *Acute_Lesion_Mask.nii
parallel -j30 -k --bar --plus cluster -i {} -t 1 -o {..}_index.nii.gz --osize={..}_size.nii.gz ::: *Mask.nii
parallel -j30 --bar -k --plus 'fslmaths {} -thr $(fslstats {} -P 80) -bin {..}_thr.nii.gz' ::: *_size.nii.gz
# no close operation for the alm.
#parallel -j30 --bar -k --plus 'fslmaths {} -dilM -ero -bin -dilM -ero -bin {..}_closeop.nii.gz' ::: *_thr.nii.gz
# endregion

# region train validation config files for ALM training
cd /scratch/adluru/sp_adluru/JIMData/GTLabels_ALM
parallel -j1 -k echo $(pwd)/{} ::: *thr.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainGtLabels_ALM.cfg
parallel -j1 -k 'fn={/};echo $(pwd)/T1WImages/${fn%_Acute*}_BRAVO_uniform_normalized_BFC_brain_demean_destd.nii.gz' ::: GTLabels_ALM/*thr.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainChannels_t1c_ALM.cfg
parallel -j1 -k 'fn={/};echo $(pwd)/T1WBrainMasks/${fn%_Acute*}_BRAVO_uniform_normalized_BFC_brain_mask.nii.gz' ::: GTLabels_ALM/*thr.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainRoiMasks_ALM.cfg


ls GTLabels_ALM/*size_thr.nii.gz | parallel -k echo $(pwd)/{} > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainGtLabels_ALM_Nov082019.cfg
ls GTLabels_ALM/*size_thr.nii.gz | sed 's/.*_ALM\///g;s/_Acute.*//g' | parallel -k echo $(pwd)/T1WImages/{}_BRAVO_uniform_normalized_BFC_brain_demean_destd.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainChannels_t1c_ALM_Nov082019.cfg
ls GTLabels_ALM/*size_thr.nii.gz | sed 's/.*_ALM\///g;s/_Acute.*//g' | parallel -k echo $(pwd)/T1WBrainMasks/{}_BRAVO_uniform_normalized_BFC_brain_mask.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainRoiMasks_ALM_Nov082019.cfg

parallel -k 'echo $(pwd)/dwiinstruc/{1}_nozfi_b1bc_rc_withgrad_{2}_instruc.nii.gz >> ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainChannels_{2}_ALM_Nov082019.cfg' ::: $(ls JIMData/GTLabels_ALM/*size_thr.nii.gz | sed 's/.*_ALM\///g;s/_Acute.*//g') ::: md rd ad fa dwimin dwimean b0mean dwistd dwirms

ls JIMData/GTLabels_ALM/*size_thr.nii.gz | sed 's/.*_ALM\///g;s/_Acute.*//g' | parallel -k echo $(pwd)/T1WBrainMasks/{}.flair_stdorientation_BFC_bet_in_struc.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainChannels_flair_ALM_Nov092019.cfg

ls train/trainChannels_*Nov*.cfg | parallel -k --bar 'sed -n -e 3p -e 6p -e 9p -e 12p -e 18p -e 24p {} > {//}/validation/{/.}_validation.cfg'
ls train/trainChannels_*Nov*.cfg | parallel -k --bar 'sed -i.bak -e "3d;6d;9d;12d;18d;24d" {}'

ls train/trainGtLabels_ALM_Nov082019.cfg | parallel -k --bar 'sed -n -e 3p -e 6p -e 9p -e 12p -e 18p -e 24p {} > {//}/validation/{/.}_validation.cfg'
ls train/trainGtLabels_ALM_Nov082019.cfg | parallel -k --bar 'sed -i.bak -e "3d;6d;9d;12d;18d;24d" {}'

ls train/trainRoiMasks_ALM_Nov082019.cfg | parallel -k --bar 'sed -n -e 3p -e 6p -e 9p -e 12p -e 18p -e 24p {} > {//}/validation/{/.}_validation.cfg'
ls train/trainRoiMasks_ALM_Nov082019.cfg | parallel -k --bar 'sed -i.bak -e "3d;6d;9d;12d;18d;24d" {}'

ls train/trainGtLabels_ALM_Nov082019.cfg.bak | parallel -k --bar 'sed -n -e 3p -e 6p -e 9p -e 12p -e 18p -e 24p {}|sed "s/.*_ALM\///g;s/\_Ac.*//g"' | parallel echo {}_Pred_ALM.nii.gz > train/validation/validationNamesOfPredictions_ALM_Nov092019.cfg
# endregion

# region .cfg files updates.
ls trainChannels_*Nov*.cfg | parallel sed -i.bak2 's/instruc.nii.gz/instruc_demean_destd.nii.gz/g' {}
sed -i.bak3 's/in_struc.nii.gz/in_struc_demean_destd.nii.gz/g' trainChannels_flair_ALM_Nov092019.cfg
sed -i.bak3 's/JIMData\/T1WImages/T1/g' trainChannels_t1c_ALM_Nov082019.cfg
sed -i.bak4 's/\_BRAVO\_uniform/.anat_stdorientation/g' trainChannels_t1c_ALM_Nov082019.cfg

ls *Nov*_validation.cfg | parallel sed -i.bak3 's/instruc.nii.gz/instruc_demean_destd.nii.gz/g' {}
ls *Nov*_validation.cfg | parallel sed -i.bak4 's/in_struc.nii.gz/in_struc_demean_destd.nii.gz/g' {}
sed -i.bak5 's/JIMData\/T1WImages/T1/g;s/\_BRAVO\_uniform/.anat\_stdorientation/g' trainChannels_t1c_ALM_Nov082019_validation.cfg

sed -i.bak4 's/JIMData\/T1WBrainMasks/T1/g;s/_BRAVO_uniform/.anat_stdorientation/g' trainRoiMasks_ALM_Nov082019.cfg
sed -i.bak4 's/JIMData\/T1WBrainMasks/T1/g;s/_BRAVO_uniform/.anat_stdorientation/g' trainRoiMasks_ALM_Nov082019_validation.cfg
# endregion

# region training ALM Nov 9, 2019.
./deepMedicRun -model ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/models/modelConfig_uw_ALM.cfg -train ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainConfig_uw_ALM.cfg -dev cuda1
# endregion
# region test cfg files
cd /scratch/adluru/sp_adluru
ls dti/*fa.nii.gz | sed 's/.*dti\///g;s/_nozfi.*//g' | parallel -k echo $(pwd)/flairinstruc/{}.flair_stdorientation_BFC_bet_in_struc_demean_destd.nii.gz >  ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testChannels_flair_ALM_Nov122019.cfg
sed -i 's/KS//g;s/\/[0-9][0-9][0-9]/&_/g;s/[0-9][0-9][0-9]_/KS_&/g' ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testChannels_flair_ALM_Nov122019.cfg
parallel -k 'echo $(pwd)/dwiinstruc/{1}_nozfi_b1bc_rc_withgrad_{2}_instruc_demean_destd.nii.gz >> ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testChannels_{2}_ALM_Nov122019.cfg ' ::: $(ls dti/*fa.nii.gz | sed 's/.*dti\///g;s/_nozfi.*//g') ::: fa md rd ad dwimin dwimean b0mean dwistd dwirms
ls dti/*fa.nii.gz | sed 's/.*dti\///g;s/_nozfi.*//g' | parallel -k echo {}_Pred_ALM.nii.gz > ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testNamesOfPredictions_ALM_Nov122019.cfg
ls dti/*fa.nii.gz | sed 's/.*dti\///g;s/_nozfi.*//g' | parallel -k echo $(pwd)/T1/{}.anat_stdorientation_normalized_BFC_brain_mask.nii.gz >  ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/test/testRoiMasks_ALM_Nov122019.cfg

sed -i.bak '/KS_019_V1/d' testChannels_flair_ALM_Nov122019.cfg
ls testChannels_*Nov*.cfg | parallel sed -i.bak2 '/KS019V1/d' {}
sed -i.bak '/KS019V1/d' testNamesOfPredictions_ALM_Nov122019.cfg
sed -i.bak '/KS019V1/d' testRoiMasks_ALM_Nov122019.cfg

# endregion
# region testing ALM Nov. 12, 2019
outdir=/scratch/adluru/sp_adluru/DMOrigOutputUW_ALMV1
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
modelcfg=$configdir/models/modelConfig_uw_ALM.cfg
testcfg=$configdir/test/testConfig_uw_ALM.cfg
finalmodel=$outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-11-12.14.22.10.939083.model.ckpt
./deepMedicRun -model $modelcfg \
    -test $testcfg \
    -load $finalmodel \
    -dev cuda0
# endregion
# region training ALM Nov 11, 2019.
model=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/models/modelConfig_uw_ALM2.cfg
train=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainConfig_uw_ALM2.cfg
./deepMedicRun -model $model -train $train -dev cuda0
# endregion

# region training ALM Nov 12, 2019.
./deepMedicRun -model ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/models/modelConfig_uw_ALM3.cfg -train ~/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles/train/trainConfig_uw_ALM3.cfg -dev cuda1
# endregion
# region testing ALM Nov. 13, 2019
outdir=/scratch/adluru/sp_adluru/DMOrigOutputUW_ALMV1
configdir=/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/DeepMedicConfigFiles
modelcfg=$configdir/models/modelConfig_uw_ALM3.cfg
testcfg=$configdir/test/testConfig_uw_ALM3.cfg
finalmodel=$outdir/saved_models/trainSessionDmOriginal/deepMedicOriginal.trainSessionDmOriginal.final.2019-11-13.06.45.43.662733.model.ckpt
./deepMedicRun -model $modelcfg \
    -test $testcfg \
    -load $finalmodel \
    -dev cuda0
# endregion

# region n=65 generate the appropriate dwi contrast based on the Stroke 2019 paper that Veena sent
cd /scratch/adluru/sp_adluru/dti
parallel -j24 --bar 'dwiextract {} -shells 0 - | mrmath - mean {.}_b0mean.nii.gz -axis 3' ::: *withgrad.mif
parallel -j24 --bar -k 'dwiextract {} -shells 2000 - | mrmath - mean dwicontrasts/{/.}_dwimean.nii.gz -force -axis 3' ::: dti/*withgrad.mif
 parallel -j24 --bar -k --dry-run 'dwiextract {1} -shells 2000 - | mrmath - {2} dwicontrasts/{1/.}_dwi{2}.nii.gz -force -axis 3' ::: dti/*withgrad.mif ::: min max std norm rms
# endregion
# region n=65 register that dwi contrast and the rest of the DTI measures to t1w

parallel --dry-run --plus -j24 --bar epi_reg -v --epi={1} --t1={2} --t1brain={3} --out=epi2struc/{1/..}_epi2struc --noclean ::: dti/*b0mean.nii.gz :::+ T1/*BFC.nii.gz :::+ T1/*BFC_brain.nii.gz
cd /scratch/adluru/sp_adluru/epi2struc
parallel -j20 --bar convert_xfm -omat {.}_inv.mat -inverse {} ::: *epi2struc.mat

parallel -j24 --bar -k --plus --dry-run flirt -in {1} -ref {2} -applyxfm -init epi2struc/{1/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dti/*b0mean.nii.gz :::+ T1/*BFC_brain.nii.gz
parallel -j24 --bar -k --plus --dry-run flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dti/*withgrad_fa.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz
parallel -j24 --bar -k --plus --dry-run flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dti/*withgrad_md.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz
parallel -j24 --bar -k --plus --dry-run flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dti/*withgrad_ad.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz
parallel -j24 --bar -k --plus --dry-run flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dti/*withgrad_rd.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz

parallel -j24 --bar -k --plus flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dwicontrasts/*dwimean.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz
parallel -j24 --bar -k --plus flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dwicontrasts/*dwimin.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz
parallel -j24 --bar -k --plus flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dwicontrasts/*dwimax.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz
parallel -j24 --bar -k --plus flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dwicontrasts/*dwirms.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz
parallel -j24 --bar -k --plus flirt -in {1} -ref {2} -applyxfm -init epi2struc/{3/..}_epi2struc.mat -out dwiinstruc/{1/..}_instruc.nii.gz ::: dwicontrasts/*dwistd.nii.gz :::+ T1/*BFC_brain.nii.gz :::+ dti/*b0mean.nii.gz

cd /scratch/adluru/sp_adluru/dwiinstruc
parallel --dry-run --plus -j24 -k --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz' ::: *.nii.gz

epi_reg -v --epi=dti/KS001V1_nozfi_b1bc_rc_withgrad_b0mean.nii.gz --t1=T1/KS001V1.anat_stdorientation_normalized_BFC.nii.gz --t1brain=T1/KS001V1.anat_stdorientation_normalized_BFC_brain.nii.gz --out=KS001V1epi2struc --noclean

convert_xfm -omat KS001V1epi2struc_inv.mat -inverse KS001V1epi2struc.mat
flirt -in T1/KS001V1.anat_stdorientation_normalized_BFC_brain.nii.gz -ref dti/KS001V1_nozfi_b1bc_rc_withgrad_b0mean.nii.gz -applyxfm -init KS001V1epi2struc_inv.mat -out KS001V1strucinepi.nii.gz
# endregion

# region SS058 axis 3
cat train/trainChannels_*Nov*.cfg | grep SS058 | parallel --bar -j8  mrpad {} {} -axis 2 13 13 -force
cat train/trainRoiMasks_ALM_Nov082019.cfg | grep SS058 | parallel mrpad {} {} -axis 2 13 13 -force
# endregion

# region dwi to t1 registration
ls dti/*b0mean.nii.gz | sed 's/.*dti\///g;s/\_.*//g' | parallel -j24 -k --bar epi_reg -v --epi=dti/{}_nozfi_b1bc_rc_withgrad_b0mean.nii.gz --t1=T1/{}.anat_stdorientation_normalized_BFC.nii.gz --t1brain=T1/{}.anat_stdorientation_normalized_BFC_brain.nii.gz --out=epi2struc/{}_epi2struc --noclean

parallel -j24 -k --bar flirt -in dti/{1}_nozfi_b1bc_rc_withgrad_{2}.nii.gz -ref T1/{1}.anat_stdorientation_normalized_BFC_brain.nii.gz -init epi2struc/{1}_epi2struc.mat -applyxfm -out dwiinstruc/{1}_nozfi_b1bc_rc_withgrad_{2}_instruc.nii.gz ::: $(ls dti/*b0mean.nii.gz | sed 's/.*dti\///g;s/\_.*//g') ::: fa md ad rd b0mean

parallel --dry-run -j24 -k --bar flirt -in dwicontrasts/{1}_nozfi_b1bc_rc_withgrad_{2}.nii.gz -ref T1/{1}.anat_stdorientation_normalized_BFC_brain.nii.gz -init epi2struc/{1}_epi2struc.mat -applyxfm -out dwiinstruc/{1}_nozfi_b1bc_rc_withgrad_{2}_instruc.nii.gz ::: $(ls dti/*b0mean.nii.gz | sed 's/.*dti\///g;s/\_.*//g') ::: dwimin dwimean dwistd dwirms

parallel --dry-run --plus -j24 -k --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz -force' ::: dwiinstruc/*_instruc.nii.gz
# endregion

# region t1 demean_destd
parallel --dry-run --plus -j24 -k --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz' ::: T1/*stdorientation_normalized_BFC_brain.nii.gz
# endregion

# region FLAIR pre-processing
cd /scratch/adluru/sp_adluru/flair
parallel -j30 --bar fslreorient2std {} {.}_stdorientation.nii.gz ::: *flair.nii
parallel --dry-run --bar --plus -j24 -k N4BiasFieldCorrection -d 3 -i {} -o [{..}_BFC.nii.gz,{..}_BF.nii.gz] -r -s 2 ::: *flair_stdorientation.nii.gz
ls KS*028* | parallel 'cp {} $(echo {}|sed "s/flair/flair\_stdorientation/g")'
parallel --dry-run -j30 --bar --plus bet {} {..}_bet -f 0.6 -m -R ::: *flair_stdorientation_BFC.nii.gz
parallel --dry-run -j24 --bar -k --plus flirt -in {1} -ref {2} -cost normmi -searchcost normmi -omat flair2struc/{1/..}_to_{2/..}.mat ::: flair/*stdorientation_BFC_bet.nii.gz :::+ T1/*anat*stdorientation*BFC_brain.nii.gz
parallel --dry-run -j24 --bar -k --plus flirt -in {1} -ref {2} -applyxfm -init flair2struc/{1/..}_to_{2/..}.mat -out flairinstruc/{1/..}_in_struc.nii.gz ::: flair/*BFC_bet.nii.gz :::+ T1/*BFC_brain.nii.gz


ls flair/*stdorientation_BFC_bet.nii.gz | sed 's/.*flair\///g;s/.flair.*//g' | grep -v SS064V1 | parallel --dry-run -j24 --rpl '{_} s/\_//g' --bar -k flirt -in flair/{}.flair_stdorientation_BFC_bet.nii.gz -ref T1/{_}.anat_stdorientation_normalized_BFC_brain.nii.gz -cost normmi -searchcost normmi -omat flair2struc/{_}_flair2struc.mat

ls flair/*stdorientation_BFC_bet.nii.gz | sed 's/.*flair\///g;s/.flair.*//g' | grep -v SS064V1 | parallel --dry-run -j24 --rpl '{_} s/\_//g' --bar -k flirt -in flair/{}.flair_stdorientation_BFC_bet.nii.gz -ref T1/{_}.anat_stdorientation_normalized_BFC_brain.nii.gz -init flair2struc/{_}_flair2struc.mat -applyxfm -out flairinstruc/{}.flair_stdorientation_BFC_bet_in_struc.nii.gz

parallel --dry-run --plus -j24 -k --bar 'arr=($(mrstats {} -quiet -output mean -output std -ignorezero));mrcalc {} ${arr[0]} -sub ${arr[1]} -div {..}_demean_destd.nii.gz -force' ::: flairinstruc/*_in_struc.nii.gz
# endregion
