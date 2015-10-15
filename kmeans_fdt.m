function kmeans_fdt(fdt_matrix2_file,fdt_paths_file,coords_for_fdt_matrix2_file,number_of_clusters,varargin)
% Wrapper to run simple kmeans clustering on the output of FSL's probtrackx
% ran with --omatrix2 option. Calculates cross-correlation matrix of fdt_matrix2,
<<<<<<< HEAD
% runs kmeans, writes results to disk, and evaluates using the silhouette measure.
% Cross-correlation matrix file can also be given as input argument, since
% this can be time consuming to calculate
=======
% runs kmeans, and writes results to disk. Cross-correlation matrix file can
% also be given as input argument, since this can be time consuming to calculate
>>>>>>> origin/master
%--------------------------------------------------------------------------
%
% Use
%   kmeans_fdt(fdt_matrix_file,fdt_paths_file,coords_for_fdt_matrix2_file,number_of_clusters)
%   kmeans_fdt(fdt_matrix_file,fdt_paths_file,coords_for_fdt_matrix2_file,number_of_clusters,'CC',cross_corr_matrix)
%
% Obligatory inputs:
%   fdt_matrix_file2                string containing full name of the fdt_matrix2
%                                   file from FSL
%   fdt_paths_file                  string containing full name of fdt_paths file
%                                   from FSL
%   coords_for_fdt_matrix2_file     string containing full name of the
%                                   coords_for_fdt_matrix2_file from FSL
%   number_of_clusters              vector with number of clusters to use
%
% Optional inputs (using parameter format):
%   CC                              cross-correlation matrix
%   Cinit_method                    string initialization method, see
%                                   km_init.m for options
%   n_repeats                       number of kmeans replications per
%                                   cluster number (default 20)
%
% Output
%   none        results are reported in figures and written to the current
%               directory as clusters_*
%
% version history
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
n_repeats = 20;

if nargin>4
    for vargnr = 2:2:length(varargin)
        switch varargin{vargnr-1}
            case 'CC'
                CC_file = varargin{vargnr};
            case 'Cinit_method'
                Cinit_method = varargin{vargnr};
            case 'n_repeats'
                n_repeats = varargin{vargnr};
        end
    end
end

%==================================================
% Load data
%==================================================

fprintf('Loading data...');

% Load datasize
[~,~,ext] = fileparts(fdt_matrix2_file);
if isequal(ext,'.dot')
    x = load(fdt_matrix2_file);
    M=full(spconvert(x)); % Reorder the data
elseif isequal(ext,'.gz')
    M = read_avw(fdt_matrix2_file);
end

fprintf('done\n');

%==================================================
% Prepare cross correlation matrix
%==================================================

fprintf('Creating cross-correlation matrix...');

if isempty(CC_file)
    
    CC = 1 + corrcoef(M');
    clear M;
    
elseif ~isempty(CC_file)
    
    load(CC_file);
    
end

fprintf('done\n');

%==================================================
% Perform kmeans
%==================================================

fprintf('Performing kmeans...\n');

kmeans_solutions = [];
for c = number_of_clusters
    
    fprintf('...%i clusters\n',c);
    
    %--------------------------------------------
    % Choose kmeans version
    %--------------------------------------------
    
    % Matlab standard kmeans
    % idx = kmeans(CC,c);

    % MrCat kmeans
    Cinit = km_init(CC,c,Cinit_method,n_repeats); % Determine kmeans starting values
<<<<<<< HEAD
    idx = kmeans_fast(CC,c,'n_repeats',n_repeats,'Cinit',Cinit); % Perform kmeans
=======
    idx = kmeans_fast(CC,c,'replicates',n_repeats,'Cinit',Cinit); % Perform kmeans
>>>>>>> origin/master

    %--------------------------------------------
    % Collect results
    %--------------------------------------------
    
    kmeans_solutions = [kmeans_solutions idx]; % store the result
    
    % Reorder the cross-correlation matrix and save it to disk
    sortedCC = sort_CC_matrix(CC,idx,idx,2,['sorted_matrix_' num2str(c) '_clusters']);
    
    % Backproject to brain
    [mask,~,scales] = read_avw(fdt_paths_file);
    mask = 0*mask;
    [~,~,ext] = fileparts(coords_for_fdt_matrix2_file);
    if isempty(ext)
        coord = load(coords_for_fdt_matrix2_file)+1;
    elseif (isequal(ext,'.gz') || isequal(ext,'.nii'))
        coord = read_avw(coords_for_fdt_matrix2_file)+1;
    end
    ind = sub2ind(size(mask),coord(:,1),coord(:,2),coord(:,3));
    [~,~,j] = unique(idx);
    mask(ind) = j;
    save_avw(mask,['clusters_' num2str(c)],'f',scales);
        
end

fprintf('done kmeans\n');

%==================================================
% Evaluate using various measures (warning: this takes quite some time)
%==================================================

fprintf('Evaluating results...\n');

<<<<<<< HEAD
km_silhouette(kmeans_solutions,CC);
=======
% fprintf('...Hierarchy index...\n');
% HI = km_hierarchyindex(kmeans_solutions,10^6);
fprintf('...Silhouette...\n');
km_silhouette(kmeans_solutions,CC);
% fprintf('...Variation of information...\n');
% VI = km_vi(kmeans_solutions);
>>>>>>> origin/master

fprintf('done\n');

fprintf('Done!\n');