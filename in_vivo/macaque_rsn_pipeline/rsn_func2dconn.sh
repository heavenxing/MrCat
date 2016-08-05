#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# rsn_func2dconn.sh


# ------------------------------ #
# Help
# ------------------------------ #

usage() {
cat <<EOF

rsn_func2dconn.sh: Register func to F99 and create dconn. Assuming standardized data organization

example:
      sh rsn_func2dconn.sh /Users/rogiermars/data/rsc/peewee filtered_brain

usage: $(basename $0)
      obligatory arguments
        <subjectdir> : subject directory containing functional, structural, and transform directories
        <functionalimg> : basename (without path) of the functional image
      optional arguments
          [--wbdir=<directory containing wb_command>] (default: /Applications/workbench1.1.1/bin_macosx64)
          [--fullcleanup] : remove all intermediate files

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
wbdir=/Applications/workbench1.1.1/bin_macosx64
fullcleanup=FALSE

# parse the input arguments
for a in "$@" ; do
  case $a in
    --wbdir=*)   wbdir="${a#*=}"; shift ;;
    --fullcleanup) fullcleanup=TRUE; shift ;;
    #-o=*|--option=*)    option="${a#*=}"; shift ;;
    *)                  arg="$arg $a"; shift ;; # ordered arguments
  esac
done

# parse for obligatory arguments
# extract arguments that don't start with "-"
argobl=$(echo $arg | tr " " "\n" | grep -v '^-') || true
# parse obligatory arguments from the non-dash arguments
subjdir=$(echo $argobl | awk '{print $1}')
functionalimg=$(echo $argobl | awk '{print $2}')

# check if obligatory arguments have been set
if [[ -z $subjdir ]] ; then
  >&2 echo ""; >&2 echo "error: please specify the subject directory."
  usage; exit 1
fi
if [[ -z $functionalimg ]] ; then
  >&2 echo ""; >&2 echo "error: please specify the functional image name."
  usage; exit 1
fi

# remove img and base from list of arguments
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
# Data into standard space
#=========================================

echo "rsn_func2dconn: Warping functional to F99"

if [ ! -d "${subjdir}/F99" ]; then
  mkdir ${subjdir}/F99
fi

fslroi ${subjdir}/functional/${functionalimg}.nii.gz ${subjdir}/functional/example_func.nii.gz 0 1

flirt -in ${subjdir}/functional/example_func.nii.gz \
  -ref ${subjdir}/structural/struct_restore_brain.nii.gz \
  -out ${subjdir}/transform/example_func_flirted2struct \
  -omat ${subjdir}/transform/func2struct.mat

applywarp -i ${subjdir}/functional/${functionalimg}.nii.gz \
  -o ${subjdir}/F99/${functionalimg}.nii.gz \
  -r ${MRCATDIR}/ref_macaque/F99/McLaren.nii.gz \
  -w ${subjdir}/transform/struct_to_F99_warp.nii.gz \
  --premat=${subjdir}/transform/func2struct.mat

#=========================================
# Project to surface
#=========================================

echo "rsn_func2dconn: Projecting functional to surface"

L=${MRCATDIR}/in_vivo/macaque_rsn_pipeline/lh.fiducial.10k.surf.gii
R=${MRCATDIR}/in_vivo/macaque_rsn_pipeline/rh.fiducial.10k.surf.gii

wb_command -volume-to-surface-mapping \
  ${subjdir}/F99/${functionalimg}.nii.gz $L \
  ${subjdir}/F99/${functionalimg}_L.func.gii -trilinear
wb_command -volume-to-surface-mapping \
  ${subjdir}/F99/${functionalimg}.nii.gz $R \
  ${subjdir}/F99/${functionalimg}_R.func.gii -trilinear

#=========================================
# Create dtseries
#=========================================

echo "rsn_func2dconn: Creating dtseries"

wb_command -cifti-create-dense-timeseries \
  ${subjdir}/F99/${functionalimg}.dtseries.nii \
  -left-metric ${subjdir}/F99/${functionalimg}_L.func.gii \
  -right-metric ${subjdir}/F99/${functionalimg}_R.func.gii

#=========================================
# create dconn
#=========================================

echo "rsn_func2dconn: Creating dconn"

wb_command -cifti-correlation \
  ${subjdir}/F99/${functionalimg}.dtseries.nii \
  ${subjdir}/F99/${functionalimg}.dconn.nii

#=========================================
# cleanup
#=========================================

if [[ $fullcleanup == TRUE ]] ; then
    rm ${subjdir}/transform/example_func_flirted2struct.nii.gz
    rm ${subjdir}/F99/${functionalimg}.nii.gz
    rm ${subjdir}/F99/${functionalimg}.dtseries.nii
fi

rm ${subjdir}/F99/${functionalimg}_L.func.gii
rm ${subjdir}/F99/${functionalimg}_R.func.gii
