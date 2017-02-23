function [final_tracks,tracks_tail,data,debug] = MTF_rawdata(data, model,bb_choice)
% MTF   Tracks a set of predefined (mouse) features over a given video.
%
% INPUT:
% data: Data stuff
% model: Models for detection
%----------------------------
% notes: data.flip indicates
%        false - mouse in original video faces right
%        true - mouse in original video faces left
%        if field empty non-existent = auto detection of mouse orientation
%-----------------------------
% This method relies on predefined (or trained) detectors that are specific
% for each feature to be tracked. Features can be either point features
% (e.g. paws, snout) or area features (e.g. tail).
%
% Images are filtered using the provided detectors and post-processing is
% done to extract the candidates:
% For point features, non-maxima suppression is performed a set of discrete
% image positions are kept as candidates.
%
% For area features, contiguous regions that have a detection score above a
% certain threshold are kept as candidates.
%
% Point features are then tracked over the whole sequence in a batch
% (offline) approach using:
%
% Efficient Second Order Multi-Target Tracking with Exclusion Constraints
% Russel C., Setti F., Agapito L.
% British Machine Vision Conference (BMVC 2011), Dundee, UK, 2011.
%
% Code for that tracker is available here:
% http://www.eecs.qmul.ac.uk/~chrisr/tracking.tar.gz.
%
% Area features are not tracked over time. the highest scoring area from
% each image is kept.
%
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org)
% Later adjustments by: Hugo Marques (HGM), Dennis Eckmeier (DE), 
%                       Goncalo Figueira (GF)
% Created: 15/10/2013
% Last Modified: 28/10/2015 [DE]

%% Pre-processing the video to extract important quantities:
if ischar(data.vid)
    vid = VideoReader(data.vid); % reading the video
elseif isobject(data.vid)
    if strcmpi(get(data.vid,'Type'),'VideoReader')
        vid = data.vid;
    else
        error('Object in data.vid not supported');
    end
end
% Checking if need to precompute background:
if ischar(data.bkg)
    if strcmpi(data.bkg,'compute')
        Bkg = read(vid,[1 Inf]);
        if length(size(Bkg)) > 3
            Bkg = squeeze(Bkg(:,:,1,:));
        end
        Bkg = median(Bkg,3);
    else
        % Attempt to read the backgrond as an image:
        Bkg = imread(data.bkg);
    end
else
    Bkg = data.bkg;
end

N_frames = floor(vid.Duration * vid.FrameRate);
% N_frames = 500;
% warning('frame number was set to 10 for debugging reasons! - DE')

N_views = 2; % FIXME: Should come from the code...

% % [GF]
% % check if mouse comes from L or R based file name
% % do not use checkmouseside function
% if strcmp(data.bkg(end-4),'L')
%     flip = 1;
% else
%     flip = 0;
% end
% %

if ~isfield(data,'flip')
    data.flip = checkMouseSide(vid,Bkg); % Check if video is reversed.
elseif ischar(data.flip)
    switch data.flip
        case 'LR' % check if mouse comes from L or R based file name [GF]
            if strcmp(data.bkg(end-4),'L')
                data.flip = true;
            else
                data.flip = false;
            end           
    end
elseif ~any(ismember([0 1],data.flip))
    data.flip = checkMouseSide(vid,Bkg); % Check if video is reversed.
end

if ~isfield(data,'scale')
    scale = 1;
else
    scale = data.scale; % FIXME: Check where this is computed...
end

if ~isfield(data,'threshold')
    threshold = 0.01;
else
    threshold = data.threshold; % FIXME: Check where this is computed...
end

if ~isfield(data,'split_line')
    split_line = computeSplitLine(vid,Bkg); % Compute split line.
else
    split_line = data.split_line;
end
split_line = round(split_line*scale);
ind_warp_mapping = data.ind_warp_mapping;
inv_ind_warp_mapping = data.inv_ind_warp_mapping;
% clear data

% Line features (at this point, just the tail):
line_features = fieldnames(model.line);
N_linelike_features = length(line_features);
N_tail_points = 15; % FIXME: Hardcoded for the LocoMouse setup.

% Point features:
point_features = fieldnames(model.point);
N_pointlike_features = length(point_features);
N_features_per_point_track = zeros(1,N_pointlike_features);
for i_point = 1:N_pointlike_features
    N_features_per_point_track(i_point) = model.point.(point_features{i_point}).N_points;
