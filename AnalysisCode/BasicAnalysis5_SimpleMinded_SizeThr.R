# source('H:/adluru/StrokeAndDiffusionProject/uwstrokeproject/AnalysisCode/RSNATheme.R')
source('C:/Users/nadluru/uwstrokeproject/AnalysisCode/RSNATheme.R')

# Merging with basic demographics ====
imgcsv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTI_MNIFlipped_SimpleMinded_SizeThr_Nov272019.csv'))
democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
mcsv = merge(
  imgcsv,
  democsv,
  by.x = c('ID'),
  by.y = c('SubjectID'),
  all.x = T
)
mcsv %>% write.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_SMST_Nov272019.csv'),
                   row.names = F)

# CSVs for baseline comparisons (mean) ======
imgcsv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTI_MNIFlipped_SimpleMinded_SizeThr_Nov272019.csv')) %>%
  group_by(ID, MeasureName, ROIName) %>% summarise(MeanValue = mean(Value))
democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
mcsv = merge(
  imgcsv,
  democsv,
  by.x = c('ID'),
  by.y = c('SubjectID'),
  all.x = T
)
mcsv %>% write.csv(paste0(csvroot, 'StrokeDTIMean_SMST_Nov272019.csv'),
                   row.names = F)

csv = read.csv(paste0(csvroot, 'StrokeDTIMean_SMST_Nov272019.csv'))
csvlong = csv %>%
  mutate(NormAcuteTimePeriod = AcuteTimePeriod / AgeAtVisit) %>%
  gather(
    ClinicalMeasureName,
    ClinicalMeasureValue,
    YearsOfEducation:NormAcuteTimePeriod,
    factor_key = T
  )
csvlong %>% write.csv(paste0(csvroot, 'StrokeDTIMeanLong_SMST_Nov272019.csv'),
                      row.names = F)
csvlong %>%
  filter(!(
    ClinicalMeasureName %in% c(
      'AcuteTimePeriod',
      'AgeAtVisit',
      'YearsOfEducation',
      'VerbalFluencyRaw'
    )
  )) %>%
  write.csv(paste0(csvroot, 'StrokeDTIMeanLongFiltered_SMST_Nov272019.csv'),
            row.names = F)

# CSVs for baseline comparisons (mean diff) ======
csvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFiltered_SMST_Nov272019.csv'))
csvdiff = csvlong %>%
  group_by(ID, Gender, ClinicalMeasureName,
           MeasureName) %>%
  arrange(ROIName, .by_group = T) %>%
  mutate(MeanDiff = MeanValue - lag(MeanValue),
         DiffName = paste0(ROIName, '-', lag(ROIName))) %>%
  filter(!is.na(MeanDiff))

csvdiff %>% write.csv(paste0(csvroot, 'StrokeDTIMeanDiff_SMST_Nov272019.csv'),
                      row.names = F)

# CSVs for baseline comparisons (mean diff unfiltered) ======
csvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLong_SMST_Nov272019.csv'))
csvdiff = csvlong %>%
  group_by(ID, Gender, ClinicalMeasureName,
           MeasureName) %>%
  arrange(ROIName, .by_group = T) %>%
  mutate(MeanDiff = MeanValue - lag(MeanValue),
         DiffName = paste0(ROIName, '-', lag(ROIName))) %>%
  filter(!is.na(MeanDiff))

csvdiff %>% write.csv(paste0(csvroot, 'StrokeDTIMeanDiffUnfiltered_SMST_Nov272019.csv'),
                      row.names = F)

# Computing KLD (Laplace) between lesion and contra lesion distributions ======
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_SMST_Nov272019.csv'))
klddf = csv %>% group_by(ID, MeasureName) %>%
  do(
    ID = unique(.$ID),
    MeasureName = unique(.$MeasureName),
    kldiv = KLD(density(.$Value[which(.$ROIName == 'Ipsilesional')],
                        from = 0,
                        to = case_when(unique(.$MeasureName) == 'FA' ~ 1,
                                       TRUE ~ 2),
                        bw = case_when(unique(.$MeasureName) == 'FA' ~ 0.05,
                                       TRUE ~ 0.1))$y,
                density(.$Value[which(.$ROIName == 'Contralesional')],
                        from = 0,
                        to = case_when(unique(.$MeasureName) == 'FA' ~ 1,
                                       TRUE ~ 2),
                        bw = case_when(unique(.$MeasureName) == 'FA' ~ 0.05,
                                       TRUE ~ 0.1))$y)$mean.sum.KLD
  )
