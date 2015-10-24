function Ibw = blackOutImageRegions(Ibw, centers, box_size)
% BLACKOUTIMAGEREGIONS  masks out image regions given locations and box
% size.
%
% Input:
%
% Ibw: an IxJ logical matrix.
% centers: Nx1 or Nx2 indices reprensenting image locations.
% box_size: the region around the centers to be masked out (set to false).
%
% Points that have at least one NaN coordinate are ignored.
%
% Output:
% 
% Ibw: The result from masking regions form the input image.

size_I = size(Ibw);
if ismatrix(centers)
    
    if isrow(centers)
        % Convert 2D coordinates to linear indices:
        c = cell(2,1);
        [c{:}] = ind2sub(size_I,centers);
        centers = cell2mat(c);
    end
    
    centers = centers(:,~any(isnan(centers),1)); % Removing NaNs
   
    cc = ceil(box_size/2);
    
    centers(1,:) = centers(1,:) - cc(1);
    centers(2,:) = centers(2,:) - cc(2);
    N_centers = size(centers,2);
    
    end_centers = zeros(2,N_centers);
    end_centers(1,:) = centers(1,:) + box_size(1)-1;
    end_centers(2,:) = centers(2,:) + box_size(2)-1;
    
    for i_c = 1:size(centers,2)
        Ibw(max(centers(1,i_c),1):min(end_centers(1,i_c),size_I(1)),max(centers(2,i_c),1):min(end_centers(2,i_c),size_I(2))) = false;
    end
else
    error('centers must be either a vector of linear indices or a 2xN matrix of subscript indices.');
end

% This seemed more elegant for dealing with boxes out of the image but it
% turned out to be much slower. Computing the canonical window and
% extracting indices like that is still faster if the box is known to be
% fully within the image
% if ~exist('canonical_row_col','var')
%     canonical_center = ceil(box_size/2);
%     canonical_row_col = cell(1,2);
%     canonical_row_col{1} = reshape(repmat((1:box_size(1)) - canonical_center(1),box_size(2),1),[],1)';
%     canonical_row_col{2} = repmat((1:box_size(2)) - canonical_center(2),1,box_size(1));
% end

% % Computing the result:
% res_row = bsxfun(@plus,centers(1,:)',canonical_row_col{1});
% res_col = bsxfun(@plus,centers(2,:)',canonical_row_col{2});
% 
% % Checking sizes:
% valid_ind = res_row > 0 & res_row <= size_I(1) & res_col > 0 & res_col <= size_I(2);
% idx = sub2ind(size_I,res_row(valid_ind),res_col(valid_ind));
% Ibw(idx) = false;
