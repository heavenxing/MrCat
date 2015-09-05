function stats = sm_compare2template(template,data,nperms,method)
% function stats = sm_compare2template(template,data,nperms,method)
%
% Compare a template spider to the spider of a group of subjects
%
% Inputs:
%   template    number_of_arms*1 spider
%   data        number_of_arms*number_of_subjects matrix of spiders
%   nperms      number of permutations to perform
%   method      'manhattan' or 'cosine_similarity'
%
% Ouput:
%   stats.
%       actual      statistic of the actual data
%       criterion   minimum value from which data is not significant
%       nperms      number of permutations used
%       p           p-value
%       permutedD   statistics resulting from all permutations
%       result      string indicating whether match with template was significant
%
% Calls: sm_findpermutations2.m, normalize0.m, manhattan.m
%
% Rogier B. Mars, University of Oxford, 18122014
% RBM 28122014 Revamped to correct errors and work with
%              sm_findpermutations2 28122014 revision
% RBM 30122014 Minor tweak to include actual in the permutedD
% RBM 04012015 Added cosine similarity method

%===============================================
% Housekeeping
%===============================================

stats.nperms = nperms;

if size(template,1)~=size(data,1), error('Error in sm_compare2template: Template and data are of different length!'); end

%===============================================
% Determine permutations
%===============================================

fprintf('Determining permutations...\n');

perms = sm_findpermutations2(size(data,2),size(data,1),stats.nperms);
% save perms perms; beep; break;

%===============================================
% Calculate actual statistic
%===============================================

fprintf('Calculating actual statistic...\n');

switch method
    case 'manhattan'
        stats.actual = manhattan(normalize0(template),normalize0(mean(data,2)));
    case 'cosine_similarity'
        stats.actual = cosine_similarity(normalize0(template),normalize0(mean(data,2)));
end


%===============================================
% Perform permutations
%===============================================

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

%===============================================
% Determine criterion and report (this section needs some tidying up)
%===============================================

fprintf('Determining criterion...\n');

permutedD = sort(permutedD);

% histogram
myhist = hist(permutedD,25); figure; hist(permutedD,25); hold on;

loc = find(sort(permutedD)==stats.actual);

% p value
switch method
    case 'manhattan'
    	stats.p = length(find(sort(permutedD)<=stats.actual)) /length(permutedD);
    case 'cosine_similarity'
        stats.p = 1- (length(find(sort(permutedD)<=stats.actual)) /length(permutedD));
end

%--------------------------------------
% criterion
%--------------------------------------

switch method
    case 'manhattan'
        stats.criterion = permutedD(floor(0.05*length(permutedD)));
    case 'cosine_similarity'
        stats.criterion = permutedD(ceil(0.95*length(permutedD)));
end
cl = line([stats.criterion stats.criterion],[0 max(myhist)+1]); set(cl,'color','b');

% actual data
dl = line([stats.actual stats.actual],[0 max(myhist)+1]); set(dl,'color','r');

legend('Perm data','Criterion','Actual data'); hold off;

stats.permutedD = permutedD;

%--------------------------------------
% Determine significance
%--------------------------------------

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

%===============================================
% Subfunctions
%===============================================

function output = sortmatrixrows(data,order)

output = [data order];
output = sortrows(output,size(output,2));
output = output(:,1:size(output,2)-1);