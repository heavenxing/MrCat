function stats = sm_comparegroups(data1,data2,nperms,method,varargin)
% Compare two groups of spiders
%--------------------------------------------------------------------------
%
% Use
%   stats = sm_comparegroups(data1,data2,nperms,method,varargin)
%
% Input
%   data1       number_of_arms*number_of_subjects_group1 matrix of spiders
%   data2       number_of_arms*number_of_subjects_group2 matrix of spiders
%   nperms      number of permutations to perform
%   method      'manhattan' or 'cosine_similarity'
%
% Optional (parameter-value pairs)
%   normalize   normalization method 'normalize0', 'none',
%               'normalize0_all' (normalize over the whole of the two
%               groups, default)
%   plottitle   empty or string containing plot title
%
% Ouput
%   stats.
%       actual      statistic of the actual data
%       criterion   maximum value from which data is not significant
%       nperms      number of permutations used
%       p           p-value
%       permutedD   statistics resulting from all permutations
%       result      string indicating whether match with template was significant
%
% Dependency
%   manhattan.m
%   cosine_similarity.m
%
% version history
% 2016-05-10  Rogier    Results handling improved to use perm_results.m
% 2015-09-16	Lennart		documentation
% 2015-09-06  Rogier    Cleaned up for GitHub release
% 2015-08-12  Rogier    Added plottitle option
% 2015-04-28  Rogier    Added normalize0_all option and made default
% 2015-04-24  Rogier    Added varargin and normalize option
% 2015-01-04  Rogier    Added cosine similarity method
% 2014-12-30  Rogier    created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2014-12-30
%--------------------------------------------------------------------------


%===============================
%% Housekeeping
%===============================

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


%===============================
%% Determine permutations
%===============================

fprintf('Determining permutations...\n');

perms = [];
for p = 1:nperms
    perms = [perms; randomize_vector([ones(1,size(data1,2)) ones(1,size(data2,2))*2])];
end


%===============================
%% Determine actual statistic
%===============================

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


%===============================
%% Perform permutations
%===============================

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


%===============================
%% Determine criterion and report (this section needs tidying up)
%===============================

fprintf('Evaluating results...\n');

permutedD = [stats.actual; permutedD];
[pvalue,results] = perm_results(permutedD,'toplot','yes');

fprintf('Done!\n');


%===============================
%% sub functions
%===============================

function output = randomize_rows(matrix)

matrix = [matrix randperm(size(matrix,1))'];
matrix = sortrows(matrix,size(matrix,2));
output = matrix(:,1:size(matrix,2)-1);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
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
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function output = normalize0(input)
% As normalize1.m, but returning vector normalized between 0 and 1 instead
% of between -1 and 1.
%--------------------------------------------------------------------------
% version history
% 2015-09-16	Lennart		documentation
% 2013-03-28  Rogier    Adapted to suit both 2D and 3D matrices
% 2013-01-31  Rogier    created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2013-01-31
%--------------------------------------------------------------------------

orig_size = size(input);

input = input(:);
output = ((input-min(input))./(max(input)-min(input)));

% Reshape back to input format
if length(orig_size)==2
    output = reshape(output,orig_size(1),orig_size(2));
elseif length(orig_size)==3
    output = reshape(output,orig_size(1),orig_size(2),orig_size(3));
else
    error('Input matrices of this size are currenlty not supported!');
end
