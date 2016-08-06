# This is an example resting state fMRI pipeline. It takes you from raw nifti_gz
# data to a preprocessed, registered dataset and dense connectome. The idea is
# that it is as modular as possible, so it's easy to add future steps
#
# Directory structure follows the HCP format a bit. There is a study directory,
# in there there are subject directories, in there directories according to the
# different spaces (functional, structural, F99, etc). In the functional data
# there should be a "raw.nii.gz", in the structural directory there should be a
# "struct.nii.gz"
#
# version history
# 31052016 RBM  created

#=======================================
# Set up stuff (edit this part)
#=======================================

studydir=/vols/Data/rbmars/hipp
subj=subj1
declare -a tasklist=("filter")

workbench_dir=/Applications/workbench1.1.1/bin_macosx64
export MRCATDIR=/vols/Data/rbmars/hipp/MrCat
export wb_command=${workbench_dir}/wb_command

# Recommended order of pipeline:
# reorient_struc_oxford or reorient_struct_sinai (done)
# bet_and_register_struc (done)
# reorient_func_oxford or reorient_func_sinai (done)
# bet_func (done)
# coreg_func_struct (done)
# filter (done)
# regressout_CSFWM (done)
# dtseries (done)
# normalize_ts (done)
# smooth_dtseries (done)
# dtseries2dconn (done)
# dconn (done) (DEPRECATED: now create dtseries and then do dtseries2dconn)

#=======================================
# Do the work (don't edit this part)
#=======================================

#---------------------------------------
# Set MrCat environment variable
#---------------------------------------

if [[ -z $MRCATDIR ]] ; then
  # export the MrCat location
  if [[ $OSTYPE == "linux-gnu" ]] ; then
    MRCATDIR="$HOME/scratch/MrCat-dev"
  elif [[ $OSTYPE == "darwin"* ]] ; then
    MRCATDIR="$HOME/code/MrCat-dev"
  fi
  export MRCATDIR
fi

