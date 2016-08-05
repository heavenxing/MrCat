#!/bin/sh
#
# Script to fnirt all monkeys to template with affine starting guess
#

if [ "$#" -ne 7 ] && [ "$#" -ne 8 ]
then
  echo Usage: 
  echo $0 ref refmask basedir in mat config out
  echo or
  echo $0 ref refmask basedir in mat config out jid
  exit 1
fi

basedir=$3

txtname=`mktemp ${basedir}/log/fnirt_all_first_level.txt.XXXXXX`

for mon in ${basedir}/monkeys/*
do
  echo "fnirt --ref=$1 --refmask=$2 --in=${mon}/$4 --aff=${mon}/$5 --config=$6 --intout=${mon}/$7_int --cout=${mon}/$7_warps -v" >> $txtname
done

if [ "$#" -eq  8 ]
then
  jid=`fsl_sub -q short.q -j $8 -t $txtname`
else
  jid=`fsl_sub -q short.q -t $txtname`
fi

echo $jid