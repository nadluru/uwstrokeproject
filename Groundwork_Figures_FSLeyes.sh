#!/bin/bash
t1w=./t1w/SS004V1.anat_stdorientation_normalized_BFC_brain.nii.gz
alm=./alm/SS004V1_Acute_Lesion_Mask_size_thr.nii.gz
almcontra=./alm/SS004V1_Acute_Lesion_Mask_size_thr_swapx.nii.gz
bbox=($(fslstats $alm -w))
xvox=$(echo ${bbox[0]}+${bbox[1]}/2 | bc)
yvox=$(echo ${bbox[2]}+${bbox[3]}/2 | bc)
zvox=$(echo ${bbox[4]}+${bbox[5]}/2 | bc)

fsleyes render --outfile $(basename $t1w .nii.gz).png --size 800 600 --scene ortho --voxelLoc $xvox $yvox $zvox --displaySpace $t1w --xcentre 0 0 --ycentre 0 0 --zcentre 0 0 --xzoom 1000.0 --yzoom 1000.0 --zzoom 1000.0 --hideLabels --layout horizontal --hidex --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --cursorColour 0.0 1.0 0.0 --colourBarLocation top --colourBarLabelSide top-left --colourBarSize 100.0 --labelSize 12 --performance 3 --movieSync $t1w --name "$(basename $t1w .nii.gz)" --overlayType volume --alpha 100.0 --brightness 50.0 --contrast 50.0 --cmap greyscale --negativeCmap greyscale --displayRange 0.0 0.18030960857868195 --clippingRange 0.0 0.18211270466446877 --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 --smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0 $alm --name "$(basename $alm .nii.gz)" --overlayType label --alpha 100.0 --brightness 50.0 --contrast 50.0 --lut harvard-oxford-subcortical --outline --outlineWidth 1 --volume 0 $almcontra --name "$(basename $almcontra .nii.gz)" --overlayType label --alpha 100.0 --brightness 50.0 --contrast 50.0 --lut random --outline --outlineWidth 1 --volume 0

# region lr flipped scenes
parallel bash RenderFSLEyes_Scene1.sh {1} {2} {3} ::: t1w/SS0*.nii.gz :::+ alm/SS0*thr.nii.gz :::+ alm/SS0*thr_swapx.nii.gz

ls *.png | parallel convert {1} -gravity north -fill white -pointsize 50 -annotate 0 {2} {1.}_anno.png :::: - :::+ $(ls *.png | sed "s/V1.*//g")
# endregion

# region fa scenes
parallel bash RenderFSLEyes_Scene1.sh {1} {2} {3} ::: dti/SS0*fa_instruc.nii.gz :::+ alm/SS0*thr.nii.gz :::+ alm/SS0*thr_swapx.nii.gz

ls *fa_instruc.png | parallel convert {1} -gravity north -fill white -pointsize 50 -annotate 0 {2} {1.}_anno.png :::: - :::+ $(ls *.png | sed "s/V1.*//g")
# endregion

# region mni lr flipped scenes
cat 27list.txt | parallel bash RenderFSLEyes_Scene1.sh flairinstruc/{}*in_struc.nii.gz alm/{}*thr.nii.gz tomni/{}*in_native.nii.gz

ls *in_struc.png | parallel convert {1} -gravity north -fill white -pointsize 50 -annotate 0 {2} {1.}_anno.png :::: - :::+ $(ls *.png | sed "s/V1.*//g")
# endregion

# region brain mask checks
SS054
SS007
SS004
# endregion
