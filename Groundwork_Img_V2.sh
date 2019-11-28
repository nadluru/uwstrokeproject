#!/bin/bash

# region global variable names
scratch=/scratch/adluru/sp_adluru
# endregion
# region functions
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
# endregion

# region (organization) simple minded approach
cd $scratch
mkdir SimpleMinded
cat 27list.txt | parallel --bar cp {}/BRAVO*.nii SimpleMinded/{}_BRAVO_uniform.nii
cat 27list.txt | parallel --bar cp {}/Acute*.nii SimpleMinded/{}_Acute_Lesion_Mask.nii
 cat 27list.txt | parallel cp JIMData/GTLabels_ALM/{}*size_thr.nii.gz ./SimpleMinded/
cat 27list.txt | parallel --bar cp dti/{}*withgrad_??.nii.gz SimpleMinded/dti/
cat 27list.txt | parallel --bar cp dti/{}*withgrad_b0mean.nii.gz SimpleMinded/dti/
# endregion

# region t1w bet and epi_reg with b0mean (generated in Groundwork_Img.sh)
cd $scratch/SimpleMinded
parallel -j27 --bar bet {} {.}_bet -m -f 0.3 -R ::: *BRAVO_uniform.nii
parallel -j27 --bar epi_reg -v --epi={1} --t1={2} --t1brain={2.}_bet.nii.gz --out={2.}_epi_reg --noclean ::: dti/*_b0mean.nii.gz :::+ *BRAVO_uniform.nii

parallel --dry-run -j27 -k --plus --bar --rpl '{i} s/.*dti\///;s/_nozfi.*//' flirt -in {} -ref {i}_BRAVO_uniform.nii -applyxfm -init {i}_BRAVO_uniform_epi_reg.mat -out {..}_in_bravo.nii.gz ::: dti/*withgrad_??.nii.gz
# endregion

# region (batch) flirt => fnirt => mni => flip LR => inv
parallel --dry-run -j27 --bar bash SwapInMNI.sh {1} {2} $scratch/SimpleMinded/MNIFlip ::: $scratch/SimpleMinded/*BRAVO_uniform_bet.nii.gz :::+ $scratch/SimpleMinded/*Acute_Lesion_Mask.nii
# endregion

# region (batch) applywarp => mni flip LR => inv
parallel --dry-run -j27 --bar bash SwapInMNI_ApplyWarpsOnly.sh {1} {2} $scratch/SimpleMinded/MNIFlip ::: $scratch/SimpleMinded/*BRAVO_uniform_bet.nii.gz :::+ $scratch/SimpleMinded/*Acute_Lesion_Mask_size_thr.nii.gz
# endregion

# region (post swapx fix) 
cd /study/utaut2/T1WIAnalysisNA/RSNA2019FinalSetForAnalysis
ls tomni/*in_native.nii.gz | parallel --bar -j20 --rpl '{.a} s/.anat/_anat/' cp {} {.a}
ls dti/*withgrad_??_in_bravo.nii.gz | parallel --dry-run --rpl '{i} s/_nozfi.*/_Acute_Lesion_Mask/;s/.*dti\///;s/.gz//' --rpl '{c} s/_nozfi.*/_BRAVO_uniform_bet_ALM_in_MNI_swapx_in_native/;s/.*dti\//MNIFlip\//' WriteVoxelwiseCSV {i}.nii {c}.nii.gz {}
~/.linuxbrew/bin/csvstack *final.csv > StrokeVoxelwiseDTI_MNIFlipped_SimpleMinded.csv
# endregion