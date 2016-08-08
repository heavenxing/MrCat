function [L,thrdata,varargout] = cluster_threshold(data,height,extent,varargin)
% function [L,thrdata,varargout] = cluster_threshold(data,height,extent,varargin)
%
% Threshold 3D matrix based on cluster height and extent
%--------------------------------------------------------------------------
%
% Use:
%   [L,thrdata] = cluster_threshold(data,2.5,10)
%   [L,thrdata,reporttable] = cluster_treshold(data,2.5,10)
%
% Obligatory inputs:
%   data    data matrix
%   height  height threshold (inclusive)
%   extent  extent threshold (inclusive)
%
% Optional inputs (using parameter format):
%   conn            desired connectivity following bwlabeln, 6 default
%   report_table    'yes' (default) or 'no'
%
% Obligatory outputs:
%   L       thresholded matrix with numbers for each significant cluster
%   thrdata thresholded original matrix
%
% Optional outputs:
%   varagout{1}     report table containing for each cluster a row with the
%                   cluster number, the x,y,z coords, and the size
%
% version history
% 18072016 RBM Added table output varagout{1}
% 17072016 RBM Added table reporting
% 14042016 RBM MrCat compatible
% 02042015 RBM Created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2015-04-02
%--------------------------------------------------------------------------


%===============================================
% Housekeeping
%===============================================

% Defaults
conn = 6;
report_table = 'yes';

% Optional inputs
if nargin>2
    for vargnr = 2:2:length(varargin)
        switch varargin{vargnr-1}
            case 'conn'
                conn = varargin{vargnr};
            case 'report_table'
                report_table = varargin{vargnr};
        end
    end
end

%===============================================
% Do the work
%===============================================

% Threshold based on height
data = threshold(data,height);

% Get clusters
L = bwlabeln(data,conn);

% Threshold based on extent
thrdata = zeros(size(data));
for c = 1:max(L(:))
    
    if length(find(L(:)==c))<extent
        L(find(L==c)) = 0;
    elseif length(find(L(:)==c))>=extent
        thrdata(find(L==c)) = data(find(L==c));
    end
    
end

%===============================================
% Report table
%===============================================

switch report_table
    
    case 'yes'
        
        report = [];
        
        bw = bwconncomp(thrdata);
        
        % Collect cluster sizes
        clustsizes = [];
        for c = 1:bw.NumObjects
            clustsizes = [clustsizes; [c length(bw.PixelIdxList{c})]];
        end
        clustsizes = sortrows(clustsizes,-2);
        
        fprintf('Clusters (by size):\n');
        fprintf('Clust_ID\tClust_loc\tClust_size\n');
        fprintf('==========================================\n');
        for c = 1:bw.NumObjects
            data = zeros(size(data)); data(bw.PixelIdxList{c}(ceil(length(bw.PixelIdxList{c})/2)))=1;
            [i,j,k] = ind2sub(size(data),find(data==1));
            fprintf('%i\t\t%i %i %i\t%i\n',clustsizes(c,1),i,j,k,clustsizes(c,2));
            report = [report; [c i j k clustsizes(c,1)]];
        end
        
        varargout{1} = report;
        
end