% Locomouse Training
% This code uses the hand labelled data provided by Locomouse_Labelling to
% train image detectors for the chosen features. Detectors are trained
% using a linear Support Vector Machine (SVM). This code uses the LIBSVM
% library (http://www.csie.ntu.edu.tw/~cjlin/libsvm/index.html) but the
% MATLAB SVM tools from the statistical toolbox could potentially also be
% used. However, these have not been tested.
%
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org)
% Last Modified: 17/11/2014

%%% FIXME: Decide what to do with the histogram mapping of the mouse and
%%% how to calibrate that.

%% User defined parameters:
% I) Defining the dataset:
% A dataset is defined by a set of videos and the corresponding hand
% labelled data as provided by Locomouse_Labelling.
% 
% The LocoMouse_Labelling code follows a predefined naming scheme where if
% a video is named L7Y10_control1.avi then it expects by default the
% labelling file to be L7Y10_control1_labelling.mat.  If the dataset 
% follows this naming convention then only the video file needs to be 
% specified. Otherwise, it must be manually. 
%
% Information for the background and calibration files is stored inside 
% the labelling file. If no such information exists, the program reads the
% user provided values. If those do not exists, the program searches for
% files following the default naming convention (e.g. for the
% L7Y10_control1.avi video file, the default background and calibration 
% file names are respectivelly L7Y10_control1.png and
% L7Y10_control1_calibration.mat.
dataset.name = 'tutorial';

% Useful when data lies inside a main folder. All other paths can be 
% provided realtive to this one. To disable set to empty string or matrix. 
% dataset.path = '/media/winpart/Users/jrkf/My Documents/MATLAB/CNP/L7Y_dataset/'; 
dataset.path = '/media/winpart/Users/jrkf/My Documents/locomouse_hugo/';
% Training:
dataset.training_vid = {'E1_31_211_1_training_0.265_0.265_1_1_cut.avi'}; % Cell with the paths to the videos.
% MAT files with the hand labelled data. Leave empty for searching files
% with the default naming convention or manually specify a labelling file
% here.
dataset.training_labels = {''}; 

% Background files:
% Accepts path to an image, an image, an empty matrix 
% (if no background subtraction is needed) or the strings 'median' if it 
% is to be computed as the median image of the video (not recomended for 
% large videos!), or '' (empty string) if it is defined on the 
% labelling file.
dataset.bkg = {''}; 

% II) Training parameters:
% These are options of special ways in which the hand labelled data can be
% pre-processed. It requires the knowledge of the structure of the labelled
% data by the user.
%
% Example:
%
% On the default labelling structure for LocoMouse there are 'Point' type
% features, for the paws and snout, and a 'Line' type featuere for the
% Tail.
%
% The paws and snout are most of the time oriented along the corridor, so
% no there is no need to rotate the samples. The tail segments on the other
% hand can vary greatly in orientation. Since the training data might not
% contain all these orientations, it is best to rotate those samples to
% increase the variability. Setting up the parameters would look like:
%
% training_options.rotate_samples = true; -> Includes rotated samples.
% training_options.rotation_angles = {{0,0},{[-60 -30 0 30 60 90]}};
%
% Where angles are set in degrees.
%
% This assumes knowledge of the labelling sturcture so that 
% training_options.rotation_angles{1}{2} refers to the snout and
% training_options.rotation_angles{2}{1} refers to the tail.
%
% If the same angle range is to be used for all features, provide a single
% matrix (e.g. training_options.rotation_angles = [-30 0 30] applies those
% 3 rotation angles to all features.

% Boolean variable deciding wether to save partial results. Results are
% saved on dataset.path or pwd if dataset.path is empty.
training_options.save_cache = true;
% Boolean variable deciding wether to load cached data, if it exists.
training_options.load_cache = false; 
% Boolean variable deciding wether to train on orinal images or corrected
% (when available...).
training_options.correct_images = true;
% Boolean variables deciding which features to use rotated samples. If a
% single value is provided, the same is used for all features.
training_options.rotate_samples = true;
% List of angles to use for each feture, in degrees.
training_options.rotation_angles = {{0,[-45 0 45]},{[-60 -30 0 30 60 90]}};
% training_options.rotation_angles = {{0,0},{0}};
% Number of negative samples to extract per frame, per feature. It a single
% value is provided, the same value is used for all features.
training_options.N_negative_data_per_frame = 10;
% Allow samples to outside the image. Sometimes features are to close to
% the edge of the image, making the box go partially out of it. Use with
% caution.
training_options.allow_partial_views = true;
% Restricts the collection of negative data from a window around the mouse
% ('mouse_window') or allows collection on the whole image ('whole_image').
training_options.negative_data_mode = 'mouse_window';
% After training the detector with the random negative images, it can be
% evaluated on the whole images to identify other false positive regions
% and retrain accounting for that. Boolean value.
training_options.refine = true;
training_options.refine_which_detectors = {{false,false},{true}};

%% Extracting samples from labelled set:
% The input images are processed for training the detector. If desired, a
% warp is applied to the image to correct the mirror/camera distortion. It
% is also possible to load this images from a cache directory if they have
% already been processed before.

% 1) Extracting the hand annotated samples from the images:
% Data must be annotated with the LocoMouse_Labelling tool.
N_videos = length(dataset.training_vid);