end
N_pointlike_tracks = sum(N_features_per_point_track);

% Structures that remain after the for loop:
tracks_tail = zeros(3,N_tail_points,N_frames);
tracks_joint = cell(N_pointlike_features,N_frames);
tracks_bottom = cell(N_pointlike_features,N_frames);

Unary = cell(N_pointlike_features,N_frames);
Pairwise = cell(N_pointlike_features,N_frames-1);

% Computing expected image size based on mapping size:
expected_im_size = size(inv_ind_warp_mapping);

%% Estimating mouse size:
% Since all paws are detected with the same detector they are discriminated
% by using location priors. These location priors are defined in a tight
% bounding box surrounding the mouse. The size of this box is estimated
% first. The box also improves the detection of other features such as tail
% and nose.
bounding_box = NaN(2,3,N_frames);
bdymasscenter = nan(N_frames,2); % [GF]

[p_boundingBoxFunctions, ~, ~]=fileparts(which('computeMouseBox')); % find the folder containing BoundingBoxOptions.mat
load([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'ComputeMouseBox_cmd_string','ComputeMouseBox_option'); % load bounding box option information
disp(['Using bounding box option "',char(ComputeMouseBox_option(bb_choice)),'"']); 
tcmd_string = strtrim(char(ComputeMouseBox_cmd_string(bb_choice)));
disp(['(',tcmd_string,')']);
flip = data.flip;
parfor i_images = 1:N_frames
    % CODE TESTING [DE]
    contrast_template = 'C:\Users\Dennis\Documents\DATA_DarkvsLight_Overground\Contrast_Template.mat';
    [I,Iaux] = readMouseImage( ...
        vid,...
        i_images,...
        Bkg,...
        flip,...
        scale,...
        ind_warp_mapping,...
        expected_im_size,...
        'contrast_template',...
        contrast_template);
%     % -----------------------------------------------------------------------------------------------
%     
%      [I,Iaux] = readMouseImage(vid,i_images,Bkg,data.flip,scale,ind_warp_mapping,expected_im_size);
    
    
    
    % To change bounding box computation, see READ_BEFORE_CHANGING_ANYTHING.m 
    % in ... \LocoMouse_Dev\LocoMouse_Tracker\boundingBoxFunctions  [DE]
    [bounding_box(:,:,i_images),~,~] = Call_computeMouseBox(Iaux, split_line,tcmd_string); % Call_computeMouseBox executes eval(tcmd_string)
    bdymasscenter(i_images,:) = computebdymass(I,split_line); % calculates the center of mass of the silhouette of the mouse [GF]
end

% Take mean box size and add 3 standard deviations:
% bounding_box_dim is defined as smallest box between the largest observed
% and the mean+3*std box;

bounding_box_dim = round(nanmin(nanmean(bounding_box(2,:,:),3) + 3 * nanstd(bounding_box(2,:,:),0,3), nanmax(bounding_box(2,:,:),[],3)))';

% Since the boxes are estimated independently their displacement over time
% is noisy. To reduce this effect we filter its position using a moving
% average filter of size Nsamples.
%%%FIXME: framerate.
Nsamples = 5; 
coeff = ones(1, Nsamples)/Nsamples;
bounding_box = round(squeeze(bounding_box(1,:,:)));
% debug.bounding_box = bounding_box;
% debug.bounding_box_dim = bounding_box_dim;
temp = bounding_box;
temp = filter(coeff, 1,temp' ,[],1)';
bounding_box(:,:,Nsamples+1:end-Nsamples) = round(temp(:,:,Nsamples+1:end-Nsamples));clear temp N_samples coeff
xvel = diff(squeeze(bounding_box(1,:,:)),1,2);

% Parameters for the tracker:
%%% FIXME: Normalize this according to box size and framerate.
% image size, and other size parameters used.
% Occluded points:
occluded_distance = 15; % Maximum allowed displacement (in pixels).
grid_spacing = 20;
tail_x_threshold = round(max(bounding_box_dim(1,:))/2); % Minimum percentage of box that must be visible for tail to be detected.

% Defining the occlusion grid. There is a cap on 0.75*width and
godo2 = round(grid_spacing/2);
[X,Y] = meshgrid(godo2:grid_spacing:bounding_box_dim(2)-godo2,godo2:grid_spacing:round(0.75*bounding_box_dim(1)));% Grid of occlusion points.
OcclusionGrid = [Y(:)';X(:)'-split_line]; 
clear X Y godo2 grid_spacing
Nong = size(OcclusionGrid,2);
alpha_vel = 1E-1; % Weight of the velocity term.
Ncandidates = zeros(N_pointlike_features,N_frames);

if isfield(data,'reference_histogram')
    I_hist_origin{1} = imresize(data.reference_histogram{1},bounding_box_dim([2 1])');
    I_hist_origin{2} = imresize(data.reference_histogram{2},bounding_box_dim([3 1])');
    match_histogram = true;
else
    match_histogram = false;
    I_hist_origin = [];
end

% loading weight settings [DE]
WS=load([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'WeightSettings');
tweight =  WS.WeightSettings{bb_choice};
% Looping over all the images
% warning('for changed to FOR for debugging reasons. [DE]')
parfor i_images = 1:N_frames
%     warning('function breaking debugging edit. [DE]')
%     i_images=ceil(N_frames/2);
   %% Reading images from video and preprocessing data:
   % disp(['frame: ',num2str(i_images)]);
    bounding_box_i = bounding_box(:,i_images);
    
    % CODE TESTING [DE]
    contrast_template = 'C:\Users\Dennis\Documents\DATA_DarkvsLight_Overground\Contrast_Template.mat';
    [~,Iaux] = readMouseImage( ...
        vid,...
        i_images,...
        Bkg,...
        data.flip,...
        scale,...
        ind_warp_mapping,...
        expected_im_size,...
        'contrast_template',...
        contrast_template);
    % -----------------------------------------------------------------------------------------------
        
    % [~,Iaux] = readMouseImage(vid,i_images,Bkg,data.flip,scale,ind_warp_mapping,expected_im_size);
    I_cell = cell(1,2);
    [I_cell{[2 1]}] = splitImage(Iaux,split_line);
    
    OFFSET = bounding_box(:,i_images) - bounding_box_dim;
    x_cut = max(OFFSET(1) + 1,1):bounding_box_i(1);
    l_x_cut = length(x_cut);
    
    % Processing views:
    for i_views = 1:N_views
        if ~isempty(I_cell{i_views})
            I_cell{i_views} = I_cell{i_views}(max(1,OFFSET(i_views+1) + 1):bounding_box_i(i_views+1),x_cut);
            if match_histogram
                I_cell{i_views} = imhistmatch(I_cell{i_views},I_hist_origin{i_views});
            end
        end
    end
    
    %% Detecting line features (e.g. tail):
    % Line features are detected independently from the other features
    % (e.g. point features). While not optimal, each feature type follows a
    % different detection strategy and combining them is not straight
    % forward. Line features are detected sequentially, following the order
    % defined in the model. As order changes the result, it is best to
    % experiment which order is more likely to give the desired results.
    Tmask = cell(2,1);
    % Initializing the masks to true:
    for i_views = 1:N_views
        Tmask{i_views} = true(size(I_cell{i_views}));
    end
    
    for i_line_features = 1:N_linelike_features
        w_line = model.line.(line_features{i_line_features}).w;
        rho_line = model.line.(line_features{i_line_features}).rho;
%         box_line = model.line.(line_features{i_line_features}).box_line;
        mask_i = cell(1,2);
        
        if l_x_cut > tail_x_threshold && ~all(cellfun(@isempty,w_line))
            % We only attempt at detecting tht tail if more than
            % tail_x_threshold (%) of the box width is visible in the
            % image.
            x_tail_cut = 1:l_x_cut-round(0.8*tail_x_threshold);
            
            % Croping the mouse:
            [tracks_tail(:,:,i_images),tm] = tailDetectionFilter3(cellfun(@(x)(x(:,x_tail_cut)),I_cell,'un',0),Tmask, split_line,w_line,rho_line,N_tail_points);
            mask_i = cellfun(@(x,y)([x true(size(x,1),size(y,2)-size(x,2))]),tm,I_cell,'un',0);
            tracks_tail(:,:,i_images) = bsxfun(@plus,tracks_tail(:,:,i_images),bsxfun(@max,OFFSET,zeros(3,1)));
        else
            mask_i{1} = true(size(I_cell{1}));
            mask_i{2} = true(size(I_cell{2}));
            tracks_tail(:,:,i_images) = NaN(3,N_tail_points);
        end
        
        % Masking the detected feature out of the input image:
        for i_views = 1:N_views
        Tmask{i_views} = Tmask{i_views} & mask_i{i_views};
        end
    end
    %% Detecting point features:
    
    % Initializing auxiliary structures:
    scores = cell(1,N_views);
    i = cell(1,N_views);
    j = cell(1,N_views);
    D2 = cell(1,N_views);
    
    for i_point = 1:N_pointlike_features
        w_point = model.point.(point_features{i_point}).w;
        rho_point = model.point.(point_features{i_point}).rho;
        box_size_point = model.point.(point_features{i_point}).box_size;
        
        for i_views = 1:N_views
            if ~isempty(I_cell{i_views})
                % Filtering witht the detector:
                Cmat = conv2(double(I_cell{i_views}), w_point{i_views}, 'same') - rho_point{i_views};
                % Removing potential positive detections on black pixels and zeroing out negative detections.
                scores{i_views} = Cmat .* double(im2bw(sc(I_cell{i_views}),0.1)); Cmat(Cmat<0) = 0;
                scores{i_views}(~Tmask{i_views}) = 0;
                detections = scores{i_views} > 0;
            else
                Cmat = zeros(size(I_cell{i_views}));
                detections = false;
            end
            
            if any(detections(:))
                scores{i_views} = scores{i_views}(detections);
                ind_temp = 1:numel(I_cell{i_views});
                
                % Transforming linear coordinates into image coordinates:
                [i{i_views}, j{i_views}] = ind2sub(size(I_cell{i_views}),ind_temp(detections)');
                if i_views  == 1
                    % Apply non-maxima suppresion to detected areas:
%                     [D2{i_views}, scores{i_views}] = nmsMax_mexed([i{i_views} j{i_views}],box_size_point{i_views}, scores{i_views}','center'); % use pre-compiled version
                    [D2{i_views}, scores{i_views}] = nmsMax([i{i_views} j{i_views}],box_size_point{i_views}, scores{i_views}','center',0.5,true);
                    % Refine locations taking the weighted mean of detections scores arond the maxima found:
%                     D2{i_views} = weightedMean(D2{i_views}, Cmat, box_size_point{i_views});
%                     [D2{i_views}, scores{i_views}] = nmsMax_mexed(D2{i_views},box_size_point{i_views}, scores{i_views},'center'); % use pre-compiled version
                    %[D2{i_views}, scores{i_views}] = nmsMax(D2{i_views},box_size_point{i_views}, scores{i_views},'center');
                    D2{1}(:,2) = D2{1}(:,2) + max(OFFSET(1),0);
                    D2{1}(:,1) = D2{1}(:,1) + split_line + max(OFFSET(2),0);
                    tracks_bottom{i_point,i_images} = [D2{1}(:,[2 1])';scores{i_views}];
                    
                    
                else
                    % Applying a more conservative non-maxima suppression
                    % algorithm for the side view:
                    [D2{i_views}, scores{i_views}] = peakClustering([i{i_views} j{i_views}],box_size_point{i_views}, scores{i_views}','center','max'); 
                    % There is too much overlap to refine these
                    % detections...
                    D2{2}(:,1) = D2{2}(:,1) + max(OFFSET(3),0);
                    D2{2}(:,2) = D2{2}(:,2) + max(OFFSET(1),0);
                end
                
            else
                D2{i_views} = zeros(0,2);
                scores{i_views} = zeros(1,0);
                if i_views == 1
                    tracks_bottom{i_point,i_images} = zeros(3,0);
                end
            end
        end
        
        %% Matching detections between views:
        % To match the detections we resort to the use of our image
        % distortion calibration to generate auxiliary candidate locations
        % on the corrected space. Comparisons are thus made in such space
        % where the y coordinates of both views match each other.
        
        % Checking for matches:
        if any(cellfun(@isempty,D2))
            tracks_joint{i_point,i_images} = zeros(5,0);
        else
            % Pairing boxes that overlap horizontally for at least T of box
            % width. This flexibility is required due to calibration errors
            % and independent NMS between views.
            T = 0.7; % FIXME: Although defined as a percentage, give opportunity to tune.
            
            if i_images > 1
                % Due to the geometry of the problem it is possible to have
                % ambiguous sets of correspondences (e.g. when paws cross
                % each other we might have two bottom view candidates that
                % could match either of two (or more) side view points). In
                % such cases we use velocity (image difference) cues to
                % increase separation accuracy. This method works well if
                % one paw is static and another moving, but will fail if
                % both paws have similar motion.
                
                
                % CODE TESTING [DE]
                %[~,Iaux2] = readMouseImage(vid,i_images-1,Bkg,data.flip,scale,ind_warp_mapping,expected_im_size);
                contrast_template = 'C:\Users\Dennis\Documents\DATA_DarkvsLight_Overground\Contrast_Template.mat';
                [~,Iaux2] = readMouseImage( ...
                    vid,...
                    i_images-1,...
                    Bkg,...
                    data.flip,...
                    scale,...
                    ind_warp_mapping,...
                    expected_im_size,...
                    'contrast_template',...
                    contrast_template);
                % -----------------------------------------------------------------------------------------------

                
                
                I_vel = double(Iaux) - double(Iaux2);
                moving = I_vel > 25; %%% FIXME: This clearly depends on image size. Must be normalized in some way.
                D21_mov = reshape(getWindowFromImage(moving,D2{1}',round(box_size_point{1})/2),[],size(D2{1},1));
                D22_mov = reshape(getWindowFromImage(moving,D2{2}',round(box_size_point{2})/2),[],size(D2{2},1));

                D21_mov = sum(D21_mov,1) >= 0.02*prod(box_size_point{1}); %%% FIXME: Find robust values for moving/not moving classification.
                D22_mov = sum(D22_mov,1) >= 0.05*prod(box_size_point{2});
            else
                D21_mov = true(1,size(D2{1},1));
                D22_mov = true(1,size(D2{2},1));
            end
            % Box with for the first view is used, although it should
            % usually be the same.
            [Pairs, scores_pairs] = boxPairingsWithVelConstraint(D2{1}, D2{2}, scores{1}, scores{2}, D21_mov, D22_mov, box_size_point{1}(2), 'bottom', T);
            tracks_joint{i_point, i_images} = [Pairs scores_pairs]';
            tracks_joint{i_point, i_images} = tracks_joint{i_point, i_images}([2 1 3 4 5],:);
        end
        
        %% Computing unary potentials for tracking:
        % Defining the weights for candidate locations for each feature:
        % FIXME: The classes for the LocoMouse system have been hard coded
        % here. For this to be general, there should be a field on the
        % model structure specifying (via a function handle for instance)
        % how the area prior for each class is computed (e.g.
        % model.point.paw.area_prior = 'computePawAreaWeights'; where
        % computePawAreaWeights is a function that return the weights
        % varialbe as computed here.

        switch point_features{i_point}
            case 'paw'
                weights = zeros(4,size(tracks_bottom{i_point,i_images},2));
                if ~isempty(weights)
                    X = OFFSET(1) + [0.3*bounding_box_dim(1) bounding_box_dim(1)];
                    Y = OFFSET(2)+ split_line + [0 bounding_box_dim(2)];
                    for tpaw = 1:4 %[Front Right, Hind Right, Front Left, Hind Left]
                        weights(tpaw,:) = pawQuadrantWeights_Distance(tracks_bottom{i_point,i_images}(1,:),tracks_bottom{i_point,i_images}(2,:),X,Y,tweight(tpaw,:)); 
                    end
                    weights = weights';
                    
                    % Check for "impossible" candidates (i.e. candidates
                    % that have 0 weight for all 4 paws).
                    anynotzero = any(weights > 0,2);
                    tracks_bottom{i_point,i_images} = tracks_bottom{i_point,i_images}(:,anynotzero);
                    weights = weights(anynotzero,:);
                    Ncandidates(i_point,i_images) = sum(anynotzero);
                    Unary{i_point,i_images} = [repmat(tracks_bottom{i_point,i_images}(3,:)',1,4).*weights;zeros(Nong,4)];
                else
                    Unary{i_point,i_images} = zeros(Nong,4);
                end
                
            case 'snout'
                weights = zeros(1,size(tracks_bottom{i_point,i_images},2));
                if ~isempty(weights)
                    X = OFFSET(1) + [0 bounding_box_dim(1)];
                    Y = OFFSET(2)+ split_line + [0 bounding_box_dim(2)];
                    weights(1,:) = pawQuadrantWeights_Distance(tracks_bottom{i_point,i_images}(1,:),tracks_bottom{i_point,i_images}(2,:),X,Y,tweight(5,:)); % snout
                    weights = weights';
                    valid_snout = weights > 0;
                    tracks_bottom{i_point,i_images} = tracks_bottom{i_point,i_images}(:,valid_snout);
                    Unary{i_point,i_images} = [tracks_bottom{i_point,i_images}(3,:)'.*weights(valid_snout,:);zeros(Nong,1)];
                    Ncandidates(i_point,i_images) = sum(valid_snout);
                    
                else
                    Unary{i_point,i_images} = zeros(Nong,1);
                end
        end
    end
end
% Finished all the image processing. Clearing variables related to that
% step:
% clear Bkg N_tail_points detection_threshold_point detection_threshold_tail tail_x_threshold bounding_box_dim

%% Computing pairwise potentials:
% Due to the way for works we cannot access entry i and i+1 of the same
% cell array without huge overhead. Therefore we sacrifice a bit of memory
% and create an auxiliary structure where each index accesses two frames at
% the time.
%
% Emircal tests have shown that a for loop only pays off if if sequence
% the sequence is relatively large (~400 frames) but that is usually the
% case.

tracks_bottom_aux = tracks_bottom(:,2:end);
parfor i_images = 1:(N_frames-1)
    OGi = bsxfun(@minus,bounding_box(1:2,i_images),OcclusionGrid);
    for i_point = 1:N_pointlike_features
        Pairwise{i_point, i_images} = computePairwiseCost(tracks_bottom{i_point,i_images}(1:2,:),tracks_bottom_aux{i_point,i_images}(1:2,:),OGi,abs(xvel(i_images))+occluded_distance,alpha_vel);
    end
end
clear tracks_bottom_aux tracks_bottom_aux2

%% Tracking:
% Perform bottom view tracking: Tracking is first solved for the bottom
% view case as that is the simplest and more reliable.
M = cell(N_pointlike_tracks,1);
final_tracks = NaN(3,N_pointlike_tracks,N_frames);

for i_point = 1:N_pointlike_features
    % The method used for tracking is not invariant to the order of
    % the features (i.e. the order of the columns on the unary
    % potential). Thus we run all possible combinations of inputs
    % and take the solution with higher score. In case of draw the
    % first one is picked.
    
    O = combinator(model.point.(point_features{i_point}).N_points,model.point.(point_features{i_point}).N_points,'p'); %FIXME: To generalize the code for other
    N_order = size(O,1);
    
    if N_order > 1
        m = cell(1,N_order);
        U = Unary(i_point,:);
        P = Pairwise(i_point,:);
        Cost = zeros(1,N_order);
        for i_o = 1:N_order
            u = cellfun(@(x)(x(:,O(i_o,:))),U,'un',false);
            m{i_o} = match2nd(u,P,[],Nong,0);
            c = computeMCost(m{i_o},u,P(1,:));
            Cost(i_o) = sum(c(:));
        end
        [~,imax] = max(Cost);
        M{i_point}(O(imax,:),:) = m{imax};
        clear U P T Cost m u c imax
    else
        M{i_point} =  match2nd (Unary(i_point,:), Pairwise(i_point,:), [],Nong, 0);
    end
end
clear O Norder
M = cell2mat(M);

%% Side view tracking:
% Now that we have the location of the features on the
% bottom view, we search for their best match on the side view.

% Building structures for top view tracking:
M_top = zeros(size(M));
Unary_top = cell(N_pointlike_features,N_frames);
Pairwise_top = cell(N_pointlike_features,N_frames-1);
occluded_distance_top = 15;
nong_vect = split_line-round(occluded_distance_top/2):-occluded_distance_top:1;
alpha_vel = 100;
Nong_top = length(nong_vect);
tracks_top = cell(N_pointlike_tracks,N_frames);
i_point = 1;
point_check = N_features_per_point_track(1);
box_size_point = model.point.(point_features{1}).box_size;

for i_tracks = 1:N_pointlike_tracks
    % Checking which feature is being tracked:
    if i_tracks > point_check
        i_point = i_point + 1;
        point_check = point_check + N_features_per_point_track(i_point);
        box_size_point = model.point.(point_features{i_point}).box_size;
    end
    
    Ncandidates_top = zeros(1,N_frames);
    tracks_joint2 = cell(1,N_frames);
    
    % Computing unary potentials:
    for i_images = 1:N_frames
        if M(i_tracks,i_images) <= size(tracks_bottom{i_point,i_images},2)
            % If there is bottom view candidate:
            candidates = all(bsxfun(@eq,tracks_joint{i_point,i_images}(1:2,:),tracks_bottom{i_point,i_images}(1:2,M(i_tracks,i_images))),1);
            if any(candidates)
                % If there are matching Z points compute the unary term:
                tracks_joint2{i_images} = tracks_joint{i_point,i_images}([1:3 5],candidates);
                Ncandidates_top(i_images) = sum(candidates);
                Unary_top{i_tracks,i_images} = [tracks_joint2{i_images}(end,:) zeros(1,Nong_top)]';
            else
                % Otherwise add just the occlusion grid points.
                tracks_joint2{i_images} = zeros(4,0);
                Unary_top{i_tracks,i_images} = zeros(Nong_top,1);
            end
            
        else
            % Otherwise add just the occlusion grid points.
            tracks_joint2{i_images} = zeros(4,0);
            Unary_top{i_tracks,i_images} = zeros(Nong_top,1);
        end
    end
    tracks_top(i_tracks,:) = tracks_joint2;
    
    % Computing pairwise potentials:
    tracks_joint_2_aux = tracks_joint2(2:N_frames);
    parfor i_images = 1:(N_frames-1)
        Pairwise_top{i_tracks, i_images} = computePairwiseCost(tracks_joint2{i_images}(3,:),tracks_joint_2_aux{i_images}(3,:),nong_vect,occluded_distance_top,alpha_vel);
    end
    clear tracks_joint_2_aux x
    
    % Tracking:
    Mpf_top = match2nd (Unary_top(i_tracks,:), Pairwise_top(i_tracks,:), [],Nong_top, 0);
    
    parfor i_images = 1:N_frames
        % Reading the final tracks:
        bottom_cond = M(i_tracks,i_images) <= Ncandidates(i_point,i_images) && M(i_tracks,i_images) > 0;
        top_cond = Mpf_top(i_images) <= Ncandidates_top(i_images) && Mpf_top(i_images) > 0;
        if bottom_cond && top_cond
            final_tracks(:,i_tracks,i_images) = [tracks_bottom{i_point,i_images}(1:2,M(i_tracks,i_images));tracks_joint2{i_images}(3,Mpf_top(i_images))];
        elseif bottom_cond
            final_tracks(:,i_tracks,i_images) = [tracks_bottom{i_point,i_images}(1:2,M(i_tracks,i_images));NaN];
        end
        
        % Performing Z NMS: Perform this step only if more features of the same
        % detector are used (e.g. perform 3 times for paws).
        if i_tracks < point_check && top_cond
            temp = final_tracks(:,i_tracks,i_images)';
            kp = findOverlap(temp(:,[1 3]),tracks_joint{i_point,i_images}([1 3],:)',box_size_point{2},'center',0.5);
            tracks_joint{i_point,i_images}(:,kp) = repmat(zeros(5,1),1,sum(kp));
        end
    end
    M_top(i_tracks,:) = Mpf_top;
end

% The output of this tracker should either be the "internal" tracks of the
% algorithm i.e. always from left to right, or the fully corrected tracks
% i.e. that match the input video. Vertically flipped internal tracks are
% not a meaningful representation. 
%
% Code that flipped the tracks moved to the
% convertTracksToUnconstrainedView function. [joaofayad]

% Debug data:
debug.bounding_box = bounding_box;
debug.bounding_box_dim = bounding_box_dim;
debug.Occlusion_Grid_Bottom = OcclusionGrid;
debug.Occlusion_Vect_Top = nong_vect;
debug.tracks_bottom = tracks_bottom;
debug.M = M;
debug.tracks_top = tracks_top;
debug.M_top = M_top;
debug.nong_vect = nong_vect;
debug.Unary = Unary;
debug.Pairwise = Pairwise;
debug.xvel = xvel;
debug.occluded_distance = occluded_distance;
data.split_line = split_line;
data.bodymasscenter = bdymasscenter; % [GF]