function kmeans_fdt(fname_fdt_matrix2,fname_fdt_paths,fname_coords_for_fdt_matrix2,nClusters,varargin)
% Wrapper to run simple kmeans clufname_coords_for_fdt_matrix2stering on the output of FSL's probtrackx
% ran with --omatrix2 option. Calculates cross-correlation matrix of fdt_matrix2,
% runs kmeans, writes results to disk, and evaluates using the silhouette measure.
% Cross-correlation matrix file can also be given as input argument, since
% this can be time consuming to calculate
%--------------------------------------------------------------------------
%
% Use
%   kmeans_fdt('fdt_matrix2.dot','fdt_paths.nii.gz','coords_for_fdt_matrix2',3)
%   kmeans_fdt('./mydatadir/fdt_matrix2.dot','./mydatadir/fdt_paths.nii.gz','./mydatadir/coords_for_fdt_matrix2',3,'outdir','./myanalysisdir')
%
% Obligatory inputs:
%   fname_fdt_matrix2               string containing full name of the
%                                   fdt_matrix2 file from FSL
%   fname_fdt_paths                 string containing full name of
%                                   fdt_paths file from FSL
%   fname_coords_for_fdt_matrix2    string containing full name of the
%                                   coords_for_fdt_matrix2_file from FSL
%   nClusters                       vector with number of clusters to use
%
% Optional inputs (using parameter format):
%   CC                              cross-correlation matrix
%   Cinit_method                    string initialization method, see
%                                   km_init.m for options
%   n_repeats                       number of kmeans replications per
%                                   cluster number (default 20)
%   evaluation                      string with evaluation method:
%                                   'silhouette', 'hierarchyindex',
%                                   or 'none' (default)
%   outdir                          output directory (default: pwd)
%   connexity                       connexity constraint, 0 to do nothing
%                                   (default) or fudge factor value
%   create_probtrack_masks          write out mask images with each cluster
%                                   separately 'yes' or 'no' (default)
%   io_toolbox                      use the FieldTrip ('ft') toolbox to
%                                   read/write the images (default), or use
%                                   FSL ('fsl'). The latter used to be the
%                                   canonical option, but its results are
%                                   not compatible with the new FSLeyes.
%
% Output
%   none        results are reported in figures and written to the output
%               directory as cluster_k* for the combined result,
%               cluster_k*_c* for the individual cluster masks, and
%               cluster_k*_not* for the cluster specific exclusion masks.
%               Non-zero voxels indicated in the file
%               km_report_nonconnected in the output directory
%
% version history
% 2016-11-02    Rogier  Code cleanup
% 2016-07-21    Rogier  Fix bug put in yesterday about FSL use for file
%                       handling
% 2016-07-20    Rogier  Fix bug in which non-connected voxels are
%                       incompatible with connexity constraint
% 2016-05-18   Rogier/Bart added plot_individual option
% 2016-05-12    Rogier  Added connexity constraint option
% 2016-04-15    Rogier  changed default evaluation to 'none' and improved
%                       documentation
% 2016-03-06    Rogier  added optional output directory, added removal
%                       of nonzero voxels, and implemented hierarchyindex
% 2016-03-05    Rogier  made silhouette evaluation optional
% 2015-10-23    Rogier  fixed conflicts associated with previous erroneous
%                       GitHub misuse
% 2015-10-14	Rogier  created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2015-10-14
%--------------------------------------------------------------------------

% Test input:
% fdt_matrix2_file = './2_CC_ccops/fdt_matrix2.nii.gz';
% fdt_paths_file = './2_CC_ccops/fdt_paths.nii.gz';
% coords_for_fdt_matrix2_file = './2_CC_ccops/coords_for_fdt_matrix2.nii.gz';
% CC_file = [];
% number_of_clusters = [2 3 4 5 6 7 8 9];

%==================================================
% Housekeeping
%==================================================

