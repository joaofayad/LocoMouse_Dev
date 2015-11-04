function [box, cc, I_crop] = computeMouseBox_TM_DD_V1(im,mirror_line)

% COMPUTEMOUSEBOX in its different version computes the bounding box around 
% the mouse on a background subtracted image.
% Different setups may demand adjustments.
%
% This script is adapted to be used with a head-free treadmill setup.
%
% IMPUT:
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
% TREADMILL SPECIFICS:
%   [1] In this script the object detection is exclusively done on the lateral
%       view, because the view through the treadmill makes it very difficult.
%   [2] Due to additional noise around the edges, the side view is padded
%       in a black frame
%   [3] The bounding box width is hardcoded.
%   [4] The final box only uses the bottom right corner of the detected
%       object.
%
% WHEN EDITING THIS FUNCTION:
%   0. Check different existing functions to find the one that gives you the
%      best result and modify that function.
%   1. Save changes into a copy replacing 'DE' with your initials and
%      change the function name appropriately.
%   2. Ensure the OUTPUT remains in the format described above.
%   3. Comment your changes to allow the next person to understand what you
%      did.
% ----------------------------------------------------------
% formerly known as computeMouseBoxNewTest by Dana Darmohray
% outcomes should be identical to computeMouseBox_TM_DE_V1
% ----------------------------------------------------------

bottom_thresh=.01;
side_thresh=.01;
H = fspecial('disk',5);


side_view=[0 0 size(im,2) mirror_line];
bottom_view=[0 mirror_line size(im,2) size(im,1)-mirror_line];
box1 = NaN(2,4);
%% side view
clear rprops_side
I_crop{1}=imcrop(im,side_view);
imside=imadjust(I_crop{1});
imside(:,1:46)=0; % remove left edges x
imside(:,761:size(I_crop{1},2))=0; % remove right edges x
imside(1:100,:)=0; % remove top edges y
imside(150:size(I_crop{1},1),:)=0; % remove bottom edges y

binary_side=((im2bw(imside,side_thresh)));
filtered_side=bwareaopen(binary_side,500);
filtered_side = imfilter(filtered_side,H,'replicate');
BW5 = imfill(filtered_side,'holes');

rprops_side=regionprops(BW5,'Area','BoundingBox');
objs=vertcat(rprops_side.BoundingBox);


 if ~isempty(objs)


%% bottom view
I_crop{2}=imcrop(im,bottom_view);

box=[max(objs(:,1)+objs(:,3)),size(I_crop{2},1)-1,165;...
    400,size(I_crop{2},1),150];

 else
  box=   NaN(2,3);
 end

%[BRC_x BRC_yb BRC_yt;width height_b height_t]

%    336   115   117
%    335   114  101
%    Bottom:
%subplot(2,1,1)

% rectangle('Position', 
% cla
% % imshow(Iaux); hold on;
% 
% % subplot(2,1,1)
% %  imshow(areafilter_bottom); hold on; 
% %  title(num2str(box1(1,1)))
% 
% plot([box(1,1) box(1,1)],[box(1,2)+mirror_line box(1,2)+mirror_line-box(2,2)],'*-'); hold on;% -> Right Vertical line
% plot([box(1,1)-box(2,1) box(1,1)-box(2,1)],[box(1,2)+mirror_line box(1,2)+mirror_line-box(2,2)],'*-') %-> Left Vertical line
% plot([box(1,1) box(1,1)-box(2,1)],[box(1,2)+mirror_line box(1,2)+mirror_line],'*-') %-> Bottom Horizontal line
% plot([box(1,1) box(1,1)-box(2,1)],[box(1,2)+mirror_line-box(2,2) box(1,2)+mirror_line-box(2,2)],'*-')% -> Top Horizontal line

%Top:
% 
% cla
%  imshow(BW5); hold on; 
% plot([box(1,1) box(1,1)],[box(1,3)-box(2,3) box(1,3)],'r*-')
% plot([box(1,1)-box(2,1) box(1,1)-box(2,1)],[box(1,3)-box(2,3) box(1,3)],'r*-')
% plot([box(1,1) box(1,1)-box(2,1)],[box(1,3) box(1,3)],'r*-')
% plot([box(1,1) box(1,1)-box(2,1)],[box(1,3)-box(2,3) box(1,3)-box(2,3)],'r*-')
% % %    
end