klddf$ID %<>% unlist %>% as.factor
klddf$MeasureName %<>% unlist %>% as.factor
klddf$kldiv %<>% unlist

democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
mcsv = merge(
  klddf,
  democsv,
  by.x = c('ID'),
  by.y = c('SubjectID'),
  all.x = T
)
mcsv %>% write.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'),
                   row.names = F)

kcsv = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
kcsvlong = kcsv %>%
  mutate(NormAcuteTimePeriod = AcuteTimePeriod / AgeAtVisit) %>%
  gather(
    ClinicalMeasureName,
    ClinicalMeasureValue,
    YearsOfEducation:NormAcuteTimePeriod,
    factor_key = T
  )
kcsvlong %>% write.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplace_SMST_Nov272019.csv'),
                       row.names = F)
kcsvlong %>%
  filter(!(
    ClinicalMeasureName %in% c(
      'AcuteTimePeriod',
      'AgeAtVisit',
      'YearsOfEducation',
      'VerbalFluencyRaw'
    )
  )) %>%
  write.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplaceFiltered_SMST_Nov272019.csv'),
            row.names = F)

# Visualizing (annotated-Laplace) basic plots of distributions =======
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_SMST_Nov272019.csv'))
kcsvmean = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFiltered_SMST_Nov272019.csv'))
kcsvmeandiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiff_SMST_Nov272019.csv'))
kcsvkld = read.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplaceFiltered_SMST_Nov272019.csv'))
p = csv %>% mutate(SID = ID) %>%
  select(-ID) %>%
  group_by(SID) %>%
  do(
    plots = ggplot(
      data = .,
      aes(
        x = Value,
        y = MeasureName,
        color = ROIName,
        fill = ROIName
      )
    ) +
      geom_density_ridges(alpha = 0.2,
                          scale = 1.25) +
      geom_segment(
        data = subset(kcsvmean,
                      ID == unique(.$SID)),
        aes(
          x = MeanValue,
          xend = MeanValue,
          y = as.numeric(MeasureName),
          yend = as.numeric(MeasureName) + 0.9,
          color = ROIName
        )
      ) +
      geom_text(
        data = subset(kcsvmean,
                      ID == unique(.$SID)) %>%
          mutate(y_pos = rep(c(0.1, 0.8), n() / 2)),
        aes(
          x = MeanValue,
          y = as.numeric(MeasureName) + y_pos,
          label = round(MeanValue, digits = 2)
        ),
        color = 'black'
      ) +
      geom_text(
        data = merge(
          subset(kcsvkld, ID == unique(.$SID)),
          subset(kcsvmeandiff, ID == unique(.$SID))
        ),
        aes(
          x = 1.75,
          y = as.numeric(MeasureName) + 0.25,
          label = paste('MASY:', round(kldiv, 2),
                        '\nDiff:', round(MeanDiff, 2))
        ),
        inherit.aes = F
      ) +
      gtheme +
      xlim(0, 2) +
      coord_capped_cart(bottom = 'both',
                        left = 'both') +
      labs(
        y = 'DTI measure name',
        x = 'DTI measure value'
        #,
        #title = paste('Subject', unique(.$SID))
      ),
    filename = paste('DTIDistributions_Laplace_SMST_Nov272019', unique(.$SID),
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.5,
      height = 5.0
    ),
    y = print(.$plots),
    z = dev.off()
  )