% Defaults
CC_file = [];
Cinit_method = 'plusplus';
nRepeats = 20;
evaluation = 'none';
outDir = './';
connexity = 0;
flgProbtrackMasks = false;
flgIOToolbox = 'ft'; % use FieldTrip instead of FSL to write out nifti images

if nargin>4
  for vargnr = 2:2:length(varargin)
    switch varargin{vargnr-1}
      case 'CC'
        CC_file = varargin{vargnr};
      case 'Cinit_method'
        Cinit_method = varargin{vargnr};
      case 'n_repeats'
        nRepeats = varargin{vargnr};
      case 'evaluation'
        evaluation = varargin{vargnr};
      case 'outdir'
        outDir = varargin{vargnr};
      case 'connexity'
        connexity = varargin{vargnr};
      case 'create_probtrack_masks'
        flgProbtrackMasks = varargin{vargnr};
      case 'io_toolbox'
        flgIOToolbox = varargin{vargnr};
    end
  end
end

% Create output directory
if ~isempty(outDir)
  if ~(outDir(length(outDir))=='/'), outDir = [outDir '/']; end
  if ~exist(outDir,'dir'), mkdir(outDir); end;
end

%==================================================
% Load data
%==================================================

fprintf('Loading data...');

% Load datasize
[~,~,ext] = fileparts(fname_fdt_matrix2);
if isequal(ext,'.dot')
  x = load(fname_fdt_matrix2);
  M=full(spconvert(x)); % Reorder the data
elseif isequal(ext,'.gz')
  M = read_avw(fname_fdt_matrix2);
end

% load the reference image
if strcmpi(flgIOToolbox,'ft')
  % use the FieldTrip image reader/writer package
  refImg = ft_read_mri(fname_fdt_paths);
  zeroImg = 0*refImg.anatomy;
else
  % save_avw is the FSL default, but is not compatible with FSLeyes
  [zeroImg,~,scales] = read_avw(fname_fdt_paths);
  zeroImg = 0*zeroImg;
end
% temporary place holder for the output image(s)
outImg = zeroImg;

% load the reference image
[~,~,ext] = fileparts(fname_coords_for_fdt_matrix2);
if isempty(ext)
  coord = load(fname_coords_for_fdt_matrix2)+1;
elseif (isequal(ext,'.gz') || isequal(ext,'.nii'))
  if strcmpi(flgIOToolbox,'ft')
    coord = ft_read_mri(fname_coords_for_fdt_matrix2);
    coord = coord.anatomy+1;
  elseif strcmpi(flgIOToolbox,'fsl')
    coord = read_avw(fname_coords_for_fdt_matrix2)+1;
  end
end

fprintf('done\n');

%==================================================
% Remove non-connected data
%==================================================

% kmeans crashes if there are voxels/vertices that have only zero
% connections to the target. Therefore, these are here removed from the
% data and associated variables are adapted

