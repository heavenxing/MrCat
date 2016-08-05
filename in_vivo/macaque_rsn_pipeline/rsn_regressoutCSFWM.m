% rsn_regressoutCSFWM
% Produces Yr after regressing X out of Y
%
% Y is NxP and X is NxQ
%--------------------------------------------------------------------------
%
% version history
% 2016-03-23    Rogier  added to MrCat, based on Saad's original
%
%--------------------------------------------------------------------------

%==================================================
% Load confounds
%==================================================

CSF = load('./transform/CSF_eig.txt');
WM = load('./transform/WM_eig.txt');

%==================================================
% Load and reshape data
%==================================================

[data, dims,scales,bpp,endian] = read_avw('./functional/filtered_brain.nii.gz');
n_volumes = size(data,4);

newdata = reshape(data,size(data,1)*size(data,2)*size(data,3),n_volumes);

%==================================================
% Regress out
%==================================================

newdata = newdata';

m=repmat(mean(newdata),size(newdata,1),1);

M=[ones(n_volumes,1) [CSF WM]];

newdataR = newdata - (M*(pinv(M)*newdata)) + m;

%==================================================
% Reshape and save
%==================================================

newdata2 = reshape(newdataR',size(data,1),size(data,2),size(data,3),n_volumes);
save_avw(newdata2,'./functional/filtered_brain_noCSFWM.nii.gz','f',scales');



% figure
% subplot(1,2,1),hold on
% plot(X,Y,'k.')
% plot(X,M*(pinv(M)*Y),'r');
% subplot(1,2,2),hold on
% plot(X,Yr,'.');