# Visualizing (MASY) plots with KLD =====
# excludelist = c('SS035', 'SS036', 'SS067', 'SS022')
excludelist = c('')
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplaceFiltered_SMST_Nov272019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter(!(ID %in% excludelist)) %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = ClinicalMeasureValue,
          y = kldiv,
          color = GenderSampleSize)
    ) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(
        aes(fill = GenderSampleSize),
        alpha = 0.2,
        method = 'lm'
      ) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      lm(
        kldiv ~ ClinicalMeasureValue +
          Gender +
          ClinicalMeasureValue:Gender,
        data = .
      )
    )$p.value[[4]] %>%
      round(digits = 3),
    Name = paste(unique(.$ClinicalMeasureName),
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = plyr::mapvalues(
      .$ClinicalMeasureName,
      c('VerbalFluencyNormed',
        'NormAcuteTimePeriod'),
      c('Normalized verbal fluency',
        'Normalized acute time period')
    ),
    ylabelName = paste0('MASY [',
                        .$MeasureName,
                        ']'),
    xpos = case_when(
      .$ClinicalMeasureName == 'VerbalFluencyNormed' ~ -2,
      .$ClinicalMeasureName == 'NormAcuteTimePeriod' ~ 0.05
    )
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = .$ylabelName),
    filename = paste('MASYLaplaceSMST', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# Visualizing (MASY subset) plots with KLD =====
includelist = read.csv(paste0(csvroot, 'VerbalInfluence.csv'))
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplaceFiltered_SMST_Nov272019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter((ID %in% includelist$ID)) %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = ClinicalMeasureValue,
          y = kldiv,
          color = GenderSampleSize)
    ) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(
        aes(fill = GenderSampleSize),
        alpha = 0.2,
        method = 'lm'
      ) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      lm(
        kldiv ~ ClinicalMeasureValue +
          Gender +
          ClinicalMeasureValue:Gender,
        data = .
      )
    )$p.value[[4]] %>%
      round(digits = 3),
    Name = paste(unique(.$ClinicalMeasureName),
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = plyr::mapvalues(
      .$ClinicalMeasureName,
      c('VerbalFluencyNormed',
        'NormAcuteTimePeriod'),
      c('Normalized verbal fluency',
        'Normalized acute time period')
    ),
    ylabelName = paste0('MASY [',
                        .$MeasureName,
                        ']'),
    xpos = case_when(
      .$ClinicalMeasureName == 'VerbalFluencyNormed' ~ -2,
      .$ClinicalMeasureName == 'NormAcuteTimePeriod' ~ 0.05
    )
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = .$ylabelName),
    filename = paste('MASYLaplaceSMSTSubset', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# Visualizing (MASY raw verbal) plots with KLD =====
includelist = read.csv(paste0(csvroot, 'VerbalInfluence.csv'))
kcsv = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
p = kcsv %>%
  na.omit() %>%
  filter((ID %in% includelist$ID)) %>%
  group_by(MeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = VerbalFluencyRaw,
          y = kldiv,
          color = GenderSampleSize)
    ) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(
        aes(fill = GenderSampleSize),
        alpha = 0.2,
        method = 'lm'
      ) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      lm(
        kldiv ~ VerbalFluencyRaw +
          Gender +
          VerbalFluencyRaw:Gender,
        data = .
      )
    )$p.value[[4]] %>%
      round(digits = 3),
    Name = paste('VerbalFluencyRaw',
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = 'Raw verbal fluency',
    ylabelName = paste0('MASY [',
                        .$MeasureName,
                        ']')
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = .$ylabelName),
    filename = paste('MASYLaplaceSMSTSubsetVerbalRaw', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# Visualizing (MASY median split) plots with KLD =====
includelist = read.csv(paste0(csvroot, 'VerbalInfluence.csv'))
kcsv = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
p = kcsv %>%
  na.omit() %>%
  filter((ID %in% includelist$ID)) %>%
  mutate(VerbalBehavior = VerbalFluencyRaw > median(VerbalFluencyRaw)) %>%
  group_by(MeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = kldiv,
        color = VerbalBehavior,
        fill = VerbalBehavior)
    ) +
      geom_density(alpha = 0.2) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      t.test(kldiv ~ VerbalBehavior, data = .)
    )$p.value %>%
      round(digits = 3),
    Name = paste('VerbalFluencyRaw',
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = 'Raw verbal fluency',
    ylabelName = paste0('MASY [',
                        .$MeasureName,
                        ']')
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = .$ylabelName),
    filename = paste('MASYLaplaceSMSTSubsetVerbalRawMedianSplit', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# Visualizing (IpsiMean) plots with baseline mean =====
# excludelist = c('SS035', 'SS036', 'SS067', 'SS022')
excludelist = c('')
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFiltered_SMST_Nov272019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter(ROIName == 'Ipsilesional' & !(ID %in% excludelist)) %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = ClinicalMeasureValue,
          y = MeanValue,
          color = GenderSampleSize)
    ) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(
        aes(fill = GenderSampleSize),
        alpha = 0.2,
        method = 'lm'
      ) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      lm(
        MeanValue ~ ClinicalMeasureValue +
          Gender +
          ClinicalMeasureValue:Gender,
        data = .
      )
    )$p.value[[4]] %>%
      round(digits = 3),
    Name = paste(unique(.$ClinicalMeasureName),
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = plyr::mapvalues(
      .$ClinicalMeasureName,
      c('VerbalFluencyNormed',
        'NormAcuteTimePeriod'),
      c('Normalized verbal fluency',
        'Normalized acute time period')
    ),
    ylabelName = paste0(
      'Mean (Ipsi) \\[',
      .$MeasureName,
      '\\]',
      case_when(.$MeasureName == 'FA' ~ '',
                TRUE ~ ' $\\mu$m$^2$ms$^{-1}$')
    ),
    xpos = case_when(
      .$ClinicalMeasureName == 'VerbalFluencyNormed' ~ -2,
      .$ClinicalMeasureName == 'NormAcuteTimePeriod' ~ 0.05
    )
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = TeX(.$ylabelName)),
    filename = paste('MeanSMST', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# Visualizing (ContraMean) plots with baseline mean =====
# excluelist = c('SS035', 'SS036', 'SS067', 'SS022')
excludelist = c('')
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFiltered_SMST_Nov272019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter(ROIName == 'Contralesional' & !(ID %in% excludelist)) %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = ClinicalMeasureValue,
          y = MeanValue,
          color = GenderSampleSize)
    ) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(
        aes(fill = GenderSampleSize),
        alpha = 0.2,
        method = 'lm'
      ) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      lm(
        MeanValue ~ ClinicalMeasureValue +
          Gender +
          ClinicalMeasureValue:Gender,
        data = .
      )
    )$p.value[[4]] %>%
      round(digits = 3),
    Name = paste(unique(.$ClinicalMeasureName),
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = plyr::mapvalues(
      .$ClinicalMeasureName,
      c('VerbalFluencyNormed',
        'NormAcuteTimePeriod'),
      c('Normalized verbal fluency',
        'Normalized acute time period')
    ),
    ylabelName = paste0(
      'Mean (Contra) \\[',
      .$MeasureName,
      '\\]',
      case_when(.$MeasureName == 'FA' ~ '',
                TRUE ~ ' $\\mu$m$^2$ms$^{-1}$')
    ),
    xpos = case_when(
      .$ClinicalMeasureName == 'VerbalFluencyNormed' ~ -2,
      .$ClinicalMeasureName == 'NormAcuteTimePeriod' ~ 0.05
    )
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = TeX(.$ylabelName)),
    filename = paste('MeanContraSMST', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# Visualizing (MeanDiff) plots with baseline mean diff =====
#excludelist = c('SS035', 'SS036', 'SS067', 'SS022')
excludelist = c('')
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanDiff_SMST_Nov272019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter(ROIName == 'Ipsilesional' & !(ID %in% excludelist)) %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')') %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = ClinicalMeasureValue,
          y = MeanDiff,
          color = GenderSampleSize)
    ) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(
        aes(fill = GenderSampleSize),
        alpha = 0.2,
        method = 'lm'
      ) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      lm(
        MeanDiff ~ ClinicalMeasureValue +
          Gender +
          ClinicalMeasureValue:Gender,
        data = .
      )
    )$p.value[[4]] %>%
      round(digits = 3),
    Name = paste(unique(.$ClinicalMeasureName),
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = plyr::mapvalues(
      .$ClinicalMeasureName,
      c('VerbalFluencyNormed',
        'NormAcuteTimePeriod'),
      c('Normalized verbal fluency',
        'Normalized acute time period')
    ),
    ylabelName = paste0(
      '$\\Delta$ (Ipsi - contra) \\[',
      .$MeasureName,
      '\\]',
      case_when(.$MeasureName == 'FA' ~ '',
                TRUE ~ ' $\\mu$m$^2$ms$^{-1}$')
    ),
    xpos = case_when(
      .$ClinicalMeasureName == 'VerbalFluencyNormed' ~ -2,
      .$ClinicalMeasureName == 'NormAcuteTimePeriod' ~ 0.05
    )
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = TeX(.$ylabelName)),
    filename = paste('MeanDiffSMST', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# Basic info ====
imgcsv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_SMST_Nov272019.csv'))
imgids = imgcsv %>% select(ID) %>% distinct() %>% pull
democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
democsv %>% 
  filter(SubjectID %in% imgids) %>% 
  summarise(MeanAge = mean(AgeAtVisit), 
            MeanYoE = mean(YearsOfEducation, na.rm = T))


# Age effect on KLD =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplace_SMST_Nov272019.csv'))
mdl = kcsvlong %>% 
  filter(ClinicalMeasureName == 'AgeAtVisit') %>% 
  group_by(MeasureName) %>%
  do(
    pval = (lm(kldiv ~ 
               ClinicalMeasureValue,
             data = .) %>% tidy())$p.value[[2]]
  )

kcsvlong %>% 
  filter(ClinicalMeasureName == 'AgeAtVisit') %>% 
  ggplot(data = ., aes(x = ClinicalMeasureValue, 
                       y = kldiv)) + 
  geom_point() + 
  geom_smooth(method = 'lm') +
  facet_rep_grid(.~MeasureName) +
  gtheme + labs(x = 'Age at visit',
                y = 'MASY')


# Gender effect on KLD =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplace_SMST_Nov272019.csv'))
mdl = kcsvlong %>% 
  filter(ClinicalMeasureName == 'AgeAtVisit') %>% 
  group_by(MeasureName) %>%
  do(
    pval = (lm(kldiv ~ 
                 Gender,
               data = .) %>% tidy())$p.value[[2]]
  )

p = kcsvlong %>% 
  filter(ClinicalMeasureName == 'AgeAtVisit') %>% 
  ggplot(data = ., aes(x = kldiv, 
                       color = Gender,
                       fill = Gender)) + 
  geom_density(alpha = 0.2) + 
  facet_rep_grid(.~MeasureName) +
  gtheme + labs(x = 'MASY',
                y = 'Density of samples')
pdf(paste0(figroot, '/GenderMASY.pdf'),
    width = 5.75,
    height = 3.25)
print(p)
dev.off()

# Gender effect Delta =====
excludelist = c('')
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanDiff_SMST_Nov272019.csv'))
mdl = kcsvlong %>% 
  filter(ClinicalMeasureName == 'NormAcuteTimePeriod') %>% 
  group_by(MeasureName) %>%
  do(
    pval = (lm(MeanDiff ~ 
                 Gender,
               data = .) %>% tidy())$p.value[[2]]
  )

p = kcsvlong %>% 
  filter(ClinicalMeasureName == 'NormAcuteTimePeriod') %>% 
  ggplot(data = ., aes(x = MeanDiff, 
                       color = Gender,
                       fill = Gender)) + 
  geom_density(alpha = 0.2) + 
  facet_rep_grid(.~MeasureName) +
  gtheme + labs(x = TeX('$\\Delta$(Ipsi - contra)'),
                y = 'Density of samples') +
  theme(axis.text.x = element_text(angle = 90))
p
pdf(paste0(figroot, '/GenderDelta.pdf'),
    width = 5.75,
    height = 3.25)
print(p)
dev.off()

# Gender difference mean ipsi =======
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFiltered_SMST_Nov272019.csv'))
mdl = kcsvlong %>% 
  filter(ClinicalMeasureName == 'NormAcuteTimePeriod' &
           ROIName == 'Ipsilesional') %>% 
  group_by(MeasureName) %>%
  do(
    pval = (lm(MeanValue ~ 
                 Gender,
               data = .) %>% tidy())$p.value[[2]]
  )

p = kcsvlong %>% 
  filter(ClinicalMeasureName == 'NormAcuteTimePeriod') %>% 
  ggplot(data = ., aes(x = MeanValue, 
                       color = Gender,
                       fill = Gender)) + 
  geom_density(alpha = 0.2) + 
  facet_rep_grid(.~MeasureName) +
  gtheme + labs(x = 'Mean (Ipsi)',
                y = 'Density of samples') +
  theme(axis.text.x = element_text(angle = 90))
p
pdf(paste0(figroot, '/GenderIpsi.pdf'),
    width = 5.75,
    height = 3.25)
print(p)
dev.off()



# Verbal effect on MASY separately by gender =====
excludelist = c('')
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongLaplaceFiltered_SMST_Nov272019.csv'))

p = kcsvlong %>%
  na.omit() %>%
  filter(!(ID %in% excludelist)) %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName, GenderSampleSize) %>%
  do(
    plots = ggplot(
      data = .,
      aes(x = ClinicalMeasureValue,
          y = kldiv,
          color = GenderSampleSize)
    ) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(
        aes(fill = GenderSampleSize),
        alpha = 0.2,
        method = 'lm'
      ) +
      coord_capped_cart(bottom = 'both',
                        left = 'both'),
    pvalue = tidy(
      lm(
        kldiv ~ ClinicalMeasureValue,
        data = .
      )
    )$p.value[[2]] %>%
      round(digits = 3),
    Name = paste(unique(.$ClinicalMeasureName),
                 unique(.$MeasureName),
                 sep = '_'),
    xlabelName = plyr::mapvalues(
      .$ClinicalMeasureName,
      c('VerbalFluencyNormed',
        'NormAcuteTimePeriod'),
      c('Normalized verbal fluency',
        'Normalized acute time period')
    ),
    ylabelName = paste0('MASY [',
                        .$MeasureName,
                        ']'),
    xpos = case_when(
      .$ClinicalMeasureName == 'VerbalFluencyNormed' ~ -2,
      .$ClinicalMeasureName == 'NormAcuteTimePeriod' ~ 0.05
    )
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      geom_text(
        x = -Inf,
        y = -Inf,
        hjust = -0.1,
        vjust = -1.0,
        label = paste('p:',
                      .$pvalue),
        inherit.aes = F,
        size = 6
      ) +
      gtheme +
      theme(legend.position = c(0.7, 0.9)) +
      labs(x = .$xlabelName,
           y = .$ylabelName),
    filename = paste('MASYLaplaceSMST', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 5.0,
      height = 4.15
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )

# One sampled t-tests (MASY) =======
kcsvkld = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
mdls = kcsvkld %>% 
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$kldiv, alternative = 'greater')
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
       aes(x = name,
           y = est,
           color = name,
           fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = -Inf,
                angle = 90,
                label = paste0('p=', 
                               formatC(pval, format = 'e', digits = 2))), 
            hjust = -0.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('MASY'),
       title = 'Full sample (n = 27)') +
  theme(plot.title = element_text(hjust = 0.5))
