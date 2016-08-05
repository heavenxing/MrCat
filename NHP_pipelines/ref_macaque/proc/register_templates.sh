#!/usr/bin/env bash
set -e    # stop immediately on error

# code depends on FSL

# retrieve the directory of this script
dirScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# define data directories
dirSL=$dirScript/../SL
dirMNI=$dirScript/../MNI
dirF99=$dirScript/../F99
dirTrans=$dirScript/../transform
mkdir -p $dirTrans
config=$dirScript/fnirt_1mm.cnf


# warp F99 to SL
# best so far: refmask=McLaren_brain_mask_strict, but works pretty much as good as refmask=McLaren_brain_mask
refbase=SL
refdir=$dirSL
ref=McLaren
refmask=McLaren_brain_mask_strict
imgbase=F99
imgdir=$dirF99
img=F99_restore
imgmask=F99_brain_mask
echo "register $imgbase to reference $refbase"

# perform linear registration of the F99 to reference
flirt -dof 12 -ref $refdir/$ref -refweight $refdir/$refmask -in $imgdir/$img -inweight $imgdir/$imgmask -omat $dirTrans/${imgbase}_to_${refbase}.mat
convert_xfm -omat $dirTrans/${refbase}_to_${imgbase}.mat -inverse $dirTrans/${imgbase}_to_${refbase}.mat

# use spline interpolation to apply the linear transformation matrix
#applywarp --rel --interp=spline -i $imgdir/$img -r $refdir/$ref --premat=$dirTrans/${imgbase}_to_${refbase}.mat -o $refdir/${imgbase}_lin

# and now non-linear
fnirt --ref=$refdir/$ref --refmask=$refdir/$refmask --in=$imgdir/$img --inmask=$imgdir/$imgmask --aff=$dirTrans/${imgbase}_to_${refbase}.mat --fout=$dirTrans/${imgbase}_to_${refbase}_warp --config=$config

# and use spline interpolation to apply the warp field (the F99 template has high spatial frequencies)
applywarp --rel --interp=spline -i $imgdir/$img -r $refdir/$ref -w $dirTrans/${imgbase}_to_${refbase}_warp -o $refdir/$img
fslmaths $refdir/$img -thr 0 $refdir/$img

# and now invert the warp field
invwarp -w $dirTrans/${imgbase}_to_${refbase}_warp -o $dirTrans/${refbase}_to_${imgbase}_warp -r $imgdir/$img

# use trilinear interpolation (the McLaren img is already smooth)
applywarp --rel --interp=trilinear -i $refdir/$ref -r $imgdir/$img -w $dirTrans/${refbase}_to_${imgbase}_warp -o $imgdir/$ref
fslmaths $imgdir/$ref -thr 0 $imgdir/$ref

# do the same for the McLaren WM probability map
applywarp --rel --interp=trilinear -i $refdir/${ref}_WM -r $imgdir/$img -w $dirTrans/${refbase}_to_${imgbase}_warp -o $imgdir/${ref}_WM
fslmaths $imgdir/${ref}_WM -thr 0 $imgdir/${ref}_WM

# and for the T2-weighted image
applywarp --rel --interp=trilinear -i $refdir/${ref}_T2 -r $imgdir/$img -w $dirTrans/${refbase}_to_${imgbase}_warp -o $imgdir/${ref}_T2
fslmaths $imgdir/${ref}_T2 -thr 0 $imgdir/${ref}_T2

# ditch the warp coeficient and log
imrm $imgdir/${img}_warpcoef
mv -f $imgdir/${img}_to_*.log $dirTrans/

echo "  done"


# warp MNI to SL
imgbase=MNI
imgdir=$dirMNI
img=MNI
imgmask=MNI_brain_mask
echo "register $imgbase to reference $refbase"

# perform linear registration of the F99 to reference
flirt -dof 12 -ref $refdir/$ref -refweight $refdir/$refmask -in $imgdir/$img -inweight $imgdir/$imgmask -omat $dirTrans/${imgbase}_to_${refbase}.mat
convert_xfm -omat $dirTrans/${refbase}_to_${imgbase}.mat -inverse $dirTrans/${imgbase}_to_${refbase}.mat

