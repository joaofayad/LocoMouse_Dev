function labelled_data = extractManualLabelling(data, manual_labelling, options)
% extractManualLabelling Given a data and manual_labelling structures
% extracts all the labelled windows, while generating N negative (i.e.
% non-orverlapping with the hand labelled data) samples per image, per
% feature.
%
% INPUT:
%
% data: A structure with the fields:
% - vid: Path or VideoReader structure to a MATLAB supported video.
% - bkg: Path or image matrix of a background image.
% - ind_warp_mapping: A correction map to aligne the side and bottom views.
% - inv_ind_warp_mapping: The rever map to the original image.
%
% manual_labelling: A structure with the fields:
% - scale: Scale factor for the data.
% - flip: boolean for vertical image flip. Flipping is performed to the
% image before extracting the windows, not to the windows after extraction.
% - split_line: Horizontal line splitting the image in two.
%
% options: A structure with the fields:
% - N_negative_data_per_frame: Number of negative samples per frame, per
% class.
% - allow_partial_views: Boolean allowing or not partial views as positive
% samples. When not allowed, these are still prevented from being used as
% negative data.
% - negative_data_mode: Must be either 'mouse_window', where it extracts
% negative data from a bounding box around the mouse computed with very
% basic thresholding techniques; or 'whole image' where samples are taken
% from the whole image.
% - rotate_samples: Boolean allowing samples to be rotated to increase
% sample variability.
% - rotation_angles: A vector with angles in degrees by which to rotate the
% samples.
% Note: All these options can be meade specefic for each class by providing
% them in a cell structure that matches the labelling structure (see
% LocoMouse_Labelling and LocoMouse_Training_script).
%
% OUTPUT:
%
% labelled_data: A structure with the fields:
%
% For more information about the fields of the structures, check the
% LocoMouse_Training_script.
%
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org)
% Last Modified: 17/11/2014


%% Parsing inputs and auxiliary variables:
if ischar(data.vid)
    data.vid = VideoReader(data.vid);
end

if ischar(data.bkg) && ~isempty(data.bkg)
    data.bkg = imread(data.bkg);
end

N_images = length(manual_labelling.labelled_frames);
%%% FIXME: This should come from the labelling code, although it will be
%%% hardcoded for two, maybe it can be expanded to more views in the
%%% future.
N_views = 2;
N_types = length(manual_labelling.labels);
N_classes = cell(1,N_types);
for i_types = 1:N_types
    N_classes{i_types} = length(manual_labelling.labels{i_types});
end

