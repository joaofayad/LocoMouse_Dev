function [IDX,IDX_inv,Centroids,cos_theta] = LocoMouse_Calibrate_views(vid,bkg,split_line,t,frame_opts)
% LocoMouse_Calibrate_views Given a video of the LocoMouse setup of the 
% calibration object estimates the distortion map between the views.
%
% Calibration is performed by assuming the cosine of the lines between the
% two projections (side and bottom) of the same point varies linearly with
% X. It is also assumed the calibration object is a "point-like" white
% object that can be easily segmented by background subtraction and
% thresholding at 50%.
%
% INPUT:
% vid: VideoReader structure or path to video file.
% bkg: Background image or path to such image.
% split_line: Vertical coordinate on the image where the views can be split
% by a horizontal line (see splitViews).
% t: threshold for im2bw (default value t =0.5).
% plot_figures: boolean to plot angles and lines.
% OUTPUT:
% IDX: Index map between raw and corrected image such that Inew =
% uint8(zeros(size(I)); Inew = I(IDX);
% IDX_inv: Index map between corrected and raw image such that I =
% uint8(zeros(size(Inew)); I = Inew(IDX_inv);

% Checking if we have the structure or the path:
if ischar(vid)
    vid = VideoReader(vid);
elseif isobject(vid)
    if ~strcmpi(get(vid,'Type'),'VideoReader')
        error('Input object must be of the VideoReader type.')
    end
else
    error('Input must be a VideoReader object or a path to a MATLAB supported video file.');
end
% Checking if we have the image or the path:
if ~exist('bkg','var')
    bkg = 'compute';
end

if ischar(bkg)
    if strcmpi(bkg,'compute')
        bkg = computeMedianBackground(vid);
    else
        bkg = imread(bkg);
    end
end

if any(size(bkg) ~= [vid.Height vid.Width])
    error('Background image does not match input video size.');
end

if ~exist('split_line','var');
    % Computing the split line:
    split_line = computeSplitLine(vid,bkg);
end

if ~exist('t','var')
    t = 0.5;
end

%% Processing the images and looking for the calibration object:
frame_vec = frame_opts(1):frame_opts(2):frame_opts(3);
N_frames = length(frame_vec);
Centroids = NaN(2,2,N_frames);
parfor i_images = 1:N_frames
% Read the image, remove the background and threshold:
    i_frame = frame_vec(i_images);
    I = im2bw(read(vid,i_frame)-bkg,t);
    
    % Split:
    I_cell = cell(2,1);
    [I_cell{[2 1]}] = splitImage(I,split_line);
    % Look for the centroid at each view:
    for i_v = 1:2
        CC = regionprops(I_cell{i_v},'Centroid','PixelList');
        switch length(CC)
            case 0
            case 1
                Centroids(:,i_v,i_images) = CC.Centroid([2 1])';
            otherwise
                % Usually there will be just one, but just in case...
                [~,idmax] = max(cellfun(@(x)(size(x,1)),{CC(:).PixelList}));
                Centroids(:,i_v,i_images) = CC(idmax).Centroid([2 1]);
        end
    end
end
Centroids = permute(Centroids,[1 3 2]);
Centroids(1,:,1) = Centroids(1,:,1) + split_line;
    
%% Given the correspondences found on the images, compute the distortion
% maps:
% Checking for full correspondences only:
ind = all(~isnan(Centroids(:,:,1))&~isnan(Centroids(:,:,2)));
Centroids = Centroids(:,ind,:);

% Computing angles:
V = Centroids(:,:,2) - Centroids(:,:,1);
cos_theta = V(2,:)./(sqrt(sum(V.^2)));
% if plot_figures
%     figure()
%     title('Cos_theta vs X')
%     plot(Centroids(2,:,1),cos_theta,'.')
% end
% clear V

% Computing angles based on view 1 (bottom):
M = [Centroids(2,:,2);ones(1,size(Centroids(2,:,2),2))]';
line_coefficients = M\(cos_theta');
clear M

% Creating generic matrix and distorting it:
% imdistortion according to abc plane fitting:
[X,Y] = meshgrid(1:vid.Width,1:vid.Height);

% Estimating the angle based on the X coordinate:
cos_col = [1:vid.Width;ones(1,vid.Width)]'*line_coefficients;
sin_col = sqrt(1-cos_col.^2);
Xdist = X + bsxfun(@times,(Y-1),(cos_col./sin_col)');

% Computing the forward map to the corrected image:
offset = min(Xdist(:));
Xdist_grid = round(Xdist - offset + 1);
Width_dist = max(Xdist_grid(:));
[Xnew,Ynew] = meshgrid(1:Width_dist,1:vid.Height);
IDX = knnsearch([Xdist_grid(:) Y(:)],[Xnew(:) Ynew(:)]);
IDX = reshape(IDX,vid.Height,Width_dist);
IDX_inv = knnsearch([Xnew(:) Ynew(:)],[Xdist_grid(:) Y(:)]);
IDX_inv = reshape(IDX_inv,vid.Height,vid.Width);