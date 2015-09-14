function [HI,varargout] = km_hierarchyindex(idx,nperm)
% function [HI,varargout] = km_hierarchyindex(idx,nperm)
%
% Computers hierarchy index for clustering solutions as described (poorly)
% in Kahnt et al. (2012) J Neurosci
%
% Input
%   idx     Vectors with indices of cluster solutions
% Optional
%   nperm   Number of random permutations to compare the HI to (pass 0 to
%           ignore)
%
% Output
%   HI                  Vector of HI for each solution
%   Subsequent output   Vector of random permutation solutions
%
% version history
% 2014-12-01    Lennart speeded up code
% 2014-05-02    Rogier  created
%
% Rogier B. Mars, University of Oxford, 05022014


%% housekeeping
%-------------------------------
narginchk(1,2);
if nargin<2 || isempty(nperm), nperm = 0; end

%=========================================================
% Calculate HI
%=========================================================

% variables:
%   i   cluster index at the current level
%   j   custer index at the previous level

HI = nan(1,size(idx,2)-1);
ncluster = max(idx,[],1);
for i = 2:size(idx,2)
    j = i-1;
    
    % create x (matrix whose elements reflect nr of voxels in cluster i
    % coming from cluster j)
    x = nan(ncluster(i),ncluster(j));
    for xi = 1:ncluster(i)
        for xj = 1:ncluster(j)
            x(xi,xj) = sum((idx(:,i)==xi).*(idx(:,j)==xj));
        end
    end
    
    % Check that x is the right size
    if ~(size(x,1)==max(idx(:,i))) || ~(size(x,2)==max(idx(:,j))), error('Error: x of wrong size in km_hierarchyindex.m!'); end
    
    % Calculate HI(k)
    HI(j) = sum(max(x,[],2)./sum(x,2)) / ncluster(i);
    
end

%=========================================================
% Random permutations (if requested)
%=========================================================

HIrandperm = nan(nperm,length(HI));
for permutnr = 1:nperm
    
    for k = 1:size(idx,2)
        idx(:,k) = randomize_vector(idx(:,k));
    end
    
    for i = 2:size(idx,2)
        j = i-1;
        
        % create x (matrix whose elements reflect nr of voxels in cluster i
        % coming from cluster j)
        x = nan(ncluster(i),ncluster(j));
        for xi = 1:ncluster(i)
            for xj = 1:ncluster(j)
                x(xi,xj) = sum((idx(:,i)==xi).*(idx(:,j)==xj));
            end
        end
        
        % Check that x is the right size
        if ~(size(x,1)==max(idx(:,i))) || ~(size(x,2)==max(idx(:,j))), error('Error: x of wrong size in km_hierarchyindex.m!'); end
        
        % Calculate HI(k)
        HIrandperm(permutnr,j) = sum(max(x,[],2)./sum(x,2)) / ncluster(i);
        
    end
    
end

varargout{1} = mean(HIrandperm,1);

%=========================================================
% Plot results
%=========================================================

figure; hold on; title('Hiearchy index');
plot(1:length(HI),HI,'o');
if nperm>0, plot(1:length(HI),varargout{1},'*'); legend('HI','Random permuation');
else legend('HI');
end
hold off;