function Xout = warpPointCoordinates(Xin, ind_warp_mapping, im_size, flip)
% warpPointCoordinates Give a set of image coordinates, warps them to
% another image according to ind_warp_mapping.
% 
% INPUT:
%
% Xin: [N 2] vector with the 2D image coordinates of the points on the
% original image. [y x]
% 
% ind_warp_mapping: [Nj Mj] Lookup table for mapping a [Ni Mi] image into a
% [Nj Mj] image.
%
% im_size: [Ni Mi] size of the input image.
%
% flip_in: Boolean signaling if the coordinates are vertically flipped in
% regards to the mapping. If so, Xin must be flipped before applying the
% map.
%
% flip_out: Boolean signaling if the coordinates are to be vertically
% flipped after the mapping.
%
% OUTPUT: 
% 
% Xout: [N 2] vector with the 2D image coordinates of the points on
% the out image.

if isempty(ind_warp_mapping)
    Xout = Xin;
    return;
end

if flip
    % Reverting the flip before applying the mapping:
    Xin(:,2) = size(ind_warp_mapping,2) - Xin(:,2) + 1;
end

valid = (all(Xin>0 & bsxfun(@le,Xin,im_size),2)) & all(~isnan(Xin),2);
ind = sub2ind(im_size ,Xin(valid,1), Xin(valid,2));
try
    warp_ind = ind_warp_mapping(round(ind));
catch tError
    disp(getReport(tError,'extended'));
end
Xout = NaN(size(Xin));
[Xout(valid,1),Xout(valid,2)] = ind2sub(im_size, warp_ind);

if flip
    % Reapplying the flip:
    Xout(:,2) = im_size(2) - Xout(:,2) + 1;
end