p
pdf(paste0(figroot, 'MASYOnly.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()


# One sampled t-tests (MASY by Male) =======
kcsvkld = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
mdls = kcsvkld %>% 
  filter(Gender == 'Male') %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$kldiv, alternative = 'greater')
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = -Inf,
                angle = 90,
                label = round(pval, digits = 6)), 
            hjust = -0.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('MASY'),
       title = 'Male (n = 16)') +
  theme(plot.title = element_text(hjust = 0.5))
p
pdf(paste0(figroot, 'MASYOnly_Male.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()


# One sampled t-tests (MASY by Female) =======
kcsvkld = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
mdls = kcsvkld %>% 
  filter(Gender == 'Female') %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$kldiv, alternative = 'greater')
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = -Inf,
                angle = 90,
                label = round(pval, 6)), 
            hjust = -0.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('MASY'),
       title = 'Female (n = 11)') +
  theme(plot.title = element_text(hjust = 0.5))
p
pdf(paste0(figroot, 'MASYOnly_Female.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()

# One sampled t-tests (MASY by Low verbal) =======
kcsvkld = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
mdls = kcsvkld %>% 
  filter(VerbalFluencyRaw < median(VerbalFluencyRaw)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$kldiv, alternative = 'greater')
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = -Inf,
                angle = 90,
                label = round(pval, 6)), 
            hjust = -0.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('MASY'),
       title = 'Low verbal fluency (n = 13)') +
  theme(plot.title = element_text(hjust = 0.5))
