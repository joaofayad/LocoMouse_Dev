function [Centroids,ind,cos_theta] = LocoMouse_CalibrationCorrespondences(vid,bkg,split_line,t,frame_vec)
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
   
elseif verLessThan('matlab','8.5')
    if ~strcmpi(class(vid),'VideoReader')
        error('Input object must be of the VideoReader type.');
    end
elseif isobject(vid)
    if ~strcmpi(class(vid),'VideoReader')
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

if isempty(bkg)
    bkg = uint8(zeros([vid.Height vid.Width]));
elseif any(size(bkg) ~= [vid.Height vid.Width])
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
N_frames = length(frame_vec);
Centroids = NaN(2,2,N_frames);
Itemp = read(vid,1);
if length(size(Itemp)) == 3
    rgb = true;
else
    rgb = false;
end
parfor i_images = 1:N_frames
% Read the image, remove the background and threshold:
    i_frame = frame_vec(i_images);
    I = read(vid,i_frame);
    if (rgb)
        I = I(:,:,1);
    end
    I = im2bw(I-bkg,t);
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

% Computing angles:
V = NaN(2,N_frames);
cos_theta = NaN(1,N_frames);
V(:,ind) = Centroids(:,ind,2) - Centroids(:,ind,1);
cos_theta(ind) = V(2,ind)./(sqrt(sum(V(:,ind).^2)));