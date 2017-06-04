function [Tail,Tail_Mask,tail_length] = tailDetection_BasedOnSide(Ii, Mi, mirror_line, w, rho, N, tail_length)
% TAILDETECTION detects the tail based on thresholding.
%
% INPUT:
% I: I can be a grayscale image or a 1x2 cell. If I is a cell, it must have
% the bottom image on I{1} and the top image on I{2};
% Mi: Boolean mask of valid pixels for detection.
% mirror_line: Height at which to split the image in half if I is a
% grayscale image.
% box_size: A 1x2 cell with the box size for the tail on each view (1 -
% bottom, 2 - top).
% w: a 1x2 cell with the filter for the tail on each view (1 - bottom, 2 -
% top).
% rho: a 1x2 cell with the bias value for the tail filte on each view (1 -
% bottom, 2 - top).
%
% OUTPUT:
% Tail:
% T_mask: A mask to remove the tail pixels (and respective boxes) from the
% image.

switch class(Ii)
    case 'uint8'
        I_cell = cell(1,2);
        [I_cell{2:-1:1}] = splitImage(Ii,mirror_line);
    case 'cell'
        I_cell = Ii;
    otherwise
        error('Supported classes for I are uint8 or cell.');
end
clear I

IT = (conv2(I_cell{2},w{2},'same')-rho{2}) > 0;
IB = (conv2(I_cell{1},w{1},'same')-rho{1}) > 0;

% Treatig the side view as the dominant view
IT = imdilate(IT,strel('square',5));

% Split IT into segments
% Without knowledge of how long the tail is splitting into consistent
% segments is not possible. Will assume a segment to be x percent of the
% bounding box

CC = bwconncomp(IT);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx] = max(numPixels);

Tail_Mask{2} = false(size(IT));
Tail_Mask{2}(CC.PixelIdxList{idx}) = true;

% segment_length = 0.1 * size(I_cell{2},2);
has_point = any(Tail_Mask{2},1);
N = 15;

st = find(has_point,1,'first');
en = find(has_point,1,'last');

tail_length = en - st + 1;
i_views = 2;

steps = en - (0:N).*round((tail_length)/N);
steps = steps(steps>0);
steps = steps(end:-1:1);
Ntail = length(steps)-1;
tail_side = NaN(2,N);

for i_tail = 1:Ntail
    x = sum(Tail_Mask{i_views}(:,steps(i_tail):steps(i_tail+1)),1);
    y = sum(Tail_Mask{i_views}(:,steps(i_tail):steps(i_tail+1)),2);
    c = [x*(1:length(x))'/sum(x(:));(1:length(y))*y/sum(y(:))];
    tail_side(:,i_tail) = [steps(i_tail);0] + round(c);
end

tail_side(1,:) = min(max(1,tail_side(1,:)),size(IT,2));
tail_side(2,:) = min(max(1,tail_side(2,:)),size(IT,1));

% Bottom view:
Tail = NaN(3,N);

CC = bwconncomp(IB);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx] = max(numPixels);
Tail_Mask{1} = false(size(IB));
Tail_Mask{1}(CC.PixelIdxList{idx}) = true;

has_point_bottom_view = any(Tail_Mask{1},1);
for i_points = 1:size(tail_side,2)
   
    try
    if ~isnan(tail_side(1,i_points)) && has_point_bottom_view(tail_side(1,i_points)) 
                
        y_bottom_s = find(IB(:,tail_side(1,i_points)),1,'first');
        
        if isempty(y_bottom_s)
            continue;
        end
        
        y_bottom_e = find(Tail_Mask{1}(:,tail_side(1,i_points)),1,'last');
        
        Tail(2,i_points) = (y_bottom_s + y_bottom_e)/2;
        
    end
    catch
        'wtf'
    end
    
end

Tail(2,~isnan(Tail(2,:))) = min(max(1,Tail(2,~isnan(Tail(2,:)))),size(IB,1)) + mirror_line;

Tail_Mask{1} = false(size(I_cell{1}));

Tail_Mask{2} = ~Tail_Mask{2};

Tail([1 3],:) = tail_side;