nonConnected = ~any(M');

if sum(nonConnected)>0

  % Report non-connected voxels
  outName = [outDir 'cluster_nonconnected'];
  outImg = zeroImg;
  ind = sub2ind(size(outImg),coord(:,1),coord(:,2),coord(:,3));
  outImg(ind) = nonConnected;
  % if strcmpi(flgIOToolbox,'ft')
  %    disp('I am using fieldtrip');
  %    ft_write_mri(outName,outImg,'dataformat','nifti','transform',refImg.transform);
  % else
  %     disp('I am using FSL');
       save_avw(outImg,outName,'f',[1.25 1.25 1.25 1]);
  % end

  % Remove non-connected voxels
  M(nonConnected==1,:) = [];
  coord(nonConnected==1,:) = [];

end

%==================================================
% Prepare cross correlation matrix
%==================================================

% load or caluculate the cross-correlation matrix
if isempty(CC_file)
  fprintf('Creating cross-correlation matrix...');
  CC = km_calculateCC(M','plot_data','yes');
elseif ~isempty(CC_file)
    switch lower(CC_file)
        case 'no'
            CC = M;
        case 'pca'
            nComp = 10;
            [~,CC] = pca(M,'NumComponents',nComp);
        otherwise
            fprintf('Loading cross-correlation matrix...');
            load(CC_file);
    end
end

% Perform check of cross-correlation matrix
if length(find(isnan(CC(:))))>0
   error('Error in MrCat:kmeans_fdt: cross-correlation matrix contains NaN!');
end

% Implement connexity constraint
if connexity>0
    if sum(nonConnected)>0
        CC = km_connexityconstraint_volume(CC,fname_coords_for_fdt_matrix2,'nonconnected',nonConnected);
    elseif sum(nonConnected)==0
        CC = km_connexityconstraint_volume(CC,fname_coords_for_fdt_matrix2);
    end
end

fprintf('done\n');

%==================================================
% Perform kmeans
%==================================================

fprintf('Performing kmeans...\n');

kmeans_solutions = [];
for k = nClusters

  fprintf('...%i clusters\n',k);

  %--------------------------------------------
  % Choose kmeans version
  %--------------------------------------------

  % Matlab standard kmeans
  % idx = kmeans(CC,c,'Replicates',nRepeats);

  % MrCat kmeans
  Cinit = km_init(CC,k,Cinit_method,nRepeats); % Determine kmeans starting values
  idx = kmeans_fast(CC,k,'replicates',nRepeats,'Cinit',Cinit); % Perform kmeans

  %--------------------------------------------
  % Collect results
  %--------------------------------------------

  kmeans_solutions = [kmeans_solutions idx]; % store the result

  % Reorder the cross-correlation matrix and save it to disk
  if size(CC,1) == size(CC,2)
    sortedCC = sort_CC_matrix(CC,idx,idx,2,[outDir 'sorted_matrix_' num2str(k) '_clusters']);
  end

  %--------------------------------------------
  % Backproject to brain
  %--------------------------------------------

  % create a mask of cluster indices
  ind = sub2ind(size(outImg),coord(:,1),coord(:,2),coord(:,3));
  [~,~,j] = unique(idx);
  clusterImg = zeroImg;
  clusterImg(ind) = j;

  % write the cluster mask image to the output directory
  outName = sprintf('%scluster_k%d.nii.gz',outDir,k);
  if strcmpi(flgIOToolbox,'ft')
    ft_write_mri(outName,clusterImg,'dataformat','nifti','transform',refImg.transform);
  else
    save_avw(clusterImg,outName,'f',scales);
  end

  % Output a mask for each cluster (and the inverse)
  if istrue(flgProbtrackMasks)
    for c = 1:k

      % Output a .nii.gz with only this cluster
      outName = sprintf('%scluster_k%d_c%d.nii.gz',outDir,k,c);
      outImg = zeroImg;
      outImg(clusterImg==c) = 1;
      if strcmpi(flgIOToolbox,'ft')
        ft_write_mri(outName,outImg,'dataformat','nifti','transform',refImg.transform);
      else
        save_avw(outImg,outName,'f',scales);
      end

      % Ouput a .nii.gz with everything but this cluster
      outName = sprintf('%scluster_k%d_not%d.nii.gz',outDir,k,c);
      outImg = zeroImg;
      outImg(clusterImg>0 & clusterImg~=c) = 1;
      if strcmpi(flgIOToolbox,'ft')
        ft_write_mri(outName,outImg,'dataformat','nifti','transform',refImg.transform);
      else
        save_avw(outImg,outName,'f',scales);
      end

    end
  end

end

save all

fprintf('done kmeans\n');

%==================================================
% Evaluate using various measures
%==================================================

switch evaluation

  case 'none'

    % do nothing

  case 'silhouette'

    fprintf('Evaluating results using silhouette measure...\n');
    km_silhouette(kmeans_solutions,CC,'savefig',outDir,'savesilh',outDir);
    fprintf('done\n');

  case 'hierarchyindex'

    fprintf('Evaluating results using hierarchy index...\n');
    [HI,random_HI_means] = km_hierarchyindex(kmeans_solutions,'nperms',1000,'savefig',outDir);
    fprintf('done\n');

end

fprintf('Done!\n');
