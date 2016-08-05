#!/bin/sh
#
# Script to flirt all monkeys to skull stripped MNI template.
#

if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]
then
  echo Usage: 
  echo $0 ref basedir in out
  echo or
  echo $0 ref basedir in out jid
  exit 1
fi

basedir=$2

if [ ! -d "${basedir}/log" ]
then
  echo Creating ${basedir}/log
  mkdir ${basedir}/log
fi
txtname=`mktemp ${basedir}/log/flirt_all.txt.XXXXXX`

for mon in ${basedir}/monkeys/*
do
  echo "flirt -ref $1 -in ${mon}/$3 -omat ${mon}/$4" >> $txtname
done

if [ "$#" -eq  5 ]
then
  jid=`fsl_sub -q veryshort.q -j $5 -t $txtname`
else
  jid=`fsl_sub -q veryshort.q -t $txtname`
fi

echo $jid
