function opt =  my_covar_opt(opt)

opt = dtd_covariance_opt(opt);

opt.dtd_covariance.fig_maps = {'s0' 'MD' 'FA' 'MKi' 'MKa' 'MKt' 'uFA'};