p
pdf(paste0(figroot, 'MASYOnly_LowVerbal.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()

# One sampled t-tests (MASY by High verbal) =======
kcsvkld = read.csv(paste0(csvroot, 'StrokeDTIKLDLaplace_SMST_Nov272019.csv'))
mdls = kcsvkld %>% 
  filter(VerbalFluencyRaw >= median(VerbalFluencyRaw)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$kldiv, alternative = 'greater')
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = -Inf,
                angle = 90,
                label = round(pval, 6)), 
            hjust = -0.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('MASY'),
       title = 'High verbal fluency (n = 14)') +
  theme(plot.title = element_text(hjust = 0.5))
p
pdf(paste0(figroot, 'MASYOnly_HighVerbal.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()

# One sampled t-test (meandiff) =======
kcsvmeandiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiff_SMST_Nov272019.csv'))
mdls = kcsvmeandiff %>%
  filter(grepl('Acute', ClinicalMeasureName)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$MeanDiff)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
       aes(x = name,
           y = est,
           color = name,
           fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = paste0('p=', 
                               formatC(pval, format = 'e', digits = 2))), 
            hjust = 1.5, 
            size= 9,
            color = 'black') +
  labs(x = '',
       y = TeX('$\\Delta$(Ipsi - Contra)'),
       title = 'Full sample (n = 27)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'DeltaOnly.pdf'),
    width = 5.65, height = 5.45)
print(p)
dev.off()

# One sampled t-test (meandiff by Male) =======
kcsvmeandiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiff_SMST_Nov272019.csv'))
mdls = kcsvmeandiff %>%
  filter(grepl('Acute', ClinicalMeasureName) &
           Gender == 'Male') %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$MeanDiff)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('$\\Delta$(Ipsi - Contra)'),
       title = 'Male (n = 16)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'DeltaOnly_Male.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()

