#!/bin/bash

cd /study/utaut2/T1WIAnalysisNA/RSNA2019FinalSetForAnalysis/Figures/Production
parallel -j24 --bar convert {} -density 300 -quality 100% -trim {.}.png ::: *.pdf