source('H:/adluru/StrokeAndDiffusionProject/uwstrokeproject/AnalysisCode/RSNATheme.R')

# Merging with basic demographics ====
imgcsv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTI_MNIFlipped_Nov262019.csv'))
democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
mcsv = merge(
  imgcsv,
  democsv,
  by.x = c('ID'),
  by.y = c('SubjectID'),
  all.x = T
)
mcsv %>% write.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_Nov262019.csv'),
                   row.names = F)

# CSVs for baseline comparisons (mean) ======
imgcsv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTI_MNIFlipped_Nov262019.csv')) %>%
  group_by(ID, MeasureName, ROIName) %>% summarise(MeanValue = mean(Value))
democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
mcsv = merge(
  imgcsv,
  democsv,
  by.x = c('ID'),
  by.y = c('SubjectID'),
  all.x = T
)
mcsv %>% write.csv(paste0(csvroot, 'StrokeDTIMeanNov262019.csv'),
                   row.names = F)

csv = read.csv(paste0(csvroot, 'StrokeDTIMeanNov262019.csv'))
csvlong = csv %>%
  mutate(NormAcuteTimePeriod = AcuteTimePeriod / AgeAtVisit) %>%
  gather(
    ClinicalMeasureName,
    ClinicalMeasureValue,
    YearsOfEducation:NormAcuteTimePeriod,
    factor_key = T
  )
csvlong %>% write.csv(paste0(csvroot, 'StrokeDTIMeanLongNov262019.csv'),
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
  write.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov262019.csv'),
            row.names = F)

# CSVs for baseline comparisons (mean diff) ======
csvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov262019.csv'))
csvdiff = csvlong %>%
  group_by(ID, Gender, ClinicalMeasureName,
           MeasureName) %>%
  arrange(ROIName, .by_group = T) %>%
  mutate(MeanDiff = MeanValue - lag(MeanValue),
         DiffName = paste0(ROIName, '-', lag(ROIName))) %>%
  filter(!is.na(MeanDiff))

csvdiff %>% write.csv(paste0(csvroot, 'StrokeDTIMeanDiffNov262019.csv'),
                      row.names = F)

