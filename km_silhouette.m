function km_silhouette(idxx,CC,varargin)
% function km_silhouette(idxx,CC,varargin)
%
% Evaluate range of kmeans solutions using Matlab's silhouette
%
% Obligatory inputs:
%   idxx        voxels*number_of_solutions cluster index matrix
%   CC          matrix submitted to kmeans
%
% Optional inputs (using parameter format):
%   savefig     string with figure basenames
%   savesilh    string with basename to save silhouette values to *.mat
%               file
%
% Rogier B. Mars, University of Oxford, 25022014
% 24112014 RBM Added varargin options to save fig and silh values

%==================================================
% Housekeeping
%==================================================

savefig = [];
savesilh = [];

% Optional inputs
if nargin>2
    for vargnr = 2:2:length(varargin)
        switch varargin{vargnr-1}
            case 'savefig'
                savefig = varargin{vargnr};
            case 'savesilh'
                savesilh = varargin{vargnr};
        end
    end
end

%==================================================
% Do the work
%==================================================

nsolutions = size(idxx,2);

h = figure; hold on; plotnr = 1;

for cc = 1:size(idxx,2)
    
    fprintf('Silhouette: %i clusters...\n',max(idxx(:,cc)));
    subplot(ceil(nsolutions/3),3,plotnr);
    [silh,h] = silhouette(CC,idxx(:,cc),'sqeuclid');
    set(get(gca,'Children'),'FaceColor',[.8 .8 1])
    xlabel('Silhouette Value');
    ylabel('Cluster');
    title([num2str(max(idxx(:,cc))) ' cluster solution']);
    plotnr = plotnr + 1;
    
    allsilh{cc} = silh;
    % save allsilh allsilh
    
end

if ~isempty(savefig)
    saveas(h,strcat(savefig, '_silhouette_plots.jpg'));
end
if ~isempty(savesilh)
    save(strcat(savesilh, '_silhouette_values.mat'),'allsilh');
end

hold off;

%==================================================
% Report group measures
%==================================================

for cc = 1:size(idxx,2)
    meansilh(cc) = mean(allsilh{cc});
end
h = figure; plot([max(idxx(:,1)):max(idxx(:,size(idxx,2)))],meansilh);
if ~isempty(savefig)
    saveas(h,strcat(savefig, '_mean_silhouette_value_plot.jpg'));
end