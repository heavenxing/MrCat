function do_MIGP(datasets,output)
% Peform MIGP group-PCA as described in  as specified in Smith et al. (2014)
% 101:738-749.
%--------------------------------------------------------------------------
%
% Use
%   do_MIGP({'dataset1',dataset2'},'outputname.mat')
%
% Obligatory inputs:
%   datasets    cell containing strings with full input file names, which
%               can have extensions .nii.gz (NIFTI_GZ), .mat, or .nii
%               (CIFTI)
%   output      string full output file name (.mat)
%
% Requires readimgfile.m
%
% version history
% 2016-06022    Rogier bug in data reading fixed
% 2016-04-26    Rogier changed file handling to use readimgfile
% 2016-03-08    Rogier created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2015-03-08
%--------------------------------------------------------------------------

%==================================================
% Do the work
%==================================================

W=[];
dPCAint=1200;
for i=1:length(datasets)

    %----------------------------------------------
    % Load data
    %----------------------------------------------

    % fprintf('Loading data...');
    [~,~,ext] = fileparts(datasets{i});
    if isequal(ext,'.mat')
        B = load(datasets{i});
    else
        B = readimgfile(datasets{i});
    end

    %----------------------------------------------
    % Regress out mean
    %----------------------------------------------

    % fprintf('Regressing out mean...');
    B=regress_out(B',mean(B)')';
    grot=demean(B');
    W=double([W; demean(grot)]);

    %----------------------------------------------
    % PCA
    %----------------------------------------------

    fprintf('PCA...');
    [uu,dd]=eigs(W*W',min(dPCAint,size(W,1)-1));

    W=uu'*W;

end

dPCA=1000;

%==================================================
% Save output
%==================================================

data=W(1:dPCA,:)'; clear W;
save(output,'data','-v7.3');
