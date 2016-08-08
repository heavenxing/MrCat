function x=normalise(x,dim)
% Remove the mean value and make the std=1
%--------------------------------------------------------------------------
%
% Use:
%   normalise(X,DIM)

% version history
% 2016-03-08    Rogier created, based on Saad Jbabdi's original
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2015-03-08
%-------------------------------------------------------------------------- 

dims = size(x);
dimsize = size(x,dim);
dimrep = ones(1,length(dims));
dimrep(dim) = dimsize;

x = x - repmat(mean(x,dim),dimrep);
x = x./repmat(std(x,0,dim),dimrep);
x(isnan(x)) = 0;
x = x./sqrt(dimsize-1);