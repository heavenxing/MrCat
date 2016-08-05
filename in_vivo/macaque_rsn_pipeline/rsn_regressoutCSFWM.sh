#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# This is template script for a simple fixed processing pipeline


# ------------------------------ #
# Help
# ------------------------------ #

usage() {
cat <<EOF

rsn_regressoutCSFWM.sh: Reorient an image according to macaque standard

example:
      sh regressout_CSFWM.sh subjdir functional

usage: $(basename $0)
      obligatory arguments
        <subjdir> : subject directory
        <functional> : name of the functional time series
      optional arguments
       [--fast=<structural_brain>] : perform fast on structural first. Otherwise
                                     assuming segmented struct_restore_brain files
                                     present

EOF
}

# ------------------------------ #
# Housekeeping
# ------------------------------ #
# if no arguments given, or help is requested, return the usage
if [[ $# -eq 0 ]] || [[ $@ =~ --help ]] ; then usage; exit 0; fi

# if too few arguments given, return the usage, exit with error
if [[ $# -lt 2 ]] ; then >&2 usage; exit 1; fi

# set defaults

# parse the input arguments
for a in "$@" ; do
  case $a in
    --fast=*)   fastbrain="${a#*=}"; shift ;;
    #-o=*|--option=*)    option="${a#*=}"; shift ;;
    *)                  arg="$arg $a"; shift ;; # ordered arguments
  esac
done

# parse for obligatory arguments
# extract arguments that don't start with "-"
argobl=$(echo $arg | tr " " "\n" | grep -v '^-') || true
# parse obligatory arguments from the non-dash arguments
subjdir=$(echo $argobl | awk '{print $1}')
img=$(echo $argobl | awk '{print $2}')

# check if obligatory arguments have been set
if [[ -z $subjdir ]] ; then
  >&2 echo ""; >&2 echo "error: please specify the input image."
  usage; exit 1
fi
if [[ -z $img ]] ; then
  >&2 echo ""; >&2 echo "error: please specify the input image."
  usage; exit 1
fi

# remove img and base from list of arguments
arg=$(echo $arg | tr " " "\n" | grep -v "$subjdir") || true
arg=$(echo $arg | tr " " "\n" | grep -v "$img") || true

# check if no redundant arguments have been set
if [[ -n $arg ]] ; then
  >&2 echo ""; >&2 echo "unsupported arguments are given:" $arg
  usage; exit 1
fi


# ------------------------------ #
# Do the work
# ------------------------------ #

#=========================================
# Warp CSF and WM from template to functional space
#=========================================

struct_brain=struct_restore_brain

if [[ ! -z $fastbrain ]] ; then
  struct_brain=${fastbrain}
  fast -n 3 -t 1 -g --nobias ${subjdir}/structural/${fastbrain}
fi

#=========================================
# CSF and WM to functional space
#=========================================

# WM
flirt -in ${subjdir}/structural/${struct_brain}_seg_2.nii.gz \
  -out ${subjdir}/functional/WM.nii.gz \
  -ref ${subjdir}/functional/example_func.nii.gz \
  -applyxfm -init ${subjdir}/transform/struct_to_example_func_restore.mat

# CSF
flirt -in ${subjdir}/structural/${struct_brain}_seg_0.nii.gz \
  -out ${subjdir}/functional/CSF.nii.gz \
  -ref ${subjdir}/functional/example_func.nii.gz \
  -applyxfm -init ${subjdir}/transform/struct_to_example_func_restore.mat

# WM
#applywarp -i ${MRCATDIR}/ref_macaque/F99/McLaren_pve_0 \
#  -o ${subjdir}/functional/WM.nii.gz \
#  -r ${subjdir}/functional/example_func.nii.gz \
#  -w ${subjdir}/transform/F99_to_struct_warp.nii.gz \
#  --postmat=${subjdir}/transform/struct2func.mat

#  # CSF
#  applywarp -i ${MRCATDIR}/ref_macaque/F99/McLaren_pve_2 \
#    -o ${subjdir}/functional/CSF.nii.gz \
#    -r ${subjdir}/functional/example_func.nii.gz \
#    -w ${subjdir}/transform/F99_to_struct_warp.nii.gz \
#    --postmat=${subjdir}/transform/struct2func.mat

#=========================================
# Extract time courses
#=========================================

# WM
fslmeants -i ${subjdir}/functional/${img}\
  -o ${subjdir}/transform/WM_eig.txt \
  -m ${subjdir}/functional/WM.nii.gz --eig

# CSF
fslmeants -i ${subjdir}/functional/${img}\
  -o ${subjdir}/transform/CSF_eig.txt \
  -m ${subjdir}/functional/CSF.nii.gz --eig

#=========================================
# Regress out
#=========================================

cd ${subjdir}
matlab -nodisplay \< ${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rsn_regressoutCSFWM.m
cd ${MRCATDIR}
