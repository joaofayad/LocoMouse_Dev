function [output_file_path_data,output_file_path_images] = locoMouseOutputPathDataImages(output_path,vid_path)
% locoMouseOutputPathDataImages parses the video file name and returns
% the path to the corresponding background according to the LocoMouse
% system format. Assumes background is a PNG file.
%
% Example:
% 
% [output_file_path_data, output_file_path_images] = locoMouseOutputPathDataImages('C:\output','C:\Session_2\G6AE1_99_28_1_control_S2T10.avi');
% data_path will be 'C:\output\G6AE1\Session_2\data\'
% image_path will be 'C:\output\G6AE1\Session_2\image\'
%
% INPUT:
% output_path: The global output path for all the dataset analysis.
% video_path: A string with the absolute path to the video.
%
% OUTPUT:
% output_file_path_data: Path for the mat file resulting from tracking the
% video given in video_path.
%
% output_file_path_images: Path for the image files resulting from tracking
% the video given in video_path.

% Extracting the animal and session name:
[vid_path,vid_name,~] = fileparts(char(vid_path));
parsed_path = strsplit(vid_path,filesep);
parsed_name = regexp(vid_name,'(.*)_(.*)','tokens');
output_file_path_data = fullfile(output_path,parsed_path{end},parsed_name{1}{1},'data');
output_file_path_images = fullfile(output_path,parsed_path{end},parsed_name{1}{1},'images');