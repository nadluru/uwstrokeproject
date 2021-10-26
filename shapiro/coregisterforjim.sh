#!/bin/bash

bravo=$1
flair=$2
b0=$3
adc=$4

suffix=matorient
parallel --bar --plus mrconvert {} -strides $bravo {..}_$suffix.nii.gz -force ::: $flair
parallel --bar --plus flirt -datatype float -in {..}_$suffix.nii.gz -ref $bravo -omat {..}_$suffix.mat ::: $flair
parallel --bar --plus flirt -datatype float -in {..}_$suffix.nii.gz -ref $bravo -applyxfm -init {..}_$suffix.mat -out {..}_${suffix}_reg.nii.gz ::: $flair

#parallel --bar --plus mrconvert {} -strides $bravo {..}_$suffix.nii.gz -force ::: $b0 $adc $flair
#parallel --bar --plus flirt -datatype int -in {..}_$suffix.nii.gz -ref $bravo -omat {..}_$suffix.mat ::: $b0 $adc $flair
#parallel --bar --plus flirt -datatype int -in {..}_$suffix.nii.gz -ref $bravo -applyxfm -init {..}_$suffix.mat -out {..}_${suffix}_reg.nii.gz ::: $b0 $adc $flair
# parallel --bar --plus flirt -datatype int -in {1..}_$suffix.nii.gz -ref $bravo -applyxfm -init {2..}_$suffix.mat -out {1..}_${suffix}_reg.nii.gz ::: $adc :::+ $b0
