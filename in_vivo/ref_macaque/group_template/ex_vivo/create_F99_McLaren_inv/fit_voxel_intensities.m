function fit_voxel_intensities(workDir,refDir,flgFit)

% report in the terminal that this scirpt is correctly called
disp('');
disp('Now running fit_voxel_intensities');

% compare target and reference voxel intensities
flgPlot = false;

% define work and reference directories if not specified
if nargin<3 || isempty(flgFit), flgFit = 'spline'; end % 'poly' or 'spline'
if nargin<2 || isempty(refDir), refDir = fullfile(homepath,'code','MrCat-dev','ref_macaque'); end
if nargin<1 || isempty(workDir), workDir = fullfile(refDir,'proc','ex_vivo_template'); end

if strcmpi(flgFit,'spline')
  disp('The source and reference voxel intensities will be related to each other by fitting a set of smoothing splines');
else
  disp('The source and reference voxel intensities will be related each other by fitting a third order polynomial function');
end
disp('');

% add the fieldtrip fileio toolbox, is not already present
if ~exist('ft_read_mri')
  MRCATDIR = getenv('MRCATDIR');
  addpath(fullfile(MRCATDIR,'external','fieldtrip','fileio'));
end

% switch between reference image types
flgRefType = 'regular'; % 'inverse'
switch flgRefType
  case 'regular'
    fnameRef = fullfile(refDir,'F99','McLaren.nii.gz');
    xlimVal = [80 320];
    ylimVal = [80 240];
  case 'inverse'
    fnameRef = fullfile(workDir,'McLaren_inv.nii.gz');
    xlimVal = [80 240];
    ylimVal = [80 240];
end
fnameRefMask = fullfile(refDir,'F99','McLaren_brain_mask_strict.nii.gz');
% read in reference and mask images
refImg = ft_read_mri(fnameRef);
refMask = ft_read_mri(fnameRefMask);

% read in source image
fnameSource = fullfile(workDir,'T1w_restore_F99.nii.gz');
sourceImg = ft_read_mri(fnameSource);

% combine the masks and extract data
flgMaskData = false;
if flgMaskData
  % read in mask image
  fnameSourceMask = fullfile(workDir,'brainmask_F99.nii.gz');
  sourceMask = ft_read_mri(fnameSourceMask);
  maskComb = logical(refMask.anatomy(:)) & logical(sourceMask.anatomy(:)) & refImg.anatomy(:) > 0 & sourceImg.anatomy(:) > 0;
else
  maskComb = true(numel(refMask.anatomy),1); xlimVal(1) = 0; ylimVal(1) = 0;
end
refDat = refImg.anatomy(maskComb);
sourceDat = sourceImg.anatomy(maskComb);

% plot source and reference against each other
if flgPlot
  figure; plot(refDat(1:100:end),sourceDat(1:100:end),'g+');
  xlim(xlimVal); ylim(ylimVal);
end

% fit a polynomial through the raw data
if flgPlot
  fitraw = fit(refDat,sourceDat,'poly3','Normalize','on','Robust','on');
  hold on; plot(fitraw,'r');
end

% to ensure all sections get equal weighting in the curve fitting
% resample the raw data at a consistent (and lower) rate
fs = 1; % desired sampling frequency in units of refDat values
[y,ty] = resample(sourceDat,refDat,fs);
if flgPlot, hold on; plot(ty,y,'b*'); end

% fit a set of smoothing splines to resampled (but not low-passed) data
fitsp = fit(ty,y,'smoothingspline','Normalize','on','SmoothingParam',0.999);
if flgPlot, hold on; plot(fitsp,'b'); end

% low-pass filter
[b,a] = butter(6,0.1/(fs/2),'low');
ylp = filtfilt(b,a,y);
if flgPlot, hold on; plot(ty,ylp,'k+'); end

% fit a polynomial on the resampled and low-passed data
fitlp = fit(ty,ylp,'poly3','Normalize','on','Robust','on');
if flgPlot, hold on; plot(fitlp,'k'); end

% decide if you like the polynomial or the splines better
% the spline is a closer match, but the lp fit is a more consistent
% descriptor (less degrees of freedom)
if strcmp(flgFit,'spline')
  curvefit = fitsp;
else
  curvefit = fitlp;
end

% evaluate the fit from reference to predicted source
if flgPlot
  refMatchDat = curvefit(refDat);
  figure; plot(sourceDat(1:100:end),refMatchDat(1:100:end),'g+');
  xlim([120 200]); ylim([120 200]);
end

% write out a new reference image
fnameRefInv = fullfile(workDir,'McLaren_inv_fit.nii.gz');
dat = refImg.anatomy;
dat(:) = curvefit(refImg.anatomy);
dat(dat>190) = 0;
ft_write_mri(fnameRefInv,dat,'dataformat','nifti','transform',refImg.transform);

disp('');
disp('Finished fit_voxel_intensities');
disp('');
