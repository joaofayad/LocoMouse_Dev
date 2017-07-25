function [output_file_path_data,output_file_path_images] = sameOutputFolder(output_path,vid_path)
% sameOutputFolder sets the output path on "output_path" regardless of
% where the input video is located.
%
% Example:
% 
% [output_file_path_data, output_file_path_images] = sameOutputFolder('C:\output','C:\Session_2\G6AE1_99_28_1_control_S2T10.avi');
% data_path will be 'C:\output\data\'
% image_path will be 'C:\output\image\'
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
output_file_path_data = fullfile(output_path,'data');
output_file_path_images = fullfile(output_path,'images');