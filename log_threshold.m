function output = log_threshold(data,perc_threshold)
% function output = log_threshold(data,perc_threshold)
%
% Log transform all data > 0, normalize by dividing by the maximum value,
% and zero everything < perc_threshold
%
% Perc_threshold is a value between 0 and 1, so cutting off the bottom
% five percent values happens when 0.05 is passed
%
% Rogier B. Mars, University of Oxford, 22032013
% 09052013 RBM Threshold based on maximum value now
% 10052013 RBM Added data normalization by dividing by the maximum value
%              and substantial rearrange and commenting
% 16052013 RBM Changed order to: log transform, normalize, threshold

vizdata = 0;

%=============================================================
% Ancient version
%
% data(find(data>0)) = log(data(find(data>0)));
% logdata = sort(log(data(find(data>0))));
% 
% % % Based on length data
% % cutoff = round(length(logdata)*perc_threshold);
% cutoff = logdata(cutoff);
% data(find(data<cutoff)) = 0;
% 
% output = data;
%
%=============================================================

if vizdata==1, figure; subplot(1,4,1); hist(data(find(data(:)>0))); end

%=============================================================
% Log transform
%=============================================================

data(find(data>0)) = log(data(find(data>0)));
% logdata = sort(log(data(find(data>0))));

if vizdata==1, subplot(1,4,2); hist(data(find(data(:)>0))); end

%=============================================================
% Normalize (divide by maximum value)
%=============================================================

maxvalue = max(data(:));
data(find(data>0)) = data(find(data>0))./maxvalue;
clear maxvalue;

if vizdata==1, subplot(1,4,3); hist(data(find(data(:)>0))); end

%=============================================================
% Threshold
%=============================================================

maxvalue = max(data(:));
cutoff = perc_threshold*maxvalue;
data(find(data<cutoff)) = 0;

if vizdata==1, subplot(1,4,4); hist(data(find(data(:)>0))); end

output = data;