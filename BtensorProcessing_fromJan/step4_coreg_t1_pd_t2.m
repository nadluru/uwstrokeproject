% coreg t1
i_t1_nii_fn = fullfile(ip, 'MPRAGE_3','MPRAGE_3_MPRAGE_20191126120530_3.nii');
o_t1_nii_fn = fullfile(op, 'T1_MPRAGE.nii.gz');

if (~opt.do_overwrite && exist(o_t1_nii_fn, 'file'))
    
    disp('T1 already registered');
    
elseif (~isempty(i_t1_nii_fn))
    s_corr_pa = mdm_s_from_nii(msf_find_fn(op, 'FWF_topup_pa.nii.gz'));
    
    % Use a high b-value for the registration
    s_tmp = mdm_s_subsample(s_corr_pa, 7 == (1:s_corr_pa.xps.n), wp, opt);
    
    % Do rigid body registration
    p_fn   = elastix_p_write(elastix_p_6dof(150), fullfile(wp, 'p_t1_fwf.txt'));
    res_fn = elastix_run_elastix(i_t1_nii_fn, s_tmp.nii_fn, p_fn, wp);
    
    % Save the result
    [I,h] = mdm_nii_read(res_fn);
    mdm_nii_write(I, o_t1_nii_fn, h);
end

% coreg PD T2
i_PD_t2_nii_fn = fullfile(ip, 'Axial_PDT2_TSE_2','Axial_PDT2_TSE_2_Axial_PD-T2_TSE_20191126120530_2_e1.nii');
o_PD_t2_nii_fn = fullfile(op, 'PD_T2.nii.gz');

if (~opt.do_overwrite && exist(o_PD_t2_nii_fn, 'file'))
    
    disp('FLAIR already registered');
    
elseif (~isempty(i_flair_nii_fn))
    
    s_corr_pa = mdm_s_from_nii(msf_find_fn(op, 'FWF_topup_pa.nii.gz'));
    
    % Use the highest b-value for the registration
    s_tmp = mdm_s_subsample(s_corr_pa, 7 == (1:s_corr_pa.xps.n), wp, opt);
    
    % Do rigid body registration
    p_fn   = elastix_p_write(elastix_p_6dof(150), fullfile(wp, 'p_PD_T2_fwf.txt'));
    res_fn = elastix_run_elastix(i_PD_t2_nii_fn, s_tmp.nii_fn, p_fn, wp);
    
    % Save the result
    [I,h] = mdm_nii_read(res_fn);
    mdm_nii_write(I, o_PD_t2_nii_fn, h);
end








