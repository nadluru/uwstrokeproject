
s_pa_fn = fullfile(ip,'a_ep2d_diff_fwf_simple_STE_B0_PA_11','a_ep2d_diff_fwf_simple_STE_B0_PA_11_a_ep2d_diff_fwf_simple_STE_B0_PA_20191126120530_11.nii');

s_pa = mdm_s_from_nii(s_pa_fn,0);
s_ap = mdm_s_from_nii(fullfile(op,'FWF_mc.nii.gz'));

% select the low b-acquisition
topup_fn = fullfile(op, 'FWF_topup.nii.gz');

s_corr = mdm_s_topup(s_ap, s_pa, wp, topup_fn, opt);
s_corr_pa = mdm_s_powder_average(s_corr, op, opt); %needed for coregistration





