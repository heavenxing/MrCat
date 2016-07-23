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

if(nargin<2)
    wb_command='/Applications/workbench/bin_macosx64/wb_command';
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