function [box, cc, I_crop] = computeMouseBox_HF(im,split_line,ParameterSet)

% COMPUTEMOUSEBOX in its different version computes the bounding box around 
% the mouse on a background subtracted image.
% Different setups may demand adjustments.
%
% This is a collection of hardcoded parameters, usually used for videos with 
% head-fixed animals.
% 
% INPUT:
% I: background subtracted grayscale image.
% split_line: pixel hight dividing the two views.
%
% OUTPUT: 
% - bounding box: a 2x3 matrix for 
%              [br_x    br_yb      br_yt; ...
%               width   height_b   height_t];
                %   with
                %   br_x    = x of bottom right corner
                %   br_yb   = y of bottom half of the image (bottom view)
                %   br_yt   = y of top half of the image (lateral view)
                %   width   = width
                %   height_b= height in bottom half of the image
                %   height_t= height in top half of the image
%               Cordinates refer to the image halves *after cutting*. 
%               In whole image br_yt needs to be added to the split line.
%
% - cc:     2x2 matrix where the i-th column is the 2x1 image coordinates 
%           of the centroid of the bounding in view i (i == 1 is bottom). 
% - I_crop: 2x1 cell with the bottom and top view cropped images.
%
% WHEN EDITING THIS FUNCTION:
%   0. Check different existing functions to find the one that gives you the
%      best result and modify that function.
%   1. Copy and paste a set of variables and edit and comment the unused lines.
%   2. Ensure the OUTPUT remains in the format described above.
%   3. Comment your changes to allow the next person to understand what you
%      did.
%
%   FIXME: the parameter set should become selectable from the GUI
%
% ------------------------------------------
% original by Hugo Marques 2015
% ------------------------------------------

cc = [];
side_view_box=[0 0 size(im,2) split_line];
side_view=[0 0 size(im,2) split_line];
bottom_view=[0 split_line size(im,2) size(im,1)-split_line];
box = NaN(2,4);
%% side view
I_crop{1}=imcrop(im,side_view);
%% bottom view
I_crop{2}=imcrop(im,bottom_view);

if isnumeric(ParameterSet)
    ParameterSet = num2str(ParameterSet);
end

switch ParameterSet
    % FIRST PARAMETERS SET
    case '1'
        BRC_x =345; % bottom right corner in x   %% why is this bigger than image width when using image processing?
        BRC_yb=103; % bottom view cropped image y
        BRC_yt= 174; % side view cropped image y
        width_im=330; % total width of image
        height_b=size(I_crop{2},1); % height of bottom view
        height_t=size(I_crop{1},1); % height of side view
         
	% SECOND PARAMETERS SET
    case '2'
        BRC_x = 615; % bottom right corner in x   %% why is this bigger than image width when using image processing?
        BRC_yb = 171; % bottom view cropped image y
        BRC_yt = 172; % side view cropped image y
        width_im = 540; % total width of image
        height_b = 173; % height of bottom view
        height_t = 171; % height of side view

    % THIRD PARAMETER SET
    case '3'
        BRC_x = 591; % bottom right corner in x   %% why is this bigger than image width when using image processing?
        BRC_yb = 166; % bottom view cropped image y
        BRC_yt = 71; % side view cropped image y
        width_im = 517; % total width of image
        height_b = 169; % height of bottom view
        height_t = 71; % height of side view
end


box=[BRC_x BRC_yb BRC_yt;width_im height_b height_t];


    % im=imread('E:\testing2\tracking test\e4_bg.png'); % load image
    %  figure;
    % imshow(im); hold on;
    % plot([BRC_x BRC_x],[BRC_yb+split_line BRC_yb + split_line-height_b],'*-') %-> Right Vertical line
    % plot([BRC_x-width_im BRC_x-width_im],[BRC_yb+split_line BRC_yb+split_line-height_b],'*-')% -> Left Vertical line
    % plot([BRC_x  BRC_x-width_im],[BRC_yb+split_line BRC_yb+split_line],'*-')% -> Bottom Horizontal line
    % plot([BRC_x  BRC_x-width_im],[BRC_yb+split_line-height_b BRC_yb+split_line-height_b],'*-') %-> Top Horizontal line
    % hold on;
    % %
    % 
    % 
    % plot([BRC_x  BRC_x ],[BRC_yt-height_t BRC_yt],'*-')
    % plot([BRC_x-width_im BRC_x-width_im],[BRC_yt-height_t BRC_yt],'*-')
    % plot([BRC_x  BRC_x-width_im],[BRC_yt BRC_yt],'*-')
    % plot([BRC_x  BRC_x-width_im],[BRC_yt-height_t BRC_yt-height_t],'*-')

end
