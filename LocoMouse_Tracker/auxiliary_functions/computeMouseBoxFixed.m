function [box, cc, I_crop] = computeMouseBoxFixed(im,mirror_line,~)

cc = [];
side_view_box=[0 0 size(im,2) mirror_line];
side_view=[0 0 size(im,2) mirror_line];
bottom_view=[0 mirror_line size(im,2) size(im,1)-mirror_line];
box = NaN(2,4);
%% side view
I_crop{1}=imcrop(im,side_view);
%% bottom view
I_crop{2}=imcrop(im,bottom_view);

% FIRST PARAMETERS SET
% BRC_x =345; % bottom right corner in x   %% why is this bigger than image width when using image processing?
% BRC_yb=103; % bottom view cropped image y
% BRC_yt= 174; % side view cropped image y
% width_im=330; % total width of image
% height_b=size(I_crop{2},1); % height of bottom view
% height_t=size(I_crop{1},1); % height of side view
% % 
% [size(I_crop{2},1) size(I_crop{1},1)]

% SECOND PARAMETERS SET
% BRC_x = 615; % bottom right corner in x   %% why is this bigger than image width when using image processing?
% BRC_yb = 171; % bottom view cropped image y
% BRC_yt = 172; % side view cropped image y
% width_im = 540; % total width of image
% height_b = 173; % height of bottom view
% height_t = 171; % height of side view


% THIRD PARAMETER SET
BRC_x = 591; % bottom right corner in x   %% why is this bigger than image width when using image processing?
BRC_yb = 166; % bottom view cropped image y
BRC_yt = 71; % side view cropped image y
width_im = 517; % total width of image
height_b = 169; % height of bottom view
height_t = 71; % height of side view



box=[BRC_x BRC_yb BRC_yt;width_im height_b height_t];


% im=imread('E:\testing2\tracking test\e4_bg.png'); % load image
%  figure;
% imshow(im); hold on;
% plot([BRC_x BRC_x],[BRC_yb+mirror_line BRC_yb + mirror_line-height_b],'*-') %-> Right Vertical line
% plot([BRC_x-width_im BRC_x-width_im],[BRC_yb+mirror_line BRC_yb+mirror_line-height_b],'*-')% -> Left Vertical line
% plot([BRC_x  BRC_x-width_im],[BRC_yb+mirror_line BRC_yb+mirror_line],'*-')% -> Bottom Horizontal line
% plot([BRC_x  BRC_x-width_im],[BRC_yb+mirror_line-height_b BRC_yb+mirror_line-height_b],'*-') %-> Top Horizontal line
% hold on;
% %
% 
% 
% plot([BRC_x  BRC_x ],[BRC_yt-height_t BRC_yt],'*-')
% plot([BRC_x-width_im BRC_x-width_im],[BRC_yt-height_t BRC_yt],'*-')
% plot([BRC_x  BRC_x-width_im],[BRC_yt BRC_yt],'*-')
% plot([BRC_x  BRC_x-width_im],[BRC_yt-height_t BRC_yt-height_t],'*-')


