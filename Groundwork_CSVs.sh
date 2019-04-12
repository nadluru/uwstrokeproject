#!/bin/bash

cd CSVs
cp StrokeVoxelwiseDTI.csv StrokeVoxelwiseDTITrimmed.csv
sed -i 's/\_nozfi\_dwi\_preproc\_bc\_//g' StrokeVoxelwiseDTITrimmed.csv
sed -i 's/\_in\_bravo//g' StrokeVoxelwiseDTITrimmed.csv
sed -i 's/Acute\_Lesion\_Mask/AcuteLesionMask/g' StrokeVoxelwiseDTITrimmed.csv
sed -i 's/AcuteLesionMask\_Swapx/ContraLesionMask/g' StrokeVoxelwiseDTITrimmed.csv