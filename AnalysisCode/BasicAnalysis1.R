# libraries=====
library(ANTsR)
library(dplyr)
library(expm)
library(parallel)
library(magrittr)
library(tidyr)
library(plyr)
detach(package:plyr)

library(DataCombine)
library(ggplot2)
library(ggridges)
library(GGally)
library(lemon)

# Initial variables =======
rm(list = ls(all = TRUE))
homedir = 'Z:/adluru/'
homedir = 'Z:/'
homedir = '/home/nadluru/'
homedir = '/home/adluru/'
projRoot = paste0(homedir, 'StrokeAndDiffusionProject/uwstrokeproject/')
projRoot = paste0(homedir, 'uwstrokeproject/')
csvRoot = paste0(projRoot, 'CSVs/')
dataroot = '/bitest/adluru/'
dataroot = 'X:/adluru/'
figroot = paste0(dataroot, 'Figures/')

# Reorganizing csv columns =====
csv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed.csv'))
csv %<>% separate(ID, sep ="V1", into = c('ID', 'MeasureName'))
csv$ID %<>% as.factor
csv$MeasureName %<>% as.factor
csv %<>% separate(ROI, sep = "_", into = c('tmpID', 'ROIName')) %>%
  select(-tmpID)
csv$ROIName %<>% as.factor
csv %>% write.csv(file = paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed2.csv'),
                  row.names = FALSE)
csv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed2.csv'))

# Merging with basic demographics ====
imgcsv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed2.csv'))
democsv = read.csv(paste0(csvRoot, 'BasicDemographics.csv'))
library(plyr)
democsv$Gender %<>% mapvalues(from = c('F', 'M'),
                          to = c('female', 'male')) %>%
  as.factor
detach(package:plyr)
mcsv = merge(imgcsv, democsv, by.x = c('ID'), by.y = c('SUBJECTID'), all.x = TRUE)
mcsv %>% write.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed3.csv'),
                   row.names = FALSE)

# Computing KLD between lesion and contra lesion distributions ======
library(LaplacesDemon)
csv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed3.csv'))
klddf = csv %>% group_by(ID, MeasureName) %>%
  do(
    ID = unique(.$ID),
    MeasureName = unique(.$MeasureName),
    kldiv = KLD(density(.$Value[which(.$ROIName == 'AcuteLesionMask')])$y,
                density(.$Value[which(.$ROIName == 'ContraLesionMask')])$y)$mean.sum.KLD
  )
klddf$ID %<>% unlist %>% as.factor
klddf$MeasureName %<>% unlist %>% as.factor
klddf$kldiv %<>% unlist
democsv = read.csv(paste0(csvRoot, 'BasicDemographics.csv'))
library(plyr)
democsv$Gender %<>% mapvalues(from = c('F', 'M'),
                              to = c('female', 'male')) %>%
  as.factor
detach(package:plyr)
mcsv = merge(klddf, democsv,
             by.x = c('ID'),
             by.y = c('SUBJECTID'),
             all.x = TRUE)
mcsv %>% write.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'),
                   row.names = FALSE)

kcsv = read.csv(paste0(csvRoot, 'StrokeDTIKLDColsRenamed2.csv'))
kcsvlong = kcsv %>% 
  gather(ClinicalMeasureName, 
         ClinicalMeasureValue,
         Years.of.Education:Normalized.Verbal.Fluency,
         factor_key = TRUE)
kcsvlong %>% write.csv(paste0(csvRoot, 'StrokeDTIKLDLong.csv'),
                       row.names = FALSE)
