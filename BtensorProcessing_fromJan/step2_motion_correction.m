
%merge the ste and lte data into one nii file
%s_struc = mdm_s_merge({s_lte, s_ste}, op, 'FWF', opt);

% motion correction of reference
p_fn = elastix_p_write(elastix_p_affine(200), fullfile(op, 'p.txt'));

s_lowb = mdm_s_subsample(s_lte, s_lte.xps.b < 1.1e9, op, opt);
s_mec  = mdm_mec_b0(s_lowb, p_fn, op, opt);

% extrapolation-based motion correction
% described in https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0141825
s_mc = mdm_mec_eb(s_struc, s_mec, p_fn, op, opt);

% powder average
s_pa = mdm_s_powder_average(s_mc, op, opt);

