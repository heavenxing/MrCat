function [hf, ha, hp, hl] = spiderwedge(data,varargin)
%--------------------------------------------------------------------------
% Create a spider plot of data (an M axes by N set matrix). Supports wedge,
% patch, and line spider plots. So contrary to what its name suggests, it
% does more than just wedges.
%
% Input
%   data        matrix of size M (axes) by N (set).
%
% Optional parameter-value pair input
%   PlotType    'wedge', 'patch', 'line', 'contour' ['wedge']
%   Alpha       value (0 to 1) to set the FaceAlpha of patches [0.3]
%   Color       either an RGB matrix, color char, or color index
%   WedgeWidth  value (0 to 1) to set the relative width of wedges [0.8]
%   ConnContour boolean (true false) connect wedge contours or not [true]
%   PlotAxes    boolean (true false) plot the axes lines or not [true]
%   SortSets    boolean (true false) sort wedge sets by magnitude [false]
%   Title       title of the plot
%   Range       peak range of the data (Mx1 or Mx2)
%   NaNZero     boolean (true false) replace NaNs in data by zeros [true]
%   Scale       'none', 'set', 'axis' ['none']
%   NrTickMarks number (>0) of tick marks on the axes [4]
%   Label       cell vector with axes names (Mxq) in [name unit] pairs
%   Legend      cell vector with dataset legend identification (1xN)
%   Handle      figure or plot handle
%
%   Any remaining Parameter-Value pairs are passed along to the plotting
%   funcion creating the wedge, patch, or line.
%
% Optional output
%   hf          figure handle
%   ha          axes handle
%   hp          plot handle
%   hl          legend handle
%
% version history
% 2015-08-12    Lennart added contour plotting option
% 2015-03-11    Lennart added NaNZero option
% 2015-02-16    Lennart added documentation and examples
% 2015-02-16    Lennart added SortSets
% 2015-02-01    Lennart general clean-up
% 2015-02-01    Lennart changed input to parameter-value pairs
% 2015-02-01    Lennart added 'patch' and 'wedge' plot types
% 2014-12-23    Michael adapted
% 2008-01-30    Michael	created
%
% copyright:
% Lennart Verhagen & Rogier B. Mars
% University of Oxford, 2015-02-01
%
% Michael Arant
% Michelin Maericas Research and Development Corp, 2008-01-30
%
%
%% examples of how to use the function spider_wedge
%
% minimal use with 9 axes in 1 set
% dat = [2 4 5 3 1 3 6 4 5]';
% spider_wedge(dat);
%
% clean: no title, no labels, no axes, no lines
% spider_wedge(dat,'Title','','Label',{},'PlotAxes',false,'LineStyle','none');
%
% clean, with error bars
% err = rand(length(dat),1);
% spider_wedge(dat,err,'Title','','Label',{},'PlotAxes',false,'LineStyle','none');
%
% plot spider wedges with spider lines
% [hf, ha] = spider_wedge(dat,err,'Title','','Label',{},'PlotAxes',false,'LineStyle','none');
% hold(ha,'on');
% spider_wedge(dat(randperm(length(dat))),err(randperm(length(dat))),'Handle',ha,'PlotType','line','Title','','Label',{},'PlotAxes',false,'Color','r');
%
% % minimal use with 3 axes and 4 sets
% dat = [1 2 3 4; 2 3 4 5; 1 3 5 7];
% spider_wedge(dat);
%
% % plot data as a patch or as a line
% spider_wedge(dat,'PlotType','patch');
% spider_wedge(dat,'PlotType','line');
%
% % plot data as a wedge contour, of different widths, and connected or not
% spider_wedge(dat,'PlotType','contour');
% spider_wedge(dat,'PlotType','contour','WedgeWidth',1);
% spider_wedge(dat,'PlotType','contour','ConnContour',true);
% spider_wedge(dat,'PlotType','contour','WedgeWidth',0.5,'ConnContour',true);
%
% % minimal use with 4 axes and 3 sets
% spider_wedge(dat');
%
% % scale to the range over sets for each axis individually
% spider_wedge(dat,'Scale','axis');
%
% % scale to the range of each set
% spider_wedge(dat,'Scale','set');
%
% % not transparant
% spider_wedge(dat,'Alpha',1);
%
% % sort sets based on magnitude
% spider_wedge(dat,'Alpha',1,'SortSets',true);
%
% % give plot title, axis labels, and set labels (legend)
% spider_wedge(dat(:,3:4),'Title','This is the title','Label',{'right','left-up','left-down'},'Legend',{'first','second'});
%
% % do not plot axes, lines, title, nor labels
% spider_wedge(dat(:,3),'PlotAxes',false,'LineStyle','none','Title','','Label',{},'SortSets',true,'Alpha',0.5);
%
% % plot skinny wedges with dashed lines in a fixed range with three tickmarks
% spider_wedge(dat(:,3),'WedgeWidth',0.3,'Range',[2 5],'NrTickMarks',3,'LineStyle','--','Title','','Label',{},'SortSets',true,'Alpha',0.5);
%
% % plot sets in subplots, with fixed range, and set the color by index
% figure;
% spider_wedge(dat(:,1),'Handle',subplot(2,2,1),'Range',[0 7],'Color',1,'PlotAxes',false,'LineStyle','none','Label',{},'Title','first');
% spider_wedge(dat(:,2),'Handle',subplot(2,2,2),'Range',[0 7],'Color',2,'PlotAxes',false,'LineStyle','none','Label',{},'Title','second');
% spider_wedge(dat(:,3),'Handle',subplot(2,2,3),'Range',[0 7],'Color',3,'PlotAxes',false,'LineStyle','none','Label',{},'Title','third');
% spider_wedge(dat(:,4),'Handle',subplot(2,2,4),'Range',[0 7],'Color',4,'PlotAxes',false,'LineStyle','none','Label',{},'Title','fourth');
%
%
%% credits & copyright
%
% based on the file 'spider.m' by Michael Arant, 2008-01-30
% Copyright (c) 2014, Michael Arant
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%--------------------------------------------------------------------------


%% housekeeping
%-------------------------------
% parse input arguments based on input, default and expected values
p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'data',@isnumeric);
addOptional(p,'err',[],@isnumeric);
addParameter(p,'PlotType','wedge',@(x) any(validatestring(x,{'wedge','patch','line','contour'})));
addParameter(p,'Title','Look out! He is a Spider-pig.',@ischar);
addParameter(p,'Alpha',0.3,@(x) isnumeric(x) && x>=0 && x<=1);
addParameter(p,'Color',[],@(x) ischar(x) || isnumeric(x));
addParameter(p,'WedgeWidth',0.8,@(x) isnumeric(x) && x>=0 && x<=1);
addParameter(p,'ConnContour',false,@(x) islogical(x) || x==0 || x==1);
addParameter(p,'PlotAxes',true,@(x) islogical(x) || x==0 || x==1);
addParameter(p,'SortSets',false,@(x) islogical(x) || x==0 || x==1);
addParameter(p,'Range',[],@isnumeric);
addParameter(p,'NaNZero',true,@(x) islogical(x) || x==0 || x==1);
addParameter(p,'Scale','none',@(x) isnumeric(x) || any(validatestring(x,{'none','no','set','axis'})));
addParameter(p,'NrTickMarks',4,@(x) isnumeric(x) && x>=0);
addParameter(p,'Handle',[],@ishandle);
addParameter(p,'Label',[],@(x) iscell(x) || isempty(x));
addParameter(p,'Legend',[],@iscell);
parse(p,data,varargin{:});