# Visualizing basic plots of distributions =======
csv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed3.csv'))
p = csv %>% group_by(ID) %>%
  do(
    plots = ggplot(data = .,
                   aes(x = Value,
                       y = MeasureName,
                       color = ROIName,
                       fill = ROIName)) + 
      #geom_density_ridges(aes(point_color = ROIName),
       #                   jittered_points = TRUE,
        #                  point_alpha = 0.1,
         #                 point_shape = "|",
          #                point_size = 3,
#                          rel_min_height = .01,
           #               size = 0.25,
            #              alpha = 0.5, 
             #             scale = 1.0,
              #            position = position_points_jitter(height = 0)) +
  geom_density_ridges(
                      alpha = 0.2, 
                      scale = 1.0
                      ) +
      theme(axis.text = element_text(size = 15),
            axis.title = element_text(size = 15),
            strip.text = element_text(size = 15),
            legend.title = element_text(size = 15),
            legend.text = element_text(size = 15),
            plot.title = element_text(size = 15, hjust = 0.5),
            panel.border = element_blank(), 
            axis.line = element_line()) +
      coord_capped_cart(bottom = 'both',
                        left = 'both') +
      labs(y = 'DTI measure name',
           x = 'DTI measure value')
    ,
    Name = unique(.$ID)
  ) %>%
  rowwise() %>%
  do(plotsanno = .$plots + 
       labs(title = paste('Subject', .$Name)),
     filename = paste('DTIDistributions', .$Name, 
                      sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(x = pdf(paste0(figroot, gsub("/", "", .$filename), '.pdf'),
             width = 7.5, height = 5.5),
     y = print(.$plotsanno),
     z = dev.off()
  )

p = csv %>% 
  mutate(Age = Age_at_Visit1.visit1.date...DOB. %>% as.factor) %>% 
  ggplot(aes(x = Value, y = Age, color = ROIName, fill = ROIName)) + 
  geom_density_ridges(alpha = 0.2, scale = 1.0) + 
  facet_rep_wrap(Gender~MeasureName, scales = "free")
p

csv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed3.csv'))
p = csv %>% group_by(ID) %>%
  do(
    plots = ggplot(data = .,
                   aes(x = Value,
                       y = MeasureName,
                       color = ROIName,
                       fill = ROIName)) + 
      geom_density_ridges(
        alpha = 0.2, 
        scale = 1.0
      ) +
      theme(axis.text = element_text(size = 15),
            axis.title = element_text(size = 15),
            strip.text = element_text(size = 15),
            legend.title = element_text(size = 15),
            legend.text = element_text(size = 15),
            plot.title = element_text(size = 15, hjust = 0.5),
            panel.border = element_blank(), 
            axis.line = element_line()) +
      coord_capped_cart(bottom = 'both',
                        left = 'both') +
      labs(y = 'DTI measure name',
           x = 'DTI measure value')
    ,
    Name = unique(.$ID)
  ) %>%
  rowwise() %>%
  do(plotsanno = .$plots + 
       labs(title = paste('Subject', .$Name)),
     filename = paste('DTIDistributions', .$Name, 
                      sep = '_') %>% trimws
  ) %>%
  rowwise() %>%
  do(x = pdf(paste0(figroot, gsub("/", "", .$filename), '.pdf'),
             width = 7.5, height = 5.5),
     y = print(.$plotsanno),
     z = dev.off()
  )

csv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed3.csv'))
p = csv %>% filter(Value <= 3.0) %>%
  mutate(Age = Age_at_Visit1.visit1.date...DOB. %>% as.factor) %>%
  ggplot(aes(x = Age,
             y = Value,
             fill = ROIName)) +
  geom_boxplot(outlier.alpha = 0.1) +
  facet_rep_grid(MeasureName~Gender,
                 scales = "free_y",
                 repeat.tick.labels = FALSE) +
  theme(axis.text = element_text(size = 15),
        axis.text.x = element_text(angle = 0, hjust = 1),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(x = 'Age [years]',
       y = 'DTI measure')
p

# Visualizing plots with KLD =====
kcsvlong = read.csv(paste0(csvRoot, 'StrokeDTIKLDLong.csv'))
p = kcsvlong %>% 
  filter(!(ClinicalMeasureName %in% c('Acute.Time.Period',
                                      'Age',
                                      'Years.of.Education',
                                      'Verbal.Fluency.Raw',
                                      'NIH.Stroke.Scale'))) %>%
  ggplot(aes(x = ClinicalMeasureValue,
                    y = kldiv,
                    color = Gender)) +
  geom_point(size = 3, alpha = 0.8) +
  geom_smooth(method = 'lm') +
  #scale_y_continuous(limits = c(0, 2)) +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Microstructural asymmetry (MASY)',
       x = 'Clinical measure')
p

library(broom)
kcsvlong = read.csv(paste0(csvRoot, 'StrokeDTIKLDLong.csv'))
dfTxt = kcsvlong %>% 
  filter(!(ClinicalMeasureName %in% c('Acute.Time.Period',
                                      'Age',
                                      'Years.of.Education',
                                      'Verbal.Fluency.Raw',
                                      'NIH.Stroke.Scale'))) %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    pvalue = tidy(lm(kldiv ~ ClinicalMeasureValue + 
                Gender + 
                ClinicalMeasureValue:Gender,
              data = .))$p.value[[4]] %>% round(digits = 3)
  )
#dfTxt$Gender = rep('Male', 8)
#dfTxt$Gender %<>% unlist
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)
dfTxt$xpos = c(0.1, 0) %>% rep(4)
dfTxt$ypos = c(2) %>% rep(8)
p + geom_text(data = dfTxt, color = 'black', size = 6,
              aes(x = -Inf, y = -Inf, label = pvalue,
                  color = 'black'), 
              hjust = 0, vjust = -1) + 
  facet_rep_wrap(ClinicalMeasureName~MeasureName, ncol = 4,
                 scales = "free")
