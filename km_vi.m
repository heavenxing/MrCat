function VI = km_vi(idx)
% function VI = km_vi(idx)
%
% Calculate variation of information metric (Meila, 2007 following Kahnt et al.,2012, J
% Neurosci) between cluster solutions
%
% Input:
%   idx     number_of_voxels*number_of_solutions
%
% Output:
%   VI      variation of information metric vector
%
% Calls: columnentropy.m, mutualinformation.m
%
% Rogier B. Mars, University of Oxford, 18022014
% 12082015 RBM Allow comparison of more than two solution in one go
% 01092015 RBM Housekeeping

%=========================================================
% Housekeeping
%=========================================================

if (size(idx,2)==1), error('Error in MrCat:km_vi: Input idx has wrong number of columns in km_vi.m!'); end

%=========================================================
% Do the work
%=========================================================

VI = [];

for c = 2:size(idx,2)
    VI(c-1) = columnentropy(idx(:,c-1)) + columnentropy(idx(:,c)) - 2*mutualinformation([idx(:,c-1) idx(:,c)]);
end

% Note: if there are k clusters, with K<=sqrt(n), then VI<=2log(k)