#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# rsn_func2dconn.sh


# ------------------------------ #
# Help
# ------------------------------ #

usage() {
cat <<EOF

rsn_bet_func.sh: Bet functional data using standard FSL BET

example:
      sh rsn_be_func.sh /Users/rogiermars/data/rsc/peewee raw

usage: $(basename $0)
      obligatory arguments
        <subjectdir> : subject directory containing functional directory
        <functionalimg> : basename (without path) of the functional time series

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

# parse the input arguments
for a in "$@" ; do
  case $a in
    # --wbdir=*)   setting="${a#*=}"; shift ;;
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

fslroi ${subjdir}/functional/${functionalimg}.nii.gz ${subjdir}/functional/example_func.nii.gz 0 1

bet ${subjdir}/functional/example_func.nii.gz ${subjdir}/functional/example_func_brain.nii.gz -f 0.7 -m

fslmaths ${subjdir}/functional/${functionalimg}.nii.gz \
  -mas ${subjdir}/functional/example_func_brain_mask.nii.gz \
  ${subjdir}/functional/${functionalimg}_brain.nii.gz
