#!/usr/bin/env bash
#set -e    # don't stop immediately on error as wm_import will return one

# dependent on having FSl and workbench installed, including wb_import and wb_command

# retrieve the directory of this script
dirScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# define the original, processing and final data directory
dirOrig=$dirScript/../orig/F99
dirProc=$dirScript/F99
rm -rf $dirProc
mkdir -p $dirProc
cd $dirProc
dirFinal=$dirScript/../F99
dirSurf=$dirFinal/surf
mkdir -p $dirSurf

# ------------------------------ #
# section 1: convert the Caret files to nifti/cifti/gifti using Workbench
# ------------------------------ #

# define original data directories
dirLeft=$dirOrig/Macaque.F99.LEFT.STANDARD-SCENES.73730/CARET_TUTORIAL_SEPT06/MACAQUE
dirRight=$dirOrig/Macaque.F99.RIGHT.STANDARD-SCENES.73730/CARET_TUTORIAL_SEPT06/MACAQUE

# define spec files to be converted
specLeft=Macaque.F99.LEFT.STANDARD-SCENES.73730.spec
specRight=Macaque.F99.RIGHT.STANDARD-SCENES.73730.spec



# import the CARET 5 spec files for the right hemi
wb_import -spec-file right $dirRight/$specRight # this one seems to work best, so run it first
wb_import -spec-file left $dirLeft/$specLeft    # unfortunately it crashes before making the left hemi F6 and PTH surfaces

# Some files are missing fror the left hemisphere because of the error/crash,
# most importantly the surfaces for in the F6 and PTH spaces. One could try to
# install Caret and create spec files for theses files individually, and convert
# those single spec files. Maybe that'll work?

# set the structure of the border files, and update to latest version
# the border file for the left hemisphere does not work properly, so force it to the left hemisphere (this will give a warning)
cp Macaque.F99UA1.COMPOSITE_PartititioningSchemes.73730.border Macaque.F99UA1.LEFT.COMPOSITE_PartititioningSchemes.73730.border
wb_command -set-structure Macaque.F99UA1.LEFT.COMPOSITE_PartititioningSchemes.73730.border CORTEX_LEFT
wb_command -file-convert -border-version-convert Macaque.F99UA1.LEFT.COMPOSITE_PartititioningSchemes.73730.border 3 Macaque.F99UA1.LEFT.COMPOSITE_PartititioningSchemes.73730.border -surface Macaque.F99UA1.LEFT.FIDUCIAL.Std-MESH.73730.surf.gii
wb_command -file-convert -border-version-convert Macaque.F99UA1.COMPOSITE_PartititioningSchemes.73730.border 3 Macaque.F99UA1.RIGHT.COMPOSITE_PartititioningSchemes.73730.border -surface Macaque.F99UA1.RIGHT.FIDUCIAL.Std-MESH.73730.surf.gii
wb_command -set-structure Macaque.F99UA1.LEFT.COMPOSITE_PartititioningSchemes.73730.border CORTEX_LEFT
wb_command -set-structure Macaque.F99UA1.RIGHT.COMPOSITE_PartititioningSchemes.73730.border CORTEX_RIGHT
rm Macaque.F99UA1.COMPOSITE_PartititioningSchemes.73730.border

# merge files that cover both hemispheres
wb_command -cifti-create-label Macaque.F99UA1.BOTH.COMPOSITE.73730.dlabel.nii -left-label Macaque.F99UA1.BOTH.COMPOSITE.73730.label.gii -right-label Macaque.F99UA1.BOTH.COMPOSITE.73730.label.gii
wb_command -cifti-create-dense-scalar Macaque.F99UA1.BOTH.COMPOSITE.73730.dscalar.nii -left-metric Macaque.F99UA1.BOTH.COMPOSITE.73730.func.gii -right-metric Macaque.F99UA1.BOTH.COMPOSITE.73730.func.gii
wb_command -cifti-create-dense-scalar Macaque.F99UA1.COMPOSITE_LVE00-INJECTIONS.73730.dscalar.nii -left-metric Macaque.F99UA1.COMPOSITE_LVE00-INJECTIONS.73730.func.gii -right-metric Macaque.F99UA1.COMPOSITE_LVE00-INJECTIONS.73730.func.gii
wb_command -cifti-create-label Macaque.F99UA1.LR.AREAS_VISUAL_MULTI-SCHEME.73730.atlas.dlabel.nii -left-label Macaque.F99UA1.LR.AREAS_VISUAL_MULTI-SCHEME.73730.atlas.label.gii -right-label Macaque.F99UA1.LR.AREAS_VISUAL_MULTI-SCHEME.73730.atlas.label.gii
wb_command -cifti-create-label Macaque.F99UA1.LR.LVE00_PROBABILISTIC.73730.atlas.dlabel.nii -left-label Macaque.F99UA1.LR.LVE00_PROBABILISTIC.73730.atlas.label.gii -right-label Macaque.F99UA1.LR.LVE00_PROBABILISTIC.73730.atlas.label.gii
rm Macaque.F99UA1.BOTH.COMPOSITE.73730.label.gii Macaque.F99UA1.BOTH.COMPOSITE.73730.func.gii Macaque.F99UA1.COMPOSITE_LVE00-INJECTIONS.73730.func.gii Macaque.F99UA1.LR.AREAS_VISUAL_MULTI-SCHEME.73730.atlas.label.gii Macaque.F99UA1.LR.LVE00_PROBABILISTIC.73730.atlas.label.gii

