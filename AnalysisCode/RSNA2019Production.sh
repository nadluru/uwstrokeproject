#!/bin/bash

parallel -j3 convert {} -density 300 -quality 100% -trim {.}.png ::: *.pdf

montage -pointsize 20 -label "(a) Mean DTI"   Mean1.png  \
        -label "(b) Mean DTI difference"  MeanDiff1.png  \
          \( MASY1.png  -set label "(c) MASY"  \) \
          -tile 1x  -frame 5  -geometry '+10+10>' \
          -title 'Relationship between \n clinical measures and microstructure'   RSNAComposite.png


montage -pointsize 20 -label "(a) Mean DTI"   Mean1.png  \
        -label "(b) Mean DTI difference"  MeanDiff1.png  \
          \( MASY1.png  -set label "(c) MASY"  \) \
          -tile 1x  -frame 5  -geometry '+10+10>' RSNAComposite.png


convert -size 815x -pointsize 40 -gravity center caption:'Sex specific relationships between \n clinical measures and microstructure' RSNAComposite.png -size 815x -pointsize 20 -gravity center caption:'Figure 1. (a) Relationships using the average DTI measures in the ipsilesional regions and (b) using the difference between average DTI measures in the contralesional and ipsilesional regions do not show statistical significance for the interaction effect of sex and the clinical measures. (c) The statistical significance of the interaction effect is most pronounced (reflected by smaller p-values) when using the microstructural asymmetry computed using symmetrized Kullback Leibler divergence (sKLD) between the distributions of DTI measures in the ipsilesional and contralesional regions.' -gravity center -frame 2 -append RSNACompositeAnno.png