% retrieve input arguments from inputParser object
data        = p.Results.data;
err         = p.Results.err;
PlotType    = p.Results.PlotType;
FaceAlpha   = p.Results.Alpha;
Color       = p.Results.Color;
WedgeWidth  = p.Results.WedgeWidth;
ConnContour = p.Results.ConnContour;
PlotAxes    = p.Results.PlotAxes;
SortSets    = p.Results.SortSets;
TitleStr    = p.Results.Title;
MinMax      = p.Results.Range;
NaNZero     = p.Results.NaNZero;
Scale       = p.Results.Scale;
NrTickMarks = p.Results.NrTickMarks;
LabelCell   = p.Results.Label;
LegendCell  = p.Results.Legend;
hf          = p.Results.Handle;
ParamVal    = p.Unmatched;

% number of axes and sets in the data matrix
[nr_ax,nr_set] = size(data);
% too few axes?
if nr_ax < 3
	warning('MRCAT:SPIDER:TooFewAxes','Are you sure about your data size? These plots usually start to make sense with more than two axes.')
end

% replace NaNs by zeros?
if NaNZero
    data(isnan(data)) = 0;
end

% check for maximum range
if isempty(MinMax) || ~isreal(MinMax)
	% no range given or range is in improper format
	% define new range
	MinMax = [min([min(data,[],2) zeros(nr_ax,1)],[],2) max(data,[],2)];
	% check for negative minimum values
	if ~isempty(ismember(-1,sign(data)))
		% negative value found - adjust minimum range
		for s = 1:nr_ax
			% negative range for axis ii - set new minimum
			if min(data(s,:)) < 0
				MinMax(s,1) = min(data(s,:)) - 0.25 * (max(data(s,:)) - min(data(s,:)));
			end
		end
	end