# One sampled t-test (meandiff by Female) =======
kcsvmeandiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiff_SMST_Nov272019.csv'))
mdls = kcsvmeandiff %>%
  filter(grepl('Acute', ClinicalMeasureName) &
           Gender == 'Female') %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$MeanDiff)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('$\\Delta$(Ipsi - Contra)'),
       title = 'Female (n = 11)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'DeltaOnly_Female.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()

# One sampled t-test (meandiff by Low verbal) =======
kcsvmeandiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiffUnfiltered_SMST_Nov272019.csv'))
mdls = kcsvmeandiff %>%
  filter(ClinicalMeasureName == 'VerbalFluencyRaw') %>%
  filter(ClinicalMeasureValue < median(ClinicalMeasureValue)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$MeanDiff)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('$\\Delta$(Ipsi - Contra)'),
       title = 'Low verbal fluency (n = 13)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'DeltaOnly_LowVerbal.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()

# One sampled t-test (meandiff by High verbal) =======
kcsvmeandiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiffUnfiltered_SMST_Nov272019.csv'))
mdls = kcsvmeandiff %>%
  filter(ClinicalMeasureName == 'VerbalFluencyRaw') %>%
  filter(ClinicalMeasureValue >= median(ClinicalMeasureValue)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.),
    htest = t.test(.$MeanDiff)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
