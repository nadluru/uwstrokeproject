% Trying md-mri on Utah sample.

% include 2020a in setup_paths.m
addpath('~/study/utaut2/T1WIAnalysisNA/Utah/md-dmri/')
setup_paths

mdm_fit --data /Users/nadluru/StrokeUtahProject/processed/FWF.nii.gz ...
    --method dtd_codivide ...
    --out /Users/nadluru/StrokeUtahProject/output/ ...
    --xps /Users/nadluru/StrokeUtahProject/processed/FWF_xps.mat;