p
pdf(paste0(figroot, 'MASY1', '.pdf'),
    width = 10.25, height = 6)
print(p)
dev.off()
p + geom_text(data = dfTxt, color = 'black',
              aes(x = xpos, y = ypos, label = pvalue,
                  color = 'black'), 
              hjust = 0, vjust = -1) + 
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free")


csv = read.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'))
p = csv %>% mutate(Age = Age_at_Visit1.visit1.date...DOB.) %>%
  ggplot(aes(x = Age,
             y = kldiv,
             color = Gender)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(MeasureName~.,
                 scales = "fixed") +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Distributional distance',
       x = 'Age')
p


csv = read.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'))
p = csv %>% mutate(ATP = AcuteTimePeriod.visit1.date...stroke.onset.date..year.visit1dtcol..year.strokeonsetcol..days.) %>%
  ggplot(aes(x = ATP,
             y = kldiv,
             color = Gender)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(MeasureName~.,
                 scales = "fixed") +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Distributional distance',
       x = 'Acute time period')
p

csv = read.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'))
p = csv %>% mutate(ATP = AcuteTimePeriod.visit1.date...stroke.onset.date..year.visit1dtcol..year.strokeonsetcol..days./Age_at_Visit1.visit1.date...DOB.) %>%
  ggplot(aes(x = ATP,
             y = kldiv,
             color = Gender)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(MeasureName~.,
                 scales = "fixed") +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Distributional distance',
       x = 'Acute time period/Age')
p
csv = read.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'))
p = csv %>% mutate(YOE = Years.of.Education) %>%
  ggplot(aes(x = YOE,
             y = kldiv,
             color = Gender)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(MeasureName~.,
                 scales = "fixed") +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Distributional distance',
       x = 'Years of education')
p

csv = read.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'))
p = csv %>% mutate(VF = Verbal.fluency.Raw.V1) %>%
  ggplot(aes(x = VF,
             y = kldiv,
             color = Gender)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(MeasureName~.,
                 scales = "fixed") +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Distributional distance',
       x = 'Verbal fluency')
p

csv = read.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'))
p = csv %>% mutate(VF = Verbal.fluency.Normed.V1..corrected.for.age.and.education.) %>%
  ggplot(aes(x = VF,
             y = kldiv,
             color = Gender)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(MeasureName~.,
                 scales = "fixed") +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Distributional distance',
       x = 'Normalized verbal fluency')
p


csv = read.csv(paste0(csvRoot, 'StrokeDTIKLD.csv'))
p = csv %>% mutate(NIHSS = NIHSS_V1..NIH.Stroke.Scale.) %>%
  ggplot(aes(x = NIHSS,
             y = kldiv,
             color = Gender)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(MeasureName~.,
                 scales = "fixed") +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Distributional distance',
       x = 'NIH stroke scale')
p
# Some testing ======
citation("LaplacesDemon")
tmpind <- which(index(dat0[[1]])=="2016-12-30")
density_tot <- density(100*retd[1:tmpind])
KL <- KLD(density_tot$y, dens[[2017]]$y)
plot(KL$KLD.py.px)


# Baseline relating clinical measures just with the DTI measures =====
imgcsv = read.csv(paste0(csvRoot, 'StrokeVoxelwiseDTITrimmed3.csv')) %>%
  group_by(ID, MeasureName, ROIName) %>% summarise(MeanValue = mean(Value))
democsv = read.csv(paste0(csvRoot, 'BasicDemographics.csv'))
library(plyr)
democsv$Gender %<>% mapvalues(from = c('F', 'M'),
                              to = c('Female', 'Male')) %>%
  as.factor
detach(package:plyr)
mcsv = merge(imgcsv, democsv, 
             by.x = c('ID'),
             by.y = c('SUBJECTID'),
             all.x = TRUE)
library(plyr)
mcsv$MeasureName %<>% mapvalues(from = c('fa', 'ad', 'md', 'rd'),
                                to = c('FA', 'AD', 'MD', 'RD')) %>% 
  as.factor
detach(package:plyr)
mcsv %>% write.csv(paste0(csvRoot, 'StrokeDTIMean.csv'),
                   row.names = FALSE)

