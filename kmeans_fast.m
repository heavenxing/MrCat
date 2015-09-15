function [idx,C,sumd,D] = kmeans_fast(X,k,varargin)
% function [idx,C,sumd,D] = kmeans_fast(X,k,varargin)
% KMEANS_FAST Cluster multivariate data using the k-means algorithm. This
% code is strongly vectorized to improve speed beyond MATLAB kmeans.m
%
% Obligatory inputs:
%   X               points-by-dimension matrix with multivariate data
%   k               scalar with number of clusters to find
%   
% Optional inputs (using name-value pairs):
%   'replicates'    scalar with number of replicates (nr_rep) to run and
%                   select best (lowest summed distance) from
%   'Cinit'         - string describing method to initialize centroids
%                   - k-by-size(X,2)-by-nr_rep matrix with initial
%                     centroids
%
% Outputs:
%   idx             size(X,1)-by-1 vector with one class label per row in X
%   C               k-by-size(X,2) matrix with the centroids corresponding
%                   to each class
%   sumd            k-by-1 vector with summed distances of X to centroids
%                   per class
%   D               size(X,1)-by-1 vector of distances of X to centroids
%
%
% version history
% 2015-09-15    Rogier          Prepared for Github
% 2014-12-01    Lennart         added 'Cinit' option
% 2014-12-01    Lennart         added 'replicates' option
% 2014-12-01    Lennart         added sumd and D output
% 2014-11-01    Lennart         cleaned up code
% 2013-02-08    Laurent Sorber  added k-means++ initialisation
% 2009-07-01    Michael Chen    created litekmeans
%
% copyright of earlier versions (see end of file):
%   k-means++ addition: kmeans.m
%   Version: 2013-02-08
%   Written by Laurent Sorber (Laurent.Sorber@cs.kuleuven.be)
%
%   Original function: litekmeans.m
%   Version: 2012-02-04
%   Created: 2009-07-01
%   Written by Michael Chen (sth4nth@gmail.com).
%
% reference:
%   J. B. MacQueen, "Some Methods for Classification and Analysis of
%   MultiVariate Observations", in Proc. of the fifth Berkeley Symposium on
%   Mathematical Statistics and Probability, L. M. L. Cam and J. Neyman,
%   eds., vol. 1, UC Press, 1967, pp. 281-297.
%
% Lennart Verhagen & Rogier B. Mars
% University of Oxford, 2014-04-01
%--------------------------------------------------------------------------

% sort input
p = inputParser;
default.Replicates = 1;
default.Cinit = [];
p = addParam(p,'Replicates',default,@isscalar);
p = addParam(p,'Cinit',default);
parse(p,varargin{:});
nr_rep = p.Results.Replicates;
Cinit = p.Results.Cinit;

% set string to evaluate: determine if requested number of clusters has
% been found, or skip this check.
eval_str = 'length(unique(idx_r)) ~= k';
if ~isempty(Cinit)
    if isnumeric(Cinit) && size(Cinit,3) ~= nr_rep
        error('KMEANS_PLUSPLUS:Cinit_dimensions','Cinit must have the requested number of replications in the third dimensions: n x d x nr_rep');
    end
    if isnumeric(Cinit) || (ischar(Cinit) && strcmpi(Cinit,'kdtree'))
        eval_str = 'isempty(idx_r)';
    end
end
n = size(X,1);

sumD = Inf;
flg_k = true;
% loop over requested number of replicates
for r = 1:nr_rep
    
    idx_r = [];
    % if requested: loop until a solution with k cluster has been found
    while eval(eval_str)
        
        if isempty(Cinit)
            % The k-means++ initialization
            % included here to prevent dependence on kmeans_init.m
            % Reference:
            %   D. Arthur and S. Vassilvitskii, "k-means++: The Advantages
            %   of Careful Seeding", Technical Report 2006-13, Stanford
            %   InfoLab, 2006.
            C_r = X(1+round(rand*(n-1)),:);
            idx_r = ones(n,1);
            for i = 2:k
                D_r = X-C_r(idx_r,:);
                D_r = cumsum(sqrt(dot(D_r,D_r,2)));
                if D_r(end) == 0
                    idx = idx_r;
                    C = C_r; C(i:k,:) = X(ones(k-i+1,1),:);
                    sumd = NaN; D = NaN;
                    return;
                end
                C_r(i,:) = X(find(rand < D_r/D_r(end),1),:);
                [~,idx_r] = max(bsxfun(@minus,2*real(X*C_r'),dot(C_r,C_r,2).'),[],2);
            end
        else
            if ischar(Cinit)
                % generate initial centroids based on Cinit string
                C_r = km_init(X,k,Cinit);
                if r==2 && strcmpi(Cinit,'kdtree')
                    warning('KMEANS_INIT:kdtree_replications','The kdtree initialisation algorithm will give the same result for every replication.');
                end
            else
                % use given centroids for initial round
                C_r = Cinit(:,:,r);
            end
            [~,idx_r] = max(bsxfun(@minus,2*real(X*C_r'),dot(C_r,C_r,2).'),[],2);
        end
        
        % The k-means algorithm
        idx1 = 0;
        while any(idx_r ~= idx1)
            idx1 = idx_r;
            for i = 1:k, l = idx_r==i; C_r(i,:) = sum(X(l,:))/sum(l); end
            [~,idx_r] = max(bsxfun(@minus,2*real(X*C_r'),dot(C_r,C_r,2).'),[],2);
        end
        
    end % while length(unique(idx_r)) ~= k
    
    % flag if correct number of clusters has been found
    flg_k = flg_k && length(unique(idx_r)) == k;
    
    % calculate squared euclidean distance to centroids
    if nr_rep > 1 || nargout > 2
        D_r = euclid(X,C_r(idx_r,:),2).^2;
        sumd_r = nan(k,1);
        for i = 1:k, sumd_r(i) = sum(D_r(idx_r==i,:)); end
    end
    
    % sort output
    if nr_rep==1 || sum(D_r) < sumD
        if r < nr_rep, sumD = sum(D_r); end
        idx = idx_r;
        if nargout > 1, C = C_r; end
        if nargout > 2, sumd = sumd_r; end
        if nargout > 3, D = D_r; end
    end
        
end % for r = 1:nr_rep

% give warning if the requested number of clusters could not be reached.
if ~flg_k
    if isnumeric(Cinit)
        warning('KMEANS:PLUSPLUS:replications_fixed','One or more solutions have less than the requested number of clusters, but they could not be improved because the number of replications is fixed by Cinit.');
    end
    if ischar(Cinit) && strcmpi(Cinit,'kdtree')
        warning('KMEANS:PLUSPLUS:Cinit_fixed','The solution has less than k clusters, but it could not be improved because the kdtree Cinit algorithm will always give the same result.');
    end
end


%% Copyright notice for line 126 and affiliates
% Copyright (c) 2009, Michael Chen All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.