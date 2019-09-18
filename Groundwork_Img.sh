#!/bin/bash

# region pre-RSNA
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
