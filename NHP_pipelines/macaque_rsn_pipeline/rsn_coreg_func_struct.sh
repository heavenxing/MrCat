#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# This is template script for a simple fixed processing pipeline


# ------------------------------ #
# Help
# ------------------------------ #

usage() {
cat <<EOF

rsn_coreg_func_struct.sh: Calculate linear transformations between functional and structural using flirt

example:
      sh regressout_CSFWM.sh subjdir img

usage: $(basename $0)
      obligatory arguments
        <subjdir> : subject directory
        <func_img> : the betted functional image to process (this can be the whole time series)
        <struct_img> : the betted structural image to process


EOF
}

# ------------------------------ #
# Housekeeping
# ------------------------------ #
# if no arguments given, or help is requested, return the usage
if [[ $# -eq 0 ]] || [[ $@ =~ --help ]] ; then usage; exit 0; fi

# if too few arguments given, return the usage, exit with error
if [[ $# -lt 3 ]] ; then >&2 usage; exit 1; fi

# set defaults

# parse the input arguments
for a in "$@" ; do
  case $a in
    #--func=*)   functionalimg="${a#*=}"; shift ;;
    #--subjdir=*)    option="${a#*=}"; shift ;;
    *)                  arg="$arg $a"; shift ;; # ordered arguments
  esac
done

# parse for obligatory arguments
# extract arguments that don't start with "-"
argobl=$(echo $arg | tr " " "\n" | grep -v '^-') || true
# parse obligatory arguments from the non-dash arguments
subjdir=$(echo $argobl | awk '{print $1}')
func_img=$(echo $argobl | awk '{print $2}')
struct_img=$(echo $argobl | awk '{print $3}')

# remove img and base from list of arguments
arg=$(echo $arg | tr " " "\n" | grep -v "$subjdir") || true
arg=$(echo $arg | tr " " "\n" | grep -v "$func_img") || true
arg=$(echo $arg | tr " " "\n" | grep -v "$struct_img") || true

# check if no redundant arguments have been set
if [[ -n $arg ]] ; then
  >&2 echo ""; >&2 echo "unsupported arguments are given:" $arg
  usage; exit 1
fi

# ------------------------------ #
# Do the work
# ------------------------------ #

# Create transform directory if necessary
if [ ! -d "${subjdir}/transform" ]; then
  mkdir ${subjdir}/transform
fi

# Get first volume of the functional data
fslroi ${subjdir}/functional/${func_img} ${subjdir}/functional/example_func.nii.gz 0 1

# func2struct
flirt -in ${subjdir}/functional/example_func.nii.gz \
  -ref ${subjdir}/structural/${struct_img} \
  -out ${subjdir}/transform/example_func_flirted2struct \
  -omat ${subjdir}/transform/func2struct.mat

# inverse: struct2func
convert_xfm -omat ${subjdir}/transform/struct2func.mat \
  -inverse ${subjdir}/transform/func2struct.mat