# create a spec file, add all files
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F6.LR+orig.nii.gz
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.F6.RIGHT.FIDUCIAL.Std-Mesh.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F99UA1.BOTH.COMPOSITE.73730.dlabel.nii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F99UA1.BOTH.COMPOSITE.73730.dscalar.nii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F99UA1.BOTH.LewisVE00+orig.nii.gz
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F99UA1.COMPOSITE_LVE00-INJECTIONS.73730.dscalar.nii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_LEFT Macaque.F99UA1.LEFT.COMPOSITE_PartititioningSchemes.73730.border
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_LEFT Macaque.F99UA1.LEFT.FIDUCIAL.Std-MESH.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_LEFT Macaque.F99UA1.LEFT.FLAT.CartSTD.Std-MESH.clean.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_LEFT Macaque.F99UA1.LEFT.INFLATED.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_LEFT Macaque.F99UA1.LEFT.VERY_INFLATED.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F99UA1.LR.03-11+orig.nii.gz
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F99UA1.LR.AREAS_VISUAL_MULTI-SCHEME.73730.atlas.dlabel.nii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec INVALID Macaque.F99UA1.LR.LVE00_PROBABILISTIC.73730.atlas.dlabel.nii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.F99UA1.RIGHT.COMPOSITE_PartititioningSchemes.73730.border
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.F99UA1.RIGHT.FIDUCIAL.Std-MESH.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.F99UA1.RIGHT.FLAT.CartSTD.Std-MESH.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.F99UA1.RIGHT.FLAT.LOBAR_CUTS.Std-MESH.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.F99UA1.RIGHT.INFLATED.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.F99UA1.RIGHT.VERY_INFLATED.73730.surf.gii
wb_command -add-to-spec-file Macaque.F99.STANDARD-SCENES.73730.wb.spec CORTEX_RIGHT Macaque.PHT00.RIGHT.FIDUCIAL.Std-MESH.73730.surf.gii
rm -f $specLeft $specRight

# return
cd $dirScript


# ------------------------------ #
# section 2: create a brain mask
# ------------------------------ #

# create a working directory
rm -rf $dirProc/bet/
mkdir -p $dirProc/bet/

# copy and take the absolute values (in the original values above 100 are wrapped to -100)
fslmaths $dirProc/Macaque.F99UA1.LR.03-11+orig.nii.gz -abs $dirProc/bet/F99

# there is a single P-A line that is corrupted, smooth interpolate it
fslmaths $dirProc/bet/F99 -mul 0 -add 1 -roi 73 1 0 -1 54 1 0 -1 -binv $dirProc/bet/smoothfill_mask
fslsmoothfill -i $dirProc/bet/F99 -m $dirProc/bet/smoothfill_mask -o $dirProc/bet/F99 > /dev/null
# clean up
imrm $dirProc/bet/smoothfill_mask $dirProc/bet/F99_init $dirProc/bet/F99_idxmask $dirProc/bet/F99_vol2 $dirProc/bet/F99_vol32
fslmaths $dirProc/bet/F99 -thr 0 $dirProc/bet/F99

# this brain extraction depends on the McLaren reference,
# so please run proc_McLaren.sh first
# original in: $dirScript/../orig/McLaren/112RM-SL_T1
# output: $dirScript/McLaren/McLaren and $dirScript/McLaren/McLaren_brain_mask

# now create a nice brain mask for this F99 image
sh $dirScript/bet_F99.sh \
--workdir=$dirProc/bet \
--F99dir=$dirProc/bet \
--F99img=F99 \
--refname=SL \
--refimg=$dirScript/McLaren/McLaren \
--refmask=$dirScript/McLaren/McLaren_brain_mask \
--refmaskstrict=$dirScript/McLaren/McLaren_brain_mask_strict \
--scriptdir=$dirScript \
--config=$dirScript/fnirt_1mm.cnf \
--betorig --biascorr --betrestore --refreg --brainmask


# ------------------------------ #
# section 3: register F6 and F99
# ------------------------------ #

# why on earth are F6 and F99 not registered to the same space already?
# F6 is much smaller than F99


# ------------------------------ #
# section 4: copy and rename files
# ------------------------------ #

# move them to the appropriate space folder
imcp $dirProc/bet/F99 $dirFinal/F99
imcp $dirProc/bet/F99_restore $dirFinal/F99_restore
imcp $dirProc/bet/F99_brain_mask $dirFinal/F99_brain_mask
imcp $dirProc/bet/F99_brain_mask_strict $dirFinal/F99_brain_mask_strict

# copy and rename surface files
mv $dirProc/Macaque.F99UA1.LEFT.FIDUCIAL.Std-MESH.73730.surf.gii $dirSurf/F99.left.fiducial.surf.gii
mv $dirProc/Macaque.F99UA1.LEFT.FLAT.CartSTD.Std-MESH.clean.73730.surf.gii $dirSurf/F99.left.flat.surf.gii
mv $dirProc/Macaque.F99UA1.LEFT.INFLATED.73730.surf.gii $dirSurf/F99.left.inflated.surf.gii
mv $dirProc/Macaque.F99UA1.LEFT.VERY_INFLATED.73730.surf.gii $dirSurf/F99.left.very_inflated.surf.gii
mv $dirProc/Macaque.F99UA1.RIGHT.FIDUCIAL.Std-MESH.73730.surf.gii $dirSurf/F99.right.fiducial.surf.gii
mv $dirProc/Macaque.F99UA1.RIGHT.FLAT.CartSTD.Std-MESH.73730.surf.gii $dirSurf/F99.right.flat.surf.gii
mv $dirProc/Macaque.F99UA1.RIGHT.INFLATED.73730.surf.gii $dirSurf/F99.right.inflated.surf.gii
mv $dirProc/Macaque.F99UA1.RIGHT.VERY_INFLATED.73730.surf.gii $dirSurf/F99.right.very_inflated.surf.gii
