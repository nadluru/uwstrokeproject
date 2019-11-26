# Loading the libraries ====
library(ggsci)
library(ggplot2)
library(scales)
library(dplyr)
library(tidyr)
library(magrittr)
library(stringr)
library(latex2exp)
library(forcats)
# library(plotflow)
library(broom)
library(purrr)
library(scales)
library(ggpol)
library(ggrepel)
library(lemon)
library(ggsignif)
library(gmodels)
library(margins)
library(lmPerm)
library(permuco)
library(permute)

library(DataCombine)
library(ggplot2)
library(ggridges)
library(GGally)
library(lemon)
library(LaplacesDemon)

# Initializing variables =====
rm(list = ls(all = TRUE))
# computer = 'waislin'
computer = 'waiswin'
homedir = case_when(
  computer %>% str_detect(regex('waiswin', 
                                ignore_case = T)) ~ 'H:/adluru/',
  computer %>% str_detect(regex('waislin',
                                ignore_case = T)) ~ '/home/adluru/',
  computer %>% str_detect(regex('bender',
                                ignore_case = T)) ~ '/home/nadluru/'
)
study = case_when(
  computer %>% str_detect(regex('waiswin', ignore_case = T)) ~ 'Y:/',
  computer %>% str_detect(regex('waislin', ignore_case = T)) ~ '/study/'
)
scratch = case_when(
  computer %>% str_detect(regex('waiswin', ignore_case = T)) ~ 'X:/',
  computer %>% str_detect(regex('waislin', ignore_case = T)) ~ '/scratch/'
)
csvroot = paste0(homedir, 'StrokeAndDiffusionProject/uwstrokeproject/CSVs/')
figroot = paste0(study, 'utaut2/T1WIAnalysisNA/RSNA2019FinalSetForAnalysis/Figures/')
# figroot = paste0(scratch, 'adluru/ProductionFiguresJournal/')

# ggplot theme ====
dodge = position_dodge(width = 0.9)
txtSize = 18
gtheme = theme(legend.key = element_rect(colour = "black"),
               legend.title = element_text(size = txtSize),
               legend.text = element_text(size = txtSize),
               legend.background = element_blank(),
               legend.position = c(0.9, 0.9)) +
  theme(legend.position = "top", legend.title = element_blank()) +
  theme(strip.text.x = element_text(size = txtSize),
        strip.text.y = element_text(size = txtSize)) +
  # theme(panel.background = element_rect(colour = "deepskyblue4",
  #                                       linetype = 1),
  #       strip.text.x = element_text(size = txtSize),
  #       strip.text.y = element_text(size = txtSize),
  #       strip.background = element_rect(fill = "mediumspringgreen",
  #                                       colour = "deepskyblue4")) +
  theme(axis.text = element_text(colour = "black",
                                 size = txtSize)) +
  theme(plot.title = element_text(size = txtSize),
        axis.title = element_text(size = txtSize)) +
  theme(axis.line = element_line()) +
  theme(
    panel.background = element_rect(fill = "white"),
    panel.grid.major = element_line(size = 0.5, linetype = 'solid',
                                    colour = "gray"), 
    panel.grid.minor = element_line(size = 0.2, linetype = 'solid',
                                    colour = "gray")
  ) +
  theme(strip.background = element_rect(fill = "white"))
