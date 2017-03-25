%--------------------------------------------------------------------------
%
% CreateBoundingBoxOptions
% (Dennis Eckmeier, DE, 03.11.2015)
% 
% In order to implement different computeMouseBox functions and weighting settings
% as options for the LocoMouse_tracker GUI:
% 
% 1. copy the existing BoundingBoxOptions.mat and CreateBoundingBoxOptions.m
%    rename the copy by adding the reversed(!) date.
%    example: BoundingBoxOptions_2015_11_16.mat for 16.11.2015
% 
% 2. create the function you want to implement in the path indicated by
    [p_boundingBoxFunctions, ~, ~]=fileparts(which('computeMouseBox'));   
% 3. copy and paste these lines to the end of this file and un-comment them:
    %     %% <OPTION DESCRIPTION AND AUTHOR INITIALS>
    %     tON = tON+1;
    %     option(tON) = {'<NAME>'};
    %     cmd_string(tON) = {'<COMMAND STRING>'};
%  
% 4. Replace parts framed by <> example:
    %     %% [3] Treadmill setup (Dana)
    %     tON = tON+1; % don't edit
    %     option(tON) = {'Treadmill DD V1'};
    %     cmd_string(tON) = {'[bounding_box(:,:,1), cc, I_crop] =  computeMouseBox_TM_DD_V1(Iaux,split_line);'};
    %     weight_settings{tON} = [1,1,0.6;... % Front Right
    %                             0,1,0.6;... % Hind Right
    %                             1,0,0.6;... % Front Left
    %                             0,0,0.6];   % Hind Left
%    
% 5. Run this file.    

%% DON'T EDIT THIS SECTION
    tON=0;
     % default weight settings:
     weight_defaults =   [1,1,0.6;... % Front Right
                          0,1,0.6;... % Hind Right
                          1,0,0.6;... % Front Left
                          0,0,0.6;... % Hind Left
                          1,0.5,0.20];% snout

%% [1] Over ground setup (original)
    tON = tON+1; % don't edit
    ComputeMouseBox_option(tON) = {'Over Ground [Ana]'}; 
    ComputeMouseBox_cmd_string(tON) = {'[bounding_box(:,:,1), cc, I_crop] =  computeMouseBox(Iaux,split_line);'};  
    WeightSettings{tON} = weight_defaults;
    
%% [1a] Ladder setup (original)
    tON = tON+1; % don't edit
    ComputeMouseBox_option(tON) = {'Ladder [Goncalo]'};
    ComputeMouseBox_cmd_string(tON) = {'[bounding_box(:,:,1), cc, I_crop] =  computeMouseBox(Iaux,split_line);'};  
    
    WeightSettings{tON} =   [1,     1,      0.6;... % Front Right
                             0.45,  1,      0.3;... % Hind Right
                             1,     0,      0.6;... % Front Left
                             0.45,  0,      0.3;... % Hind Left
                             1,     0.5,    0.20];  % snout
                         
%% [2] Treadmill setup (Dana) [rewritten by DE]
    tON = tON+1; % don't edit
    ComputeMouseBox_option(tON) = {'Treadmill [Dana] (DE)'};
    ComputeMouseBox_cmd_string(tON) = {'[bounding_box(:,:,1), cc, I_crop] =  computeMouseBox_TM_DE_V1(Iaux,split_line);'};    
    WeightSettings{tON} = weight_defaults;

%% [3] Headfixed (hard coded) (Hugo)
    tON = tON+1; % don't edit
    ParameterSet ='3'; % 
    ComputeMouseBox_option(tON) = {'Headfixed (set 3) [Hugo]'};
    ComputeMouseBox_cmd_string(tON) = {['[bounding_box(:,:,1), cc, I_crop] =  computeMouseBox_HF(Iaux,split_line,',ParameterSet,');']};    
	WeightSettings{tON} =  [0.9,	0.75,	0.3,	0.6,	1.0,	0.4,	1.0   ; ...     % FR paw
                            0.5,    0.75,	0.3,	0.2,	0.85,	0.3,	1.0   ; ...     % HR paw
                            0.9,    0.25,   0.3,	0.6,	1.0,	0.0,	0.6   ; ...     % FL paw
                            0.5,	0.25,   0.3,	0.2,	0.85,	0.0,	0.7   ; ...     % HL paw
                            1,      0.5,    0.20,	NaN,	NaN,	NaN,	NaN];           % snout

%% C++ Code:
% C++ code is run by passing it a 'c++' string instead of a bounding box
% command. This is checked by the tracking code and the c++ executable is
% run. FIXME: Implement this properly in the GUI.
% 
% ComputeMouseBox_cmd_string{tON} should be
% {{'c++','cpp_config_file_name.yml'}}
%% [4] C++ Overground
tON = tON+1; % don't edit
ComputeMouseBox_option(tON) = {'C++ Overground'}; 
ComputeMouseBox_cmd_string(tON) = {{'c++','config.yml'}};  

%% [5] C++ Treadmill
tON = tON+1; % don't edit
ComputeMouseBox_option(tON) = {'C++ Treadmill'}; 
ComputeMouseBox_cmd_string(tON) = {{'c++','config_tm.yml'}};

%% [6] C++ Head Fixed
tON = tON+1; % don't edit
ComputeMouseBox_option(tON) = {'C++ Head Fixed'}; 
ComputeMouseBox_cmd_string(tON) = {{'c++','config_hf.yml'}};

%% [7] C++ Ladder
tON = tON+1; % don't edit
ComputeMouseBox_option(tON) = {'C++ Ladder'}; 
ComputeMouseBox_cmd_string(tON) = {{'c++','config.yml'}};
           
%% [8] C++ Rotary Treadmill
tON = tON+1; % don't edit
ComputeMouseBox_option(tON) = {'C++ Rotary Treadmill'}; 
ComputeMouseBox_cmd_string(tON) = {{'c++','config_rtm.yml'}};


%%
save([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'ComputeMouseBox_option','ComputeMouseBox_cmd_string','WeightSettings')
clear('ComputeMouseBox_option','ComputeMouseBox_cmd_string','WeightSettings','tON','ParameterSet','weight_defaults','p_boundingBoxFunctions');