% Setting up options that can have a single value for multiple videos:
single_value_data_options = {'calibration'};
training_data = cell(1,N_videos);

for i_videos = 1:N_videos
    [~,video_name,~] = fileparts(dataset.training_vid{i_videos});
    
    % Checking if the training data has been stored in cache:
    cache_file_name = fullfile(dataset.path,'cache',dataset.name,sprintf('%s_training_data.mat',video_name));
    if exist(cache_file_name,'file') && training_options.load_cache
        % Loading the data:
        training_data{i_videos} = load(cache_file_name,'-struct'); %%% FIXME: Integrate with the normal output that gets saved.
    else
        % Processing the data structure:
        [data, L] = processDataStructure(dataset, i_videos);
        
        % Collecting image boxes:
        TD = extractManualLabelling(data, L, training_options);
        if training_options.save_cache
            if ~exist(fullfile(dataset.path,'cache',dataset.name,'data'),'dir')
                mkdir(fullfile(dataset.path,'cache',dataset.name,'data'));
            end
            save(cache_file_name,'-struct','TD');
        end
        training_data{i_videos} = TD;clear TD;
    end
end

clear('cache_file_name','i_options data','L','options','single_value_data_options',...
    'N_single_value_option_set', 'opt_i', 'video_name','single_value_option_set',...
    'CAL','i_options','i_video','vid_is_char','vid_is_videoreader',...
    'i_videos');

%%
% 3) Training the initial detector: we train the initial detector with the
% image samples collected so far. The resulting detector will usually have
% a reasonable performance, but many false positives are expected. These
% can be elimineted by comparisson with hand labelled ground truth and an
% additional round of training.
% All labelling files should have the same structure:
model_types = fieldnames(training_data{1}); 
N_types = length(model_types);
N_views = 2;%%%FIXME: This should come from the data in some way.

for i_types = 1:N_types
    classes = fieldnames(training_data{1}.(model_types{i_types}));
    N_classes_type = length(classes);
    for i_classes = 1:N_classes_type
        for i_views = 1:N_views 
            DATA = [];
            LABELS = [];
            box_size = training_data{1}.(model_types{i_types}).(classes{i_classes}).box_size(:,i_views);
            N_points = training_data{1}.(model_types{i_types}).(classes{i_classes}).N_points;
            for i_videos = 1:N_videos
                % Concatenating the data from all the videos:
                positive_data = training_data{i_videos}.(model_types{i_types}).(classes{i_classes}).positive{i_views};
                negative_data = training_data{i_videos}.(model_types{i_types}).(classes{i_classes}).negative{i_views};
                
                DATA = [DATA reshape(positive_data,prod(box_size),[]) reshape(negative_data,prod(box_size),[])];
                LABELS = [LABELS;ones(size(positive_data,3),1);zeros(size(negative_data,3),1)];
            end
            DATA = DATA';
            
            if ~isempty(DATA)
                % Training with SVM:
                svm_model = svmtrain(LABELS, double(DATA), '-q -s 0 -t 0'); % quiet, C-SVM, linear kernel
                w = reshape(sum(svm_model.SVs' * svm_model.sv_coef,2),box_size');
                rho = svm_model.rho;
                
                % CAUTION: Inverting the order of w is done to integrate with
                % the conv2 function. Keep this in mind when changing the
                % code...
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).w{i_views} = w(end:-1:1,end:-1:1);
                if isempty(rho)
                    rho = 0;
                end
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).rho{i_views} = rho;
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).svm_model{i_views} = svm_model;
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).box_size{i_views} = box_size;
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).N_points = N_points;
                
                
            else
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).w{i_views} = [];
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).rho{i_views} = [];
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).svm_model{i_views} = [];
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).box_size{i_views} = [];
                model.(lower(model_types{i_types})).(lower(classes{i_classes})).N_points = N_points;
            end
            
        end
    end
