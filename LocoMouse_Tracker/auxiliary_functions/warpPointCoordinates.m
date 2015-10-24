function Xout = warpPointCoordinates(Xin, ind_warp_mapping, im_size)
% warpPointCoordinates Give a set of image coordinates, warps them to
% another image according to ind_warp_mapping.
% 
% INPUT:
%
% Xin: Nx2 vector with the 2D image coordinates of the points on the
% original image.
% ind_warp_mapping: A map between two images.
% im_size_warped: 1x2 size of in image.
%
% OUTPUT:
% Xout: Nx2 vector with the 2D image coordinates of the points on the out
% image.
if isempty(ind_warp_mapping)
    Xout = Xin;
    return;
end
valid = (all(Xin>0 & bsxfun(@le,Xin,im_size),2)) & all(~isnan(Xin),2);
ind = sub2ind(im_size ,Xin(valid,1), Xin(valid,2));
warp_ind = ind_warp_mapping(ind);
Xout = NaN(size(Xin));
[Xout(valid,1),Xout(valid,2)] = ind2sub(im_size, warp_ind);
