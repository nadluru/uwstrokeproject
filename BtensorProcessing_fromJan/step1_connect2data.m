clear all
clc

% set options
opt = mdm_opt;
opt.do_overwrite = 1;
opt.verbose      = 1;

% Connect to the data folder
%EVRD, I moved code to be separate from data. so changing inputpath ip and output path op... 
% didn't see how Jan converted to .nii, but many ways to do that. he also wrote out all bvals etc... 
%ip = fullfile('..','data','raw','nii');
%/v/raid1b/ed/MRIdata/DTI/INC_Prisma/P112619/DicomData/*

% dataRoot = '~/study/utaut2/T1WIAnalysisNA/Utah/';
dataRoot = '/Users/nadluru/StrokeUtahProject/';

ip = fullfile(dataRoot, 'raw', 'nii');
%op = fullfile('..','data','processed');
op = fullfile(dataRoot, 'processed');
%wp = fullfile('..','data','interim');
wp = fullfile(dataRoot, 'interim');

msf_mkdir(op); msf_mkdir(wp);

lte_fn = fullfile(ip, 'a_ep2d_diff_fwf_simple_LTE_6/a_ep2d_diff_fwf_simple_LTE_6_a_ep2d_diff_fwf_simple_LTE_20191126120530_6.nii');
ste_fn = fullfile(ip, 'a_ep2d_diff_fwf_simple_STE_5/a_ep2d_diff_fwf_simple_STE_5_a_ep2d_diff_fwf_simple_STE_20191126120530_5.nii');

% Linear tensor data
s_lte = mdm_s_from_nii(lte_fn, 1);
s_ste = mdm_s_from_nii(ste_fn, 0);