end
clear DATA LABELS rho svm_model w box_size N_points

%%
% 4) Evaluating on full training images and extracting false positives
% and false negatives for refinement. This stage is optional and is
% controlled by training_options.refine_detectors.
if training_options.refine
    false_positives = cell(1,N_videos);
    model_coarse = model;clear model
    
    % Searching for false positive and false negative detections on each
    % video:
    for i_videos = 1:N_videos
        [data,L] = processDataStructure(dataset,i_videos);
        [false_positives{i_videos}, ~] = evaluateDetectors(data, ...
            L, model_coarse, training_options);
    end
    
    % Retraining the models:
    for i_types = 1:N_types
        classes = fieldnames(training_data{1}.(model_types{i_types}));
        N_classes_type = length(classes);
        for i_classes = 1:N_classes_type
            for i_views = 1:N_views
                if isempty(false_positives{i_videos}{i_types}{i_classes}{i_views}) || ~ training_options.refine_which_detectors{i_types}{i_classes}
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).w{i_views} = ...
                        model_coarse.(lower(model_types{i_types})).(lower(classes{i_classes})).w{i_views};
                    
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).rho{i_views} = ...
                        model_coarse.(lower(model_types{i_types})).(lower(classes{i_classes})).rho{i_views};
                    
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).svm_model{i_views} = ...
                        model_coarse.(lower(model_types{i_types})).(lower(classes{i_classes})).svm_model{i_views};
                    
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).box_size{i_views} = ...
                        model_coarse.(lower(model_types{i_types})).(lower(classes{i_classes})).box_size{i_views};
                    
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).N_points = ...
                        model_coarse.(lower(model_types{i_types})).(lower(classes{i_classes})).N_points;
                    
                else
                DATA = [];
                LABELS = [];
                box_size = training_data{1}.(model_types{i_types}).(classes{i_classes}).box_size(:,i_views);
                N_points = training_data{1}.(model_types{i_types}).(classes{i_classes}).N_points;

                % Extracting the ground truth data:
                for i_videos = 1:N_videos
                    % Concatenating the data from all the videos:
                    positive_data = training_data{i_videos}.(model_types{i_types}).(classes{i_classes}).positive{i_views};
                    negative_data = training_data{i_videos}.(model_types{i_types}).(classes{i_classes}).negative{i_views};
                    DATA = [DATA reshape(positive_data,prod(box_size),[]) reshape(negative_data,prod(box_size),[])];
                    LABELS = [LABELS;ones(size(positive_data,3),1);zeros(size(negative_data,3),1)];
                end
                
                DATA = [DATA reshape(false_positives{i_videos}{i_types}{i_classes}{i_views},...
                    prod(box_size),[])]';
                LABELS = [LABELS;zeros(size(false_positives{i_videos}{i_types}{i_classes}{i_views},3),1)];
                
                if ~isempty(DATA)
                    % Training with SVM:
                    svm_model = svmtrain(LABELS, double(DATA), '-q -s 0 -t 0'); % quiet, C-SVM, linear kernel
                    w = reshape(sum(svm_model.SVs' * svm_model.sv_coef,2),box_size');
                    rho = svm_model.rho;
                    
                    % CAUTION: Inverting the order of w is done to integrate with
                    % the conv2 function. Keep this in mind when changing the
                    % code...
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).w{i_views} = w(end:-1:1,end:-1:1);
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).rho{i_views} = rho;
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).svm_model{i_views} = svm_model;
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).box_size{i_views} = box_size;
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).N_points = N_points;
                    
                else
                    
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).w{i_views} = [];
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).rho{i_views} = [];
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).svm_model{i_views} = [];
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).box_size{i_views} = [];
                    model.(lower(model_types{i_types})).(lower(classes{i_classes})).N_points = [];
                end
                
                
                end
            end
        end
    end
end
clear box_size classes data DATA dataset false_negatives false_positives...
    i_classes i_types i_videos i_views L LABELS model_types N_classes_type...
    N_types N_videos N_views negative_data positive_data ref rho svm_model ...
    training_data training_options w N_points