% Mask for selecting views.
image_size = [data.vid.Height data.vid.Width];
Imsk = [true(manual_labelling.split_line, image_size(2));false(image_size(1) - manual_labelling.split_line, image_size(2))];
% Linear indices for the image.
im_index = 1:(data.vid.Height*data.vid.Width);
Types = cell(1,N_types);
Classes = cell(1,N_types);
Angles = cell(1,N_types);
%% Initializing the classes:
for i_types = 1:N_types
    Angles{i_types} = cell(1,N_classes{i_types});
    for i_classes = 1:N_classes{i_types}
        if ~isempty(manual_labelling.labels{i_types}{i_classes})
            type = manual_labelling.labels{i_types}{i_classes}(1).type;
            class = manual_labelling.labels{i_types}{i_classes}(1).class;
            box_size = manual_labelling.labels{i_types}{i_classes}(1).box_size;
            N_points = length(manual_labelling.labels{i_types}{i_classes});
            
            % Checking for rotated samples:
            if options.rotate_samples
                if iscell(options.rotation_angles)
                    ang = options.rotation_angles{i_types}{i_classes};
                else
                    ang = options.rotation_angles;
                end
                
                if isempty(ang)
                    ang = 0;
                end
                Angles{i_types}{i_classes} = ang;
                N_ang = length(ang);
            end
            
            labelled_data.(type).(class).positive = cell(N_images,N_ang,N_views);
            labelled_data.(type).(class).negative = {uint8(zeros([box_size(:,1)' options.N_negative_data_per_frame N_images])) ...
                uint8(zeros([box_size(:,2)' options.N_negative_data_per_frame N_images]))};
            keep_neg.(type).(class) = true(N_images,N_views);
            labelled_data.(type).(class).box_size = box_size;
            labelled_data.(type).(class).N_points = N_points;
            manual_labelling.visibility{i_types}{i_classes} = logical(cell2mat(manual_labelling.visibility{i_types}{i_classes}'));
            manual_labelling.tracks{i_types}{i_classes} = cell2mat(manual_labelling.tracks{i_types}{i_classes});
            if options.correct_images
                P = manual_labelling.tracks{i_types}{i_classes};
                if manual_labelling.flip
                    P([1 3],:,:) = data.vid.Width - P([1 3],:,:) + 1;
                end
                Ptemp = [P([2 1],:)';P([4 3],:)'];
                Ptempw = warpPointCoordinates(Ptemp,data.inv_ind_warp_mapping,size(data.inv_ind_warp_mapping));
                Ptempw = reshape(Ptempw',[2 size(P,2) size(P,3)*2]);
                Ptempw = [Ptempw([2 1],:,1:size(P,3));Ptempw([2 1],:,size(P,3)+1:end)];
                if manual_labelling.flip
                    Ptempw([1 3],:,:) = data.vid.Width - Ptempw([1 3],:,:) + 1;
                end
                manual_labelling.tracks{i_types}{i_classes} = Ptempw;clear Ptempw Ptemp P
            end
        end
    end
    Classes{i_types} = fieldnames(labelled_data.(type))';
    Types{i_types} = type;
end
clear type class box_size

%% Looping the images and extracting the positive and negative samples:
for i_images = 1:N_images
    % Read image:
    [I_orig,I_corrected] = readMouseImage(data.vid, ...
        manual_labelling.labelled_frames(i_images), data.bkg, ...
        manual_labelling.flip, manual_labelling.scale,...
        data.ind_warp_mapping,size(data.ind_warp_mapping));
    
    if options.correct_images && ~isempty(data.ind_warp_mapping)
        I = I_corrected;
    else
        I = I_orig;
    end
    clear I_orig I_corrected
    
    % Window mode:
    switch options.negative_data_mode
        case 'mouse_window'
            % Creating the bw image to compute the centroid:
            Imouse = im2bw(medfilt2(I,[5 5]),graythresh(I));
            sum_mouse = sum(Imouse);
            st = find(sum_mouse>0,1,'first');
            fs = find(sum_mouse>0,1,'last');
            
            Ibw = false(image_size);
            Ibw(:,st:fs) = true;
        case 'whole_image'
            Ibw = true(size(I));
        otherwise
            error('Unknown option for options.negative_data_mode!');
    end
    
    % Loopin the views:
    for i_views = 1:N_views
        Imsk = ~Imsk;
        % Looping the labelling structure:
        for i_types = 1:N_types
            for i_classes = 1:N_classes{i_types}
                vis = manual_labelling.visibility{i_types}{i_classes}(:,i_images,i_views);
                if any(vis(:))
                    gt_loc = manual_labelling.tracks{i_types}{i_classes}([2 1]+(i_views-1)*N_views,:,i_images);
                    
                    % To avoid problems with cropping and rotating images,
                    % the samples are extracted with larger boxes which can
                    % later be cropped to the real size:
                    box_crop = ceil(labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).box_size(:,i_views) * sqrt(2));
                    Igt_loc = getWindowFromImage(I, gt_loc(:,vis),...
                        box_crop,options.allow_partial_views);
                    
                    % Getting positive data:
                    for i_angle = 1:length(Angles{i_types}{i_classes})
                        if Angles{i_types}{i_classes}(i_angle) == 0
                            Itemp = Igt_loc;
                        else
                            Itemp = imrotate(Igt_loc,Angles{i_types}{i_classes}(i_angle),'bicubic','loose');
                        end
                        Itemp = trimBoxes(Itemp,labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).box_size(:,i_views));
                        labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).positive{i_images, i_angle, i_views} = ...
                            Itemp;
                    end
                    clear Itmep;
                    % Getting negative data:
                    switch options.negative_data_mode
                        case 'mouse_window'
                            Ibw_lv = Ibw & Imsk;
                        case 'whole image'
                            error('Whole image not supported, implement!');
                        otherwise
                            error('Unknown option for options.negative_data_mode!');
                    end
                    
                    % Remove box indices as possible negative centers:
                    Ibw_lv = blackOutImageRegions(Ibw_lv, gt_loc, labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).box_size(:,i_views));
                    
                    % Extracting the negative data: To have an as general as
                    % possible set of negative data, every time a sample is
                    % extracted a bounding box around it is blacked out. But if
                    % this is not possible, examples are allowed to overlap each
                    % other.
                    ind_lv = im_index(Ibw_lv);
                    
                    N_neg = min(options.N_negative_data_per_frame,length(ind_lv));
                    
                    negative_data_lv = zeros(1,N_neg);
                    possible = Ibw_lv;
                    
                    counter = 1;
                    while counter <= N_neg
                        if ~isempty(ind_lv)
                            % Extracting index and blacking out region around it:
                            ind_w = ind_lv(ceil(rand*length(ind_lv)));
                            negative_data_lv(counter) = ind_w;
                            possible = blackOutImageRegions(possible, ind_w, labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).box_size(:,i_views));
                            counter = counter + 1;
                            
                        else
                            % Resetting ind_top
                            possible = Ibw_lv;
                        end
                    end
                    [Ineg,Jneg] = ind2sub(image_size,negative_data_lv);
                    labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).negative{i_views}(:,:,:,i_images) ...
                        = getWindowFromImage(I,[Ineg;Jneg],labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).box_size(:,i_views),options.allow_partial_views);
                else
                   keep_neg.(Types{i_types}).(Classes{i_types}{i_classes})(i_images,i_views) = false;
                end
            end
        end
    end
end

% Post processing: We know the maximum number of boxes to extract but we
% don't know how many will be extracted, due to some being potentially
% invisible. I've opted to use cell arrays and extract only visible
% samples, as that reduces memory usage. But now the positive samples need
% to be reorganized into a single matrix:
for i_types = 1:N_types
    for i_classes = 1:N_classes{i_types}
        temp = cell(1,N_views);
        for i_views = 1:N_views
            kp = keep_neg.(Types{i_types}).(Classes{i_types}{i_classes})(:,i_views);
            N = labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).negative{i_views}(:,:,:,kp);
            temp{i_views} = cat(3,labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).positive{:,:,i_views});
            labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).negative{i_views} = N(:,:,:);
        end
        labelled_data.(Types{i_types}).(Classes{i_types}{i_classes}).positive = temp;
    end
end
clear temp