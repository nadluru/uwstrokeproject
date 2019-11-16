#!/bin/bash

# region pre rsna acceptance
cd CSVs
cp StrokeVoxelwiseDTI.csv StrokeVoxelwiseDTITrimmed.csv
sed -i 's/\_nozfi\_dwi\_preproc\_bc\_//g' StrokeVoxelwiseDTITrimmed.csv
sed -i 's/\_in\_bravo//g' StrokeVoxelwiseDTITrimmed.csv
sed -i 's/Acute\_Lesion\_Mask/AcuteLesionMask/g' StrokeVoxelwiseDTITrimmed.csv
sed -i 's/AcuteLesionMask\_Swapx/ContraLesionMask/g' StrokeVoxelwiseDTITrimmed.csv
# endregion

# region post rsna acceptance Nov. 15, 2019.
sed -i.bak 's/_nozfi.*withgrad//g;s/_instruc//g;s/Acute_Lesion_Mask_size_thr/ALM/g;s/_/,/;s/ID/ID,DTI/' StrokeVoxelwiseDTI.csv
sed -i.bak2 's/_/,/;s/ROI/SID,ROI/' StrokeVoxelwiseDTI.csv
sed -i.bak4 's/V1//;s/V1//' StrokeVoxelwiseDTI.csv
sed -i.bak3 's/ad/AD/;s/fa/FA/;s/md/MD/;s/rd/RD/' StrokeVoxelwiseDTI.csv

sed -i.bak 's/_//;s/F,/Female,/;s/M/Male/' BasicDemographicsNov152019.csv
sed -i.bak 's/ALM_swapx/Contralesional/;s/ALM/Ipsilesional/' StrokeVoxelwiseDTINov152019.csv
sed -i.bak 's/DTI/MeasureName/;s/ROI/ROIName/' StrokeVoxelwiseDTINov152019.csv
# endregion
