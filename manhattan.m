function out = manhattan(template,data)
% function out = manhattan(template,data)
%
% Calculate Mahattan distances between vectors
%
% Inputs:
%   template    arms*1 template vector
%   data        arms*spiders data matrix
%
% Output:
%   out         1*spiders vector of mahattan distances
%
% Rogier B. Mars, University of Oxford, 19112013
% RBM 02012015 Removed loop to make more efficient

%========================================
% Housekeeping
%========================================

if size(template,1)~=size(data,1), error('Error in mahattan: Size of inputs do not match!'); end

%========================================
% Do the work
%========================================

% out = [];
% for i = 1:size(data,2)
%     d = sum(abs(template-data(:,i)));
%     out = [out d];
%     clear d;
% end

out = sum(abs(repmat(template,1,size(data,2)) - data),1);