mdls$est %<>% unlist
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = est,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('$\\Delta$(Ipsi - Contra)'),
       title = 'High verbal fluency (n = 14)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'DeltaOnly_HighVerbal.pdf'),
    width = 5.65, height = 5.45)
print(p)
dev.off()

# Two sampled t-test mean ======
kcsvmean = read.csv(paste0(csvroot, 'StrokeDTIMean_SMST_Nov272019.csv'))
mdls = kcsvmean %>%
  mutate(ROIName = fct_relevel(ROIName, 'Contralesional', after = 1)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.)/2,
    htest = t.test(MeanValue ~ ROIName, data = .,
                   paired = F)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
tmp = mdls$est %>% unlist
mdls$estipsi = tmp[seq(1, 8, 2)]
mdls$estcontra = tmp[seq(2, 8, 2)]
mdls$delta = mdls$estipsi - mdls$estcontra
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = delta,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = paste0('p=', 
                               formatC(pval, format = 'e', digits = 2))), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('(Ipsi - Contra)'),
       title = 'Full sample (n = 27)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'MeanOnly.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()
# Two sampled t-test mean (Male) ======
kcsvmean = read.csv(paste0(csvroot, 'StrokeDTIMean_SMST_Nov272019.csv'))
mdls = kcsvmean %>%
  filter(Gender == 'Male') %>%
  mutate(ROIName = fct_relevel(ROIName, 'Contralesional', after = 1)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.) / 2,
    htest = t.test(MeanValue ~ ROIName, data = .,
                   paired = F)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
tmp = mdls$est %>% unlist
mdls$estipsi = tmp[seq(1, 8, 2)]
mdls$estcontra = tmp[seq(2, 8, 2)]
mdls$delta = mdls$estipsi - mdls$estcontra
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = delta,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, digits = 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('(Ipsi - Contra)'),
       title = 'Male (n = 16)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'MeanOnly_Male.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()
