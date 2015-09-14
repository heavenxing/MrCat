function C = km_init(X,k,method)
% function C = km_init(X,k,method)
%
% set initial starting points for k-means clustering
%
% RBM 01092015 Prepared for github
% Created by Lennart Verhagen, University of Oxford

% sort input
if nargin < 3 || isempty(method), method = 'plusplus'; end

% switch between centroid initialisation algorithms
switch lower(method)
    
    case 'random'
        p = randperm(size(X,1));
        C = X(p(1:5),:);
        
    case {'plus','plusplus'}
        % The k-means++ algorithm
        % D. Arthur and S. Vassilvitskii, "k-means++: The Advantages of
        % Careful Seeding", Technical Report 2006-13, Stanford InfoLab,
        % 2006.
        n = size(X,1);
        C = X(1+round(rand*(n-1)),:);
        idx = ones(n,1);
        for i = 2:k
            D = X-C(idx,:);
            D = cumsum(sqrt(dot(D,D,2)));
            if D(end) == 0
                C(i:k,:) = X(ones(k-i+1,1),:);
            else
                C(i,:) = X(find(rand < D/D(end),1),:);
                if i<k
                    [~,idx] = max(bsxfun(@minus,2*real(X*C'),dot(C,C,2).'),[],2);
                end
            end
        end
        
    case {'furthest','rogier','kkz'}
        % run km_init_furthest to place initial centres as far out as possible
        C = km_init_furthest(X,k);
        
    case 'kdtree'
        % run kmeans_init_kdtree to place initial centroids on the kd-tree
        % Redmond; Heneghan - 2007 - PattRecogLett - A method for
        % initialising the k-means clustering algorithm using kd-trees
        C = kmeans_init_kdtree(X,k);
        
    otherwise
        error('Error in MrCat:KMEANS_INIT:unsupported_method','This method (%s) is not currently supported.',method);
        
end % switch lower(method)