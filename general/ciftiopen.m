function data = ciftiopen(filename,wb_command)
% function data = ciftiopen(filename,wb_command)
%
% Open a CIFTI file by converting to GIFTI external binary first and then
% using the GIFTI toolbox. Based on Saad Jbabdi's original
%--------------------------------------------------------------------------
%
% Use:
%   data = ciftiopen('myfile.dconn.nii');
%   data = ciftiopen('yourfile','/Applications/workbench/bin_macosx64/wb_command');
%
% Uses: gifti toolbox
%
% Obligatory input:
%   filename    string containing name of CIFTI file to read in (incl
%               extension)
%
% Optional input:
%   wb_command  string containing link to wb_command version to be used
%
% version history
%   2016-05-26  Rogier  created based on Saad Jbabdi's original
%
% copyright
%   Rogier B. Mars
%   University of Oxford & Donders Institute, 2016-05-26
%--------------------------------------------------------------------------

%==================================================
% Housekeeping
%==================================================
% Implemented to work on macs, DCC, and Oxford clusters
if(nargin<2)
    if ismac && exist(fullfile('/Applications/workbench/bin_macosx64/'), 'dir')        
        wb_command = '/Applications/workbench/bin_macosx64/wb_command';
    elseif isunix && exist(fullfile('/vol/optdcc/workbench/bin_linux64/'), 'dir')  
        wb_command = '/vol/optdcc/workbench/bin_linux64/wb_command';
    elseif isunix && exist(fullfile('/opt/fmrib/workbench-1.1.1/bin_rh_linux64/'),'dir')
        wb_command = '/opt/fmrib/workbench-1.1.1/bin_rh_linux64/wb_command';
    else
        error 'Cannot find workbenck directory. Please provide path to wb_command.';
    end
end

%==================================================
% Do the work
%==================================================

% Create temporary gifti file
unix([wb_command ' -cifti-convert -to-gifti-ext ' filename ' ' filename '.gii']);

% Read in temporary gifti file
data = gifti([filename '.gii']);

% Remove temporary gifti file
unix([' rm ' filename '.gii ' filename '.gii.data']);