# Two sampled t-test mean (Female) ======
kcsvmean = read.csv(paste0(csvroot, 'StrokeDTIMean_SMST_Nov272019.csv'))
mdls = kcsvmean %>%
  filter(Gender == 'Female') %>%
  mutate(ROIName = fct_relevel(ROIName, 'Contralesional', after = 1)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.) / 2,
    htest = t.test(MeanValue ~ ROIName, data = .,
                   paired = F)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
tmp = mdls$est %>% unlist
mdls$estipsi = tmp[seq(1, 8, 2)]
mdls$estcontra = tmp[seq(2, 8, 2)]
mdls$delta = mdls$estipsi - mdls$estcontra
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = delta,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('(Ipsi - Contra)'),
       title = 'Female (n = 11)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'MeanOnly_Female.pdf'), 
    width = 5.65, height = 5.45)
print(p)
dev.off()
# Two sampled t-test mean (Low verbal) ======
kcsvmean = read.csv(paste0(csvroot, 'StrokeDTIMean_SMST_Nov272019.csv'))
mdls = kcsvmean %>%
  filter(VerbalFluencyRaw < median(VerbalFluencyRaw)) %>%
  mutate(ROIName = fct_relevel(ROIName, 'Contralesional', after = 1)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.) / 2,
    htest = t.test(MeanValue ~ ROIName, data = .,
                   paired = F)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
tmp = mdls$est %>% unlist
mdls$estipsi = tmp[seq(1, 8, 2)]
mdls$estcontra = tmp[seq(2, 8, 2)]
mdls$delta = mdls$estipsi - mdls$estcontra
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = delta,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('(Ipsi - Contra)'),
       title = 'Low verbal fluency (n = 13)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'MeanOnly_LowVerbal.pdf'),
    width = 5.65, height = 5.45)
print(p)
dev.off()
# Two sampled t-test mean (High verbal) ======
kcsvmean = read.csv(paste0(csvroot, 'StrokeDTIMean_SMST_Nov272019.csv'))
mdls = kcsvmean %>%
  filter(VerbalFluencyRaw >= median(VerbalFluencyRaw)) %>%
  mutate(ROIName = fct_relevel(ROIName, 'Contralesional', after = 1)) %>%
  group_by(MeasureName) %>%
  do(
    name = unique(.$MeasureName),
    samplesize = nrow(.) / 2,
    htest = t.test(MeanValue ~ ROIName, data = .,
                   paired = F)
  ) %>%
  do(
    name = .$name,
    samplesize = .$samplesize,
    pval = .$htest$p.value,
    est = .$htest$estimate,
    ci = .$htest$conf.int
  )
mdls$name %<>% unlist %<>% as.factor
mdls$pval %<>% unlist
mdls$samplesize %<>% unlist
tmp = mdls$est %>% unlist
mdls$estipsi = tmp[seq(1, 8, 2)]
mdls$estcontra = tmp[seq(2, 8, 2)]
mdls$delta = mdls$estipsi - mdls$estcontra
tmp = mdls$ci %>% unlist
mdls$cimin = tmp[seq(1, 8, 2)]
mdls$cimax = tmp[seq(2, 8, 2)]
p = ggplot(mdls,
           aes(x = name,
               y = delta,
               color = name,
               fill = name)) +
  geom_bar(stat = 'identity',
           alpha = 0.2) +
  geom_errorbar(aes(ymin = cimin,
                    ymax = cimax),
                width = 0.2) +
  guides(fill = F, color =F) +
  gtheme +
  geom_text(aes(x = name, 
                y = Inf, 
                angle = 90,
                label = round(pval, 6)), 
            hjust = 1.5, 
            size = 9,
            color = 'black') +
  labs(x = '',
       y = TeX('(Ipsi - Contra)'),
       title = 'High verbal fluency (n = 14)') +
  theme(plot.title = element_text(hjust = 0.5))

p
pdf(paste0(figroot, 'MeanOnly_HighVerbal.pdf'),
    width = 5.65, height = 5.45)
print(p)
dev.off()
# roughwork =====
kcsvmean %>% ggplot(aes(x = MeanValue, 
                        color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2) + 
  facet_rep_grid(.~MeasureName) + gtheme

mdls = kcsvmean %>% 
  group_by(MeasureName) %>% 
  do(h = t.test(MeanValue ~ ROIName, 
                data = ., paired = F))
md