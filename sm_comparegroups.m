function stats = sm_comparegroups(data1,data2,nperms,method,varargin)
% function stats = sm_comparegroups(data1,data2,nperms,method,varargin)
%
% Compare two groups of spiders
%
% Inputs:
%   data1       number_of_arms*number_of_subjects_group1 matrix of spiders
%   data2       number_of_arms*number_of_subjects_group2 matrix of spiders
%   nperms      number of permutations to perform
%   method      'manhattan' or 'cosine_similarity'
%
% Optional inputs (using parameter format):
%   normalize   normalization method 'normalize0', 'none',
%               'normalize0_all' (normalize over the whole of the two
%               groups, default)
%   plottitle   empty or string containing plot title
%
% Ouput:
%   stats.
%       actual      statistic of the actual data
%       criterion   maximum value from which data is not significant
%       nperms      number of permutations used
%       p           p-value
%       permutedD   statistics resulting from all permutations
%       result      string indicating whether match with template was significant
%
% Calls: uniqueperms.m, normalize0.m, manhattan.m
%
% Rogier B. Mars, University of Oxford, 30122014
% 04012015 RBM Added cosine similarity method
% 24042015 RBM Added varargin and normalize option
% 28042015 RBM Added normalize0_all option and made that the default
% 12082015 RBM Added plottitle option

%===============================================
% Housekeeping
%===============================================

stats.nperms = nperms;

if size(data1,1)~=size(data2,1), error('Error in MrCat:sm_comparegroups: Spiders are of different length!'); end

% Defaults
normalize = 'normalize0';
plottitle = [];

% Optional inputs
if nargin>4
    for vargnr = 2:2:length(varargin)
        switch varargin{vargnr-1}
            case 'normalize'
                normalize = varargin{vargnr};
            case 'plottitle'
                plottitle = varargin{vargnr};
        end
    end
end

% Log stuff
stats.log.normalize = normalize;

%===============================================
% Determine permutations
%===============================================

fprintf('Determining permutations...\n');

perms = [];
for p = 1:nperms
    perms = [perms; randomize_vector([ones(1,size(data1,2)) ones(1,size(data2,2))*2])];
end

% perms = randomise_rows(uniqueperms([ones(1,size(data1,2)) ones(1,size(data2,2))*2]));
% fprintf('Exhaustive test would need %i permutations...\n',size(perms,1));
% perms = perms(1:stats.nperms,:);

%===============================================
% Determine actual statistic
%===============================================

fprintf('Calculating actual statistic...\n');

switch method
    case 'manhattan'
        switch normalize
            case 'normalize0'
                stats.actual = manhattan(normalize0(mean(data1,2)),normalize0(mean(data2,2)));
            case 'none'
                stats.actual = manhattan(mean(data1,2),mean(data2,2));
            case 'normalize0_all'
                spider_data = [mean(data1,2); mean(data2,2)];
                spider_data = normalize0(spider_data);
                stats.actual = manhattan(spider_data(1:size(data1,1)),spider_data(size(data1,1)+1:size(data1,1)+size(data2,1)));
        end
    case 'cosine_similarity'
        switch normalize
            case 'normalize0'
                stats.actual = cosine_similarity(normalize0(mean(data1,2)),normalize0(mean(data2,2)));
            case 'none'
                stats.actual = cosine_similarity(mean(data1,2),mean(data2,2));
            case 'normalize0_all'
                spider_data = [mean(data1,2); mean(data2,2)];
                spider_data = normalize0(spider_data);
                stats.actual = cosine_similarity(spider_data(1:size(data1,1)),spider_data(size(data1,1)+1:size(data1,1)+size(data2,1)));
        end
end

%===============================================
% Perform permutations
%===============================================

fprintf('Performing permutations...\n');

data = [data1 data2];

permutedD = stats.actual;
for p = 1:stats.nperms
    
    % Permute
    curr_data1 = data(:,find(perms(p,:)==1));
    curr_data2 = data(:,find(perms(p,:)==2));
    
    % Statistic
    switch method
        case 'manhattan'
            switch normalize
                case 'normalize0'
                    permutedD = [permutedD manhattan(normalize0(mean(curr_data1,2)),normalize0(mean(curr_data2,2)))];
                case 'none'
                    permutedD = [permutedD manhattan(mean(curr_data1,2),mean(curr_data2,2))];
                case 'normalize0_all'
                    spider_data = [mean(curr_data1,2); mean(curr_data2,2)];
                    spider_data = normalize0(spider_data);
                    permutedD = [permutedD manhattan(spider_data(1:size(data1,1)),spider_data(size(data1,1)+1:size(data1,1)+size(data2,1)))];
            end
        case 'cosine_similarity'
            switch normalize
                case 'normalize0'
                    permutedD = [permutedD cosine_similarity(normalize0(mean(curr_data1,2)),normalize0(mean(curr_data2,2)))];
                case 'none'
                    permutedD = [permutedD cosine_similarity(mean(curr_data1,2),mean(curr_data2,2))];
                case 'normalize0_all'
                    spider_data = [mean(curr_data1,2); mean(curr_data2,2)];
                    spider_data = normalize0(spider_data);
                    permutedD = [permutedD cosine_similarity(spider_data(1:size(data1,1)),spider_data(size(data1,1)+1:size(data1,1)+size(data2,1)))];
            end
    end
    
end

%===============================================
% Determine criterion and report (this section needs tidying up)
%===============================================

fprintf('Determining criterion...\n');

permutedD = sort(permutedD);

% histogram
myhist = hist(permutedD,25); figure; hist(permutedD,25); hold on;

loc = find(sort(permutedD)==stats.actual);

%--------------------------------------
% p value
%--------------------------------------

switch method
    case 'manhattan'
        stats.p = 1- (length(find(sort(permutedD)<=stats.actual)) /length(permutedD));
    case 'cosine_similarity'
        stats.p = (length(find(sort(permutedD)<=stats.actual)) /length(permutedD));
end

%--------------------------------------
% criterion
%--------------------------------------

switch method
    case 'manhattan'
        stats.criterion = permutedD(ceil(0.95*length(permutedD)));
    case 'cosine_similarity'
        stats.criterion = permutedD(ceil(0.05*length(permutedD)));
end
cl = line([stats.criterion stats.criterion],[0 max(myhist)+1]); set(cl,'color','b');

% actual data
dl = line([stats.actual stats.actual],[0 max(myhist)+1]); set(dl,'color','r');

legend('Perm data','Criterion','Actual data');
title(plottitle);
hold off;

stats.permutedD = permutedD;

%--------------------------------------
% Determine significance
%--------------------------------------

switch method
    case 'manhattan'
        if stats.actual>stats.criterion
            stats.result = 'Significant difference!';
        elseif stats.actual<=stats.criterion
            stats.result = 'Not a significant difference!';
        end
    case 'cosine_similarity'
        if stats.actual<stats.criterion
            stats.result = 'Significant difference!';
        elseif stats.actual>=stats.criterion
            stats.result = 'Not a significant difference!';
        end
end

fprintf('%s\n',stats.result);

fprintf('Done!\n');

%===============================================
% Subfunctions
%===============================================

function output = randomize_rows(matrix)

matrix = [matrix randperm(size(matrix,1))'];
matrix = sortrows(matrix,size(matrix,2));
output = matrix(:,1:size(matrix,2)-1);

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