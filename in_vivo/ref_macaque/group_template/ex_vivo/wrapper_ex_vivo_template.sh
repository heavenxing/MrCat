#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files


#==============================
# settings
#==============================

# specify the script, config, work, and log directories
scriptDir=$MRCATDIR/ref_macaque/group_template
configDir=$scriptDir/config

# specify the work and log directories
workDir=$MRCATDIR/ref_macaque/group_template/ex_vivo
logDir=$workDir/log
mkdir -p $logDir

# specify the ex-vivo source data directory
#sourceDir=/vols/Data/rbmars/ex-vivo
sourceDir=$workDir/source

# specify the reference
refDir=$MRCATDIR/ref_macaque/F99
refImg=$refDir/McLaren_inv
refMask=$refDir/McLaren_brain_mask

# specify the data
monkeyList="umberto hilary oddie"
for monkey in $monkeyList ; do
  sourceImgList=$(echo $sourceImgList $sourceDir/$monkey/T1w_restore)
  sourceMaskList=$(echo $sourceMaskList $sourceDir/$monkey/brainmask)
done


#==============================
# instructions
#==============================

# STEP 1: initial registration to the reference
echo "submitting jobs: initial registration to the reference"
tmpFile=$(mktemp "$logDir/cmdtxt.source2ref.XXXXXXXXXX"); chmod +x $tmpFile
for monkey in $monkeyList ; do
  # define source image and mask
  sourceImg=$sourceDir/$monkey/T1w_restore
  sourceMask=$sourceDir/$monkey/brainmask
  # write the command to a text file
  echo sh $scriptDir/group_template.sh --workdir=$workDir --configdir=$configDir --sourceimg=$sourceImg --sourcemask=$sourceMask --base=$monkey --refimg=$refImg --refmask=$refMask --source2ref >> $tmpFile
done
jobID=$(fsl_sub -N source2ref -q short.q -l $logDir -t $tmpFile)


# STEP 2: create the first group template
echo "submitting job: group average after registration to the reference"
jobID=$(fsl_sub -N groupavg_source2ref -j $jobID -q short.q -l $logDir sh $scriptDir/group_template.sh --iteration=initial --workdir=$workDir --configdir=$configDir --sourceimg=${sourceImgList// /@} --sourcemask=${sourceMaskList// /@} --base=${monkeyList// /@} --refimg=$refImg --refmask=$refMask --groupavg --group2ref)


# ITERATIVE STEPS: register to group template, and re-create
for iCurr in 1 2 3 4 5 6 ; do


  # STEP 3: register the source images to the group template
  echo "submitting jobs: level [$iCurr] registration to the group"
  tmpFile=$(mktemp "$logDir/cmdtxt.source2group.XXXXXXXXXX"); chmod +x $tmpFile
  for monkey in $monkeyList ; do
    # write the command to a text file
    echo sh $scriptDir/group_template.sh --iteration=$iCurr --workdir=$workDir --configdir=$configDir --sourceimg=$sourceDir/$monkey/T1w_restore --sourcemask=$sourceDir/$monkey/brainmask --base=$monkey --refimg=$refImg --refmask=$refMask --source2group >> $tmpFile
  done
  jobID=$(fsl_sub -N source2group_$iCurr -j $jobID -q short.q -l $logDir -t $tmpFile)


  # STEP 4: create the group template
  echo "submitting job: group average after level [$iCurr] registration"
  jobID=$(fsl_sub -N groupavg_$iCurr -j $jobID -q veryshort.q -l $logDir sh $scriptDir/group_template.sh --iteration=$iCurr --workdir=$workDir --configdir=$configDir --sourceimg=${sourceImgList// /@} --sourcemask=${sourceMaskList// /@} --base=${monkeyList// /@} --refimg=$refImg --refmask=$refMask --groupavg --group2ref)
  #jobID=$(fsl_sub -N groupavg_$iCurr -j $jobID -q veryshort.q -l $logDir sh $scriptDir/group_template.sh --iteration=$iCurr --workdir=$workDir --configdir=$configDir --sourceimg=${sourceImgList// /@} --sourcemask=${sourceMaskList// /@} --base=${monkeyList// /@} --refimg=$refImg --refmask=$refMask --groupavg)


done
