function bkg_name = perSessionTM(vid_name)
% perSessionTM parses the video file name and returns the path to the
% corresponding background according to the LocoMouseTM format. Assumes
% background is a PNG file.
%
% Example:
%
% bkg_name =
% readLocoMouseTMBackgroundPerSession('C:\videos\G6AE1_99_28_1_control_S2T10.avi');
% will return 'C:\videos\G6AE1_99_28_1_control_S2T.png'.

[file_path,file_name,~] = fileparts(char(vid_name));
file_name = strsplit(file_name,'_');
if isempty(file_name)
    bkg_name = '';
else
    bkg_name = fullfile(file_path,[file_name{1} '_bg.png']);
end