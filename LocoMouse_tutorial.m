% LocoMouse v2.0 - Short tutorial on how to use the code
%
% Please download the relevant files from: 
%
% And place them within the LocoMouse folder.
%
% This tutorial file is better run in segments, so that each module can be
% explored. For each module, there will be inputs from the LocoMouse system
% provided, so that the user can work with acutal data.
%
% Author: Joao Fayad
% Last Modified: 17/11/2014


%% 0) Add code to MATLAB path
[tutorial_file_path,~,~] = fileparts([mfilename('fullpath'),'*.m']);

addpath(genpath(tutorial_file_path));

% Creating a directory to output some files:
mkdir(fullfile(tutorial_file_path,'tutorial_output'));

%% 1) Calibration
% Calibration of the system is done by tracking a white object over a black
% background and establishing correspondences between the side and bottom
% view.

LocoMouse_Calibration

% Try adding the video file, and run the automatic correspondence
% detection. See how correspondences can be manually edited or discarded.
% Save a calibration file for future use (not needed to complete the
% tutorial).

%% 2) Labelling feature points:
% This GUI allows the user to load a different number of videos and to
% manually anotate the location of features.
LocoMouse_Labelling

% Try adding the video file... and see how the GUI automatically loads the
% manually labelled files and determines the background and calibration, so
% long as the files follow the predefined naming scheme. Save a labelling
% file (not needed to complete the tutorial).

%% 3) Learning the Model
% This script uses the hand labelled data to train SVM detectors for the
% tail, snout and paws. However the script must be manually configured. See
% the script for more details about the available options. Don't forget to
% save the model for future use, with the struct option (e.g.
% save('model.mat','model','-struct');)
LocoMouse_Training_script

%% 4) Tracking
% The tracker GUI allows the user to add many files and track them with the
% trained model. The user needs to specify a model, a function to determine
% the background file (e.g. the LocoMouse system names the background files
% as a function of the session and animal id), a function to create the
% output folder (e.g. the LocoMouse system saves the output on a folder
% structure that depends on the name of animal), and calibration file. 
LocoMouse_Tracker

% Optionally, the code can be run from the command line as such:
model = load('model_LocoMouse_paper.mat');
load('C:\Users\Dennis\Documents\GitHub\LocoMouse_Dev\LocoMouse_Tracker\calibration_files\IDX_pen.mat');
data.vid = 'C:\Users\Dennis\Documents\LocoMouse_testing\G6AE1_98_28_1_control_S1T1.avi';
data.bkg = 'C:\Users\Dennis\Documents\LocoMouse_testing\G6AE1_98_28_1_control_S1T.png';
data.ind_warp_mapping = IDX;
data.inv_ind_warp_mapping = IDX_inv;
data.split_line = split_line; % in older versions called mirror_line;
% data.flip = 0;
[final_tracks,tracks_tail,OcclusionGrid,bounding_box,flip,data,debug] = MTF_rawdata(data, model);
[final_tracks,tracks_tail] = convertTracksToUnconstrainedView(final_tracks,tracks_tail,size(imread(data.bkg)),data.ind_warp_mapping,data.flip,data.scale);

%% 6) Displaying results:
% Results are displayed by calling LocoMouse_DisplayTracks GUI with the
% following inputs:
f_l = 'B6C3_68_0_1_AmbLight_S3T5_0';
f_s = 'B6C3_68_0_1_AmbLight_S3T';
T = load(['C:\Users\Dennis\Documents\LocoMouse_testing\data\',f_l,'.mat']);
T.data.vid = ['C:\Users\Dennis\Documents\DATA_DarkvsLight_Overground\2015_11_12_S3\',f_l,'.avi'];
T.data.bkg = ['C:\Users\Dennis\Documents\DATA_DarkvsLight_Overground\2015_11_12_S3\',f_s,'.png'];
LocoMouse_DisplayTracks({T.data,T.final_tracks,T.tracks_tail,{T.OcclusionGrid,T.bounding_box}});
model=load('C:\Users\Dennis\Documents\GitHub\LocoMouse_Dev\LocoMouse_Tracker\model_files\model_01112013_fields.mat');
T.model = model; clear model

%% 7) Debugging the tracking algorithm:
% Finally, one can check the result of filtering the image with the
% detectors, which points are kep as candidates after NMS and how they have
% been linked by the multi-target tracking algorithm by using the debug GUI
% as follows:
debugTracker({T.data,T.model,T.final_tracks,T.tracks_tail,T.OcclusionGrid,T.bounding_box,T.debug});

% This allows the user to identify potential problems with tracking, and
% which parameters/modules need to be changed.