function [false_positives, false_negatives] = evaluateDetectors(data, manual_labelling, model, options)
% evaluateDetectors     Check for true/false positives and true/false
% negatives for a set of detectors given by model on a dataset described by
% data when measured against labelled data provided by training_data. See
% LocoMouse_Labelling and LocoMouse_Training_script for more details.
%
% INPUT: See LocoMouse_Training_script for details on what each structure
% is.
%
% OUTPUT: 
%
% false_positives: A cell array with the same structure as the labels
% containing the false positive samples for each class.
%
% false_negatives: A cell array with the same structure as the labels
% containing the false negative samples for each class.
%
% For the LocoMouse system the false_negative data is not used in practice,
% as any false negative sample is already part of the initially hand
% labelled samples.
% 
% Disclaimer: Although mostly generic, this function has specific
% assumptions to work with the LocoMouse system.
%
% Author: Joao Renato Kavamoto Fayad (joaofayad@gmail.com) 
% Last Modified: 13/11/2014

%% Pre-processing the data:
N_views = 2; %% FIXME: Hardcoded for LocoMouse...
Types = fieldnames(model);
N_types = length(Types);

Classes = cell(1,N_types);
N_classes = cell(1,N_types);

for i_types = 1:N_types
    Classes{i_types} = fieldnames(model.(Types{i_types}));
    N_classes{i_types} = length(Classes{i_types});
end

false_positives = cell(1,N_types);
false_negatives = cell(1,N_types);

for i_types = 1:N_types
    false_positives{i_types} = cell(1,N_classes{i_types});
    false_negatives{i_types} = cell(1,N_classes{i_types});
    
    for i_classes = 1:N_classes{i_types}
   
        false_positives{i_types}{i_classes} = cell(1,N_views);
        false_negatives{i_types}{i_classes} = cell(1,N_views);
        
        if ~isempty(manual_labelling.labels{i_types}{i_classes})
            % Concatenating tracks per class:
            manual_labelling.visibility{i_types}{i_classes} = logical(cell2mat(manual_labelling.visibility{i_types}{i_classes}'));
            manual_labelling.tracks{i_types}{i_classes} = cell2mat(manual_labelling.tracks{i_types}{i_classes});
            
            % Checking if the labels need to be corrected for the image
            % distortion:
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
end
clear type class box_size

%% Analysing each frame:
% View image indices (precomputing):
size_im = cell(1,2);
size_im{1} = [data.vid.Height - manual_labelling.split_line data.vid.Width];
size_im{2} = [manual_labelling.split_line data.vid.Width];
ind_im = cellfun(@(x)((1:prod(x))'),size_im,'un',0);

N_frames = length(manual_labelling.labelled_frames);
counter = 0;
for i_lf = 1:N_frames
    i_images = manual_labelling.labelled_frames(i_lf);
    % Auxiliary variables:
    I_cell = cell(2,1);
    
    % Reading the image:
    [I_orig,I_dist] = readMouseImage(data.vid,i_images,data.bkg,...
        manual_labelling.flip,manual_labelling.scale,...
        data.ind_warp_mapping,size(data.ind_warp_mapping));
    
    if options.correct_images && ~isempty(data.ind_warp_mapping)
        I = I_dist;
    else
        I = I_orig;
    end
    clear I_dist I_orig
    
    % Splitting the image:
    [I_cell{[2 1]}] = splitImage(I,manual_labelling.split_line);
    
    % Looping the models:
    for i_types = 1:N_types
        Classes = fieldnames(model.(Types{i_types}));
        N_classes_type = length(Classes);
        
        for i_classes = 1:N_classes_type
            
            for i_views = 1:N_views
                % Reading Ground truth data:
                gt_loc = manual_labelling.tracks{i_types}{i_classes}([2 1]+(i_views-1)*N_views,:,i_lf);
                vis = manual_labelling.visibility{i_types}{i_classes}(:,:,i_views);
                
%                 switch Types{i_types}
%                     case 'point'
                        % The detection maps are compared by performing NMS on the
                        % resulting detection fields. For the side view, due to
                        % feature overlap, the greedy NMS version is used.
                        if ~isempty(model.(Types{i_types}).(Classes{i_classes}).w{i_views})
                            % Filtering with the detector and removing
                            % bias:
                            m  = model.(Types{i_types}).(Classes{i_classes});
                            w = m.w{i_views};
                            box_size = size(w);
                            scores = conv2(double(I_cell{i_views}),w,'same')...
                                -m.rho{i_views};
                            detections = scores(:) > 0;
                            scores = scores(detections); % Detection scores.
                            detections = ind_im{i_views}(detections); % Scalar detection locations (on sub image);
                            
                            % NMS:
                            [row_ind, col_ind] = ind2sub(size_im{i_views},detections);
                            switch i_views 
                                case 1
                                    % Bottom:
                                    [detections_2d, ~] = nmsMax([row_ind col_ind],...
                                        box_size, scores','center');
                                    gt_loc(1,:) = gt_loc(1,:) - manual_labelling.split_line;
                                    T = 0.5;% Bottom view objects do not overlap, 0.5 is ok.
                                case 2
                                    % Side:
                                    [detections_2d, ~] = peakClustering([row_ind col_ind],...
                                        box_size, scores','center','max');
                                    T = 0.30;% Side view is more complicated, allow less overlap here.
                            end
                            
                            % Evaluate detections by comparing them with
                            % the ground truth data:
                            [detection_matches, ~] = evaluateDetections(detections_2d', gt_loc, box_size', T);
                            
                            % If a point is occluded I won't decide if the detection is
                            % successful or not, as occlusion can be partial and maybe
                            % the algorithm is indeed picking up on something. Or it
                            % might be a coincidence...
                            %
                            % Extracting the false positives:
                            fp_matches = all(~detection_matches,2);
                            counter = counter + 1;
                            false_positives{i_types}{i_classes}{i_views} = cat(3,...
                                false_positives{i_types}{i_classes}{i_views},...
                                getWindowFromImage(I_cell{i_views},...
                                detections_2d(fp_matches,:)',...
                                box_size,options.allow_partial_views));
%                            
%                             fn_matches = all(~detection_matches,1);
%                             false_negatives{i_types}{i_classes}{i_views} = cat(3,...
%                                 false_negatives{i_types}{i_classes}{i_views},...
%                                 getWindowFromImage(I_cell{i_views},...
%                                 detections_2d(fn_matches,:)',...
%                                 box_size,options.allow_partial_views));
                        end
                       
%                     case 'line'
%                         % For the line the discrete hand clicked notations are not
%                         % a good representation of the line. Instead we join all
%                         % the ground truth boxes together to create a line, and
%                         % compare it to the lines we obtain on the detection.
%                 end
            end
        end
    end
end