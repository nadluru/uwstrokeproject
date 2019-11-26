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

library(broom)

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

# Production figure 1 =====
kcsvlong = read.csv(paste0(csvRoot, 'StrokeDTIKLDLong.csv'))
kcsvlong %<>% 
  filter(!(ClinicalMeasureName %in% c('Acute.Time.Period',
                                      'Age',
                                      'Years.of.Education',
                                      'Verbal.Fluency.Raw',
                                      'NIH.Stroke.Scale')))
library(plyr)
kcsvlong$ClinicalMeasureName %<>% 
  mapvalues(c('Normalized.Acute.Time.Period', 
              'Normalized.Verbal.Fluency'), 
            c('Norm. acute time period', 
              'Norm. verbal fluency'))
detach(package:plyr)

dfTxt = kcsvlong %>% 
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    pvalue = tidy(lm(kldiv ~ ClinicalMeasureValue + 
                       Gender + 
                       ClinicalMeasureValue:Gender,
                     data = .))$p.value[[4]] %>% round(digits = 3)
  )
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)
  
panno = kcsvlong %>%
  ggplot(aes(x = ClinicalMeasureValue,
             y = kldiv,
             color = Gender)) +
  geom_point(size = 3, alpha = 0.8) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 18),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        plot.title = element_text(size = 18, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Microstructural asymmetry (MASY)',
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
pdf(paste0(figroot, 'MASY1', '.pdf'),
    width = 10.95, height = 6)
print(panno)
dev.off()

# Production figure 2 ====
kcsvlong = read.csv(paste0(csvRoot, 'StrokeDTIKLDLong.csv'))
kcsvlong %<>% 
  filter(!(ClinicalMeasureName %in% c('Acute.Time.Period',
                                      'Age',
                                      'Years.of.Education',
                                      'Verbal.Fluency.Raw',
                                      'NIH.Stroke.Scale')),
         !(MeasureName %in% c('FA', 'RD')))
library(plyr)
kcsvlong$ClinicalMeasureName %<>% 
  mapvalues(c('Normalized.Acute.Time.Period', 
              'Normalized.Verbal.Fluency'), 
            c('Norm. acute time period', 
              'Norm. verbal fluency'))
detach(package:plyr)

dfTxt = kcsvlong %>% 
  group_by(MeasureName, ClinicalMeasureName) %>%
  do(
    pvalue = tidy(lm(kldiv ~ ClinicalMeasureValue + 
                       Gender + 
                       ClinicalMeasureValue:Gender,
                     data = .))$p.value[[4]] %>% round(digits = 3)
  )
dfTxt$pvalue %<>% unlist %>% paste("pvalue: ", .)


panno = kcsvlong %>%
  ggplot(aes(x = ClinicalMeasureValue,
             y = kldiv,
             color = Gender)) +
  geom_point(size = 3, alpha = 0.8) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 2) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 18),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        plot.title = element_text(size = 18, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Microstructural asymmetry (MASY)',
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
                 ncol = 2)
panno
pdf(paste0(figroot, 'MASY2', '.pdf'),
    width = 7.5, height = 6)
print(panno)
dev.off()

# Production figure 3 ====
csvdiff = read.csv(paste0(csvRoot, 'StrokeDTIMeanDiff.csv'))
library(plyr)
csvdiff$ClinicalMeasureName %<>% 
  mapvalues(c('Norm.Acute.Time.Period', 
              'Norm.Verbal.Fluency'), 
            c('Norm. acute time period', 
              'Norm. verbal fluency'))
detach(package:plyr)
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
  geom_point(size = 3, alpha = 0.8) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 18),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        plot.title = element_text(size = 18, hjust = 0.5),
        panel.border = element_blank(), 
        axis.line = element_line()) +
  coord_capped_cart(bottom = 'both',
                    left = 'both') +
  labs(y = 'Mean difference (contralesional - ipsilesional)',
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
pdf(paste0(figroot, 'MeanDiff1', '.pdf'),
    width = 10.95, height = 6)
print(panno)
dev.off()

# Production figure 4 =====
csvlong = read.csv(paste0(csvRoot, 'StrokeDTIMeanLong.csv'))
library(plyr)
csvlong$ClinicalMeasureName %<>% 
  mapvalues(c('Norm.Acute.Time.Period', 
              'Norm.Verbal.Fluency'), 
            c('Norm. acute time period', 
              'Norm. verbal fluency'))
detach(package:plyr)
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
  geom_point(size = 3, alpha = 0.8) +
  geom_smooth(method = 'lm') +
  facet_rep_wrap(ClinicalMeasureName~MeasureName,
                 scales = "free",
                 ncol = 4) +
  theme(axis.text = element_text(size = 15),
        axis.title = element_text(size = 18),
        strip.text = element_text(size = 15),
        legend.position = 'bottom',
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        plot.title = element_text(size = 18, hjust = 0.5),
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
pdf(paste0(figroot, 'Mean1', '.pdf'),
    width = 10.95, height = 6)
print(panno)
dev.off()

# Basic demo numbers ======
democsv %>% group_by(Gender) %>% 
  summarize(ma = mean(Age_at_Visit1.visit1.date...DOB.),sda = sd(Age_at_Visit1.visit1.date...DOB.))