# Computing KLD (Laplace) between lesion and contra lesion distributions ======
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_Nov262019.csv'))
klddf = csv %>% group_by(ID, MeasureName) %>%
  do(
    ID = unique(.$ID),
    MeasureName = unique(.$MeasureName),
    kldiv = KLD(density(.$Value[which(.$ROIName == 'Ipsilesional')])$y,
                density(.$Value[which(.$ROIName == 'Contralesional')])$y)$mean.sum.KLD
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
mcsv %>% write.csv(paste0(csvroot, 'StrokeDTIKLDNov2019.csv'),
                   row.names = F)

kcsv = read.csv(paste0(csvroot, 'StrokeDTIKLDNov2019.csv'))
kcsvlong = kcsv %>%
  mutate(NormAcuteTimePeriod = AcuteTimePeriod / AgeAtVisit) %>%
  gather(
    ClinicalMeasureName,
    ClinicalMeasureValue,
    YearsOfEducation:NormAcuteTimePeriod,
    factor_key = T
  )
kcsvlong %>% write.csv(paste0(csvroot, 'StrokeDTIKLDLongNov2019.csv'),
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
  write.csv(paste0(csvroot, 'StrokeDTIKLDLongFilteredNov2019.csv'),
            row.names = F)

# Computing KLD (entropy) between lesion and contra lesion distributions ======
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_Nov262019.csv'))
klddf = csv %>% group_by(ID, MeasureName) %>%
  do(
    ID = unique(.$ID),
    MeasureName = unique(.$MeasureName),
    y1 = discretize(.$Value[which(.$ROIName == 'Ipsilesional')],
                    20, c(0, case_when(.$MeasureName == 'FA' ~ 1,
                                       TRUE ~ 2))
                    ),
    y2 = discretize(.$Value[which(.$ROIName == 'Contralesional')],
                    20, c(0, case_when(.$MeasureName == 'FA' ~ 1,
                                       TRUE ~ 2))
                    )
  ) %>% rowwise() %>%
  do(
    ID = unique(.$ID),
    MeasureName = unique(.$MeasureName),
    kldiv = 0.5 * (KL.shrink(.$y1, .$y2) + 
                     KL.shrink(.$y2, .$y1))
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
mcsv %>% write.csv(paste0(csvroot, 'StrokeDTIKLDNov262019.csv'),
                   row.names = F)

kcsv = read.csv(paste0(csvroot, 'StrokeDTIKLDNov262019.csv'))
kcsvlong = kcsv %>%
  mutate(NormAcuteTimePeriod = AcuteTimePeriod / AgeAtVisit) %>%
  gather(
    ClinicalMeasureName,
    ClinicalMeasureValue,
    YearsOfEducation:NormAcuteTimePeriod,
    factor_key = T
  )
kcsvlong %>% write.csv(paste0(csvroot, 'StrokeDTIKLDLongNov262019.csv'),
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
  write.csv(paste0(csvroot, 'StrokeDTIKLDLongFilteredNov262019.csv'),
            row.names = F)

# Visualizing (annotated) basic plots of distributions =======
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_Nov262019.csv'))
kcsvmean = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov262019.csv'))
kcsvmeandiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiffNov262019.csv'))
kcsvkld = read.csv(paste0(csvroot, 'StrokeDTIKLDLongFilteredNov262019.csv'))
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
        x = 'DTI measure value',
        title = paste('Subject', unique(.$SID))
      ),
    filename = paste('DTIDistributions_Nov262019', unique(.$SID),
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


# Visualizing (facets) plots with KLD =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongFilteredNov2019.csv'))
dfTxt = kcsvlong %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(pvalue = tidy(
    lm(
      kldiv ~ ClinicalMeasureValue +
        Gender +
        ClinicalMeasureValue:Gender,
      data = .
    )
  )$p.value[[4]] %>% round(digits = 3))
dfTxt$pvalue %<>% unlist %>% paste("p: ", .)
dfTxt$xpos = c(0.1, 0) %>% rep(4)
dfTxt$ypos = c(2) %>% rep(8)
panno = kcsvlong %>%
  ggplot(aes(x = ClinicalMeasureValue,
             y = kldiv,
             color = Gender)) +
  geom_point(size = 1.5, alpha = 0.8) +
  geom_smooth(aes(fill = Gender),
              alpha = 0.2,
              method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName ~ MeasureName,
                 scales = "free",
                 ncol = 4) +
  gtheme +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Microstructural asymmetry (MASY)',
       x = 'Clinical measure') +
  geom_text(
    data = dfTxt,
    color = 'black',
    aes(
      x = xpos,
      y = ypos,
      label = pvalue,
      color = 'black'
    ),
    hjust = 0.5,
    vjust = -1
  )
panno
pdf(paste0(figroot, 'MASY', '.pdf'),
    width = 10.95,
    height = 6)
print(panno)
dev.off()


# Visualizing (no facets) plots with KLD =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongFilteredNov2019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')')
         %>% as.factor) %>%
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
    filename = paste('MASY', .$Name,
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

# Baseline visualization (mean) ======
csvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov2019.csv'))
dfTxt = csvlong %>%
  filter(ROIName == 'Ipsilesional') %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(pvalue = tidy(
    lm(
      MeanValue ~ ClinicalMeasureValue +
        Gender +
        ClinicalMeasureValue:Gender,
      data = .
    )
  )$p.value[[4]] %>% round(digits = 3))
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)
panno = csvlong %>%
  filter(ROIName == 'Ipsilesional') %>%
  ggplot(aes(x = ClinicalMeasureValue,
             y = MeanValue,
             color = Gender)) +
  geom_point(size = 1.5, alpha = 0.2) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName ~ MeasureName,
                 scales = "free",
                 ncol = 4) +
  gtheme +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Mean DTI value',
       x = 'Clinical measure') +
  geom_text(
    data = dfTxt,
    aes(x = -Inf,
        y = -Inf,
        label = pvalue),
    color = 'black',
    size = 6,
    hjust = -0.1,
    vjust = -1
  )
panno
pdf(paste0(figroot, 'Mean', '.pdf'),
    width = 10.25,
    height = 6)
print(panno)
dev.off()

# Visualizing (no facets) plots with baseline mean =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov2019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter(ROIName == 'Ipsilesional') %>%
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
      'Mean \\[',
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
    filename = paste('Mean', .$Name,
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

# Baseline visualization (mean diff) ========
csvdiff = read.csv(paste0(csvroot, 'StrokeDTIMeanDiffNov2019.csv'))
dfTxt = csvdiff %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(pvalue = tidy(
    lm(
      MeanDiff ~ ClinicalMeasureValue +
        Gender +
        ClinicalMeasureValue:Gender,
      data = .
    )
  )$p.value[[4]] %>%
    round(digits = 3))
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)

panno = csvdiff %>%
  ggplot(aes(x = ClinicalMeasureValue,
             y = MeanDiff,
             color = Gender)) +
  geom_point(size = 1.5, alpha = 0.2) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName ~ MeasureName,
                 scales = "free",
                 ncol = 4) +
  gtheme +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Mean DTI difference (ipsi - contra)',
       x = 'Clinical measure') +
  geom_text(
    data = dfTxt,
    aes(x = -Inf,
        y = -Inf,
        label = pvalue),
    color = 'black',
    size = 6,
    hjust = -0.1,
    vjust = -1
  )
panno
pdf(paste0(figroot, 'MeanDiff', '.pdf'),
    width = 10.25,
    height = 6)
print(panno)
dev.off()

# Visualizing (no facets) plots with baseline mean diff =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanDiffNov2019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')') %>% as.factor) %>% ungroup %>%
  filter(ROIName == 'Ipsilesional') %>%
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
    filename = paste('MeanDiff', .$Name,
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
