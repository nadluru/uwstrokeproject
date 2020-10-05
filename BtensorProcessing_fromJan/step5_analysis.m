
opt = mdm_opt;
opt.do_overwrite = 1;
opt.verbose      = 1;
opt =  my_covar_opt(opt);

% connect to data (use motion and topup corrected merged FWF file)
s = mdm_s_from_nii(fullfile(op, 'FWF_topup.nii.gz'));
s.mask_fn = fullfile(op, 'mask.nii.gz');

opt.filter_sigma = 0.4; %smooth data a bit

% all
dtd_covariance_pipe(s, op, opt); %dtd covariance analysis outputs MD, FA, muFA, MK_A, MK_I, MK_t

% change s to only s_lte
dti_lls_pipe(s,op,opt);
dki_lls_pipe(s,op,opt);


