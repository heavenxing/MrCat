#!/bin/sh
#
# Script to resample all monkeys
#

if [ "$#" -ne 5 ] && [ "$#" -ne 6 ]
then
  echo Usage: 
  echo $0 ref basedir in warps out
  echo or
  echo $0 ref basedir in warps out jid
  exit 1
fi

basedir=$2

if [ ! -d "${basedir}/log" ]
then
  echo Creating ${basedir}/log
  mkdir ${basedir}/log
fi
txtname=`mktemp ${basedir}/log/resample_all.txt.XXXXXX`

for mon in ${basedir}/monkeys/*
do
  echo "applywarp --ref=$1 --in=${mon}/$3 --warp=${mon}/$4 --interp=spline --out=${mon}/$5" >> $txtname
done

if [ "$#" -eq  6 ]
then
  jid=`fsl_sub -q veryshort.q -j $6 -t $txtname`
else
  jid=`fsl_sub -q veryshort.q -t $txtname`
fi

echo $jid