function stats = sm_compare2template(template,data,nperms,method)
% Compare a template spider to the spider of a group of subjects
%--------------------------------------------------------------------------
% Use
%   stats = sm_compare2template(template,data,nperms,method)
%
% Input
%   template    number_of_arms*1 spider
%   data        number_of_arms*number_of_subjects matrix of spiders
%   nperms      number of permutations to perform
%   method      'manhattan' or 'cosine_similarity'
%
% Ouput
%   stats.
%       actual      statistic of the actual data
%       criterion   minimum value from which data is not significant
%       nperms      number of permutations used
%       p           p-value
%       permutedD   statistics resulting from all permutations
%       result      string indicating whether match with template was significant
%
% Dependency
%   sm_findpermutations.m
%   manhattan.m
%   cosine_similarity.m
%
% version history
% 2015-09-16	Lennart		documentation
% 2015-09-06  Rogier    Cleaned up for GitHub release
% 2015-01-04  Rogier    Added cosine similarity method
% 2014-12-30  Rogier    Minor tweak to include actual in the permutedD
% 2014-12-28  Rogier    work with sm_findpermutations 2014-12-28 revision
% 2014-12-28  Rogier    Revamped to correct errors
% 2014-12-18  Rogier    created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2014-12-18
%--------------------------------------------------------------------------


%===============================
%% Housekeeping
%===============================

stats.nperms = nperms;

if size(template,1)~=size(data,1), error('Error in sm_compare2template: Template and data are of different length!'); end


%===============================
%% Determine permutations
%===============================

fprintf('Determining permutations...\n');

perms = sm_findpermutations(size(data,2),size(data,1),stats.nperms);


%===============================
%% Calculate actual statistic
%===============================

fprintf('Calculating actual statistic...\n');

switch method
    case 'manhattan'
        stats.actual = manhattan(normalize0(template),normalize0(mean(data,2)));
    case 'cosine_similarity'
        stats.actual = cosine_similarity(normalize0(template),normalize0(mean(data,2)));
end


%===============================
%% Perform permutations
%===============================

fprintf('Performing permutations...\n');

permutedD = stats.actual;
for p = 1:stats.nperms

    % Permute
    curr_data = []; curr_perms = perms(p,:);
    for b = 1:size(data,2)
        curr_data = [curr_data sortmatrixrows(data(:,b),curr_perms(1,1:size(data,1))')];
        curr_perms(:,1:size(data,1)) = [];
    end

    % Statistic
    switch method
        case 'manhattan'
            permutedD = [permutedD manhattan(normalize0(template),normalize0(mean(curr_data,2)))];
        case 'cosine_similarity'
            permutedD = [permutedD cosine_similarity(normalize0(template),normalize0(mean(curr_data,2)))];
    end

end


%===============================
%% Determine criterion and report
%===============================

fprintf('Determining criterion...\n');

permutedD = sort(permutedD);
stats.permutedD = permutedD;
loc = find(sort(permutedD)==stats.actual);

%-------------------------------
% p value
%-------------------------------

switch method
    case 'manhattan'
    	stats.p = length(find(sort(permutedD)<=stats.actual)) /length(permutedD);
    case 'cosine_similarity'
        stats.p = 1- (length(find(sort(permutedD)<=stats.actual)) /length(permutedD));
end

%-------------------------------
% criterion
%-------------------------------

switch method
    case 'manhattan'
        stats.criterion = permutedD(floor(0.05*length(permutedD)));
    case 'cosine_similarity'
        stats.criterion = permutedD(ceil(0.95*length(permutedD)));
end

%-------------------------------
% plot
%-------------------------------

myhist = hist(permutedD,25); figure; hist(permutedD,25); hold on;
cl = line([stats.criterion stats.criterion],[0 max(myhist)+1]); set(cl,'color','b');
dl = line([stats.actual stats.actual],[0 max(myhist)+1]); set(dl,'color','r');
legend('Perm data','Criterion','Actual data'); hold off;

%-------------------------------
% Determine significance
%-------------------------------

switch method
    case 'manhattan'
        if stats.actual<stats.criterion
            stats.result = 'Significant match!';
        elseif stats.actual>=stats.criterion
            stats.result = 'Not a significant match!';
        end
    case 'cosine_similarity'
        if stats.actual>stats.criterion
            stats.result = 'Significant match!';
        elseif stats.actual<=stats.criterion
            stats.result = 'Not a significant match!';
        end
end

fprintf('%s\n',stats.result);

fprintf('Done!\n');


%===============================
%% sub functions
%===============================

function output = sortmatrixrows(data,order)

output = [data order];
output = sortrows(output,size(output,2));
output = output(:,1:size(output,2)-1);
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