elseif size(MinMax,1) ~= nr_ax
	if size(MinMax,1) == 1
		% assume that all axes have commom scale
		MinMax = ones(nr_ax,1) * MinMax;
	else
		% insuffent range definition
		error('Range size must be Mx1 - number of axes x 1: %g axis ranges defined, %g axes exist',size(MinMax,1),nr_ax)
	end
elseif size(MinMax,2) == 1
	% assume range is a maximum range - define minimum
	MinMax = sort([min([zeros(nr_ax,1) min(data,[],2) - 0.25 * (max(data,[],2) - min(data,[],2))],[],2) MinMax],2);
end

% implement range type
switch Scale
    case {'no','none','set'}
        MinMax(:,1) = min(MinMax(:,1),[],1);
        MinMax(:,2) = max(MinMax(:,2),[],1);
end

% check axis labels
if isempty(LabelCell)
    if ~iscell(LabelCell)
        % define default labels
        if nr_ax < 27
            LabelCell = cellstr(char(64+(1:nr_ax))');
        else
            LabelCell = cellstr(sprintf('%g',1:nr_ax)');
        end
    end
elseif size(LabelCell,1) ~= nr_ax
	if size(LabelCell,2) == nr_ax
		LabelCell = LabelCell';
	else
		error('Axis labels must be Mx1 - number of axes x 1: %g axis labels defined, %g axes exist',size(LabelCell,1),nr_ax)
	end
elseif ischar(LabelCell)
	% check for charater labels
	LabelCell = cellstr(LabelCell);
end

% check legend labels
if nr_set > 1
    if isempty(LegendCell)
        % no data legend
        if iscell(LegendCell)
            % define default legend
            LegendCell = cell(1,nr_set); for s = 1:nr_set; LegendCell(s) = cellstr(sprintf('Set %g',s)); end
        else
            LegendCell = [];
        end
    elseif numel(LegendCell) ~= nr_set
        error('Data set label must be 1XN - 1 x number of sets: %g data sets labeled, %g exist',numel(LegendCell),nr_set)
    end
end

% check for figure or axes
if isempty(hf) || isequal(hf,0)
	% no figure or axes requested - generate new ones
	hf = figure; ha = gca(hf); cla(ha); hold on; set(hf,'color','w')
elseif ismember(hf,get(0,'children')')
	% existing figure - clear and set up
	ha = gca(hf); hold on;
elseif isinteger(hf)
	% generating a new figure
	figure(hf); ha = gca(hf); cla(ha); hold on
else
	% may be an axes - may be garbage
	try
		%is this an axes?
		if ismember(get(hf,'parent'),get(0,'children')')
			% existing figure axes - use
			ha = hf; hf = get(hf,'parent'); hold on
		end
	catch
		% make new figure and axes
		fprintf('Invalid axes handle %g passed.  Generating new figure\n',hf)
		hf = figure; ha = gca(hf); cla(ha); hold on
	end
end

% set the axes to the current text axes
axes(ha);
% set to add plot
set(ha,'nextplot','add');

% clear figure and set limits
set(ha,'visible','off'); set(hf,'color','w');
set(ha,'xlim',[-1.25 1.25],'ylim',[-1.25 1.25]); axis(ha,'equal','manual');
% title
if ~isempty(TitleStr)
    text(0,1.3,TitleStr,'horizontalalignment','center','fontsize',24,'fontweight','bold');
end

% define data set colors
if isempty(Color) || ischar(Color) && ismember(Color,{'default','auto'})
    col = get(ha,'colororder');
    idx_col = rem(1:nr_set,size(col,1)); idx_col(idx_col==0) = size(col,1);
    col = col(idx_col,:);
elseif isnumeric(Color) && size(Color,2) ~= 3
    col = get(ha,'colororder');
    idx_col = rem(Color,size(col,1)); idx_col(idx_col==0) = size(col,1);
    col = col(idx_col,:);
elseif ischar(Color)
    col = Color(:);
else
    col = Color;
end

% scale by range
angw = linspace(0,2*pi,nr_ax+1)';
mag = (data - MinMax(:,1) * ones(1,nr_set)) ./ (diff(MinMax,[],2) * ones(1,nr_set));
% scale trimming
mag(mag < 0) = 0; mag(mag > 1) = 1;

% scale error data if present
if ~isempty(err)
    err = err ./ (diff(MinMax,[],2) * ones(1,nr_set));
end

% scale data per set if requested
switch Scale
    case 'set'
        mag = bsxfun(@rdivide,mag,max(mag,[],1));
end

% wrap data (close the last axis to the first)
ang = angw(1:end-1); magw = [mag; mag(1,:)];


% make the plot
% define the axis locations
start = [zeros(1,nr_ax); cos(ang')]; stop = [zeros(1,nr_ax); sin(ang')];
% plot the axes
if PlotAxes
    plot(ha,start,stop,'color','k','linestyle','-');
else
    NrTickMarks = 0;
end
%axis equal;
% plot axes markers
inc = linspace(1/NrTickMarks,1,NrTickMarks);
mk = .025 * ones(1,NrTickMarks); tx = NrTickMarks * mk;
% loop each axis ang plot the line markers and labels
% add axes
for a = 1:nr_ax
	% plot tick marks
    if NrTickMarks > 0
        htm = plot(ha,[cos(ang(a)) * inc + sin(ang(a)) * mk; ...
            cos(ang(a)) * inc - sin(ang(a)) * mk], ...
            [sin(ang(a)) * inc - cos(ang(a)) * mk ;
            sin(ang(a)) * inc + cos(ang(a)) * mk],'color','k');
    end
	% label the tick marks
	for t = 1:NrTickMarks
% 		htxt = text([cos(ang(a)) * inc(t) + sin(ang(a)) * tx(t)], ...
% 				[sin(ang(a)) * inc(t) - cos(ang(a)) * tx(t)], ...
% 				num2str(chop(rng(a,1) + inc(jj)*diff(rng(a,:)),2)), ...
% 				'fontsize',8);
		htxt = text(cos(ang(a)) * inc(t) + sin(ang(a)) * tx(t), ...
				sin(ang(a)) * inc(t) - cos(ang(a)) * tx(t), ...
				num2str(rd(MinMax(a,1) + inc(t)*diff(MinMax(a,:)),-2)), ...
				'fontsize',8);
		% flip the text alignment for lower axes
		if ang(a) >= pi
			set(htxt,'HorizontalAlignment','right');
		end
	end
    % label each axis
    if ~isempty(LabelCell) && ~isempty(LabelCell{a,1})
        htxt = text(cos(ang(a)) * 1.1 + sin(ang(a)) * 0, ...
            sin(ang(a)) * 1.1 - cos(ang(a)) * 0, ...
            char(LabelCell(a,:)),'fontsize',16);
        % flip the text alignment for right side axes
        if ~PlotAxes
            set(htxt,'HorizontalAlignment','center');
        elseif ang(a) > pi/2 && ang(a) < 3*pi/2
            set(htxt,'HorizontalAlignment','right');
        end
    end
end

% choose between plotting either a polar wedge, patch, or a line
switch PlotType
    case 'line'
        % plot the data
        hp = polar(ha,angw*ones(1,nr_set),magw);
        hp = hp(:)';
        % set color of the lines
        for s = 1:nr_set; set(hp(s),'color',col(s,:),ParamVal); end
    case 'patch'
        % loop over data columns
        for s = 1:nr_set
            [x,y] = pol2cart(ang,mag(:,s));
            hp(s) = patch(x,y,col(s,:),'FaceAlpha',FaceAlpha,ParamVal);
        end
    case 'wedge'
        % sort data based on magnitude
        if SortSets
            [~,idx] = sort(nansum(mag,1),'descend');
            mag = mag(:,idx);
            if ~isempty(LegendCell), LegendCell = LegendCell(idx); end
            if ~isempty(err), err = err(:,idx); end
        end
        % convert polar axes to wedges around the axes
        n = max(ceil(500/nr_ax),5);
        d = diff(angw)*WedgeWidth;
        wedge = cell2mat(arrayfun(@(x,y) linspace(x,y,n),ang-d/2,ang+d/2,'UniformOutput',false));
        % loop over data columns
        for s = 1:nr_set
            % loop over wedges
            for w = 1:nr_ax
                [x,y] = pol2cart(wedge(w,:),mag(w,s));
                hp(w,s) = patch([x 0],[y 0],col(s,:),'FaceAlpha',FaceAlpha,ParamVal);
            end
        end
    case 'contour'
        % convert polar axes to wedges with 100 points around the axes
        n = max(ceil(500/nr_ax),5);
        d = diff(angw)*WedgeWidth;
        pnts = cell2mat(arrayfun(@(x,y) linspace(x,y,n),ang-d/2,ang+d/2,'UniformOutput',false))';
        if ~ConnContour, pnts(end+1,:) = nan; n = 101; end
        pnts = pnts(:);
        if ConnContour, pnts(end+1) = pnts(1); end
        % expand magnitude data
        magrep = repmat(mag,1,1,n);
        magrep = permute(magrep,[3 1 2]);
        magrep = reshape(magrep,[n*nr_ax nr_set]);
        if ConnContour, magrep(end+1,:) = magrep(1,:); end
        
        % plot the data
        hp = polar(ha,pnts*ones(1,nr_set),magrep);
        hp = hp(:)';
        % set color of the lines
        for s = 1:nr_set; set(hp(s),'color',col(s,:),ParamVal); end

end

% plot error bars if requested
if ~isempty(err)
    switch PlotType
        case {'line','patch'}
            % define width of start/stop bars
            b = 0.02;
            % reshape the magnitude and angle matrices
            errmag = nan(9*size(mag,1),size(mag,2));
            errang = errmag;
            % error line
            errmag(1:9:end,:) = mag-err;
            errmag(2:9:end,:) = mag+err;
            errang(1:9:end,:) = repmat(ang,1,nr_set);
            errang(2:9:end,:) = repmat(ang,1,nr_set);
            % start end
            c = sqrt((mag-err).^2 + b.^2);
            a = acos((mag-err)./c);
            errmag(4:9:end,:) = c;
            errmag(5:9:end,:) = c;
            errang(4:9:end,:) = repmat(ang,1,nr_set)-a;
            errang(5:9:end,:) = repmat(ang,1,nr_set)+a;
            % start end
            c = sqrt((mag+err).^2 + b.^2);
            a = acos((mag+err)./c);
            errmag(7:9:end,:) = c;
            errmag(8:9:end,:) = c;
            errang(7:9:end,:) = repmat(ang,1,nr_set)-a;
            errang(8:9:end,:) = repmat(ang,1,nr_set)+a;
            % constrain zero bound
            errmag(errmag<0) = 0;
            % plot the error bar
            he = polar(ha,errang,errmag);
            % set width and color of the bar
            if isfield(ParamVal,'LineWidth')
                lw = ParamVal.LineWidth;
            else
                lw = 2;
            end
            for s = 1:nr_set; set(he(s),'color',col(s,:),'LineWidth',lw); end
        case {'wedge'}
            % reshape the magnitude and angle matrices
            errmag = nan(3*size(mag,1),size(mag,2));
            errang = errmag;
            errmag(1:3:end,:) = mag-err;
            errmag(2:3:end,:) = mag+err;
            errmag(errmag<0) = 0;
            errang(1:3:end,:) = repmat(ang,1,nr_set);
            errang(2:3:end,:) = repmat(ang,1,nr_set);
            % plot the error bar
            he = polar(ha,errang,errmag);
            % set width and color of the bar
            for s = 1:nr_set; set(he(s),'color',col(s,:),'LineWidth',2); end
    end
end

% apply the legend
if ~isempty(LegendCell)
    hl = legend(hp(1,:),LegendCell,'location','best','Interpreter','none');
end
    

return



function [v] = rd(v,dec)
% quick round function (to specified decimal)
% function [v] = rd(v,dec)
%
% inputs  2 - 1 optional
% v       number to round    class real
% dec     decimal loaction   class integer
%
% outputs 1
% v       result             class real
%
% positive dec shifts rounding location to the right (larger number)
% negative dec shifts rounding location to the left (smaller number)
%
% michael arant
% Michelin Maericas Research and Development Corp
if nargin < 1; help rd; error('I/O error'); end

if nargin == 1; dec = 0; end

v = v / 10^dec;
v = round(v);
v = v * 10^dec;