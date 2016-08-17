function bkg_name = perSession(vid_name)
% perSession parses the video file name and returns the path to the
% corresponding background according to the LocoMouse system format.
% Assumes background is a PNG file.
%
% Example:
%
% bkg_name =
% readLocoMouseBackgroundPerSession('C:\videos\G6AE1_99_28_1_control_S2T10.avi');
% will return 'C:\videos\G6AE1_99_28_1_control_S2T.png'.

[file_path,file_name,~] = fileparts(char(vid_name));
file_name = regexp([file_name '.'],'(.*)_S(.*)T(.*)\.','tokens');
if isempty(file_name)
    bkg_name = '';
else
    bkg_name = fullfile(file_path,[file_name{1}{1} '_S' file_name{1}{2} 'T.png']);
end