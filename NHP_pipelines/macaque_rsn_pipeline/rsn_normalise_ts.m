function rsn_normalise_ts(fname)
% function rsn_normalise_ts(inputfile)
%
% Normalise the time course of 4D .nii.gz or 2D .dtseries.nii file for
% macaque_rsn_pipeline. The input file will replaced with the normalised
% file
%--------------------------------------------------------------------------
%
% Use:
%   rsn_normalise_ts('myfile.dtseries.nii');
%
% Obligatory input:
%   filename    string containing filename (with extension)
%
% Uses: read_avw.m, save_avw.m, ciftiopen.m, ciftisave.m, readimgfile.m,
% see their separate docs.
% Compatible with MrCat versions
%
% version history
% 2016-06-15	Rogier  created
%
% copyright
% Rogier B. Mars
% University of Oxford & Donders Institute, 2016-06-15
%--------------------------------------------------------------------------

% Determine data type
fprintf('Determining file type...\n');
[~,datatype] = readimgfile(fname);

switch datatype
    
    case 'NIFTI_GZ'
        fprintf('Normalising NIFTI time series along 4th dimension...\n');
    
        [data, dims,scales,bpp,endian] = read_avw(fname);
        data = normalise(data,4);
        save_avw(data,fname,'f',scales');
        
    case 'DTSERIES'
        fprintf('Normalising dtseries along 2nd dimension...\n');
        
        cifti = ciftiopen(fname);
        cifti.cdata = normalise(cifti.cdata,2);
        ciftisave(cifti,fname,size(cifti.cdata,1),'wb_command');
        
    otherwise
        error('Error in rsn_normalise_ts: Input data type not supported!');
        
end