for task in "${tasklist[@]}"; do

  #---------------------------------------
  # Reorient structural data
  #---------------------------------------

  if [ "$task" == "reorient_struc_oxford" ]; then
    echo "Task: reorienting structural data"
    cd ${studydir}/${subj}/structural
    sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_reorient.sh ${studydir}/${subj}/structural/struct.nii.gz
  fi

  if [ "$task" == "reorient_struct_sinai" ]; then
    echo "Task: reorienting structural data"
    cd ${studydir}/${subj}/structural
    sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_reorient.sh ${studydir}/${subj}/structural/struct.nii.gz
    fslswapdim ${studydir}/${subj}/structural/struct.nii.gz -x y z ${studydir}/${subj}/structural/struct.nii.gz
  fi

  #---------------------------------------
  # Bet and register structural data
  #---------------------------------------

  if [ "$task" == "bet_and_register_struc" ]; then
    echo "Task: betting and registering structural data (this will create transform directory)"
    cd ${studydir}/${subj}/structural
    sh ${MRCATDIR}/in_vivo/struct_macaque/struct_macaque.sh --subjdir=${studydir}/${subj} --structimg=${studydir}/${subj}/structural/struct.nii.gz --all --refspace=F99 --refimg=${MRCATDIR}/ref_macaque/F99/McLaren.nii.gz
  fi

  #---------------------------------------
  # Reorient functional data
  #---------------------------------------

  if [ "$task" == "reorient_func_oxford" ]; then
    echo "Task: reorienting functional data"
    cd ${studydir}/${subj}/functional
    sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_reorient.sh ${studydir}/${subj}/functional/raw.nii.gz
  fi

  if [ "$task" == "reorient_func_sinai" ]; then
    echo "Task: reorienting functional data"
    cd ${studydir}/${subj}/functional
    sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_reorient.sh ${studydir}/${subj}/functional/raw.nii.gz
    fslswapdim ${studydir}/${subj}/functional/raw.nii.gz -x y z ${studydir}/${subj}/functional/raw.nii.gz
  fi

  #---------------------------------------
  # Bet functional data
  #---------------------------------------

  if [ "$task" == "bet_func" ]; then
    echo "Task: betting functional data"
    sh ${MRCATDIR}/in_vivo/bet_macaque.sh ${studydir}/${subj}/functional/raw.nii.gz -t T2star -f 0.65 -fFP .95 -s 70
  fi

  #---------------------------------------
  # Coregister functional and structural
  #---------------------------------------

  if [ "$task" == "coreg_func_struct" ]; then
    echo "Task: coregistering functional and structural"
    fslroi ${studydir}/${subj}/functional/raw_brain.nii.gz ${studydir}/${subj}/functional/example_func.nii.gz 0 1
    sh ${MRCATDIR}/in_vivo/register_EPI_T1.sh \
      --epi=${studydir}/${subj}/functional/example_func.nii.gz \
      --t1=${studydir}/${subj}/structural/struct_restore.nii.gz \
      --t1brain=${studydir}/${subj}/structural/struct_restore_brain.nii.gz \
      --transdir=${studir}/${subj}/transform/ \
      --all
    # sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_coreg_func_struct.sh ${studydir}/${subj} raw_brain.nii.gz struct_restore_brain.nii.gz
  fi

  #---------------------------------------
  # Filter functional data
  #---------------------------------------

  if [ "$task" == "filter" ]; then
    echo "Task: filtering functional data"
    fslmaths ${studydir}/${subj}/functional/raw_brain -bptf -1 5 ${studydir}/${subj}/functional/filtered_brain.nii.gz
  fi

  #---------------------------------------
  # Regress out CSF and WM
  #---------------------------------------

  if [ "$task" == "regressout_CSFWM" ]; then
    echo "Task: regressing out CSF and WM time courses"
    if [ -f "$file" ]
    then
      # File exists: do nothing
    else
      fslroi ${studydir}/${subj}/functional/raw_brain.nii.gz ${studydir}/${subj}/functional/example_func.nii.gz 0 1
    fi
    sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_regressoutCSFWM.sh ${studydir}/${subj} filtered_brain --fast=struct_restore_brain
  fi

  #---------------------------------------
  # Warp functional data to F99 and create dtseries
  #---------------------------------------

  if [ "$task" == "dtseries" ]; then
    echo "Task: warping functional data to F99 and create dtseries"
    sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_func2dtseries.sh ${studydir}/${subj} filtered_brain_noCSFWM --wbdir=${workbench_dir} --fullcleanup
  fi

  #---------------------------------------
  # Normalize time courses
  #---------------------------------------

  if [ "$task" == "normalize_ts" ]; then
    echo "Task: Normalizing time courses"
    fname="${studydir}/${subj}/F99/filtered_brain_noCSFWM.dtseries.nii"
    matlab -nodisplay -nosplash -nodisplay -r "rsn_normalise_ts(fname);exit"
  fi

  #---------------------------------------
  # Convert dtseries to dconn
  #---------------------------------------

  if [ "$task" == "smooth_dtseries" ]; then
    echo "Task: Smoothing the dtseries"
    wb_command -cifti-smoothing \
		  ${studydir}/${subj}/F99/filtered_brain_noCSFWM.dtseries.nii \
		  3 3 ROW \
		  ${studydir}/${subj}/F99/filtered_brain_noCSFWM_rowsmooth3.dtseries.nii \
		  -left-surface ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/lh.fiducial.10k.surf.gii \
      -right-surface ${MRCATDIR}/in_vivo/macaque_rsn_pipelinerh.fiducial.10k.surf.gii
  fi

  #---------------------------------------
  # Convert dtseries to dconn
  #---------------------------------------

  if [ "$task" == "dtseries2dconn" ]; then
    echo "Task: Correlating dtseries to dconn"
    wb_command -cifti-correlation \
      ${studydir}/${subj}/F99/filtered_brain_noCSFWM.dtseries.nii \
      ${studydir}/${subj}/F99/filtered_brain_noCSFWM.dconn.nii
  fi

  #---------------------------------------
  # Warp functional data to F99 and create dtseries and dconn
  #---------------------------------------

  if [ "$task" == "dconn" ]; then
    echo "Task: warping functional data to F99 and create dtseries and dconn"
    sh ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_func2dconn.sh ${studydir}/${subj} filtered_brain_noCSFWM --wbdir=${workbench_dir} --fullcleanup
  fi

done

#---------------------------------------
# Round-up
#---------------------------------------

cd $studydir

echo "Done!"
