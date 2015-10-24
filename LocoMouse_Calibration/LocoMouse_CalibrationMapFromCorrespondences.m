function [IDX,IDX_inv] = LocoMouse_CalibrationMapFromCorrespondences(Centroids,vis,cos_theta,im_size)
% Computing angles based on view 1 (bottom):
M = [Centroids(1,vis,2);ones(1,size(Centroids(1,vis,2),2))]';
line_coefficients = M\(cos_theta(vis)');
clear M

% Creating generic matrix and distorting it:
% imdistortion according to abc plane fitting:
[X,Y] = meshgrid(1:im_size(2),1:im_size(1));

% Estimating the angle based on the X coordinate:
cos_col = [1:im_size(2);ones(1,im_size(2))]'*line_coefficients;
sin_col = sqrt(1-cos_col.^2);
Xdist = X + bsxfun(@times,(Y-1),(cos_col./sin_col)');

% Computing the forward map to the corrected image:
offset = min(Xdist(:));
Xdist_grid = round(Xdist - offset + 1);
Width_dist = max(Xdist_grid(:));
[Xnew,Ynew] = meshgrid(1:Width_dist,1:im_size(1));
IDX = knnsearch([Xdist_grid(:) Y(:)],[Xnew(:) Ynew(:)]);
IDX = reshape(IDX,im_size(1),Width_dist);
IDX_inv = knnsearch([Xnew(:) Ynew(:)],[Xdist_grid(:) Y(:)]);
IDX_inv = reshape(IDX_inv,im_size);