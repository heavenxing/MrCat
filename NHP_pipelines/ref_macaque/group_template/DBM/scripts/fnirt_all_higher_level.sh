#!/bin/sh
#
# Script to fnirt all monkeys to template with non-linear and intensity starting guess
#

if [ "$#" -ne 8 ] && [ "$#" -ne 9 ]
then
  echo Usage: 
  echo $0 ref refmask basedir in warps intensities config out
  echo or
  echo $0 ref refmask basedir in warps intensities config out jid
  exit 1
fi

basedir=$3

txtname=`mktemp ${basedir}/log/fnirt_all_higher_level.txt.XXXXXX`

for mon in ${basedir}/monkeys/*
do
  echo "fnirt --ref=$1 --refmask=$2 --in=${mon}/$4 --inwarp=${mon}/$5 --intin=${mon}/$6 --config=$7 --intout=${mon}/$8_int --cout=${mon}/$8_warps -v" >> $txtname
done

if [ "$#" -eq  9 ]
then
  jid=`fsl_sub -q short.q -j $9 -t $txtname`
else
  jid=`fsl_sub -q short.q -t $txtname`
fi

echo $jid