# use spline interpolation to apply the linear transformation matrix
#applywarp --rel --interp=spline -i $imgdir/$img -r $refdir/$ref --premat=$dirTrans/${imgbase}_to_${refbase}.mat -o $refdir/${imgbase}_lin

# and now non-linear
fnirt --ref=$refdir/$ref --refmask=$refdir/$refmask --in=$imgdir/$img --inmask=$imgdir/$imgmask --aff=$dirTrans/${imgbase}_to_${refbase}.mat --fout=$dirTrans/${imgbase}_to_${refbase}_warp --config=$config

# and use spline interpolation to apply the warp field (the F99 template has high spatial frequencies)
applywarp --rel --interp=spline -i $imgdir/$img -r $refdir/$ref -w $dirTrans/${imgbase}_to_${refbase}_warp -o $refdir/$img
fslmaths $refdir/$img -thr 0 $refdir/$img

# and now invert the warp field
invwarp -w $dirTrans/${imgbase}_to_${refbase}_warp -o $dirTrans/${refbase}_to_${imgbase}_warp -r $imgdir/$img

# use trilinear interpolation (the McLaren img is already smooth)
applywarp --rel --interp=trilinear -i $refdir/$ref -r $imgdir/$img -w $dirTrans/${refbase}_to_${imgbase}_warp -o $imgdir/$ref
fslmaths $imgdir/$ref -thr 0 $imgdir/$ref

# do the same for the McLaren WM probability map
applywarp --rel --interp=trilinear -i $refdir/${ref}_WM -r $imgdir/$img -w $dirTrans/${refbase}_to_${imgbase}_warp -o $imgdir/${ref}_WM
fslmaths $imgdir/${ref}_WM -thr 0 $imgdir/${ref}_WM

# and for the T2-weighted image
applywarp --rel --interp=trilinear -i $refdir/${ref}_T2 -r $imgdir/$img -w $dirTrans/${refbase}_to_${imgbase}_warp -o $imgdir/${ref}_T2
fslmaths $imgdir/${ref}_T2 -thr 0 $imgdir/${ref}_T2

# ditch the warp coeficient and log
imrm $imgdir/${img}_warpcoef
mv -f $imgdir/${img}_to_*.log $dirTrans/

echo "  done"


# warp F99 to MNI
refbase=MNI
refdir=$dirMNI
ref=MNI
refmask=MNI_brain_mask
imgbase=F99
imgdir=$dirF99
img=F99_restore
imgmask=F99_brain_mask
echo "register $imgbase to reference $refbase"

# perform linear registration of the F99 to reference
flirt -dof 12 -ref $refdir/$ref -refweight $refdir/$refmask -in $imgdir/$img -inweight $imgdir/$imgmask -omat $dirTrans/${imgbase}_to_${refbase}_regdirect.mat
convert_xfm -omat $dirTrans/${refbase}_to_${imgbase}_regdirect.mat -inverse $dirTrans/${imgbase}_to_${refbase}_regdirect.mat

# use spline interpolation to apply the linear transformation matrix
#applywarp --rel --interp=spline -i $imgdir/$img -r $refdir/$ref --premat=$dirTrans/${imgbase}_to_${refbase}_regdirect.mat -o $refdir/${imgbase}_lin_regdirect

# and now non-linear
fnirt --ref=$refdir/$ref --refmask=$refdir/$refmask --in=$imgdir/$img --inmask=$imgdir/$imgmask --aff=$dirTrans/${imgbase}_to_${refbase}_regdirect.mat --fout=$dirTrans/${imgbase}_to_${refbase}_warp_regdirect --config=$config

