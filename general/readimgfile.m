function [data, varargout] = readimgfile(filename,varargin)
% function [data, varargout] = readimgfile(filename,varargin)
%
% Read in any file that is vaguely related to neuroimaging, with or without
% specifying extension. If a .nii is found without .dconn or
% .dtseries it will assume that it is dealing with a NIFTI file. If no
% extension is specified it will try to find files in the order: .dot,
% .func.gii, .surf.gii, nii.gz, .dconn.nii, .dtseries.nii, and .nii.
%--------------------------------------------------------------------------
%
% Use:
%   data = readimgfile('myfile.dconn.nii');
%   [data, filetype] = readimgfile('yourfile');
%
% Obligatory input:
%   filename    string containing filename (with or without extension)
%
% Optional input (using parameter format):
%   dealwithnan     'no' (default), 'yes' to replace with zero, or value to
%                   replace nan with
%   dealwithinf     'no' (default), 'yes' to replace with zero and add 1 to
%                   all other values, or value to replace -Inf with
%
% Outputs:
%   data            matrix with data
%   varargout{1}    string containing file type
%
% Uses: read_avw.m, ciftiopen.m, gifti toolbox, see their separate docs.
% Compatible with MrCat versions
%
% version history
% 2016-05-27    Rogier  Added varargout file type
% 2016-04-22    Rogier  Fixed bug dealing with .surf.gii instead of
%                       .func.gii
% 2016-04-20    Rogier  Added options to deal with nan and -inf
% 2016-04-20	Rogier  created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2016-04-20
%--------------------------------------------------------------------------

%==================================================
% Housekeeping
%==================================================

% Defaults
dealwithnan = 'no';
dealwithinf = 'no';

if nargin>1
    for vargnr = 2:2:length(varargin)
        switch varargin{vargnr-1}
            case 'dealwithnan'
                dealwithnan = varargin{vargnr};
            case 'dealwithinf'
                dealwithinf = varargin{vargnr};
        end
    end
end

%==================================================
% Determine file type
%==================================================

[d,f,e] = fileparts(filename);

if ~isempty(e)
    
    if isequal(e,'.dot') % .dot file
        filetype = 'DOT';
    elseif isequal(e,'.gii') % gifti file
        filetype = 'GIFTI';
    elseif isequal(e,'.gz') % .nii.gz file
        filetype = 'NIFTI_GZ';
    elseif isequal(e,'.nii') % nifti or cifti file
        if regexp(f,'dconn') % dconn.nii file
            filetype = 'DCONN';
        elseif regexp(f,'dtseries') % dtseries.nii
            filetype = 'DTSERIES';
        else % assuming nifti
            filetype = 'NIFTI';
        end
    end
    
elseif isempty(e)
    
    if exist([filename '.dot'],'file')
        filetype = 'DOT';
        filename = [filename 'dot'];
    elseif exist([filename '.func.gii'],'file')
        filetype = 'GIFTI';
        filename = [filename 'func.gii'];
    elseif exist([filename '.surf.gii'],'file')
        filetype = 'GIFTI';
        filename = [filename 'surf.gii'];
    elseif exist([filename '.nii.gz'],'file')
        filetype = 'NIFTI_GZ';
        filename = [filename '.nii.gz'];
    elseif exist([filename '.dconn.nii'],'file')
        filetype = 'DCONN';
        filename = [filename '.dconn.nii'];
    elseif exist([filename '.dtseries.nii'],'file')
        filetype = 'DTSERIES';
        filename = [filename '.dtseries.nii'];
    elseif exist([filename '.nii'],'file')
        filetype = 'NIFTI';
        filename = [filename '.nii'];
    else
        error('Error in MrCat:readimgfile: File not found!');
    end
    
end

%==================================================
% Load data
%==================================================

switch filetype
    
    case 'DOT'
        data = load(filename);
        data=full(spconvert(data)); % Reorder the data
    case 'GIFTI'
        data = gifti(filename);
        if isfield(data,'cdata')
            data = data.cdata;
        end
    case 'NIFTI_GZ'
        data = read_avw(filename);
    case 'DCONN'
        data = ciftiopen(filename);
        data = data.cdata;
    case 'DTSERIES'
        data = ciftiopen(filename);
        data = data.cdata;
    case 'NIFTI'
        data = read_avw(filename);
        
end

%==================================================
% Manipulate data if so requested
%==================================================

switch dealwithnan
    case 'no'
        % do nothing
    case 'yes'
        data = replacenan(data,0);
    otherwise
        data = replacenan(data,dealwithnan);
end

switch dealwithinf
    case 'no'
        % do nothing
    case 'yes'
        data = data+1;
        data(find(data(:)==-Inf)) = 0;
    otherwise
        data(find(data(:)==-Inf)) = dealwithinf;
end

%==================================================
% Prepare variable output
%==================================================

varargout{1} = filetype;