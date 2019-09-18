#!/bin/bash

# region pre rsna acceptance (n=16)
dataroot=/mounts/data/preprocessed/modalities/dti/Strk/dti
export initroot=$dataroot/CHTC2

parallel -j1 ./DWICorrect_AddJobToDAG.sh ::: $dataroot/*V1_nozfi.mif > DWICorrect_March302019_V2.dag
# endregion

# region post rsna acceptance (n=65)
dataroot=/mounts/data/preprocessed/modalities/dti/sp_adluru/LargerDataset/dti
export initroot=$dataroot/CHTC

parallel -j1 --plus ./DWICorrect_AddJobToDAG.sh {..}_nozfi.mif ::: $dataroot/*.nii.gz > DWICorrect_September172019_V1.dag
# endregion