# and use spline interpolation to apply the warp field (the F99 template has high spatial frequencies)
applywarp --rel --interp=spline -i $imgdir/$img -r $refdir/$ref -w $dirTrans/${imgbase}_to_${refbase}_warp_regdirect -o $refdir/${img}_regdirect
fslmaths $refdir/${img}_regdirect -thr 0 $refdir/${img}_regdirect

# and now invert the warp field
invwarp -w $dirTrans/${imgbase}_to_${refbase}_warp_regdirect -o $dirTrans/${refbase}_to_${imgbase}_warp_regdirect -r $imgdir/$img

# use trilinear interpolation (the MNI img is already smooth)
applywarp --rel --interp=spline -i $refdir/$ref -r $imgdir/$img -w $dirTrans/${refbase}_to_${imgbase}_warp_regdirect -o $imgdir/${ref}_regdirect
fslmaths $imgdir/${ref}_regdirect -thr 0 $imgdir/${ref}_regdirect

# ditch the warp coeficient and log
imrm $imgdir/${img}_warpcoef
mv -f $imgdir/${img}_to_*.log $dirTrans/

echo "  done"


echo "creating McLaren brain masks in F99 and MNI space"
thr=$(fslstats $dirSL/McLaren -P 25)
fslmaths $dirF99/McLaren -thr $thr -bin $dirF99/McLaren_brain_mask
fslmaths $dirMNI/McLaren -thr $thr -bin $dirMNI/McLaren_brain_mask

thr=$(fslstats $dirSL/McLaren -P 30)
fslmaths $dirF99/McLaren -thr $thr -bin $dirF99/McLaren_brain_mask_strict
fslmaths $dirMNI/McLaren -thr $thr -bin $dirMNI/McLaren_brain_mask_strict
echo "  done"


echo "warping the F99 surfaces to SL and MNI"
mkdir -p $dirSL/surf
mkdir -p $dirMNI/surf
for hemi in left right ; do
  wb_command -surface-apply-warpfield $dirF99/surf/F99.$hemi.fiducial.surf.gii $dirTrans/SL_to_F99_warp.nii.gz $dirSL/surf/F99.$hemi.fiducial.surf.gii -fnirt $dirTrans/F99_to_SL_warp.nii.gz
  wb_command -surface-apply-warpfield $dirF99/surf/F99.$hemi.fiducial.surf.gii $dirTrans/MNI_to_F99_warp.nii.gz $dirMNI/surf/F99.$hemi.fiducial.surf.gii -fnirt $dirTrans/F99_to_MNI_warp.nii.gz
done
echo "  done"


# The code below is not used by default. But if you want to combine the A>B and
# B>C warps into an A>C warp, to make sure all transformations are
# interchangeable, please check the files postpadded with "_viaSL".

# now combine the F99 > SL and SL > MNI warps to obtain the F99 > MNI warp
echo "combine previous warps to SL, to get tranfrom between MNI and F99 via SL"

# first from F99, via SL, to MNI
convertwarp --rel --relout --ref=$dirMNI/MNI --warp1=$dirTrans/F99_to_SL_warp --warp2=$dirTrans/SL_to_MNI_warp --out=$dirTrans/F99_to_MNI_warp_viaSL
applywarp --rel --interp=spline -i $dirF99/F99_restore -r $dirMNI/MNI -w $dirTrans/F99_to_MNI_warp_viaSL -o $dirMNI/F99_restore_viaSL
fslmaths $dirMNI/F99_restore_viaSL -thr 0 $dirMNI/F99_restore_viaSL

# then from MNI, via SL, to F99
convertwarp --rel --relout --ref=$dirF99/F99_restore --warp1=$dirTrans/MNI_to_SL_warp --warp2=$dirTrans/SL_to_F99_warp --out=$dirTrans/MNI_to_F99_warp_viaSL
applywarp --rel --interp=spline -i $dirMNI/MNI -r $dirF99/F99 -w $dirTrans/MNI_to_F99_warp_viaSL -o $dirF99/MNI_viaSL
fslmaths $dirF99/MNI_viaSL -thr 0 $dirF99/MNI_viaSL

echo "  done"
