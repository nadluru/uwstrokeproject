# 06/07/2021 merging dwi, flair, bravo from csr, k, sp, r01 =========
scsvroot = 'H:/adluru/StrokeAndDiffusionProject/uwstrokeproject/shapiro/csvs/'
c('csr', 'sp', 'k', 'r01') %>% map(function(s) map(c('_dwi_adc.csv', '_dwi_b0.csv', '_flair.csv', '_bravo.csv'), ~paste0(s, .x)) %>% map(~read.csv(paste0(scsvroot, .x))) %>% reduce(inner_join, by = 'id') %>% write.csv(paste0(scsvroot, s, '_joined.csv'), row.names = F, quote = F))

