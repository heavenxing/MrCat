function perms = sm_findpermutations(nsubjects,narms,nperms)
% function perms = sm_findpermutations(nsubjects,narms,nperms)
%
% Create permutations for sm_compare2template.m
%
% Obligatory inputs:
%   nsubjects   number of exchangeability blocks
%   narms       number of elements/units per block
%   nperms      number of permutations to returns
%
% Output:
%   perms       permutations matrix, each as a rows vector of format
%               [subj1_arm_order subj2_arm_order subj3_arm_order...]
%
% This is a simplified version of sm_findpermutations2 for GitHub release.
% Currently only supports quick, random permutation search
%
% Rogier B. Mars, University of Oxford, 06092015

%======================================================
% Housekeeping
%======================================================

fprintf('Exhaustive test would need %i permutations...\n',factorial(narms)^nsubjects);

%======================================================
% Do the work
%======================================================

perms = [];
for p = 1:nperms
    curr_perm = [];
    for s = 1:nsubjects
        curr_perm = [curr_perm randomize_vector([1:narms])];
    end
    perms = [perms; curr_perm]; clear curr_perm;
end

%===============================================
% Subfunctions
%===============================================

function output = randomize_vector(input)

if size(input,1)>size(input,2)
    orientation = 'vertical';
elseif size(input,2)>size(input,1)
    orientation = 'horizontal';
end

switch orientation
    case 'vertical'
        input = [input randperm(size(input,1))'];
        input = sortrows(input,2);
        output = input(:,1);
    case 'horizontal'
        input = [input' randperm(size(input,2))'];
        input = sortrows(input,2);
        input = input(:,1);
        output = input';
end