source('H:/adluru/StrokeAndDiffusionProject/uwstrokeproject/AnalysisCode/RSNATheme.R')
source('/Users/nadluru/home/adluru/StrokeAndDiffusionProject/uwstrokeproject/AnalysisCode/RSNATheme.R')

# Merging with basic demographics ====
imgcsv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTINov152019.csv'))
democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
mcsv = merge(
  imgcsv,
  democsv,
  by.x = c('ID'),
  by.y = c('SubjectID'),
  all.x = T
)
mcsv %>% write.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo.csv'),
                   row.names = F)

# CSVs for baseline comparisons (mean) ======
imgcsv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTINov152019.csv')) %>%
  group_by(ID, MeasureName, ROIName) %>% summarise(MeanValue = mean(Value))
democsv = read.csv(paste0(csvroot, 'BasicDemographicsNov152019.csv'))
mcsv = merge(
  imgcsv,
  democsv,
  by.x = c('ID'),
  by.y = c('SubjectID'),
  all.x = T
)
mcsv %>% write.csv(paste0(csvroot, 'StrokeDTIMeanNov2019.csv'),
                   row.names = F)

csv = read.csv(paste0(csvroot, 'StrokeDTIMeanNov2019.csv'))
csvlong = csv %>%
  mutate(NormAcuteTimePeriod = AcuteTimePeriod / AgeAtVisit) %>%
  gather(
    ClinicalMeasureName,
    ClinicalMeasureValue,
    YearsOfEducation:NormAcuteTimePeriod,
    factor_key = T
  )
csvlong %>% write.csv(paste0(csvroot, 'StrokeDTIMeanLongNov2019.csv'),
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
  write.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov2019.csv'),
            row.names = F)

# CSVs for baseline comparisons (mean diff) ======
csvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov2019.csv'))
csvdiff = csvlong %>%
  group_by(ID, Gender, ClinicalMeasureName,
           MeasureName) %>%
  arrange(ROIName, .by_group = T) %>%
  mutate(MeanDiff = MeanValue - lag(MeanValue),
         DiffName = paste0(ROIName, '-', lag(ROIName))) %>%
  filter(!is.na(MeanDiff))

csvdiff %>% write.csv(paste0(csvroot, 'StrokeDTIMeanDiffNov2019.csv'),
                      row.names = F)


# Computing KLD between lesion and contra lesion distributions ======
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo.csv'))
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

# Visualizing basic plots of distributions =======
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo.csv')) %>% 
  filter(ID == 'SS032')
p = csv %>% group_by(ID) %>%
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
                          scale = 1.0) +
      gtheme +
      xlim(0, 2) +
      theme(legend.position = c(0.7, 0.5)) +
      coord_capped_cart(bottom = 'both',
                        left = 'both') +
      labs(y = 'DTI measure name',
           x = 'DTI measure value')
    ,
    Name = unique(.$ID)
  ) %>%
  rowwise() %>%
  do(
    plotsanno = .$plots +
      labs(title = paste('Subject', .$Name)),
    filename = paste('DTIDistributions', .$Name,
                     sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(
    x = pdf(
      paste0(figroot, gsub("/", "", .$filename), '.pdf'),
      width = 7.5,
      height = 5.5
    ),
    y = print(.$plotsanno),
    z = dev.off()
  )


# Visualizing (no facets) plots with KLD =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIKLDLongFilteredNov2019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')') 
         %>% as.factor) %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(data = .,
                   aes(
                     x = ClinicalMeasureValue,
                     y = kldiv,
                     color = GenderSampleSize
                   )) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(aes(fill = GenderSampleSize),
                  alpha = 0.2,
                  method = 'lm') +
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

# Visualizing (no facets, ipsi) plots with baseline mean =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov2019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter(ROIName == 'Ipsilesional') %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')') 
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(data = .,
                   aes(
                     x = ClinicalMeasureValue,
                     y = MeanValue,
                     color = GenderSampleSize
                   )) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(aes(fill = GenderSampleSize),
                  alpha = 0.2,
                  method = 'lm') +
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


# Visualizing (no facets, contra) plots with baseline mean =====
kcsvlong = read.csv(paste0(csvroot, 'StrokeDTIMeanLongFilteredNov2019.csv'))
p = kcsvlong %>%
  na.omit() %>%
  filter(grepl('Contra', ROIName)) %>%
  group_by(MeasureName, ClinicalMeasureName, Gender) %>%
  mutate(GenderSampleSize = paste0(Gender, ' (n = ', n(), ')') 
         %>% as.factor) %>% ungroup %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    plots = ggplot(data = .,
                   aes(
                     x = ClinicalMeasureValue,
                     y = MeanValue,
                     color = GenderSampleSize
                   )) +
      geom_point(size = 1.5, alpha = 0.8) +
      geom_smooth(aes(fill = GenderSampleSize),
                  alpha = 0.2,
                  method = 'lm') +
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
    filename = paste('MeanContra', .$Name,
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
