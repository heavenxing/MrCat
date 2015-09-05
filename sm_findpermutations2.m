function perms = sm_findpermutations2(nsubjects,narms,nperms,varargin)
% function perms = sm_findpermutations2(nsubjects,narms,nperms,varargin)
%
% Find permutations without repetition
%
% Obligatory inputs:
%   nsubjects   number of exchangeability blocks
%   narms       number of elements/units per block
%   nperms      number of permutations to returns
%
% Optional inputs (using parameter format):
%   method      'standard' (default, ensures no repetitions, but very slow)
%               or 'random' (does not check for repetitions, but faster)
%
% Output:
%   perms       permutations matrix, each as a rows vector of format
%               [subj1_arm_order subj2_arm_order subj3_arm_order...]
%
% Rogier B. Mars, University of Oxford, 18122014
% RBM 24122014 Added check for doubles and changed output to single row format
% RBM 28122014 Changed variables names to narms and nsubjects
% RBM 09042015 Now includes John D'Errico's uniqueperm.m as a subfunction
% RBM 17042014 Added faster random method

%======================================================
% Housekeeping
%======================================================

fprintf('Exhaustive test would need %i permutations...\n',factorial(narms)^nsubjects);

% Defaults
method = 'standard';

% Optional inputs
if nargin>3
    for vargnr = 2:2:length(varargin)
        switch varargin{vargnr-1}
            case 'method'
                method = varargin{vargnr};
        end
    end
end

%======================================================
% Do the work
%======================================================

switch method
    
    case 'random'
        
        perms = [];
        for p = 1:nperms
            curr_perm = [];
            for s = 1:nsubjects
                curr_perm = [curr_perm randomize_vector([1:narms])];
            end
            perms = [perms; curr_perm]; clear curr_perm;
        end
        
    case 'standard'
        
        %======================================================
        % Permute over units
        %======================================================
        
        unit_perms = uniqueperms([1:narms]);
        
        %======================================================
        % Permute over blocks
        %======================================================
        
        %--------------------------------------
        % First permutation
        %--------------------------------------
        
        perms = [];
        curr_perms = [];
        
        for b = 1:nsubjects
            unit_perms = randomize_rows(unit_perms);
            curr_perms = [curr_perms unit_perms(1,:)];
        end
        
        perms = [perms; curr_perms];
        
        %--------------------------------------
        % All other permutations
        %--------------------------------------
        
        for p = 2:nperms
            
            % fprintf('.');
            
            double_flag = 1;
            while double_flag==1
                
                curr_perms = [];
                
                for b = 1:nsubjects
                    unit_perms = randomize_rows(unit_perms);
                    curr_perms = [curr_perms unit_perms(1,:)];
                end
                if sum(ismember(perms,curr_perms,'rows'))==0
                    double_flag = 0;
                elseif sum(ismember(perms,curr_perms,'rows'))>0
                    % fprintf('Double found!');
                end
                
            end
            
            perms = [perms; curr_perms];
            
        end
        
end

%===============================================
% Subfunctions
%===============================================

function output = randomize_rows(matrix)

matrix = [matrix randperm(size(matrix,1))'];
matrix = sortrows(matrix,size(matrix,2));
output = matrix(:,1:size(matrix,2)-1);

function pu = uniqueperms(vec)
% list of all unique permutations of a vector with (possibly) replicate elements
% usage: pu = uniqueperms(vec)
%
% arguments: (input)
% vec - 1xn or nx1 vector of elements, replicates allowed
%
% arguments: (output)
% pu - mxn array of permutations of vec. Each row is a permutation.
%
% The result should be the same as unique(perms(vec),'rows')
% (although the order may be different.)
%
% Example:
% pu = uniqueperms([1 1 1 2 2])
% pu =
% 1 1 1 2 2
% 1 1 2 2 1
% 1 1 2 1 2
% 1 2 1 2 1
% 1 2 1 1 2
% 1 2 2 1 1
% 2 1 1 2 1
% 2 1 1 1 2
% 2 1 2 1 1
% 2 2 1 1 1
%
% See also: unique, perms
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release: 1.0
% Release date: 2/25/08

% How many elements in vec?
vec = vec(:); % make it always a column vector
n = length(vec);

% how many unique elements in vec?
uvec = unique(vec);
nu = length(uvec);

% any special cases?
if isempty(vec)
    pu = [];
elseif nu == 1
    % there was only one unique element, possibly replicated.
    pu = vec';
elseif n == nu
    % all the elements are unique. Just call perms
    pu = perms(vec);
else
    % 2 or more elements, at least one rep
    pu = cell(nu,1);
    for i = 1:nu
        v = vec;
        ind = find(v==uvec(i),1,'first');
        v(ind) = [];
        temp = uniqueperms(v);
        pu{i} = [repmat(uvec(i),size(temp,1),1),temp];
    end
    pu = cell2mat(pu);
end

function output = randomize_vector(input)
%
% function output = randomize_vector(input)
%
% This is a recreation of the famous randomize_vector.m, it randomises the
% order of items in a vector
%
% Rogier B. Mars, University of Oxford, 09112012

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