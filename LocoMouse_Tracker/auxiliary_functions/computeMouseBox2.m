function [box, cc, I_crop] = computeMouseBox2(im,mirror_line)
bottom_thresh=.07; %% changed threshold (.115)
side_thresh=.005;
H = fspecial('disk',6);
cc = [];
%MAIN LOOP
% for n = 1:nframes
    
% im =(read(mov,n))-bg;
% im = cell2mat(I);
%side_view_box=[0 0 size(im,2) mirror_line-10]; changed dana

side_view_box=[0 0 size(im,2) mirror_line-30];

side_view=[0 0 size(im,2) mirror_line];
bottom_view=[0 mirror_line size(im,2) size(im,1)-mirror_line];
box = NaN(2,4);
%% side view
I_crop{1}=imcrop(im,side_view);
binary_side=bwareaopen((im2bw(imcrop(im,side_view_box),side_thresh)),500);
filtered_side = imfilter(binary_side,H,'replicate');
rprops_side=regionprops(filtered_side,'Area','BoundingBox');
if ~isempty(rprops_side)
    largest_object= cat(1,rprops_side.Area)==max(cat(1,rprops_side.Area));
    box(1,:)=round(rprops_side(largest_object).BoundingBox);
    % box(1,:)=[min(P_side(:,1)) min(P_side(:,2)) max(P_side(:,1))-min(P_side(:,1)) max(P_side(:,2))-min(P_side(:,2))]'; %x y w h
else
    % If object is found, use the size of the image...
    box(1,:) = [1 1 size(I_crop{1})];
end

%% bottom view
I_crop{2}=imcrop(im,bottom_view);
binary_bottom=(im2bw(I_crop{2},bottom_thresh));
filtered_bottom = imfilter(binary_bottom,H,'replicate');
areafilter_bottom= xor(bwareaopen(filtered_bottom,50),  bwareaopen(filtered_bottom,50000)); % changed area threshold 50
rprops_bottom=regionprops(areafilter_bottom,'PixelList');


%% commented imclearborder dana
% if length(rprops_bottom) > 1
%     % If more than 1 object, check for border errors:
%     bw4_bottom = imclearborder(areafilter_bottom);
%     rprops_bottom = regionprops(bw4_bottom,'PixelList');
% end

if ~isempty(rprops_bottom)
    P_bottom=cat(1,rprops_bottom.PixelList);
    box(2,:)=[min(P_bottom(:,1)) min(P_bottom(:,2)) max(P_bottom(:,1))-min(P_bottom(:,1)) max(P_bottom(:,2))-min(P_bottom(:,2))]'; %x y w h
else
    % If no object is found, use the width of the bottom view:
    box(2,:) = [1 1 size(I_crop{2},2) size(I_crop{1},1)];
end

box = [box(1,1)+box(1,3)-1, box(2,2)+box(2,4)-1, box(1,2)+box(1,4)+10-1;...
    box(1,3) box(2,4) box(1,4)];



% box = [max([box(1,1)+box(1,3)-1 box(2,1)+box(2,3)-1]) box(2,2)+box(2,4)-1 box(1,2)+box(1,4)+10-1;max([box(1,3) box(2,3)]) box(2,4) box(1,4)];
%size(im,1)-mirror_line
%% plot

% subplot(2,1,1)
% cla
% imshow(filtered_side); hold on;
% rectangle('Position',box(:,n,1)','edgecolor','g') % min object x, 0, y width max-min,width 
%  subplot(2,1,2)
%  imshow(bw4_bottom); hold on;
%  rectangle('Position',box(:,n,2)','edgecolor','r') % min object x, 0, y width max-min,width 
% title(n)
 %combine bottom and side

 %rectangle('Position',[mean(squeeze(box(1,n,:))) 0 mean(squeeze(box(3,n,:))) size(im,1)-mirror_line],'edgecolor','g') % min object x, 0, y width max-min,width 
% end
%end