csv = read.csv(paste0(csvRoot, 'StrokeDTIMean.csv'))
csv %<>% mutate(Norm.Acute.Time.Period = AcuteTimePeriod.visit1.date...stroke.onset.date..year.visit1dtcol..year.strokeonsetcol..days./Age_at_Visit1.visit1.date...DOB.,
                Norm.Verbal.Fluency = Verbal.fluency.Normed.V1..corrected.for.age.and.education.) %>%
  select(-one_of(c('Years.of.Education',
                   'Stroke.Hemisphere',
                   'Handedness',
                   'Ethnicity',
                   'Cortical.Subcortical',
                   'StrokeDetails.Refer.to.medical.records.sheet.if.available.under.Data.fMRI_Studies.StrokePlasticity.Patientdata_from_EPIC_JP_2_21_2014.',
                   'NIHSS_V1..NIH.Stroke.Scale.',
                   'Verbal.fluency.Raw.V1',
                   'Age_at_Visit1.visit1.date...DOB.',
                   'AcuteTimePeriod.visit1.date...stroke.onset.date..year.visit1dtcol..year.strokeonsetcol..days.',
                   'Verbal.fluency.Normed.V1..corrected.for.age.and.education.')))

csvlong = csv %>% gather('ClinicalMeasureName', 'ClinicalMeasureValue',
                         Norm.Acute.Time.Period:Norm.Verbal.Fluency,
                         factor_key = TRUE)
csvlong %>% write.csv(paste0(csvRoot, 'StrokeDTIMeanLong.csv'),
                      row.names = FALSE)

csvlong = read.csv(paste0(csvRoot, 'StrokeDTIMeanLong.csv'))
dfTxt = csvlong %>% 
  filter(ROIName == 'AcuteLesionMask') %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    pvalue = tidy(lm(MeanValue ~ ClinicalMeasureValue + 
                       Gender + 
                       ClinicalMeasureValue:Gender,
                     data = .))$p.value[[4]] %>% round(digits = 3)
  )
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)
panno = csvlong %>% 
  filter(ROIName == 'AcuteLesionMask') %>% 
  ggplot(aes(x = ClinicalMeasureValue,
             y = MeanValue,
             color = Gender)) +
  geom_point(size = 3, alpha = 0.2) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Mean DTI value',
       x = 'Clinical measure') +
  geom_text(data = dfTxt, 
            aes(x = -Inf, 
                y = -Inf, 
                label = pvalue), 
            color = 'black', 
            size = 6,
            hjust = -0.1, 
            vjust = -1) + 
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4)
panno

csvlong = read.csv(paste0(csvRoot, 'StrokeDTIMeanLong.csv'))
dfTxt = csvlong %>% 
  filter(ROIName == 'ContraLesionMask') %>%
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    pvalue = tidy(lm(MeanValue ~ ClinicalMeasureValue + 
                       Gender + 
                       ClinicalMeasureValue:Gender,
                     data = .))$p.value[[4]] %>% round(digits = 3)
  )
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)

panno = csvlong %>% 
  filter(ROIName == 'ContraLesionMask') %>% 
  ggplot(aes(x = ClinicalMeasureValue,
             y = MeanValue,
             color = Gender)) +
  geom_point(size = 3, alpha = 0.2) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Mean DTI value',
       x = 'Clinical measure') +
  geom_text(data = dfTxt, 
            aes(x = -Inf, 
                y = -Inf, 
                label = pvalue), 
            color = 'black', 
            size = 6,
            hjust = -0.1, 
            vjust = -1) + 
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4)
panno

csvdiff = csvlong %>% 
  group_by(ID, Gender, ClinicalMeasureName, 
           MeasureName) %>% 
  arrange(ROIName, .by_group = TRUE) %>% 
  mutate(MeanDiff = MeanValue - lag(MeanValue), 
         DiffName = paste0(ROIName, '-', lag(ROIName))) %>% 
  filter(!is.na(MeanDiff))

csvdiff %>% write.csv(paste0(csvRoot, 'StrokeDTIMeanDiff.csv'),
                      row.names = FALSE)

csvdiff = read.csv(paste0(csvRoot, 'StrokeDTIMeanDiff.csv'))
dfTxt = csvdiff %>% 
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    pvalue = tidy(lm(MeanDiff ~ ClinicalMeasureValue + 
                       Gender + 
                       ClinicalMeasureValue:Gender,
                     data = .))$p.value[[4]] %>% round(digits = 3)
  )
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)

panno = csvdiff %>% 
  ggplot(aes(x = ClinicalMeasureValue,
             y = MeanDiff,
             color = Gender)) +
  geom_point(size = 3, alpha = 0.2) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 15),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 15),
        legend.text = element_text(size = 15),
        plot.title = element_text(size = 15, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Mean DTI difference (contra - lesion)',
       x = 'Clinical measure') +
  geom_text(data = dfTxt, 
            aes(x = -Inf, 
                y = -Inf, 
                label = pvalue), 
            color = 'black', 
            size = 6,
            hjust = -0.1, 
            vjust = -1) + 
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4)
panno
