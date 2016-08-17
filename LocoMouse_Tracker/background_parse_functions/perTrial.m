function bkg_name = perTrial(vid_name)
% perTrial parses the video file name and returns the path to the
% corresponding background according to the LocoMouse system format.
% Assumes background is a PNG file.
%
% Example:
%
% bkg_name =
% readLocoMouseBackgroundPerSession('C:\videos\G6AE1_99_28_1_control_S2T10.avi');
% will return 'C:\videos\G6AE1_99_28_1_control_S2T10.png'.

[file_path,file_name,~] = fileparts(vid_name);
bkg_name = fullfile(file_path,[file_name '.png']);