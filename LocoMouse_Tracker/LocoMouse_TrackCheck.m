function varargout = LocoMouse_TrackCheck(varargin)
% LOCOMOUSE_TRACKCHECK MATLAB code for LocoMouse_TrackCheck.fig
%      LOCOMOUSE_TRACKCHECK, by itself, creates a new LOCOMOUSE_TRACKCHECK or raises the existing
%      singleton*.
%
%      H = LOCOMOUSE_TRACKCHECK returns the handle to a new LOCOMOUSE_TRACKCHECK or the handle to
%      the existing singleton*.
%
%      LOCOMOUSE_TRACKCHECK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LOCOMOUSE_TRACKCHECK.M with the given input arguments.
%
%      LOCOMOUSE_TRACKCHECK('Property','Value',...) creates a new LOCOMOUSE_TRACKCHECK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LocoMouse_TrackCheck_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LocoMouse_TrackCheck_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LocoMouse_TrackCheck

% Last Modified by GUIDE v2.5 14-Sep-2016 09:59:18

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @LocoMouse_TrackCheck_OpeningFcn, ...
        'gui_OutputFcn',  @LocoMouse_TrackCheck_OutputFcn, ...
        'gui_LayoutFcn',  [] , ...
        'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end


%% OPENING, CLOSING, GUI REFRESHING, etc

% --- Executes just before LocoMouse_TrackCheck is made visible.
function LocoMouse_TrackCheck_OpeningFcn(hObject, ~, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to LocoMouse_TrackCheck (see VARARGIN)

    % Choose default command line output for LocoMouse_TrackCheck
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);
    
    [handles.root_path,~,~] = fileparts(which('LocoMouse_TrackCheck'));

%       -- Setting up the supported image and video formats --

    % This code relies on imread and VideoReader.
    % Builing the lists to use when browsing for files:
    sup_im_files = imformats;
    extensions = [sup_im_files(:).ext];
    descriptions = cell(1,length(extensions));
    i_desc = 1;
    for i_temp = 1:length(sup_im_files)
        for i_d = 1:length(sup_im_files(i_temp).ext)
            descriptions{i_desc} = sup_im_files(i_temp).description;
            i_desc = i_desc+1;
        end
    end
    clear i_desc;
    
    handles.N_supported_im_files = length(extensions)+1;
    handles.supported_im_files = cell(handles.N_supported_im_files,2);
    handles.supported_im_files(2:end,1) = cellfun(@(x)(['*.',x]),extensions,'un',false)';
    handles.supported_im_files(2:end,2) = descriptions';

    % Initialising supported video files:
    sup_files = VideoReader.getFileFormats;
    handles.N_supported_files = size(sup_files,2)+1;
    handles.supported_files = cell(handles.N_supported_files,2);
    handles.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
    handles.supported_files(2:end,2) = {sup_files(:).Description};
    handles.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_files(2:end,1)','un',false));
    handles.supported_files{1,2} = 'All supported video files';

    % Reading background parsing modes:
    bkg_list = rdir(fullfile(handles.root_path,'background_parse_functions','*.m'),'',fullfile(handles.root_path,['background_parse_functions' filesep]) );
    bkg_list = strrep({bkg_list(:).name},'.m','');
    if isempty(bkg_list)
        bkg_list = {''};
    end
    set(handles.popupmenu_background_mode,'String',bkg_list);clear bkg_list;

    % Reading output parsing modes:
    output_list = rdir(fullfile(handles.root_path,'output_parse_functions','*.m'),'',fullfile(handles.root_path,['output_parse_functions' filesep]));
    output_list = strrep({output_list(:).name},'.m','');
    if isempty(output_list)
       output_list = {''}; 
    end
    set(handles.popupmenu_output_mode,'String',output_list);clear output_list
    
    % Reading model files:
    model_list = rdir(fullfile(handles.root_path,'model_files','*.mat'),'',fullfile(handles.root_path,['model_files' filesep]));
    model_list = strrep({model_list(:).name},'.mat','');
    if isempty(model_list)
       model_list = {' '}; 
    end
    set(handles.popupmenu_model,'String',model_list);clear model_list
    
    % FIXME: Adjust this on GUIDE on a screen with larger resolution.
    set(handles.popupmenu_background,'Units','normalized');
    P = get(handles.popupmenu_distortion_correction_files,'Position');
    set(handles.popupmenu_background,'Position',[P(1) 0.35 P(3:end)]);
    set(handles.popupmenu_background,'Enable','on');


%   -- Initializing objects     --
    set(handles.popupmenu_background,'String',{'No background image.'});
    set(handles.popupmenu_distortion_correction_files,'String',{'No correction file.'});    

    % Default class and label names: 
    % ------------- Parameters used in the locomouse tracker ------------------
    default_feature_names = {'Front Right Paw','Hind Right Paw','Front Left Paw','Hind Left Paw','Snout','Tail'};
    default_class_names = {'Paw','Paw','Paw','Paw','Snout','Tail'};
    default_feature_type = {'Point','Point','Point','Point','Point','Line'};
    default_feature_boxes = {[30 20;30 30],[30 20;30 30],[30 20;30 30],[30 20;30 30],[30 30;30 30],[30 30;30 30]};
    default_number_of_points = {1,1,1,1,1,15};
    tail_col = summer(16);
    default_feature_colors = {[1 0 0],[1 0 1],[0 0 1],[0 1 1],[1 0.6941 0.3922],tail_col(end:-1:1,:)};
    
    % default_feature_marker = {'.','.','.','.','.','.'};

    % userdata.labels = struct('type',default_feature_type, ...
    %     'class',default_class_names,...
    %     'name', default_feature_names,...
    %     'box_size',cat(1,default_feature_boxes),...
    %     'N_points',default_number_of_points);    


    % Creating the type and class structure from the default types:
    userdata.types = unique(default_feature_type,'stable');
    N_types = length(userdata.types);

    userdata.classes = cell(1,N_types);
    userdata.features = cell(1,N_types);
    userdata.labels = cell(1,N_types);

    % Initializing the figure (must be done before the plot handles):
    handles.image = imshow([],'Parent',handles.axes_frame);
    set(handles.image,'CData',[]);
    set(handles.axes_frame,'Clim',[0 255]);
    handles.image_size = size([]);

    % Creating the label tree structure:
    for i_type = 1:N_types
        match_type = strcmpi(userdata.types{i_type},default_feature_type);
        userdata.classes{i_type} = unique(default_class_names(match_type),'stable');

        N_classes_type = length(userdata.classes{i_type});
        userdata.features{i_type} =  cell(1,N_classes_type);
        handles.N_features{i_type} = cell(1,N_classes_type);
        userdata.labels{i_type} = cell(1,N_classes_type);
        userdata.plot_handles.track{i_type} = cell(1,N_classes_type);
        userdata.plot_handles.LM_track{i_type} = cell(1,N_classes_type);

        for i_class = 1:N_classes_type
            match_name = strcmpi(userdata.classes{i_type}{i_class},default_class_names);

            userdata.features{i_type}{i_class} = unique(default_feature_names(match_name),'stable');

            N_features_class_type = length(userdata.features{i_type}{i_class});

            color = default_feature_colors(match_name);

            userdata.labels{i_type}{i_class} = struct('type',default_feature_type(match_name), ...
                'class',default_class_names(match_name),...
                'name', default_feature_names(match_name),...
                'box_size',cat(1,default_feature_boxes(match_name)),...
                'N_points',default_number_of_points(match_name));

            % Initializing the plot handles for this type and class:
            userdata.plot_handles.track{i_type}{i_class} = cell(1,N_features_class_type); 
            userdata.plot_handles.LM_track{i_type}{i_class} = cell(1,N_features_class_type); 
            for i_features = 1:N_features_class_type
                userdata.plot_handles.track{i_type}{i_class}{i_features} = ...
                    plotHandles(userdata.labels{i_type}{i_class}(i_features).N_points,...
                    color{i_features});
                
                userdata.plot_handles.LM_track{i_type}{i_class}{i_features} = ...
                    plotHandles(userdata.labels{i_type}{i_class}(i_features).N_points,...
                    color{i_features});
            end
        end
    end
    clear color

    % Initializing user data:
    userdata.data = [];

    % Initializing the split line:
    handles.split_line = line(0,0,'Linestyle','-','Linewidth',1,'Visible','off','Color','w');

    % Initializing the box size:
%     set([handles.edit_h_bottom handles.edit_w_bottom handles.edit_h_side handles.edit_w_side],{'String'},...
%         cellfun(@(x)(num2str(x)),num2cell(userdata.labels{1}{1}(1).box_size(:)),'un',0));

    % Initializing the slider:
    set(handles.slider_frame,'Min',1);
    set(handles.slider_frame,'Max',100); % Any value just so it looks like something.
    set(handles.slider_frame,'Value',1);

    % Initializing the speed slider:
    set(handles.slider_speed,'Min',1);
    set(handles.slider_speed,'Max',90);
    set(handles.slider_speed,'SliderStep',[5/60 0.10]);
    set(handles.slider_speed,'Value',30);
    
    % Initializing the data:
    set(handles.figure1,'userdata',userdata);
    % Disable the structures that depend on there being videos available:
    changeGUIActiveState(handles);

    resetGUI(handles);
    handles.latest_path = pwd;
    
    % Assigning the click function to the window:
    set(handles.image,'ButtonDownFcn',{@axes_frame_ButtonDownFcn,handles});

    % Checking if data has been saved or not:
    handles.is_data_saved = true;

    % Getting active handles to disable while busy:
    handles.silenced_handles = findobj(handles.figure1,'Enable','on');
    
    % UIWAIT makes LocoMouse_TrackCheck wait for user response (see UIRESUME)
    guidata(hObject,handles)
    % uiwait(handles.figure1);
    
    % Loading latest settings
    [LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
    LMT_path = [LMT_path filesep 'GUI_Settings'];
    if exist(LMT_path,'dir')==7
        if exist([LMT_path filesep 'GUI_Recovery_Settings.mat'],'file') == 2
            LoadSettings_Callback([], [], handles, 'GUI_Recovery_Settings.mat')
        end
    end
    
    
    
end
 
% --- Outputs from this function are returned to the command line.
function varargout = LocoMouse_TrackCheck_OutputFcn(hObject, ~, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    % uiwait(handles.figure1);
    % if nargout > 0
    %     varargout{1} = rmfield(get(handles.figure1,'UserData'),'current_frame');
    % end
    % delete(handles.figure1);
end 

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

end
%key press with focus on figure1 and none of its controls.

% --- Executes when user attempts to close figure1.

function figure1_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: delete(hObject) closes the figure
    handles = guidata(gcbo);
    SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat') 
    delete(gcbo)
end

% --- Re-renders the whole GUI. Useful when switching between videos.
function handles = resetGUI(handles)
    % Check if there is any video selected, if so display first image:
    % Getting the video ID on the list:
    [userdata,video_id] = getGUIStatus(handles);
    if ~isempty(get(handles.listbox_files,'String'))

        % Updating the image size:
        set(handles.axes_frame,'Units','normalized');
        set(handles.axes_frame,'Xlim',[0.5 userdata.data(video_id).vid.Width+0.5]);
        set(handles.axes_frame,'Ylim',[0.5 userdata.data(video_id).vid.Height+0.5]);
        if userdata.data(video_id).UseLimitedWindow && any(size(userdata.data(video_id).LimitedWindow_X) == 2)
            try
            X_data = [1 max(userdata.data(video_id).LimitedWindow_X(:,2)-userdata.data(video_id).LimitedWindow_X(:,1))];
            catch t_err
                disp('Limited View Window Error');
            end
        else
            X_data = [1 userdata.data(video_id).vid.Width];
        end
        set(handles.image,'Xdata',X_data,'Ydata',[1 userdata.data(video_id).vid.Height]);
        totalFrames = int16(userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate);
        if userdata.data(video_id).current_frame <1 || userdata.data(video_id).current_frame > totalFrames
            userdata.data(video_id).current_frame = 1;
        end
        
        % Updating the vertical flip:
        set(handles.checkbox_vertical_flip,'Value',userdata.data(video_id).flip);

        % Updating the split line:
        if isnan(userdata.data(video_id).split_line)
            new_split_line = round(userdata.data(video_id).vid.Height/2);
            userdata.data(video_id).split_line = new_split_line;
            tWidth = userdata.data(video_id).vid.Width;
            set(handles.split_line ,'Xdata',[1 tWidth],'Ydata',[new_split_line new_split_line],'Visible','on');
        else
            if  userdata.data(video_id).UseLimitedWindow && ~isempty(userdata.data(video_id).LimitedWindow_X)
                
                tWidth = diff(userdata.data(video_id).LimitedWindow_X(userdata.data(video_id).current_frame,:));
            else
                tWidth = userdata.data(video_id).vid.Width;
            end
            set(handles.split_line ,'Xdata',[1 tWidth]);
        end


        % Check if there is background image to subtract:
        set(handles.popupmenu_background,'Value',userdata.data(video_id).background_popup_id);

        if userdata.data(video_id).background_popup_id == 1
            set(handles.checkbox_display_background,'Enable','off');
        else
            if isempty(userdata.data(video_id).bkg)
                set(handles.checkbox_display_background,'Value',1);
            else
                set(handles.checkbox_display_background,'Value',0);
            end
            set(handles.checkbox_display_background,'Enable','on');
        end

        % Checking the distortion options:
        set(handles.popupmenu_distortion_correction_files,'Value',userdata.data(video_id).calibration_popup_id);
        if userdata.data(video_id).calibration_popup_id == 1
            set([handles.radiobutton_corrected handles.radiobutton_original],'Enable','off');
        else
            if isempty(userdata.data(video_id).ind_warp_mapping) 
               set([handles.radiobutton_corrected handles.radiobutton_original],'Enable','off');
               fprintf('The selected calibration file contains no information about the mapping!\n');
            else
                set([handles.radiobutton_corrected handles.radiobutton_original],'Enable','on');
            end
        end
        % Updating the split line visibility:
        if get(handles.checkbox_display_split_line,'Value') == 1
            splitline_visible = 'on';
        else
            splitline_visible = 'off';
        end
        set(handles.split_line,'Visible',splitline_visible);

        % Updating the slider:
        set(handles.slider_frame,'Min',1);
        set(handles.slider_frame,'Value',1);
        set(handles.slider_frame,'Max',userdata.data(video_id).vid.NumberOfFrames);
        set(handles.slider_frame,'SliderStep',(userdata.data(video_id).current_frame_step/userdata.data(video_id).vid.NumberOfFrames)*[1 5]);
        set(handles.slider_frame,'Value',userdata.data(video_id).current_frame);

        % Updating the frame options:
        set(handles.edit_frame,'String',num2str(userdata.data(video_id).current_frame));
        set(handles.edit_start_frame,'String',num2str(userdata.data(video_id).current_start_frame));
        set(handles.edit_frame_step,'String',num2str(userdata.data(video_id).current_frame_step));

        % Saving the handles
        set(handles.figure1,'UserData',userdata);
        guidata(handles.figure1,handles);
    end
end

% --- Function to get the user data in a user friendlier way.
function [userdata, video_id, lind] = getGUIStatus(handles)
    % Input:
    % handles: handles on the GUI
    %
    % Output:
    % userdata: The userdata structure.
    % video_id: The index of the current video.
    % lind: a 4-vector with the indices for type class feature
    % and point number of the current selection.
    video_list = get(handles.listbox_files,'String');
    if isempty(video_list)
        video_id = 0;
    else
        video_id = get(handles.listbox_files,'Value');
    end
    userdata = get(handles.figure1,'UserData');
    lind = [get(handles.popupmenu_type,'Value') ...
            get(handles.popupmenu_class,'Value') ...
            get(handles.popupmenu_name,'Value')...
            get(handles.popupmenu_n_points,'Value')];
end

function changeGUIActiveState(handles)
% Disables/Enables the set of GUI features that depend on the existence of
% a video.

    userdata = getGUIStatus(handles);

    handle_list = [handles.pushbutton_SaveCorrections ...
        handles.togglebutton_PlayEpochVid ...
        handles.edit_CurrEpochEnd ...
        handles.edit_CurrEpochStart ...
        handles.pushbutton_DeleteCurrEpoch ...
        handles.pushbutton_EpochEnd ...
        handles.pushbutton_StartEpoch ...
        handles.popupmenu_MovieEpochs ...
        handles.checkbox_LimitWindow ...
        handles.checkbox_Show_LM_Track ...
        handles.slider_frame ...
        handles.slider_speed ...
        handles.edit_frame ...
        handles.edit_speed ...
        handles.edit_frame_step ...
        handles.edit_start_frame ...
        handles.togglebutton_play ...
        handles.checkbox_display_all_tracks...
        handles.checkbox_vertical_flip...
        handles.checkbox_vertical_flip...
        handles.pushbutton_remove...
        handles.pushbutton_clear_FileList...
        handles.listbox_files...
        handles.checkbox_display_split_line...
        handles.pushbutton_add_distortion_correction...
        handles.pushbutton_add_background];

    curr_status = get(handle_list(1),'Enable');
    switch curr_status
        case 'on'
            set(handle_list,'Enable','off');
            set(handles.image,'Cdata',[]);
            % Disabling the plot handles:
            PH = cat(2,userdata.plot_handles.track{:});PH = cat(2,PH{:});
            PH = cat(3,cell2mat(PH));
            set([PH(:);handles.split_line],'Visible','off');

            % Setting frame stuff to 1:
            set([handles.edit_frame handles.edit_frame_step ...
                handles.edit_frame_step],'String','1');
            % Setting the file list to empty cell so we can add multiple files:
            set(handles.listbox_files,'String',cell(0));

        case 'off'
            set(handle_list,'Enable','on');
    end
    guidata(handles.figure1,handles)
end

% ---
function data = initializeUserDataStructure(userdata,vid)
% Initializes an empty data structure and checks the current folders for
% labels, background and other information.
    [empty_track, empty_visibility] = initializeEmptytrackVisibility(userdata,vid.NumberOfFrames); 
	
    data = struct('current_frame',1, ...
        'current_frame_step',1, ...
        'current_start_frame',1, ...
        'vid',vid, ...
        'background_popup_id',1,'bkg',[],'bkg_path','', ...
        'visibility',{empty_visibility}, ...
        'LM_Track_Visibility',{empty_visibility}, ...
        'track',{empty_track},...
        'LM_track',{empty_track}, ...
        'Show_track',true, ...
        'Show_LM_track',true, ...      
        'split_line',NaN,...
        'flip',false,...
        'scale',1,...
        'calibration_popup_id',1,...
        'ind_warp_mapping',[], ...
        'inv_ind_warp_mapping',[],...
        'calibration_path','', ...
        'LimitedWindow_X',[], ...
        'UseLimitedWindow', true, ...
        'Good_Epochs',[], ...
        'BadMovie', false, ...
        'DataFile','',...
        'DebugData',[], ...
        'track_original',true,...
        'timer',[]);
    clear empty_track empty_visibility

    % If image correction data was loaded, enable the image correction
    % commands:
    if ~isempty(data.ind_warp_mapping)
        % FIXME: If the file exists, check if it is already on the list and use
        % it. If not, create a fake file on the same directory.
        if strcmpi(get(handles.radiobutton_corrected,'Enable'),'off')
            set([handles.radiobutton_corrected handles.radiobutton_original...
                handles.popupmenu_distortion_correction_files],'Enable','on');
        end
    end
end

%% CORRECTING tracks
% 'Show LocoMouse track'
function checkbox_Show_LM_Track_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Show_LM_Track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_Show_LM_Track
    
    [userdata,video_id,~] = getGUIStatus(handles);

    % Save current state in memory so its not lost when changing videos:
    userdata.data(video_id).Show_LM_track = get(hObject,'Value');
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
	updatePosition(handles);
    guidata(handles.figure1,handles);
end

% 'Show Corrected Labels'
function checkbox_ShowNewLabels_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_ShowNewLabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_ShowNewLabels
    [userdata,video_id,~] = getGUIStatus(handles);
  
    % Save current state in memory so its not lost when changing videos:
    userdata.data(video_id).Show_track = get(hObject,'Value');
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
end

% 'Limit View'
function checkbox_LimitWindow_Callback(hObject, eventdata, handles)
    [userdata,video_id,~] = getGUIStatus(handles);
  
    % Save current state in memory so its not lost when changing videos:
    userdata.data(video_id).UseLimitedWindow = get(hObject,'Value');
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
    resetGUI(handles);
end

%       ----- EPOCHS -----

% 'Start EPOCH'
function pushbutton_StartEpoch_Callback(hObject, eventdata, handles)
% 
% hObject    handle to pushbutton_StartEpoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pushbutton_StartEpoch

    [userdata,video_id,~] = getGUIStatus(handles);
    
    % Initiate new epoch
    n_epoch = [userdata.data(video_id).current_frame userdata.data(video_id).vid.NumberOfFrames];
    epochs = userdata.data(video_id).Good_Epochs;
    epochs{size(epochs,2)+1} = n_epoch;
    update_epochs(epochs,handles);
end

% 'End EPOCH'
function pushbutton_EpochEnd_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_EpochEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	[userdata,video_id,~] = getGUIStatus(handles);
	epochs = userdata.data(video_id).Good_Epochs;
    te_EndFrame = userdata.data(video_id).current_frame;    
    epochs{get(handles.popupmenu_MovieEpochs,'Value')}(2) = te_EndFrame;
    update_epochs(epochs,handles);   
end

% 'Delete Epoch'
function pushbutton_DeleteCurrEpoch_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_DeleteCurrEpoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [userdata,video_id,~] = getGUIStatus(handles);
    t_epoch = get(handles.popupmenu_MovieEpochs,'Value');
	epochs = userdata.data(video_id).Good_Epochs;
    epochs{t_epoch} = [];
    update_epochs(epochs,handles);
end

% Epochs Popupmenu
function popupmenu_MovieEpochs_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_MovieEpochs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_MovieEpochs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_MovieEpochs
    [userdata,video_id,~] = getGUIStatus(handles);
    
    userdata.data(video_id).current_frame = userdata.data(video_id).Good_Epochs{get(hObject,'Value')}(1);
    set(handles.edit_CurrEpochStart,'String',userdata.data(video_id).Good_Epochs{get(hObject,'Value')}(1))
	set(handles.edit_CurrEpochEnd,'String',userdata.data(video_id).Good_Epochs{get(hObject,'Value')}(2))  
    set(handles.figure1,'UserData',userdata)
    displayImage([],[],handles);
end

% edit current epoch start frame
function edit_CurrEpochStart_Callback(hObject, eventdata, handles)
% hObject    handle to edit_CurrEpochStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_CurrEpochStart as text
%        str2double(get(hObject,'String')) returns contents of edit_CurrEpochStart as a double
	[userdata,video_id,~] = getGUIStatus(handles);
    value = str2double(get(handles.edit_CurrEpochStart,'String'));
    t_epoch = get(handles.popupmenu_MovieEpochs,'Value');
	epochs = userdata.data(video_id).Good_Epochs;
    epochs{t_epoch}(1) = value;
    update_epochs(epochs,handles)
    
end

% edit current epoch end frame
function edit_CurrEpochEnd_Callback(hObject, eventdata, handles)
% hObject    handle to edit_CurrEpochEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_CurrEpochEnd as text
%        str2double(get(hObject,'String')) returns contents of edit_CurrEpochEnd as a double
    [userdata,video_id,~] = getGUIStatus(handles);
    value = str2double(get(handles.edit_CurrEpochEnd,'String'));
    t_epoch = get(handles.popupmenu_MovieEpochs,'Value');
	epochs = userdata.data(video_id).Good_Epochs;
    epochs{t_epoch}(2) = value;
    update_epochs(epochs,handles)
end

function update_epochs(varargin)
    % gets an updated epochs structure and the handles.
    % checks and corrects new entries to an epoch structure.
    % updates the GUI and settings
    
    n_epochs = varargin{1}; handles = varargin{2}; clear varargin
    [userdata,video_id,~] = getGUIStatus(handles);
    if ~isempty(n_epochs)
        
        
        epochs = userdata.data(video_id).Good_Epochs;
        t_epoch = get(handles.popupmenu_MovieEpochs,'Value');
        
        % using epoch starting points for chronological sorting
        starts = zeros(1,size(n_epochs,2));
        for t_te = 1:size(n_epochs,2)
            if ~isempty(n_epochs{t_te})
                starts(t_te) = n_epochs{t_te}(1);
            end
        end
        [~,s_idx]=sort(starts,'ascend');
        for t_te = 1:size(n_epochs,2)
            m_epochs{t_te} = n_epochs{s_idx(t_te)};
        end
        n_epochs = m_epochs; 
        
        % duplicated epochs
        starts = zeros(1,size(n_epochs,2));
        for t_te = 1:size(n_epochs,2)
            if ~isempty(n_epochs{t_te})
                starts(t_te) = n_epochs{t_te}(1);
            end
        end
        duplicates = find(diff(starts) == 0);
        for t_d =1:length(duplicates)
            done=false;
            if done==false && isempty(n_epochs{duplicates(t_d)})
                n_epochs{duplicates(t_d)+1} = [];
                done = true;
            end
            
            if ~done && any(isnan(n_epochs{duplicates(t_d)}))
                n_epochs{duplicates(t_d)} = [];
                done=true;
            elseif ~done && any(isnan(n_epochs{duplicates(t_d)+1}))
                n_epochs{duplicates(t_d)+1} = [];
                done=true;
            end
            if ~done 
                lengths = [diff(n_epochs{duplicates(t_d)}) diff(n_epochs{duplicates(t_d)+1})];
                if diff(lengths) ==0
                     n_epochs{duplicates(t_d)+1} = [];
                     done = true;
                else
                    [~, b] = max(lengths);
                    n_epochs{duplicates(t_d)-1+b} = [];
                    done = true;
                end
            end
        end
        done=false;
        
        % delete empty epochs
        empties = 0;
        m_epochs = [];
        for t_te = 1:size(n_epochs,2)
            tt = t_te - empties;
            if ~isempty(n_epochs{t_te})
                m_epochs{tt} = n_epochs{t_te};
            else
                empties = empties+1;
            end
        end
        n_epochs = m_epochs;
        clear m_epochs
        
        % dealing with overlaps
        
        for t_te = 1:size(n_epochs,2)
            if n_epochs{t_te}(1) <  1
                n_epochs{t_te}(1) = 1;
            end
            if n_epochs{t_te}(2) >  userdata.data(video_id).vid.NumberOfFrames
                n_epochs{t_te}(2) = userdata.data(video_id).vid.NumberOfFrames;
            end
            if ~isempty(epochs)
                new_epoch = false;
                
                tstart  = n_epochs{t_te}(1);
                tend    = n_epochs{t_te}(2);
                ostarts = zeros(1,size(epochs,2));
                oends   = zeros(1,size(epochs,2));
                for t_te2 = 1:size(epochs,2)
                    if ~isempty(epochs{t_te2})
                        ostarts(t_te2) = epochs{t_te2}(1);
                        oends(t_te2) = epochs{t_te2}(2);
                    end
                end
                
                start_idx = find(ismember(ostarts,tstart));
                end_idx = find(ismember(oends,tend));
                if isempty(start_idx) % new epoch
                    if t_te > 1 && n_epochs{t_te}(1) <= n_epochs{t_te-1}(2)
                        n_epochs{t_te-1}(2) = n_epochs{t_te}(1)-1;
                    end
                    if t_te < size(n_epochs,2) && n_epochs{t_te}(2) >= n_epochs{t_te+1}(1)
                        n_epochs{t_te}(2) = n_epochs{t_te+1}(1)-1;
                    end
                else
                    if ~isempty(start_idx) && isempty(end_idx) && t_te < size(n_epochs,2) % new end
                        n_epochs{t_te+1}(1) = n_epochs{t_te}(2)+1;
                    end
                end
                
                
            end
        end
	end
   
    epochs = n_epochs;
    
    % finding the last episode that begins before this frame:
	starts = zeros(1,size(epochs,2)+1);
    for t_te = 1:size(epochs,2)
        starts(t_te) = epochs{t_te}(1);
    end
    starts(end) = userdata.data(video_id).current_frame; starts = sort(starts,'ascend');
    t_epoch = max(find(ismember(starts,userdata.data(video_id).current_frame)))-1;
	if t_epoch < 1
        t_epoch = 1;
	end
	if t_epoch > size(epochs,2)
        t_epoch = size(epochs,2);
    end
    % update userdata
    userdata.data(video_id).Good_Epochs = n_epochs;	
    set(handles.figure1,'UserData',userdata);
    % Enable Epoch related objects
    if isempty(epochs)
        handles = toggle_Epoch_Panel(handles,false, ...
                            'MovieEpochsString','none', ...
                            'CurrEpochStartString','', ...
                            'CurrEpochEndString','', ...
                            'MovieEpochsValue',1);
    else
        handles = toggle_Epoch_Panel(handles, true, ...
        'MovieEpochsString', num2str([1:size(epochs,2)]'), ...
        'CurrEpochStartString', num2str(epochs{t_epoch}(1)), ...
        'CurrEpochEndString', num2str(epochs{t_epoch}(2)), ...
        'MovieEpochsValue', num2str(t_epoch));
    end
        
end

% REMOVE TRACKS FROM EPOCH
% --- Executes on button press in pushbutton_EpochRemoveTracks.
function pushbutton_EpochRemoveTracks_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_EpochRemoveTracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

	[userdata,video_id,~] = getGUIStatus(handles);
	totalFrames = int16(userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate);
     
    % Choosing frames to delete:
    cE_frames = userdata.data(video_id).Good_Epochs(:,handles.popupmenu_MovieEpochs.Value);
    cE_frames = [cE_frames{1}(1):cE_frames{1}(2)];
    
    % overwriting LM_tracks with NaNs   
    [tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).LM_track,totalFrames);
    tracks(:,:,cE_frames) = nan(size(tracks,1),size(tracks,2),length(cE_frames));
    tracks_tail(:,:,cE_frames) = nan(size(tracks_tail,1),size(tracks_tail,2),length(cE_frames));    
    [empty_labels,~] = initializeEmptytrackVisibility(userdata, totalFrames);
    [userdata.data(video_id).LM_track]= Convert_Track2Label(tracks,tracks_tail, empty_labels);
    
    % overwriting tracks with NaNs
    [tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).track,totalFrames);
    tracks(:,:,cE_frames) = nan(size(tracks,1),size(tracks,2),length(cE_frames));
    tracks_tail(:,:,cE_frames) = nan(size(tracks_tail,1),size(tracks_tail,2),length(cE_frames));    
    [empty_labels,~] = initializeEmptytrackVisibility(userdata, totalFrames);
    [userdata.data(video_id).track]= Convert_Track2Label(tracks,tracks_tail, empty_labels);
    
	set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
    
end

function handles = toggle_Epoch_Panel(handles, toggle, varargin)
    % gets handles, toggle 
    
    %   If toggle is on, further parameters are:
    %   'MovieEpochsString'
    %   'CurrEpochStartString'
    %   'CurrEpochEndString'
    %   'MovieEpochsValue'
    %   to toggle enable for any additional object use
    %   'toggle',handle
    
    if toggle
        toggle = 'on';
    else
        toggle = 'off';
    end    

    for tvar = 1:2:size(varargin,2)
        if ~strcmp(varargin{tvar},'toggle')
            if size(varargin{tvar+1},1) > 1
                for tv_i = 1:size(varargin{tvar+1},1)
                    eval([varargin{tvar},'{tv_i} = strtrim(num2str(',varargin{tvar+1}(tv_i,:),'));']);
                end
            else
                if ischar(varargin{tvar+1})
                    eval([varargin{tvar},' = ''',varargin{tvar+1},''';']);
                else    
                    eval([varargin{tvar},' = ',num2str(varargin{tvar+1}),';']);
                end
            end
        end
    end
    
    % update popupmenu_MovieEpochs
    if exist('MovieEpochsString','var')
        if isnumeric(MovieEpochsString)
            MovieEpochsString = num2str(MovieEpochsString);
        end
        set(handles.popupmenu_MovieEpochs, 'String',MovieEpochsString);
    end
    if exist('MovieEpochsValue','var')
        if ischar(MovieEpochsValue)
            MovieEpochsValue = str2double(MovieEpochsValue);
        end
        set(handles.popupmenu_MovieEpochs,'Value',MovieEpochsValue);
    end
    if exist('CurrEpochStartString','var')
        set(handles.edit_CurrEpochStart,'String',CurrEpochStartString);
    end
    if exist('CurrEpochEndString','var')
        set(handles.edit_CurrEpochEnd,'String',CurrEpochEndString)
    end
        
        % Enable Epoch related objects
    set([handles.edit_CurrEpochStart, ...
         handles.edit_CurrEpochEnd, ...
         handles.popupmenu_MovieEpochs, ...
         handles.pushbutton_EpochEnd ...
         handles.pushbutton_DeleteCurrEpoch, ...
         handles.togglebutton_PlayEpochVid ...
         ],'Enable',toggle) 
     % and additionals
     for tvar = 1:2:size(varargin,2)
        if strcmp(varargin{tvar},'toggle')
            eval(['set(handles.',varargin{tvar+1},',''Enable'',''',toggle,''');']) ;
        end
    end
end

function togglebutton_PlayEpochVid_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_PlayEpochVid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [userdata,video_id,~] = getGUIStatus(handles);    
    if get(handles.togglebutton_PlayEpochVid,'Value')
        set(handles.togglebutton_PlayEpochVid,'String','Playing Epoch');
        epochs = userdata.data(video_id).Good_Epochs;
        t_epoch = get(handles.popupmenu_MovieEpochs,'Value');
        userdata.data(video_id).current_frame=epochs{t_epoch}(1);
        set(handles.figure1,'UserData',userdata);
        start(userdata.data(video_id).timer);
    else
        set(handles.togglebutton_PlayEpochVid,'String','Play Epoch');
        stop(userdata.data(video_id).timer);
    end
    
end

%% AUTOMATED TRACKING FIX FUNCTIONS

% DETECT SWING AND STANCE
% --- Executes on button press in pushbutton_DetectSwingAndStance.
function pushbutton_DetectSwingAndStance_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton_DetectSwingAndStance (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    [userdata,video_id,~] = getGUIStatus(handles);
    image_size = [userdata.data(video_id).vid.Height, userdata.data(video_id).vid.Width];
	total_frames = userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate;
    SwiSta = DE_SwingStanceDetection(userdata.data(video_id).LM_track,total_frames);
    
    userdata.data(video_id).SwiSta = SwiSta;
	set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
    
end

% FILL HOLES
% --- Executes on button press in pushbutton_FillHoles.
function pushbutton_FillHoles_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_FillHoles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [userdata,video_id,~] = getGUIStatus(handles);
     disp('Reminder: pushbutton_FillHoles_Callback works on the labels, not the track!')
    total_frames = userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate;
    %     [tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).LM_track,total_frames);
    [tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).track,total_frames);
    MaxHoleSize = round(0.1250 * userdata.data(video_id).vid.FrameRate);
    tracks = DE_FillHoles(tracks,MaxHoleSize);
    
    empty_labels = initializeEmptytrackVisibility(userdata, size(tracks,3));
    userdata.data(video_id).track = Convert_Track2Label(tracks,tracks_tail, empty_labels);
    
	set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);

end


% SMOOTH:
% --- Executes on button press in pushbutton_Smooth.
function pushbutton_Smooth_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Smooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [userdata,video_id,~] = getGUIStatus(handles);
    total_frames = userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate;
    % [tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).LM_track,total_frames);
    [tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).LM_track,total_frames);
    MaxHoleSize = round(0.1250 * userdata.data(video_id).vid.FrameRate);
    tracks = DE_SmoothTracks(tracks,userdata.data(video_id).vid.FrameRate,false,MaxHoleSize);
    
	empty_labels = initializeEmptytrackVisibility(userdata, size(tracks,3));
    userdata.data(video_id).track = Convert_Track2Label(tracks,tracks_tail, empty_labels);
    
	set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
    
end

% FLIP L/R
% --- Executes on button press in pushbutton_FlipLR.
function pushbutton_FlipLR_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_FlipLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [userdata,video_id,~] = getGUIStatus(handles);
    
    data_s = load(userdata.data(video_id).DataFile);
    im_width_c = size(data_s.data.ind_warp_mapping,2);
    im_width = size(data_s.data.inv_ind_warp_mapping,2);
    
    
    data_s.data.flip = ~data_s.data.flip; % correct flip flag
        
    % turn around x values
    data_s.data.bodymasscenter(1,:) = abs(data_s.data.bodymasscenter(1,:) - im_width) +1;
    data_s.bounding_box(1,:) = abs(data_s.bounding_box(1,:) - im_width_c) +1;    
    
    for i = 1:size(data_s.debug.tracks_bottom,1)
        for ii = 1:size(data_s.debug.tracks_bottom,2)
            data_s.debug.tracks_bottom{i,ii}(1,:) = abs(data_s.debug.tracks_bottom{i,ii}(1,:) - im_width_c)+1;
        end
    end
    for i = 1:size(data_s.debug.tracks_top,1)
        for ii = 1:size(data_s.debug.tracks_top,2)
            data_s.debug.tracks_top{i,ii}(1,:) = abs(data_s.debug.tracks_top{i,ii}(1,:) - im_width_c)+1;
        end
    end
    
    data_s.final_tracks([1 3],:) = abs(data_s.final_tracks([1 3],:) - im_width)+1;
    data_s.final_tracks_c([1 3],:) = abs(data_s.final_tracks_c([1 3],:) - im_width_c)+1;
    data_s.tracks_tail([1 3],:) = abs(data_s.tracks_tail([1 3],:) - im_width)+1;
    data_s.tracks_tail_c([1 3],:) = abs(data_s.tracks_tail_c([1 3],:) - im_width_c)+1;
    
    % reassigning paw identities
    data_s.final_tracks = data_s.final_tracks(:,[3 4 1 2 5],:);
    data_s.final_tracks_c = data_s.final_tracks_c(:,[3 4 1 2 5],:);
    
    % storing the files
    fi_names = fieldnames(data_s);
    save_str = 'save(userdata.data(video_id).DataFile';
    for fi_i = 1:size(fi_names,1)
        eval([char(fi_names(fi_i)),' = data_s.',char(fi_names(fi_i)),';'])
        save_str = [save_str,', ''',char(fi_names(fi_i)),''''];
    end
    eval([save_str,',''-append'');'])
    
    % re-loading data file
    listbox_files_Callback(hObject, eventdata, handles);
    
end


% RE-TRACKING

% Toggle retrack mode.
% --- Executes on button press in togglebutton_RetrackMode.
function togglebutton_RetrackMode_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_RetrackMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_RetrackMode

    if handles.togglebutton_RetrackMode.Value
        t_string = 'Retracking';
        t_col = [1 0 0];
    else
        t_string = 'Not Retracking';
        t_col = [0.94 0.94 0.94];            
    end
    set(handles.togglebutton_RetrackMode, ... 
        'String',t_string, ...
        'BackgroundColor',t_col);
    
end


function pushbutton_ReTrack_Callback(hObject, eventdata, handles)

% hObject    handle to pushbutton_ReTrack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [userdata,video_id,~] = getGUIStatus(handles);
    DataFile = userdata.data(video_id).DataFile;
    totalFrames = int16(userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate);
    [tracks_corrected, ~]= Convert_Label2Track(userdata.data(video_id).track,totalFrames);

    % variables used by MTF_BottomView
        % Model file:
    model_file_pos = get(handles.popupmenu_model,'Value');
    model_file = get(handles.popupmenu_model,'String');model_file = model_file{model_file_pos};clear model_file_pos;
    handles = loadModel(fullfile(handles.root_path,'model_files',[model_file '.mat']),handles); clear model_file
    model = handles.model;
    point_features = fieldnames(model.point);
    
        % Numbers
    N_frames = floor(userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate);
    handles.popupmenu_model.String(handles.popupmenu_model.Value);
    point_features = fieldnames(model.point);
    N_pointlike_features = length(point_features);
    N_features_per_point_track = zeros(1,N_pointlike_features);
    for i_point = 1:N_pointlike_features
        N_features_per_point_track(i_point) = model.point.(point_features{i_point}).N_points;
    end
    N_pointlike_tracks = sum(N_features_per_point_track);

    % Flip'n'Warp
    %%% FIXME: Hacked to only do the bottom view tracks so far:
    vis_point = [cell2mat(userdata.data(video_id).visibility{1}{1}(:)); cell2mat(userdata.data(video_id).visibility{1}{2}(:))];
    vis_point_b = vis_point(:,:,1);
    vis_point_s = vis_point(:,:,2);
    
    corrected_frames_ind = find(any(vis_point_b == 2 | vis_point_s == 2,1));
    N_corrected_frames = length(corrected_frames_ind);
    
    if N_corrected_frames == 0
        warning('No manual adjustments found!');
        return;
    end
    
    correct_structure = struct('frame',cell(1,N_corrected_frames),'tracks',cell(1,N_corrected_frames));
    for i_frames = 1:N_corrected_frames
        cframes_i = corrected_frames_ind(i_frames);
        tracksc_i = tracks_corrected(1:2,:,cframes_i);
        
        % Convert tracks to corrected view:
        tracksc_i = warpPointCoordinates(tracksc_i([2 1],:)',userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping),false); % No pre and post flipping
        tracksc_i = tracksc_i(:,[2 1])';
        
        % Handling flipping outside of the warp. 
        % FIXME: The warp should have a pre and post flip boolean.
        if userdata.data(video_id).flip
            tracksc_i(1,:) = size(userdata.data(video_id).inv_ind_warp_mapping,2) - tracksc_i(1,:) + 1; 
            tracksc_i = tracksc_i(:,[3 4 1 2 5],:);
        end
        tracksc_i(isnan(tracksc_i(:))) = -1; % FIXME: What if the track really is missing?
        
        correct_structure(i_frames).frame = corrected_frames_ind(i_frames);
        correct_structure(i_frames).tracks = tracksc_i;
    end
    
    [tracks_corrected, userdata.data(video_id).DebugData] = retrackMatch2nd(correct_structure, userdata.data(video_id).DebugData, userdata.data(video_id).ind_warp_mapping,userdata.data(video_id).flip);
            % Fix the tracking matrices:
    % - Check which tracks changed and which ones are kept.
    % - Update Unary and Pairwise
    % - Run match2nd with ALL THE PERMUTATIONS!
    
%     [DE] RETRACKING MODE if the retracking broke, delete current change.
    if isempty(tracks_corrected)
        [trc,trta]  = Convert_Label2Track(userdata.data(video_id).track);
        trc(:,:,userdata.data(video_id).current_frame) = NaN;
        trta(:,:,userdata.data(video_id).current_frame) = NaN;
        empty_labels = initializeEmptytrackVisibility(userdata, size(trc,3));
        userdata.data(video_id).track = Convert_Track2Label(trc,trta,empty_labels,totalFrames);
    else
        for i_tracks = 1:5 % FIXME: Paw only
        % >> [DE] 
        userdata.data(video_id).track{1}{1}{i_tracks} = cat(4,tracks_corrected(1:2,i_tracks,:),tracks_corrected(3:4,i_tracks,:));
        % [DE] <<
        end
    end
	set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
end

function [track_bottom, D] = retrackMatch2nd(correct_structure, D, ind_warp_mapping, flip)
% Re-runs the match2nd code with manually corrected images in some frames.
% INPUT:
%
% correct_structure: A structure array with fields:
%   * frame: The index of the frame to fix.
%   * tracks: A dim x features matrix with the new locations for the
%   tracks.
%
% D: The contents of the original save file.
%
% OUTPUT:
%
% track_bottom: The new tracks.
%
% Unary: The new unary potentials.
%
% Pairwise: The new pairwise potentials.


    New_score = 100;
    alpha_vel = 1E-1;
    
    % FIXME [DE] This change should be an update to the data file
    if ~isfield(D.debug,'Occlusion_Grid_Bottom') 
        if isfield(D,'OcclusionGrid')
            D.debug.Occlusion_Grid_Bottom = D.OcclusionGrid;
        else
            error('unknown debuger version: occlusion grid was not found.')
        end
    end
    
    Nong = size(D.debug.Occlusion_Grid_Bottom,2);
    N_frames = size(D.final_tracks_c,3);

    % Copying old data:
    Unary = D.debug.Unary;
    Pairwise = D.debug.Pairwise;
    tracks_bottom = D.debug.tracks_bottom;

    for i_changes = 1:length(correct_structure)

        i_frame = correct_structure(i_changes).frame;
        tracks = correct_structure(i_changes).tracks;

        % Paw tracks (for now just them):
        candidates_paw = NaN(3,4);
        candidates_paw_joint = NaN(4,4);
        for i_paw = 1:4
            if any(tracks(:,i_paw) < 0)
                % FIXME: Implement remain and how to edit/not edit the pairwise
                % matrices.
                candidates_paw(1:2,i_paw) = D.final_tracks_c(1:2,i_paw,i_frame);
                candidates_paw_joint(1:2,i_paw) = D.final_tracks_c(1:2,i_paw);
            else
                % Candidates and unary:
                candidates_paw(1:2,i_paw) = tracks(:,i_paw);
                candidates_paw_joint(1:2,i_paw) = tracks(:,i_paw);
            end
            candidates_paw(3,i_paw) = New_score;
            candidates_paw_joint(4,i_paw) = New_score;
        end
        Unary{1,i_frame} = cat(1,New_score*eye(4),zeros(Nong,4));
        tracks_bottom{1,i_frame} = candidates_paw;
        
        % [DE] ------ Repeat for the snout
        candidates_snout = NaN(3,1);
        candidates_snout_joint = NaN(4,1);
        
        if any(tracks(:,5) < 0)
            % FIXME: Implement remain and how to edit/not edit the pairwise
            % matrices.
            candidates_snout(1:2,1) = D.final_tracks_c(1:2,5,i_frame);
            candidates_snout_joint(1:2,1) = D.final_tracks_c(1:2,5);
        else
            % Candidates and unary:
            candidates_snout(1:2,1) = tracks(:,5);
            candidates_snout_joint(1:2,1) = tracks(:,5);
        end
        candidates_snout(3,1) = New_score;
        candidates_snout_joint(4,1) = New_score;
        
        Unary{2,i_frame} = cat(1,New_score,zeros(Nong,1));
        tracks_bottom{2,i_frame} = candidates_snout;
        
        % ------ [DE]

        % Pairwise:
        for tp_i = 1:2
            % Compute the pairwise matrix from the points (i_frames < N_frames -1)
            OGi = bsxfun(@minus,D.debug.bounding_box(1:2,i_frame),D.debug.Occlusion_Grid_Bottom);
            if (i_frame < N_frames - 1)
                Pairwise{tp_i, i_frame} = computePairwiseCost(tracks_bottom{tp_i,i_frame}(1:2,:),tracks_bottom{tp_i,i_frame+1}(1:2,:),OGi,abs(D.debug.xvel(i_frame))+D.debug.occluded_distance,alpha_vel);
            end

            % Compute the pairwise matrix to the point (i_frames > 1)
            if (i_frame > 1)
                Pairwise{tp_i, i_frame-1} = computePairwiseCost(tracks_bottom{tp_i,i_frame-1}(1:2,:),tracks_bottom{tp_i,i_frame}(1:2,:),OGi,abs(D.debug.xvel(i_frame))+D.debug.occluded_distance,alpha_vel);
                % Breaking links between occluded points to make sure only the
                % manually labelled points are reachable:
        %         D.debug.Pairwise{1,i_frame-1}(5:end,size(D.debug.tracks_bottom{1,i_frame-1},2)+1:end) = 0;
                Pairwise{tp_i,i_frame-1}(5:end,:) = 0;
            end
        end

        %%% FIXME: Make sure all points are connected to different candidates
        %%% on the previous frame. If not the program will crash.
    end
    
    final_tracks_c_new = NaN(2,5,N_frames);
    np{1}=[1:4]; np{2}=[1];
    npi{1}=[1:4]; npi{2}=[5];
    for tp_i = 1:2
    % Re-run match2nd with all the permutations.
        M_new{tp_i} =  match2nd(Unary(tp_i,:), Pairwise(tp_i,:), [],Nong, 0); % paws
        
        valid_tracks{tp_i} = all(M_new{tp_i}>0,2);

        if ~all(valid_tracks{tp_i})
            warning('Constraints do not result in valid trajectories. Please edit a frame closer to the previously edited frame: NUM');
            track_bottom = [];
            return
        else
            % Get new tracks: % FIXME: This definitely needs to be modular!
           
            for i_features = np{tp_i}
                for i_frames = 1:N_frames
                    if M_new{tp_i}(i_features,i_frames) <= size(tracks_bottom{tp_i,i_frames},2)
                        final_tracks_c_new(1:2,npi{tp_i}(i_features),i_frames) = tracks_bottom{tp_i,i_frames}(1:2,M_new{tp_i}(i_features,i_frames));
                    end
                end
            end

            % Side view for now unchanged:
            D.final_tracks_c = cat(1,final_tracks_c_new,D.final_tracks_c(3,:,:));
            %final_tracks_c_new(:,5,:) = final_tracks_c(:,5,:); %%% FIXME: No snout yet!

            % Save changes to unary, pairwise and candidates:
            D.debug.Unary = Unary;
            D.debug.Pairwise = Pairwise;
            D.debug.tracks_bottom = tracks_bottom;
            if tp_i == 1
                D.debug.M(1:4,:) = M_new{tp_i};
            else
                D.debug.M(5,:) = M_new{tp_i};
            end
        end
    end
    % Convert to original_view_tracks:
    [track_bottom,~] = convertTracksToUnconstrainedView(D.final_tracks_c,D.tracks_tail_c,size(ind_warp_mapping),ind_warp_mapping,flip,1);
    
    % DE: moved the following commented code out of the way:
                %     if ~valid_tracks(i_features)
                %         warning('Could not find a valid trajectory for track %d. Rejecting changes. Try editing a smaller segment.',i_features);
                %
                %         % Adding the candidate that was previously chosen to the new
                %         % candidate list, if any:
                %         for i_changes = 1:length(correct_structure)
                %             i_frame = correct_structure(i_changes).frame;
                %
                %             % Copying old tracks:
                %             final_tracks_c_new(1:2,i_features,i_frame) = D.final_tracks_c(1:2,i_features,i_frame);
                %
                %             if D.debug.M(i_features,i_frame) <= size(D.debug.tracks_bottom{1,i_frame},2)
                %                 % Replace manual candidate for the previously existing
                %                 % candidate:
                %                 tracks_bottom{1,i_frame}(:,i_features) = D.debug.tracks_bottom{1,i_frame}(:,D.debug.M(i_features,i_frame));
                %                 M_new(i_features,i_frame) = i_features;
                %
                %             else
                %                 % Remove the candidate:
                %                 tracks_bottom{1,i_frame}(:,i_features) = [];
                %                 M_new(i_features,i_frame) = size(tracks_bottom{1,i_frame},2)+1; % I don't think which ONG matters.
                %
                %             end
                %
                %         end
                %
                %         continue;
                %     end
end


% CLEAR ALL LABELS
% --- Executes on button press in pushbutton_ClearCorrections.
function pushbutton_ClearCorrections_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ClearCorrections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	[userdata,video_id,~] = getGUIStatus(handles);
    Nframes = userdata.data(video_id).vid.NumberOfFrames;
    [empty_track, empty_visibility] = initializeEmptytrackVisibility(userdata, Nframes);
    userdata.data(video_id).track = empty_track;
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
end

% CLEAR CORRECTIONS IN CURRENT FRAME

% --- Executes on button press in pushbutton_ClearLabelsCurrentFrame.
function pushbutton_ClearLabelsCurrentFrame_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ClearLabelsCurrentFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [userdata,video_id,lind] = getGUIStatus(handles);
    current_frame = userdata.data(video_id).current_frame;
    for lind1_c = 1:size(userdata.types,2)
        for lind2_c = 1:size(userdata.classes{lind1_c},2)
            for lind3_c = 1:size(userdata.features{lind1_c}{lind2_c},2)
                userdata.data(video_id).track{lind1_c}{lind2_c}{lind3_c}(:,:,userdata.data(video_id).current_frame,:) = ...
                    nan(size(userdata.data(video_id).track{lind1_c}{lind2_c}{lind3_c}(:,:,userdata.data(video_id).current_frame,:)));
            end
        end
    end
	set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);    
end

% overwrite tracks - copy LM_Tracks to tracks
% --- Executes on button press in pushbutton_CopyTrack.
function pushbutton_CopyTrack_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_CopyTrack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [userdata,video_id,~] = getGUIStatus(handles);
    

    userdata.data(video_id).track = userdata.data(video_id).LM_track;
    
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);

end

% overwrite tracks - copy labels to LM_Tracks
% --- Executes on button press in pushbutton_OverwriteLMTrack.
function pushbutton_OverwriteLMTrack_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_OverwriteLMTrack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

	[userdata,video_id,~] = getGUIStatus(handles);
  
        % Store current LM_Tracks
        unique_id = datestr(now,'yyyymmddhhMMss');
        total_frames = userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate;
        eval(['[tracks_',unique_id,', tracks_tail_',unique_id,'] = Convert_Label2Track(userdata.data(video_id).LM_track,total_frames);']);
        save(userdata.data(video_id).DataFile,['tracks_',unique_id],['tracks_tail_',unique_id],'-append')

        % overwrite LM tracks with tracks
         userdata.data(video_id).LM_track = userdata.data(video_id).track;     
     
    % Saving Changes: %%% FIXME: If the Unary and Pairwise matrices are not stored, the tracks can only be corrected once! 
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);

end


% acccept labels - merging them with LM_Tracks
% --- Executes on button press in AcceptLabels.
function AcceptLabels_Callback(hObject, eventdata, handles)
% hObject    handle to AcceptLabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

        [userdata,video_id,~] = getGUIStatus(handles);
        
        % Store current LM_Tracks
        unique_id = datestr(now,'yyyymmddhhMMss');
        totalFrames = int16(userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate);
        eval(['[tracks_',unique_id,', tracks_tail_',unique_id,'] = Convert_Label2Track(userdata.data(video_id).LM_track,totalFrames);']);
        save(userdata.data(video_id).DataFile,['tracks_',unique_id],['tracks_tail_',unique_id],'-append')

        % merge tracks
        LM_tracks = eval(['tracks_',unique_id]); LM_tracks_tail = eval(['tracks_tail_',unique_id]); %clear(['tracks_',unique_id],['tracks_tail_',unique_id]);
        [tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).track,totalFrames);
        LM_tracks = LM_tracks(:,:,1:totalFrames);
        tracks = tracks(:,:,1:totalFrames);
        LM_tracks(~isnan(tracks)) = tracks(~isnan(tracks));
        LM_tracks_tail(~isnan(tracks_tail)) = tracks_tail(~isnan(tracks_tail));
        
        tracks = LM_tracks; tracks_tail = LM_tracks_tail; % (Stupid names)
        save(userdata.data(video_id).DataFile,'tracks','tracks_tail','-append');
        
        % write corrected tracks to LM_tracks   
        [empty_track, empty_visibility] = initializeEmptytrackVisibility(userdata,totalFrames); 
        userdata.data(video_id).LM_track = Convert_Track2Label(tracks,tracks_tail,empty_track);         
                      
     
    % Saving Changes: %%% FIXME: If the Unary and Pairwise matrices are not stored, the tracks can only be corrected once! 
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);

end


%% FILE ACTIONS

% SAVE CORRECTIONS
% --- Executes on button press in pushbutton_SaveCorrections.
function pushbutton_SaveCorrections_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton_SaveCorrections (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    [userdata,video_id,~] = getGUIStatus(handles);
    epochs = userdata.data(video_id).Good_Epochs;
    
    CorrectionLabels = userdata.data(video_id).track;
    BadMovie = userdata.data(video_id).BadMovie;
%     SwiSta = userdata.data(video_id).SwiSta;
     total_frames = userdata.data(video_id).vid.Duration * userdata.data(video_id).vid.FrameRate;
    [corr_final_tracks, corr_tracks_tail] = Convert_Label2Track(userdata.data(video_id).track,total_frames);
    [final_tracks, tracks_tail] = Convert_Label2Track(userdata.data(video_id).LM_track,total_frames);
    

    % save
    tclock = clock;
    timestamp = ['_d',num2str(tclock(1)),'_',num2str(tclock(2)),'_',num2str(tclock(3)),'_t',num2str(tclock(4)),'_',num2str(tclock(5))];
    copyfile(userdata.data(video_id).DataFile,[userdata.data(video_id).DataFile(1:end-4),'_outdated_on',timestamp,'.mat'])
%     'SwiSta',
    save(userdata.data(video_id).DataFile,'epochs', 'CorrectionLabels','BadMovie','corr_final_tracks','corr_tracks_tail','final_tracks','tracks_tail','timestamp','-append');  
    
    col = get(handles.pushbutton_SaveCorrections,'BackgroundColor');
    set(handles.pushbutton_SaveCorrections,'String','DATA SAVED','BackgroundColor',[1 0 0])
    pause(0.5)
    set(handles.pushbutton_SaveCorrections,'String','Save Corrections','BackgroundColor',col)
    
end

% 'FLAG/UNFLAG whole video'
function togglebutton_reject_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_reject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_reject
    [userdata,video_id] = getGUIStatus(handles);
    value = get(hObject,'Value');
    toggleHandles = [ handles.checkbox_LimitWindow ...
                      handles.checkbox_ShowNewLabels ...
                      handles.checkbox_Show_LM_Track ...
                      ];
    if value
        set(hObject,'String','BAD MOVIE','BackgroundColor',[0.8 0 0.2]);
        % Gray out edit stuff that should not be changed
        set(toggleHandles,'Enable','off');
        userdata.data(video_id).BadMovie = true;
        handles = toggle_Epoch_Panel(handles,false,'toggle','pushbutton_StartEpoch');
    else
        set(toggleHandles,'Enable','on');
        handles.slider_frame.Value=handles.figure1.UserData.data.current_frame;
        set(hObject,'String','GOOD MOVIE','BackgroundColor',[0 0.8 0.2]);
        userdata.data(video_id).BadMovie = false;
        handles = toggle_Epoch_Panel(handles,true,'toggle','pushbutton_StartEpoch');
    end
    set(handles.figure1,'UserData',userdata);
    handles = resetGUI(handles);
    
end

%% FRAME and VIDEO NAVIGATION

%  -- Frame Navigation --

% Frame Slider:
function slider_frame_Callback(hObject, eventdata, handles)
    % hObject    handle to slider_frame (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'Value') returns position of slider
    %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    curr_slide_step = get(handles.slider_frame,'SliderStep');
    value = get(handles.slider_frame,'Value');

    [userdata,video_id] = getGUIStatus(handles);

    if curr_slide_step(1) == 0.5 && (userdata.data(video_id).current_frame_step == 1)
        if value < userdata.data(video_id).current_frame
            value = floor(value);
        else
            value = ceil(value);
        end
    else
        value = round(value);
    end
    set(handles.edit_frame,'String',num2str(value));
    guidata(hObject,handles);
    edit_frame_Callback(handles.edit_frame,eventdata,handles);
end

% 'Current Frame'
function edit_frame_Callback(hObject, ~, handles)
    % hObject    handle to edit_frame (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of edit_frame as text
    %        str2double(get(hObject,'String')) returns contents of edit_frame as a double
    value = str2double(get(handles.edit_frame,'String'));
    [userdata,video_id] = getGUIStatus(handles);

    if ~isnan(value)
        value = round(value);
        delta = mod(value-userdata.data(video_id).current_start_frame,userdata.data(video_id).current_frame_step);
        if delta ~= 0
            value = value-delta;
        end
        value = min(max(userdata.data(video_id).current_start_frame,value),get(handles.slider_frame,'Max'));
        set(handles.edit_frame,'String',num2str(value));
        set(handles.slider_frame,'Value',value);
        userdata.data(video_id).current_frame = value;
        set(handles.figure1,'UserData',userdata);
        displayImage([],[],handles);
        updatePosition(handles);
        updateVisibility(handles);
        plotBoxImage(handles,1);
        plotBoxImage(handles,2);
        drawnow;
    else
        set(handles.edit_frame,'String',num2str(userdata.data(video_id).current_frame));
    end
    guidata(hObject,handles);
end

% 'Start Frame'
function edit_start_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_start_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_start_frame as text
%        str2double(get(hObject,'String')) returns contents of edit_start_frame as a double
new_start_frame = str2double(get(hObject,'String'));
[userdata,video_id] = getGUIStatus(handles);

if ~isnan(new_start_frame)
    new_start_frame = round(new_start_frame);
    new_start_frame = min(max(1,new_start_frame),userdata.data(video_id).vid.NumberOfFrames-1);
    
    if userdata.data(video_id).current_frame < new_start_frame
        % If we're starting ahead, update the current frame:
        userdata.data(video_id).current_frame = new_start_frame;
        set(handles.edit_frame,'String',num2str(new_start_frame));
    end
    
    if (new_start_frame + userdata.data(video_id).current_frame_step) > userdata.data(video_id).vid.NumberOfFrames
        % If with the current step we go over the limit, update the
        % step.
        new_range = max(1,userdata.data(video_id).vid.NumberOfFrame-new_start_frame);
        userdata.data(video_id).current_frame_step = new_range;
        set(handles.edit_frame_step,'String',num2str(new_range));
    end
    
    %     if ~any(userdata.data(video_id).current_frame == (new_start_frame:userdata.data(video_id).current_frame_step:userdata.data(video_id).vid.NumberOfFrames)
    delta = mod(userdata.data(video_id).current_frame-new_start_frame,userdata.data(video_id).current_frame_step);
    if delta ~= 0
        userdata.data(video_id).current_frame = userdata.data(video_id).current_frame - delta;
    end
    % We always have to edit the slider...
    new_max = userdata.data(video_id).vid.NumberOfFrames - mod(userdata.data(video_id).vid.NumberOfFrames-new_start_frame,userdata.data(video_id).current_frame_step);
    set(handles.slider_frame,'Min',new_start_frame,'Max',userdata.data(video_id).vid.NumberOfFrames - mod(userdata.data(video_id).vid.NumberOfFrames-new_start_frame,userdata.data(video_id).current_frame_step),'Value',userdata.data(video_id).current_frame);
    set(handles.edit_frame,'String',num2str(userdata.data(video_id).current_frame));
    set(handles.slider_frame,'SliderStep',userdata.data(video_id).current_frame_step/(new_max-new_start_frame+1)*[1 5]);
    set(handles.edit_start_frame,'String',num2str(new_start_frame));
    userdata.data(video_id).current_start_frame = new_start_frame;
else
    set(handles.edit_frame_step,'String',num2str(userdata.data(video_id).current_start_frame));
end
set(handles.figure1,'UserData',userdata);
guidata(hObject,handles);
end

% 'Frame Step'
function edit_frame_step_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame_step as text
%        str2double(get(hObject,'String')) returns contents of edit_frame_step as a double
    new_frame_step = str2double(get(handles.edit_frame_step,'String'));
    [userdata,video_id] = getGUIStatus(handles);

    if ~isnan(new_frame_step)
        % Getting current values for other frame parameters:
        current_start_frame = userdata.data(video_id).current_start_frame;
        current_frame = userdata.data(video_id).current_frame;

        % Updating the frame step:
        new_frame_step = round(new_frame_step);
        new_frame_step = min(max(1,new_frame_step),userdata.data(video_id).vid.NumberOfFrames-1);
        set(handles.edit_frame_step,'String',num2str(new_frame_step));

        % Computing the new maximum point:
        new_max = userdata.data(video_id).vid.NumberOfFrames - mod(userdata.data(video_id).vid.NumberOfFrames-current_start_frame,new_frame_step);
        set(handles.slider_frame,'Max',new_max);
        % Updating the step:
        set(handles.slider_frame,'SliderStep',(new_frame_step/(new_max-current_start_frame))*[1 5]);
        % Updating the current frame so it lies within the possible values:
        set(handles.slider_frame,'Value',current_frame - mod(current_frame-current_start_frame,new_frame_step));
        userdata.data(video_id).current_frame_step = new_frame_step;
        set(handles.figure1,'UserData',userdata);
        displayImage([],[],handles);
    else
        set(handles.edit_frame,'String',num2str(userdata.data(video_id).current_frame_step));
    end
    set(handles.figure1,'UserData',userdata);
    guidata(hObject,handles);
    slider_frame_Callback(handles.slider_frame,eventdata,handles);
end

% -- Play Video --

% FPS slider:
function slider_speed_Callback(hObject, eventdata, handles)
% hObject    handle to slider_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    val = get(hObject,'Value');
    restart = false;
    [userdata,video_id] = getGUIStatus(handles);
    if strcmpi(get(userdata.data(video_id).timer,'Running'),'on')
        restart = true;
        stop(userdata.data(video_id).timer);
    end
    set(userdata.data(video_id).timer,'Period',str2double(sprintf('%.02f\n',1/val)));
    set(handles.edit_speed,'String',num2str(val));
    if restart
        start(userdata.data(video_id).timer);
    end
    set(handles.figure1,'UserData',userdata);
end

% 'FPS'
function edit_speed_Callback(hObject, eventdata, handles)
% hObject    handle to edit_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_speed as text
%        str2double(get(hObject,'String')) returns contents of edit_speed as a double

    [userdata,video_id] = getGUIStatus(handles);
    value = str2double(get(hObject,'String'));
    restart = false;
    
    if strcmpi(get(userdata.data(video_id).timer,'Running'),'on')
        restart = true;
        stop(userdata.data(video_id).timer);
    end

    if isnan(value)
        value = 30;
    else
        value = min([max(1,value) 90]);
    end
    
    set(handles.edit_speed,'String',num2str(value));
    set(handles.slider_speed,'Value',value);
    set(userdata.data(video_id).timer,'Period',str2double(sprintf('%.02f\n',1/value)));
    displayImage([],[],handles);
    guidata(hObject,handles);

    if restart
        start(userdata.data(video_id).timer);
    end
    set(handles.figure1,'UserData',userdata);
end

% 'Play'
function togglebutton_play_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_play
    [userdata,video_id] = getGUIStatus(handles);
    value = get(hObject,'Value');
    toggleHandles = [handles.edit_frame handles.slider_frame handles.listbox_files handles.radiobutton_corrected handles.radiobutton_original];
    if value
        set(hObject,'String','Stop');
        % Gray out edit stuff that should not be changed
        set(toggleHandles,'Enable','off');
        start(userdata.data(video_id).timer);
    else
        set(toggleHandles,'Enable','on');
        handles.slider_frame.Value=handles.figure1.UserData.data.current_frame;
        set(hObject,'String','Play');
        stop(userdata.data(video_id).timer);

    end
    set(handles.figure1,'UserData',userdata);
    handles = resetGUI(handles);
end

% -- USING ARROWS ---

function figure1_KeyPressFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  structure with the following fields (see FIGURE)
    %	Key: name of the key that was pressed, in lower case
    %	Character: character interpretation of the key(s) that was pressed
    %	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
    % handles    structure with handles and user data (see GUIDATA)

    [userdata,video_id,lind] = getGUIStatus(handles);
	frame = userdata.data(video_id).current_frame;
    
    switch eventdata.Key
        % advance
        case 'rightarrow'
            frame = frame + userdata.data(video_id).current_frame_step;
        case 'return'
            frame = frame + userdata.data(video_id).current_frame_step;
        % move backwards
        case 'leftarrow'
            frame = frame - userdata.data(video_id).current_frame_step;
        case 'quote'
            frame = frame - userdata.data(video_id).current_frame_step;
        % switch current paw
        case 'slash'
            % FIXME (not sure how to do this at this point)
        % DELETE these track coordinates
        case 'rightbracket'
            userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,:) = ....
                nan(2,1,1,2);
        % confirm existing (copies coordinates from LM_track to track) and advance
        case 'backslash'
            track_k = userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,:);
            LM_track_k = userdata.data(video_id).LM_track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,:);
            idx_n = isnan(track_k);
            track_k(idx_n) = LM_track_k(idx_n);
            userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,:) ...
                = track_k;
            frame = frame + userdata.data(video_id).current_frame_step;
            
        otherwise
    end
%                 disp('\ - use marked pixel')
%                 disp('] - delete this tracking point')
%                 disp('enter - (default) next frame ')
%                 disp(''' - previous frame ')
%                 disp('; - jump to frame ')
%                 disp('. - switch view ')
%                 disp('x - exit');
%                 disp('/ - switch paw');
    userdata.data(video_id).current_frame = frame;
    set(handles.edit_frame,'String',num2str(frame));
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    
end

%% LABELLING OPTIONS

%           -- SIDE VIEW --
% 'I'
function edit_i_side_Callback(hObject, eventdata, handles)
% hObject    handle to edit_i_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_i_side as text
%        str2double(get(hObject,'String')) returns contents of edit_i_side as a double
new_i_side = str2double(get(handles.edit_i_side,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);

if ~isnan(new_i_side)
    curr_split_line = str2double(get(handles.edit_split_line,'String'));
    new_i_side = min(max(1,new_i_side),curr_split_line);
    
    userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,2) = new_i_side;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,2);
else
    set(handles.edit_i_side,'String',num2str(userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,2)));
end
guidata(hObject,handles);
end
% +
function pushbutton_i_side_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_side_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_side,'String'));
set(handles.edit_i_side,'String',num2str(curr_i_value+1));
edit_i_side_Callback(handles.edit_i_side,[],handles);
end
% -
function pushbutton_i_side_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_side_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_side,'String'));
set(handles.edit_i_side,'String',num2str(curr_i_value-1));
edit_i_side_Callback(handles.edit_i_side,[],handles);
end

% 'J'
function edit_j_side_Callback(hObject, eventdata, handles)
% hObject    handle to edit_j_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_j_side as text
%        str2double(get(hObject,'String')) returns contents of edit_j_side as a double
new_j_bottom = str2double(get(handles.edit_j_side,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);

if ~isnan(new_j_bottom)
    new_j_bottom = min(max(1,new_j_bottom),userdata.data(video_id).vid.Width);
    
    userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,2) = new_j_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,2);
else
    set(handles.edit_j_side,'String',num2str(userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,2)));
end
guidata(hObject,handles);
end
% +
function pushbutton_j_side_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_side_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_side,'String'));
set(handles.edit_j_side,'String',num2str(curr_j_value+1));
edit_j_side_Callback(handles.edit_j_side,[],handles);
end
% -
function pushbutton_j_side_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_side_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_side,'String'));
set(handles.edit_j_side,'String',num2str(curr_j_value-1));
edit_j_side_Callback(handles.edit_j_side,[],handles);
end
% Visibility popupmenu
function popupmenu_visible_side_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_visible_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_visible_side contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_visible_side
[userdata, video_id,lind] = getGUIStatus(handles);
vis_val = get(hObject,'Value');
switch vis_val
    case 1
        % Invisible:
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),2),'Visible','off');
    case 2
        % Visible:
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),2),'Visible','on');
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),2),'LineStyle','-');
    case 3
        % Partially visible:
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),2),'Visible','on');
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),2),'LineStyle',':');
end
userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,2) = vis_val;
set(handles.figure1,'UserData',userdata);
plotBoxImage(handles,2);
guidata(handles.figure1,handles);
end

%           -- BOTTOM VIEW --
% 'I'
function edit_i_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to edit_i_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_i_bottom as text
%        str2double(get(hObject,'String')) returns contents of edit_i_bottom as a double
new_i_bottom = str2double(get(handles.edit_i_bottom,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);

if ~isnan(new_i_bottom)
    curr_split_line = str2double(get(handles.edit_split_line,'String'));
    new_i_bottom = min(max(curr_split_line,new_i_bottom),userdata.data(video_id).vid.Height);
    
    userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,1) = new_i_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,1);
else
    set(handles.edit_i_bottom,'String',num2str(userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,1)));
end
guidata(hObject,handles);
end
% +
function pushbutton_i_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_bottom,'String'));
set(handles.edit_i_bottom,'String',num2str(curr_i_value+1));
edit_i_bottom_Callback(handles.edit_i_bottom,[],handles);
end
% -
function pushbutton_i_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_bottom,'String'));
set(handles.edit_i_bottom,'String',num2str(curr_i_value-1));
edit_i_bottom_Callback(handles.edit_i_bottom,[],handles);
end

% 'J'
function edit_j_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to edit_j_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_j_bottom as text
%        str2double(get(hObject,'String')) returns contents of edit_j_bottom as a double
new_j_bottom = str2double(get(handles.edit_j_bottom,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);

if ~isnan(new_j_bottom)
    new_j_bottom = min(max(1,new_j_bottom),userdata.data(video_id).vid.Width);
    
    userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,1) = new_j_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,1);
else
    set(handles.edit_j_bottom,'String',num2str(userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,1)));
end
guidata(hObject,handles);
end
% +
function pushbutton_j_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_bottom,'String'));
set(handles.edit_j_bottom,'String',num2str(curr_j_value+1));
edit_j_bottom_Callback(handles.edit_j_bottom,[],handles);
end
% -
function pushbutton_j_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_bottom,'String'));
set(handles.edit_j_bottom,'String',num2str(curr_j_value-1));
edit_j_bottom_Callback(handles.edit_j_bottom,[],handles);
end

% Visibility popupmenu
function popupmenu_visible_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_visible_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_visible_bottom contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_visible_bottom
[userdata, video_id,lind] = getGUIStatus(handles);
vis_val = get(hObject,'Value'); 

switch vis_val
    case 1
        % Invisible:
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),1),'Visible','off');
    case 2
        % Visible:
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),1),'Visible','on');
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),1),'LineStyle','-');
    case 3
        % Partially visible:
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),1),'Visible','on');
        set(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),1),'LineStyle',':');
end
userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}(lind(4), userdata.data(video_id).current_frame,1) = vis_val;
set(handles.figure1,'UserData',userdata);
plotBoxImage(handles,1);
guidata(handles.figure1,handles);
end

%           -- SCALE --

function edit_scale_Callback(hObject, eventdata, handles)
% hObject    handle to edit_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_scale as text
%        str2double(get(hObject,'String')) returns contents of edit_scale as a double

% getting user data:
[userdata, video_id] = getGUIStatus(handles);

val = str2num(get(handles.edit_scale,'String'));
error = true;
if ~isnan(val)
    
    if val > 4
        fprintf('The scale should not be higher than 4.');
    elseif val < 0.25
        fprintf('The scale factor should not be lower than 1/4.');
    else
        userdata.data(video_id).scale = val;
        %         userdata.data(video_id).track = userdata.data(video_id).track*val;
        error = false;
    end
end

if error
    val = num2str(userdata.data(video_id).scale);
    set(handles.edit_scale,'String',num2str(val));
else
    % update the image and userdata
    set(handles.figure1,'userdata',userdata);
    guidata(handles.figure1,handles);
    displayImage([],[],handles);
end
guidata(handles.figure1,handles);
end

%           -- SPLIT LINE PROPERTIES --
% 'I'
function edit_split_line_Callback(hObject, eventdata, handles)
% hObject    handle to edit_split_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_split_line as text
%        str2double(get(hObject,'String')) returns contents of edit_split_line as a double

new_split_line = round(str2double(get(handles.edit_split_line,'String')));
if ~isnan(new_split_line)
    [userdata,video_id,lind] = getGUIStatus(handles);
    new_split_line = min(max(1,new_split_line),userdata.data(video_id).vid.Height);
    userdata.data(video_id).split_line = new_split_line;
    set(handles.figure1,'UserData',userdata);
    set(handles.split_line ,'Xdata',[1 userdata.data(video_id).vid.Width],'Ydata',[new_split_line new_split_line]);
    
    % Check if any of the track violate the new split line:
    change = false;
    TB = userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,:,:,1);
    ind_bottom = TB < new_split_line;
    if any(ind_bottom(:))
        TB(ind_bottom) = new_split_line;
        userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,:,:,1) = TB;
        change = true;
    end
    
    TS = userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,:,:,2);
    ind_side = TS > new_split_line;
    
    if any(ind_side(:))
        TS(ind_side) = new_split_line;
        userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(2,:,:,2) = TS;
        change = true;
    end
    
    if change
        set(handles.figure1,'UserData',userdata);
        plotBoxImage(handles,1);plotBoxImage(handles,2);
        updatePosition(handles);
    end
    set(handles.edit_split_line,'String',num2str(new_split_line));
else
    set(handles.edit_split_line,'String',get(handles.split_line,'Ydata'));
end
end
% +
function pushbutton_i_split_line_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_split_line_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[userdata,video_id] = getGUIStatus(handles);
set(handles.edit_split_line,'String',num2str(userdata.data(video_id).split_line+1));
edit_split_line_Callback(handles.edit_split_line,[],handles);
end
% -
function pushbutton_i_split_line_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_split_line_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[userdata,video_id] = getGUIStatus(handles);
set(handles.edit_split_line,'String',num2str(userdata.data(video_id).split_line-1));
edit_split_line_Callback(handles.edit_split_line,[],handles);
end
% Color
function pushbutton_color_split_line_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_color_split_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_color = uisetcolor;
if length(new_color) ~= 1
    % Setting the color to the marker:
    set(handles.pushbutton_color_split_line,'BackgroundColor',new_color);
    set(handles.split_line,'Color',new_color);
end
guidata(hObject,handles);
end


%% DISPLAY OPTIONS

%       -- VIEW MATCHING --

% Radiobuttons for Original and Corrected view
function uipanel_distortion_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_distortion
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
% Update image:
    displayImage([],[],handles);

end

%       --------------------

% Correction file selection
function popupmenu_distortion_correction_files_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_distortion_correction_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_distortion_correction_files contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_distortion_correction_files

    [userdata,video_id] = getGUIStatus(handles);
    if video_id > 0
        value = get(handles.popupmenu_distortion_correction_files,'Value');
        userdata.data(video_id).ind_warp_mapping = [];
        userdata.data(video_id).inv_ind_warp_mapping = [];
        userdata.data(video_id).calibration_path = '';
        if value > 1

            file_list = get(handles.popupmenu_distortion_correction_files,'String');
            userdata.data(video_id).calibration_path = file_list{value};
            userdata.ind_warp_mapping = [];
            userdata.inv_ind_warp_mapping = [];

            L = load(userdata.data(video_id).calibration_path);
            f_to_check = {'inv_ind_warp_mapping','ind_warp_mapping','split_line'};
            for i_f = 1:length(f_to_check)
                if isfield(L,f_to_check{i_f})
                    userdata.data(video_id).(f_to_check{i_f}) = L.(f_to_check{i_f});
                end
            end
            set(handles.figure1,'userdata',userdata);

            % Update the split line:
            set(handles.edit_split_line,'String',num2str(userdata.data(video_id).split_line));
            edit_split_line_Callback([],[],handles);

            % Update the distortion pannel
            if ~isempty(userdata.data(video_id).ind_warp_mapping)
                set([handles.radiobutton_corrected handles.radiobutton_original],...
                    'Enable','on');
            else
                fprintf('The selected calibration file contains no information about the mapping!\n');
            end
        else
            set([handles.radiobutton_corrected handles.radiobutton_original],...
                'Enable','off');
        end

        userdata.data(video_id).calibration_popup_id = value;
        set(handles.figure1,'userdata',userdata);
    end
end
% 'Add'
function pushbutton_add_distortion_correction_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_distortion_correction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Browse supported file formats:
[file_name,path_name] = uigetfile(fullfile(handles.latest_path,'*.mat'),'MultiSelect','off');

if ~isequal(file_name,0) && ~isequal(path_name,0)
    [handles, N] = addDistortionCorrection(handles,fullfile(path_name,file_name));
    
    if N > 0
        % Adding the file to the list:
        calibration_list = get(handles.popupmenu_distortion_correction_files,'String');
        calibration_list{N} = fullfile(path_name,file_name);
        set(handles.popupmenu_distortion_correction_files,'String',calibration_list);
        popupmenu_distortion_correction_files_Callback([],[],handles);
    end
    
end
guidata(handles.figure1,handles);
end
% ||
% |_> Adding distortion correction file
function [handles, N] = addDistortionCorrection(handles, file_name)
% Check the existing list:
    correction_file_list = get(handles.popupmenu_distortion_correction_files,'String');
    compare_file_name = strcmpi(file_name,correction_file_list);

    if any(compare_file_name)
        % Check if the new file already exists:
        beep
        fprintf('%s is already on the distortion correction file list!\n',file_name);
        N = find(compare_file_name);
        return;
    end

    correction_file_list{end+1,:} = file_name;
    set(handles.popupmenu_distortion_correction_files,'String',correction_file_list);

    N = length(correction_file_list);
    [path_name,~,~] = fileparts(file_name);
    handles.latest_path = path_name;
    fprintf('%s added to the correction file list.\n',file_name);
end

% 'Background'
function checkbox_display_background_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_display_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_display_background
% cf = get(handles.figure1,'Userdata');
[userdata,video_id] = getGUIStatus(handles);
if get(hObject,'Value')
    userdata.data(video_id).bkg = [];
else
    userdata.data(video_id).bkg = imread(userdata.data(video_id).bkg_path);
end
set(handles.figure1,'userdata',userdata);
displayImage([],[],handles);
guidata(hObject,handles);
end
% Background file selection menu
function popupmenu_background_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_background contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_background
    [userdata,video_id] = getGUIStatus(handles);
    if video_id > 0
        try
            value = get(handles.popupmenu_background,'Value');
            string = get(handles.popupmenu_background,'String');

            if value == 1
                % Set no background:
                userdata.data(video_id).bkg_path = '';
                userdata.data(video_id).bkg = [];
                userdata.data(video_id).background_popup_id = 1;
                set(handles.checkbox_display_background,'Enable','off');
            else
                % Set chosen image:
                userdata.data(video_id).bkg_path = string{value};
                if get(handles.checkbox_display_background,'Value')
                    userdata.data(video_id).bkg = [];
                else
                    userdata.data(video_id).bkg = imread(string{value});
                end
                userdata.data(video_id).background_popup_id = value;
                set(handles.checkbox_display_background,'Enable','on');
            end
            set(handles.figure1,'userdata',userdata);
            displayImage([],[],handles);
            guidata(handles.figure1,handles);
        catch ET
            fprintf('Failed to assign chosen background!\n');
            displayErrorGui(ET);
        end
    end
end
% 'Add'
function pushbutton_add_background_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Browse supported file formats:
[file_name,path_name] = uigetfile(fullfile(handles.latest_path,'*.png'),'MultiSelect','off');

if ~isequal(file_name,0) && ~isequal(path_name,0)
    file_full_path = fullfile(path_name,file_name);clear path_name file_name
    handles = addBackgroundImage(file_full_path,handles);
end
guidata(handles.figure1,handles);
end
% |> add new file to list
function [handles,N] = addBackgroundImage(file_full_path,handles)
    % Check the existing list:
    background_list = get(handles.popupmenu_background,'String');
    check_repetition = strcmpi(file_full_path,background_list);
    if any(check_repetition)
        % Check if the new file already exists:
        fprintf('%s is already on the background file list.\n',file_full_path);
        N = find(check_repetition);
        return;
    end
    N = length(background_list)+1;
    if N == 2
        set(handles.popupmenu_background,'Enable','on');
        set(handles.checkbox_display_background,'Enable','on');
    end
    background_list{N,:} = file_full_path;
    set(handles.popupmenu_background,'String',background_list);
    fprintf('%s added to the background file list.\n',file_full_path);
end

% 'Vertical Flip'
function checkbox_vertical_flip_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_vertical_flip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_vertical_flip

    [userdata,video_id,lind] = getGUIStatus(handles);
    
    % Save current state in memory so its not lost when changing videos:
    userdata.data(video_id).flip = get(hObject,'Value');
    set(handles.figure1,'UserData',userdata);
    displayImage([],[],handles);
    updatePosition(handles);
    guidata(handles.figure1,handles);
end

% 'Split Line'
function checkbox_display_split_line_Callback(hObject, eventdata, handles)
    % hObject    handle to checkbox_display_split_line (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of checkbox_display_split_line
    value = get(hObject,'Value');
    if value == 1
        set(handles.split_line,'Visible','on');
    else
        set(handles.split_line,'Visible','off');
    end
end


%% LABEL OPTIONS

function popupmenu_type_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_type contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from popupmenu_type

    label_type = get(handles.popupmenu_type,'Value');
    [userdata,~,~] = getGUIStatus(handles);

    % Updating the popupmenu_class string:
    set(handles.popupmenu_class,'String',userdata.classes{label_type},...
        'Value',1);

    % Updating popupmenu_name:
    set(handles.popupmenu_name,'String',userdata.features{label_type}{1},...
        'Value',1);

    % Updating popupmenu n_points:
    set(handles.popupmenu_n_points,'String',num2cell(1:userdata.labels...
        {label_type}{1}(1).N_points),...
        'Value',1);
    popupmenu_n_points_Callback(hObject,eventdata,handles)
end

%selection change in popupmenu_class.
function popupmenu_class_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_class contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_class

% Changing the variable class. It has no effect on the labelling, only
% later on during training.

[userdata,~,lind] = getGUIStatus(handles);

% Updating popupmenu_name:
set(handles.popupmenu_name,'String',userdata.features{lind(1)}{lind(2)});
set(handles.popupmenu_name,'Value',1);

% Updating popupmenu n_points:
set(handles.popupmenu_n_points,'String',userdata.labels{lind(1)}{lind(1)}(lind(3)).N_points,...
    'Value',1);

popupmenu_n_points_Callback(hObject,eventdata,handles)
end

%selection change in popupmenu_name.
function popupmenu_name_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_name contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_name
    [userdata,~,lind] = getGUIStatus(handles);

    % Update popup n_points
    set(handles.popupmenu_n_points,'String',num2cell(1:userdata.labels{lind(1)}{lind(2)}(lind(3)).N_points),...
        'Value',1);
    popupmenu_n_points_Callback([],[],handles);
end

%selection change in popupmenu_n_points.
function popupmenu_n_points_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_n_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_n_points contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_n_points

    [userdata, ~, lind] = getGUIStatus(handles);

    point_list = get(handles.popupmenu_n_points,'String');
    value = get(handles.popupmenu_n_points,'Value');
    if length(point_list) == 1
        set(handles.popupmenu_n_points,'Enable','off');
    elseif strcmpi(get(handles.popupmenu_n_points,'Enable'),'off')
        set(handles.popupmenu_n_points,'Enable','on');
    end

    % Updating the boxes on the plot:
    plotBoxImage(handles,1);
    plotBoxImage(handles,2);
    updatePosition(handles);


end

%button press in pushbutton_add_label.
function pushbutton_add_label_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = getGUIStatus(handles);
[add_button,new_type,new_class,new_feature,new_n_points] = newlabel(...
    userdata.types,userdata.classes,userdata.features);

if add_button
    userdata = getGUIStatus(handles);
    % Adding the new data to the tree:
    % Check if type is new:
    type_comp = strcmpi(new_type,userdata.types);
    if any(type_comp)
        type_index = find(type_comp);
        
        class_comp = strcmpi(new_class,userdata.classes{type_index});
        if any(class_comp)
            class_index = find(class_comp);
            % The name has to be new for this class and type:
            name_index = length(userdata.features{type_index}{class_index})+1;
     
        else
            class_index = length(userdata.classes{type_index})+1;
            name_index = 1;
        end
        
    else
        type_index = length(userdata.types)+1;
        class_index = 1;
        name_index = 1;
    end
    
    new_lab.type = new_type;
    new_lab.class = new_class;
    new_lab.name = new_feature;
    new_lab.box_size = [30 20;30 30];
    new_lab.N_points = new_n_points;
    handles = addMergeLabels(handles,[type_index class_index name_index new_n_points], new_lab);
    guidata(handles.figure1,handles);
    set(handles.popupmenu_type,'Value',type_index);
    popupmenu_type_Callback([],[],handles);
    set(handles.popupmenu_class,'Value',class_index);
    popupmenu_class_Callback([],[],handles);
    set(handles.popupmenu_name,'Value',name_index);
    popupmenu_name_Callback([],[],handles);
end
guidata(handles.figure1,handles);
end

%button press in pushbutton_delete_label.
function pushbutton_delete_label_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_delete_label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Confirm delete:
[userdata,video_id,lind] = getGUIStatus(handles);
answ = questdlg(sprintf('Are you sure you want to delete the following label?\nType: %s\nClass: %s\nName: %s\nAll data for all videos for this label will be lost.',...
    userdata.types{lind(1)},...
    userdata.classes{lind(1)}{lind(2)},...
    userdata.features{lind(1)}{lind(2)}{lind(3)}),...
    'Delete Label','Yes','No','No');

if strcmpi(answ,'yes')
    % Updating the tree structure:
    % Removing the label name properties:
    userdata.features{lind(1)}{lind(2)}(lind(3)) = [];
    delete(userdata.plot_handles.track{lind(1)}{lind(2)}{lind(3)}(:))
    userdata.plot_handles.track{lind(1)}{lind(2)}(lind(3)) = [];
    userdata.labels{lind(1)}{lind(2)}(lind(3)) = [];
    Nfeatures = length(userdata.features{lind(1)}{lind(2)});
    
    if video_id > 0
        for i_videos = 1:length(userdata)
            % Removing track and visibility data:
            userdata.data(video_id).track{lind(1)}{lind(2)}(lind(3)) = [];
            userdata.data(video_id).visibility{lind(1)}{lind(2)}(lind(3)) = [];
        end
    end
    if Nfeatures == 0
        % If no names left, remove class:
        userdata.features{lind(1)}(lind(2)) = [];
        userdata.classes{lind(1)}(lind(2)) = [];
        userdata.plot_handles.track{lind(1)}(lind(2)) = [];
        userdata.labels{lind(1)}(lind(2)) = [];
        if video_id > 0
            for i_videos = 1:length(userdata)
                % Removing track and visibility data:
                userdata.data(video_id).track{lind(1)}{lind(2)} = [];
                userdata.data(video_id).visibility{lind(1)}{lind(2)} = [];
            end
        end
        
        Nclasses = length(userdata.features{lind(1)});
        
        if Nclasses == 0
            % If no classes left, remove type:
            userdata.features(lind(1)) = [];
            userdata.classes(lind(1)) = [];
            userdata.types(lind(1)) = [];
            userdata.plot_handles.track(lind(1)) = [];
            userdata.labels(lind(1)) = [];
            
            if video_id > 0
                for i_videos = 1:length(userdata)
                    % Removing track and visibility data:
                    userdata.data(video_id).track(lind(1)) = [];
                    userdata.data(video_id).visibility(lind(1)) = [];
                end
            end
            Ntype = length(userdata.features);
            
            if Ntype == 0
                % If no type is left, remove type:
                userdata.features = [];
                userdata.classes = [];
                userdata.plot_handles.track = [];
                userdata.labels = [];
                
                % Updating GUI visuals:
                set([handles.popupmenu_type handles.popupmenu_class...
                    handles.popupmenu_name handles.popupmenu_n_points...
                    handles.pushbutton_delete_label handles.checkbox_display_all_tracks],'Enable','off');
                set([handles.popupmenu_type handles.popupmenu_n_points...
                    handles.popupmenu_class handles.popupmenu_name],'String',' ');
                return;
            elseif Ntype < lind(1)
                lind(1) = Ntype;
                lind(2:4) = 1;
            end
            % Update the popupmenu from type downwards:
            set(handles.popupmenu_type,'String',userdata.types{lind(1)},...
                'Value',lind(1))
            set(handles.figure1,'userdata',userdata);
            popupmenu_type_Callback([],[],handles);
            
        elseif Nclasses < lind(2)
            lind(2) = Nclasses;
            lind(3:4) = 1;
        end
        
        % Update the popupmenu from class downwards:
        set(handles.popupmenu_class,'String',userdata.classes{lind(1)},...
            'Value',lind(2));
        set(handles.figure1,'userdata',userdata);
        popupmenu_class_Callback([],[],handles);
    elseif Nfeatures < lind(3)
        lind(3) = Nfeatures;
        lind(4) = 1;
    end
    
    % Update the popupmenu from features downwards:
    set(handles.popupmenu_name,'String',userdata.features{lind(1)}{lind(2)},...
        'Value',lind(3));
    set(handles.figure1,'userdata',userdata);
    popupmenu_name_Callback([],[],handles);
end

% Updating the GUI information:
guidata(handles.figure1,handles);
end

%button press in checkbox_all_points.
function checkbox_all_points_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_all_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_all_points
plotBoxImage(handles,1);
plotBoxImage(handles,2);
end

function checkbox_display_all_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_display_all_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_display_all_tracks
plotBoxImage(handles,1);
plotBoxImage(handles,2);

end

%% DATA GUI

% -- Processes selected video file, checks if it is already loaded and if
% not checks for existing background and labelling files:
function handles = addVideoFile(handles,path_name,file_name)
% Store the path in case more files are to be added...
handles.latest_path = path_name;
current_file_list = get(handles.listbox_files,'String');

if ~iscell(file_name)
    file_name = {file_name};
end

% Check for repeated file names:
file_name = cellfun(@(x)(fullfile(path_name,x)),file_name,'un',false);
isrepeated = cellfun(@(x)(any(strcmpi(current_file_list,x))),file_name);

file_name = file_name(~isrepeated);
% Initialize the tracking structure for such videos:
N_files = length(file_name);
[userdata, ~] = getGUIStatus(handles);
video_id = length(current_file_list);
if isempty(current_file_list)
    % Enabling the GUI:
    changeGUIActiveState(handles);
end
for i_files = 1:N_files
    % Updating the list with the current file so the video_id matches:
    current_file_list = get(handles.listbox_files,'String');
    set(handles.listbox_files,'String',cat(1,current_file_list,file_name{i_files}));
    video_id = video_id+1;
    set(handles.listbox_files,'Value',video_id);
    % Initialize the tracking structure for the videos:
    vid = VideoReader(char(file_name{i_files}));
    % Initializing the data structure for this video:
    d = initializeUserDataStructure(userdata, vid);
    
    if video_id == 1
        % FIXME: If the structure had been properly initialized as empty this
        % check would not have been needed.
        userdata.data = d;
    else
        
        userdata.data(video_id) = d;
    end
    
    set(handles.figure1,'userdata',userdata);
    [~,fname,~] = fileparts(char(file_name{i_files}));
    % Checking if there are labelling files to load for this video:
    lab_path = fullfile(vid.Path,[fname '_labelling.mat']);
    
    if exist(lab_path,'file')
        % Attempt to load label file.
        handles = loadtrack(handles, load(lab_path)); % JF: third argument true removed
    end
    userdata = get(handles.figure1,'userdata');
    % If for some reason the bkg path is not the same as the one loaded we
    % still check the current folder:
    if isempty(userdata.data(video_id).bkg_path)
        % Check if there is a background image with the same name:
        impath = fullfile(vid.Path,[fname '.png']);
        if exist(impath,'file')
            % Adding a new background image:
            [handles,N] = addBackgroundImage(impath,handles);
            userdata.data(video_id).bkg_path = impath;
            userdata.data(video_id).bkg = imread(impath);
            userdata.data(video_id).background_popup_id = N;
            set(handles.figure1,'userdata',userdata);
        end
    end
    
    %         if isempty(userdata.data(video_id).calibration_path)
    %             % Check if there is a calibration file with the same name:
    %             calpath = fullfile(vid.Path,[fname '_calibration.mat']);
    %             if exist(calpath,'file')
    %                 % Adding a new background image:
    %                 [handles,N] = addDistortionCorrection(handles,calpath);
    %                 userdata.data(video_id).calibration_path = calpath;
    %                 userdata.data(video_id).calibration_popup_id = N;
    %                 L = load(calpath);
    %                 userdata.data(video_id).ind_warp_mapping = L.ind_warp_mapping;
    %                 userdata.data(video_id).inv_ind_warp_mapping = L.inv_ind_warp_mapping;
    %                 userdata.data(video_id).split_line = L.split_line;
    %                 set(handles.figure1,'userdata',userdata);
    %                 edit_split_line_Callback([],[],handles);
    %             end
    %         end
    
    
    if ~isempty(userdata.data(end).bkg) % Check if background was loaded
        set(handles.checkbox_display_background,'Enable','on');
        set(handles.checkbox_display_background,'Value',1);
    else
        set(handles.checkbox_display_background,'Enable','off');
    end
    
    % Execute the poupmenu for the distortion files:
    guidata(handles.figure1,handles);
    
    clear vid;
end
guidata(handles.figure1,handles);
clear path_name;
end

%       -- LISTBOX --

%selection change in listbox_files.
function listbox_files_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_files contents as cell array
%#        contents{get(hObject,'Value')} returns selected item from listbox_files


try
    
    handles = GUI_Status(handles,'off');
    
    
    [userdata,video_id] = getGUIStatus(handles);
    if video_id > 0
        % Reset the GUI with the current video:
        handles = resetGUI(handles);
        
        % Output and background functions:
        bkg_mode = get(handles.popupmenu_background_mode,'Value');
        output_mode = get(handles.popupmenu_output_mode,'Value');
        bkg_fun = get(handles.popupmenu_background_mode,'String');
        bkg_fun = bkg_fun{bkg_mode};clear bkg_mode
        output_fun = get(handles.popupmenu_output_mode,'String');
        output_fun = output_fun{output_mode};clear output_mode
        output_path = get(handles.edit_output_path,'String');
        file_name=char(handles.listbox_files.String(handles.listbox_files.Value,:));
        
        [~,trial_name,~] = fileparts(file_name);
        v=VideoReader(file_name);
        set(handles.text_VidInfo, ...
            'String',[trial_name,' ::  frame rate: ',num2str(v.FrameRate),'fps - duration: ',num2str(v.Duration),'s'], ...
            'FontSize',12);
        clear v
        bkg_file = feval(bkg_fun,file_name);
        if isempty(bkg_file)
            bkg_file = 'compute';
        end
        
        [out_path_data,~] = feval(output_fun,output_path,file_name);
        
        expected_data_file = [out_path_data filesep trial_name,'.mat'];
        
        if exist(expected_data_file,'file') == 2
            loaded_data = load(expected_data_file);
            handles = loadtrack(handles, loaded_data);
            
            [userdata,video_id] = getGUIStatus(handles);
            
            userdata.data(video_id).DataFile = expected_data_file;
            % Preparing limited video window
            
            if size(loaded_data.final_tracks,1) == 4 % collecting all X data in variable xtracks
                xtracks = [loaded_data.final_tracks(1,:,:) loaded_data.final_tracks(3,:,:) loaded_data.tracks_tail(1,:,:) loaded_data.tracks_tail(3,:,:)]; % uncorrected tracks have two x values
            else
                xtracks = [loaded_data.final_tracks(1,:,:) loaded_data.tracks_tail(1,:,:)]; % corrected tracks have one x value
            end
            % the largest difference in x values found in all frames is minimum
            % window size.
            xWidth = zeros(1,size(xtracks,3));
            WindowX= zeros(1,size(xtracks,3));
            for t_fi = 1: size(xtracks,3)
                xWidth(t_fi) = nanmax(xtracks(:,:,t_fi)) - nanmin(xtracks(:,:,t_fi));
                WindowX(t_fi) = mean([nanmin(xtracks(:,:,t_fi)) nanmax(xtracks(:,:,t_fi))]);
            end
            WindowX_s = smooth(WindowX',401);
            winHalfWidth = ceil(((ceil(max(xWidth)/10)*10)+99)/2); % rounding and adding some pixels for convenience
            
            x_idx = zeros(size(xtracks,3),2);
            for t_fi = 1: size(xtracks,3)
                x_idx(t_fi,:) = round([WindowX(t_fi) - winHalfWidth , WindowX(t_fi) + winHalfWidth]);
                if min(x_idx(t_fi)) < 0
                    x_idx(t_fi,:) = x_idx(t_fi,:) - min(x_idx(t_fi,:)) +1;
                end
                if max(x_idx(t_fi,:)) > userdata.data(video_id).vid.Width
                    x_idx(t_fi,:) = x_idx(t_fi,:) - max(x_idx(t_fi,:)) + userdata.data(video_id).vid.Width;
                end
            end
            userdata.data(video_id).LimitedWindow_X = inpaint_nans(x_idx);
            userdata.data(video_id).UseLimitedWindow = true;
            set(handles.checkbox_LimitWindow,'Value',true);
            set(handles.figure1,'UserData',userdata);
            
            updatePosition(handles);
            set([handles.radiobutton_corrected handles.radiobutton_original],'Enable','on')
            
        else
            disp('DATA FILE not found. Please check settings.')
            disp(expected_data_file);
        end
        
        if exist(bkg_file,'file')==2
            bkg_ls = get(handles.popupmenu_background,'String');
            if ~any(strcmp(bkg_ls,bkg_file))
                bkg_ls = [bkg_ls; {bkg_file}];
                set(handles.popupmenu_background,'String',bkg_ls);
            end
            set(handles.popupmenu_background,'Value',find(strcmp(bkg_ls,bkg_file)));
            userdata.data(video_id).bkg_path = bkg_file;
            userdata.data(video_id).bkg = imread(bkg_file);
            userdata.data(video_id).background_popup_id = find(strcmp(bkg_ls,bkg_file));
            set(handles.figure1,'UserData',userdata);
            set(handles.checkbox_display_background,'Enable','on');
            
        end
        
        set(handles.edit_frame,'String','1');
        set(handles.edit_speed,'String','30');
        handles = resetGUI(handles);
        
        userdata.data(video_id).timer = timer('Period',str2double(sprintf('%.02f',1/30)),'ExecutionMode','FixedSpacing','TasksToExecute',Inf,'BusyMode','Queue','TimerFcn',{@displayImage,handles},'UserData',{1});
        set(handles.figure1,'UserData',userdata);
        displayImage([],[],handles);
        plotBoxImage(handles,1);
        plotBoxImage(handles,2);
        guidata(hObject,handles);
        
    end
catch err
end

handles = GUI_Status(handles,'on');
guidata(handles.figure1,handles);
end

%       -- ADD... --
%button press in pushbutton_add_file.
function pushbutton_add_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [file_name,path_name] = uigetfile(handles.supported_files,'Choose a supported video file',handles.latest_path,'MultiSelect','on');

    if ~isequal(file_name,0) && ~isequal(path_name,0)
        handles = addVideoFile(handles, path_name, file_name);
        guidata(hObject,handles);
        listbox_files_Callback(handles.listbox_files,eventdata,handles);
    end
end

%button press in pushbutton_add_folder.
function pushbutton_add_folder_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    path_name = uigetdir(handles.latest_path,'Import all supported files of selected folder.');
    if ~isequal(path_name,0)
        file_name = cell(1,0);
        % Get all allowed video files on that path:
        for i_sft = 2:handles.N_supported_files
            flist = lsOSIndependent(fullfile(path_name,handles.supported_files{i_sft-1,1}));
            if ~isempty(flist)
                flist = mat2cell(flist,ones(1,size(flist,1)),size(flist,2));
                flist = cellfun(@(x)(strtrim(x)),flist','un',0);
                file_name = [file_name flist];
            end
        end

        if ~isempty(file_name)
            handles = addVideoFile(handles, path_name, file_name);
            guidata(hObject,handles);
            listbox_files_Callback(handles.listbox_files,eventdata,handles);
        end
    end

end

%button press in pushbutton_add_with_subfolders.
function pushbutton_add_with_subfolders_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_with_subfolders (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    path_name = uigetdir('','Choose directory with supported video files');
   
    if ~isequal(path_name,0)
        file_name = cell(1,0);
        % Get all allowed video files on that path:

            flist = find_files_in_subfolders(path_name,handles.supported_files{1,1});
            
            if ~isempty(flist)
                flist = mat2cell(flist,ones(1,size(flist,1)),size(flist,2));
                flist = cellfun(@(x)(strtrim(x)),flist','un',0);
                file_name = [file_name flist];
            end
            for tfn_i = 1:size(file_name,2)
                file_name{tfn_i} = strrep(file_name{tfn_i}, [path_name filesep],'');
            end
        

        if ~isempty(file_name)
            handles = addVideoFile(handles, path_name, file_name);
            guidata(hObject,handles);
            listbox_files_Callback(handles.listbox_files,eventdata,handles);
        end
    end
end

function [list] = find_files_in_subfolders(tfolder,ext)
    
    fold_cont = dir(fullfile(tfolder));
    list={};
    for fc_i = 3: size(fold_cont,1) 
        if fold_cont(fc_i).isdir
            list = [list; find_files_in_subfolders([tfolder filesep fold_cont(fc_i).name],ext)];
        else
            [fpath,fname,fext] = fileparts([tfolder filesep fold_cont(fc_i).name]);
            if ~isempty(strfind(ext,fext))
                list = [list; {[tfolder filesep fold_cont(fc_i).name]}];
            end
        end
    end
    
    
end

%       -- REMOVE... --

%button press in pushbutton_remove.
function pushbutton_remove_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = getGUIStatus(handles);
selected_files = get(handles.listbox_files,'Value');
current_files = get(handles.listbox_files,'String');
if any(selected_files == size(current_files,1))
    value = size(current_files,1)-length(selected_files);
else
    value = selected_files(end);
end

current_files(selected_files) = [];
userdata.data(selected_files) = [];

set(handles.listbox_files,'String',current_files);
if value == 0
    % Just so the listbox doesn't crash:
    value = 1;
end
set(handles.listbox_files,'Value',value);
set(handles.figure1,'UserData',userdata);

if isempty(current_files)
    changeGUIActiveState(handles);
    guidata(hObject,handles);
else
    guidata(hObject,handles);
    listbox_files_Callback(handles.listbox_files,eventdata,handles);
end
end
%selection change in popupmenu_type.

%button press in pushbutton_clear_FileList.
function pushbutton_clear_FileList_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clear_FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.listbox_files,'String',{});
    changeGUIActiveState(handles);
end

%       -- DATA LOCATION --

%selection change in popupmenu_output_mode.
function popupmenu_output_mode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_output_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_output_mode
end

function edit_output_path_Callback(hObject, eventdata, handles)
% hObject    handle to edit_output_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_output_path as text
%        str2double(get(hObject,'String')) returns contents of edit_output_path as a double

    proposed_path = get(handles.edit_output_path,'String');

    if ~exist(proposed_path,'dir')
        set(handles.edit_output_path,'String',get(handles.figure1,'UserData'));
        fprintf('Output path is not a valid path!\n');
        beep;
    else
        set(handles.figure1,'UserData',proposed_path);
    end

    guidata(handles.figure1,handles);

end

%button press in pushbutton_browse_output.
function pushbutton_browse_output_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_browse_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    out_path = uigetdir(get(handles.edit_output_path,'String'));
    if ischar(out_path)
        set(handles.edit_output_path,'String',out_path);
    end
    guidata(handles.figure1,handles);
end

%selection change in popupmenu_background_mode.
function popupmenu_background_mode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_background_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_background_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_background_mode
end

%       -- LOAD and SAVE settings --

%button press in LoadSettings.
function LoadSettings_Callback(hObject, eventdata, handles, tlfilename)
% hObject    handle to LoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
     if exist('tlfilename')~=1
        tlfilename = [];
    end
    LMGUI_LoadSettings_Callback(handles, tlfilename);
end

%button press in SaveSettings.
function SaveSettings_Callback(hObject, eventdata, handles, tsfilename)
% hObject    handle to SaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if exist('tsfilename')~=1
        tsfilename = [];
    end
    LMGUI_SaveSettings_Callback(handles, tsfilename);
end


%% AXES_FRAME: FRAME DISPLAY
% --- Gets the position of the click from the mouse on the figure.
function axes_frame_ButtonDownFcn(hObject,eventdata,handles)
    % hObject    handle to axes_frame (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    if ~get(handles.checkbox_ShowNewLabels,'Value') 
        return; 
    end
    
    [userdata,video_id,lind] = getGUIStatus(handles);
    
    p = get(handles.axes_frame,'CurrentPoint');
    p = round(p(1,1:2));

    if p(2) > userdata.data(video_id).split_line
        
        view = 1; % Bottom
    else
        view = 2; % Side
    end

    

    % If showing corrected images, p needs to be warped back to original:
    if handles.radiobutton_corrected == get(handles.uipanel_distortion,'SelectedObject')
        % FIXME this appears to always return NaN:
        p([2 1]) = warpPointCoordinates(p([2 1]),userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping),userdata.data.flip);
    end
    
   
    if userdata.data(video_id).flip
        if  userdata.data(video_id).UseLimitedWindow
            tWidth = diff(userdata.data(video_id).LimitedWindow_X(userdata.data(video_id).current_frame,:));
        else
            tWidth = userdata.data(video_id).vid.Width;
        end
        p(1) = tWidth - p(1) + 1;
    end
    
    if userdata.data(video_id).UseLimitedWindow
        p(1) = p(1) + userdata.data(video_id).LimitedWindow_X(userdata.data(video_id).current_frame,1);
    end

    
    userdata.data(video_id).track{lind(1)}{lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,view) = p';

    userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,view) = 2;
    
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    displayImage([],[],handles);
    guidata(handles.figure1,handles);
    
    if handles.togglebutton_RetrackMode.Value
       pushbutton_ReTrack_Callback(hObject, eventdata, handles);
    end
    
end

function displayImage(obj,event,handles)
% This function reads the current frame from the video and updates it on
% the GUI.
    [userdata,video_id,~] = getGUIStatus(handles);
    if get(handles.togglebutton_PlayEpochVid,'Value')
        first_frame = userdata.data(video_id).Good_Epochs{get(handles.popupmenu_MovieEpochs,'Value')}(1);
        last_frame = userdata.data(video_id).Good_Epochs{get(handles.popupmenu_MovieEpochs,'Value')}(2);
    else
        first_frame = userdata.data(video_id).current_start_frame;
        last_frame = userdata.data(video_id).vid.NumberOfFrames;
    end
    
    if userdata.data(video_id).current_frame > last_frame
        userdata.data(video_id).current_frame = first_frame;
        set(handles.figure1,'userdata',userdata);
    elseif userdata.data(video_id).current_frame < first_frame
        % if we navigate backwards beyond frame 1, we want to turn around to the last frame step
        % in the video.
        userdata.data(video_id).current_frame = ...
            ( ...
                ( ...
                round( ...
                    (last_frame - first_frame) ...
                    / userdata.data(video_id).current_frame_step ...
                    ) ...
                -1 ...
                ) ...
                * userdata.data(video_id).current_frame_step ...
            ) ...
            + first_frame;
        set(handles.figure1,'userdata',userdata);
    end
    set(handles.slider_frame,'Value',userdata.data(video_id).current_frame);
    
    current_frame = userdata.data(video_id).current_frame;    
    
    [Iorg,Idist] = readMouseImage(userdata.data(video_id).vid,...
        current_frame,...
        userdata.data(video_id).bkg,...
        get(handles.checkbox_vertical_flip,'Value'),...
        userdata.data(video_id).scale,...
        userdata.data(video_id).ind_warp_mapping,...
        size(userdata.data(video_id).inv_ind_warp_mapping));

    if userdata.data(video_id).UseLimitedWindow
        xIDX = [userdata.data(video_id).LimitedWindow_X(current_frame,1) : userdata.data(video_id).LimitedWindow_X(current_frame,2)];
        if get(handles.checkbox_vertical_flip,'Value')
            xIDX(1,end:-1:1) = handles.figure1.UserData.data(video_id).vid.Width - xIDX +1;
        end
        xIDX = xIDX(ismember(xIDX,[1:userdata.data(video_id).vid.Width]));
        Iorg = Iorg(:,xIDX);
        Idist = Idist(:,xIDX);
    end
    
    if get(handles.uipanel_distortion,'SelectedObject') == handles.radiobutton_original
        set(handles.image,'CData',Iorg);
        set(handles.image,'XData',[1 size(Iorg,2)])
    else
        set(handles.image,'CData',Idist);
        set(handles.image,'XData',[1 size(Idist,2)])
    end
    drawnow;
    set(handles.edit_frame,'String',num2str(current_frame));
       
	plotBoxImage(handles,1); % Plots labelling for bottom view
	plotBoxImage(handles,2); % Plots labelling for side view

    % If timer is on, increment the frame counter:
    if strcmpi(get(obj,'Type'),'timer')
        if strcmpi(get(obj,'Running'),'on')
            handles.figure1.UserData.data(video_id).current_frame=current_frame+str2double(handles.edit_frame_step.String);
        end
    end
    
    set(handles.figure1,'CurrentAxes',handles.axes_frame);
end

% --- PLOTTING LABELS



function [] = plotBoxImage(handles,i_view)
    % Input:
    % user_data: the data stored in handles.figure1 as 'UserData' which
    % contains the properties of all boxes being tracked.
    % box: the index of the box to plot. If all boxes are to be plotted, the
    % index should be 0.
    [userdata, video_id,lind] = getGUIStatus(handles);
    if video_id ==0;return;end
    % Setting all handles of that view to off. This is to better deal with
    % which boxes are to be visible.
    PH = cat(2,userdata.plot_handles.track{:});PH = cat(2,PH{:});
	PH = cell2mat(cellfun(@(x)(x(:,:,i_view)),PH,'un',0));
    set(PH(:),'Visible','off');
    PH = cat(2,userdata.plot_handles.LM_track{:});PH = cat(2,PH{:});
    PH = cell2mat(cellfun(@(x)(x(:,:,i_view)),PH,'un',0));
    set(PH(:),'Visible','off');

    % Check if the image is original or distorted:
    if get(handles.uipanel_distortion,'SelectedObject') == handles.radiobutton_corrected
        warp = true;
    else
        warp = false;
    end

    N_types = length(userdata.types);
    % Check if all boxes are to be plotted
    if get(handles.checkbox_display_all_tracks,'Value')
        % Plotting all track:
        % Looping types:
        for i_type = 1:N_types
            N_classes_type = length(userdata.classes{i_type});
            for i_class = 1:N_classes_type
                N_features_class_type = length(userdata.features{i_type}{i_class});
                for i_feature = 1:N_features_class_type
                    points_to_plot = 1:userdata.labels{i_type}{i_class}(i_feature).N_points;
                    for i_point = points_to_plot
                        if userdata.data(video_id).Show_LM_track 
                            userdata = plotBoxImage_proper(userdata,video_id,[i_type i_class i_feature i_point],warp, i_view,'LM_track');
                        end
                        if userdata.data(video_id).Show_track 
                            userdata = plotBoxImage_proper(userdata,video_id,[i_type i_class i_feature i_point],warp, i_view,'track');
                        end                        
                    end
                end
            end
        end
    else
        % Plotting current track:
        % Check how many points to plot:
        if get(handles.checkbox_all_points,'Value')
            points_to_plot = 1:userdata.labels{lind(1)}{lind(2)}(lind(3)).N_points;
        else
            points_to_plot = lind(4);
        end

        % Plotting the current point:
        for i_point = points_to_plot
            if userdata.data(video_id).Show_LM_track 
                userdata = plotBoxImage_proper(userdata, video_id, [lind(1:3) i_point],warp, i_view,'LM_track');
            end
            if userdata.data(video_id).Show_track 
                userdata = plotBoxImage_proper(userdata, video_id, [lind(1:3) i_point],warp, i_view,'track');
            end             
        end
    end
    set(handles.figure1,'userdata',userdata);
end


% --- Plots a single box:
function [userdata] = plotBoxImage_proper(userdata, video_id, lind,  warp, i_view, track_field)
    flip = userdata.data(video_id).flip;
    box_size_k = userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(:,i_view);  
    LimWin = userdata.data(video_id).LimitedWindow_X(userdata.data(video_id).current_frame,flip+1);
    [tHeight,tWidth] = size(userdata.data(video_id).inv_ind_warp_mapping);
    track_k = userdata.data(video_id).(track_field){lind(1)}{lind(2)}{lind(3)}...
        (:,lind(4),userdata.data(video_id).current_frame,i_view);
    
    o_view = [3 2 1];
    track_ko = round(userdata.data(video_id).(track_field){lind(1)}{lind(2)}{lind(3)}...
        (:,lind(4),userdata.data(video_id).current_frame,o_view(i_view+1)));
    
    % if we don't have coordinates in this view but in the other, 
    % we want to suggest an x value based on the other view
    if any(isnan(track_k)) && ~any(isnan(track_ko))
        track_ko = warpPointCoordinates(track_ko([2 1])',userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping),flip);
        if i_view == 1
            track_ko(1) = track_ko(1) + userdata.data(video_id).split_line;
        else
            track_ko(1) = track_ko(1) - userdata.data(video_id).split_line;
        end
        track_ko = warpPointCoordinates(track_ko,userdata.data(video_id).ind_warp_mapping,size(userdata.data(video_id).inv_ind_warp_mapping),flip);
        track_k(1)=track_ko(2);
    end   
    
    % warp track and window
    if warp
        % warp track coordinates
        x = track_k(1); 
        if isnan(track_k(2))
            y = track_ko(1);
        else
            y = track_k(2);
        end
        % track_w = warpPointCoordinates([y x],userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).inv_ind_warp_mapping));
        track_w = warpPointCoordinates([y x],userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping),false);
        if isnan(track_k(2))
            track_k = [track_w(2) NaN];
        else
            track_k = track_w([2 1])';
        end
    end
    % flip window
    if flip
        track_k(1) = tWidth - track_k(1);
        LimWin = tWidth-LimWin;
    end
    % apply window
    if  userdata.data(video_id).UseLimitedWindow
        track_k(1) = track_k(1) - LimWin;
    end

    
    if isempty(track_field)
        visibility_k = 1;
%         visibility_k = userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}...
%         (lind(4),userdata.data(video_id).current_frame,i_view);
    elseif strcmp(track_field,'LM_track')
        visibility_k = 2;
	elseif strcmp(track_field,'track')
        visibility_k = 3;
    end


    if all(~isnan(track_k)) &&  visibility_k > 1
        % Updating center coordinate:
        set(userdata.plot_handles.(track_field){lind(1)}{lind(2)}{lind(3)}(1,lind(4),i_view),...
            'Xdata',track_k(1),...
            'Ydata',track_k(2),...
            'Visible','on');

        % track_i is defined in xy reference.
        i = track_k(2);
        j = track_k(1);

        h = box_size_k(1)./userdata.data(video_id).scale;
        w = box_size_k(2)./userdata.data(video_id).scale;

        li = i - floor(h/2);
        lj = j - floor(w/2);

        corners_xy = [lj li;lj+w-1 li;lj+w-1 li+h-1;lj li+h-1]';
        xdata = {corners_xy(1,[1 2]);corners_xy(1,[2 3]);corners_xy(1,[3 4]);corners_xy(1,[4 1])};
        ydata = {corners_xy(2,[1 2]);corners_xy(2,[2 3]);corners_xy(2,[3 4]);corners_xy(2,[4 1])};

        set(userdata.plot_handles.(track_field){lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
            {'Xdata','Ydata'},[xdata ydata]);
        if visibility_k == 3
            linestyle = ':';
        else
            linestyle = '-';
        end
        set(userdata.plot_handles.(track_field){lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
            'Visible','on',...
            'LineStyle',linestyle);
        
    elseif isnan(track_k(2)) && ~isnan(track_k(1)) &&  visibility_k > 1
        xdata = {[track_k(1) track_k(1)]};
        ydata = {[1 userdata.data(video_id).split_line userdata.data(video_id).vid.Height]};
        if i_view == 1
            ydata{1} = ydata{1}(2:3);
        elseif i_view == 2
            ydata{1} = ydata{1}(1:2);
        end
        set(userdata.plot_handles.(track_field){lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
            {'Xdata','Ydata'},[xdata ydata]);
        if visibility_k == 3
            linestyle = ':';
        else
            linestyle = '-';
        end
        set(userdata.plot_handles.(track_field){lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
            'Visible','on',...
            'LineStyle',linestyle);
    else
        set(userdata.plot_handles.(track_field){lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
            {'Xdata','Ydata'},mat2cell(NaN(4,4),ones(4,1),2*ones(1,2)));
        set(userdata.plot_handles.(track_field){lind(1)}{lind(2)}{lind(3)}(:,lind(4),i_view),...
            'Visible','off')
    end

end
% --- Update position properties on the plot:
function updatePosition(handles)
    % Updates position related properties of the GUI

    [userdata, video_id, lind] = getGUIStatus(handles);
    if video_id == 0; return; end
    
    track_fields = [{'track'},{'LM_track'}];
    if handles.checkbox_Show_LM_Track.Value
        track_choice = 2;
    else
        track_choice = 1;
    end
    pos = userdata.data(video_id).(track_fields{track_choice}){lind(1)}...
        {lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,:);
    
    vis = userdata.data(video_id).visibility{lind(1)}...
        {lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,:);
    
    flip = userdata.data(video_id).flip;

    % Check if the image is original or distorted:

    if get(handles.uipanel_distortion,'SelectedObject') == handles.radiobutton_corrected
        % If flip is one, track must first be unwarped to be flipped:
        if userdata.data(video_id).flip
            pos(1,:,:,:) = userdata.data(video_id).vid.Width - pos(1,:,:,:);
        end
        track_k = warpPointCoordinates(cat(2,pos([2 1],:,:,1),pos([2 1],:,:,2))',userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).inv_ind_warp_mapping),flip);
        pos = cat(4,track_k(1,[2 1])',track_k(2,[2 1])');
        if userdata.data(video_id).flip
            pos(1,:,:,:) = userdata.data(video_id).vid.Width - pos(1,:,:,:);
        end
    end

    set(handles.split_line,'Ydata',[userdata.data(video_id).split_line userdata.data(video_id).split_line]);
end

function updateVisibility(handles)
    [userdata,video_id,lind] = getGUIStatus(handles);

    vis = userdata.data(video_id).visibility{lind(1)}...
        {lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,:);

end

% --- Generates plot handles:
function H = plotHandles(N_points,ColorMatrix)
    H = NaN(5,N_points,2);
    for i_v = 1:2

        for i_point = 1:N_points
            H(1,i_point,i_v) = line(0,0,'Marker','.','Visible','off',...
                'Color',ColorMatrix(i_point,:));

            H(2:5,i_point,i_v) = line(zeros(2,4),zeros(2,4),'Linestyle','-',...
                'Linewidth',1,'Visible','off',...
                'Color',ColorMatrix(i_point,:));
        end

    end
end

% %% MENU
% 
% function menu_file_Callback(hObject, eventdata, handles)
%     % hObject    handle to menu_file (see GCBO)
%     % eventdata  reserved - to be defined in a future version of MATLAB
%     % handles    structure with handles and user data (see GUIDATA)
% 
% end
% 
% function menu_file_save_Callback(hObject, eventdata, handles)
%     % hObject    handle to menu_file_save (see GCBO)
%     % eventdata  reserved - to be defined in a future version of MATLAB
%     % handles    structure with handles and user data (see GUIDATA)
%     [userdata,video_id] = getGUIStatus(handles);
%     if video_id > 0
%         struct_to_save = userdata.data(video_id);
%         [~,name,~] = fileparts(struct_to_save.vid.Name);
%         [file_name,path_name] = uiputfile({'*.mat','MAT-files (*.mat)'},'Select File for Save As',fullfile(handles.latest_path,sprintf('%s_labelling.mat',name)));
% 
%         if ~isequal(file_name,0) && ~isequal(path_name,0)
%             handles.latest_path = path_name;
% 
%             % Removing the VideoReader structure and putting it as a path:
%             struct_to_save.vid = fullfile(struct_to_save.vid.Path,struct_to_save.vid.Name);
%             % For now there is no specific choice of background image, thus there
%             % is no need to save its name either.
%             struct_to_save.start_frame = struct_to_save.current_start_frame; % save start frame
%             struct_to_save.frame_step = struct_to_save.current_frame_step; % save step frame
% 
%             struct_to_save = rmfield(struct_to_save,{'current_frame','current_frame_step','current_start_frame','bkg',...
%                 'calibration_popup_id','background_popup_id','ind_warp_mapping','inv_ind_warp_mapping',});% removing fields that are no longer saved.
%             % Processing the track to a format that is compatible witht the
%             % rest of the code. Unfortunately the most useful format for
%             % analysis is [x;y;z] or [x;y;x2;z], which makes indexing the 
%             % bottom view slightly more complicated.
%             labelled_frames = false(1,userdata.data(video_id).vid.NumberOfFrames);
%             N_types = length(userdata.types);
% 
%             % Extracting the visibility:
%             for i_type = 1:N_types
%                 N_class_type = length(userdata.classes{i_type});
%                 for i_class = 1:N_class_type
%                     labelled_frames = labelled_frames | ...
%                         any(any(cell2mat(struct_to_save.visibility{i_type}{i_class}')>1,1),3);
%                 end
%             end
% 
% 
%             for i_type = 1:N_types
%                 N_class_type = length(userdata.classes{i_type});
% 
%                 for i_class = 1:N_class_type
%                     N_feature_class_type = length(userdata.features{i_type}{i_class});
% 
%                     for i_feature = 1:N_feature_class_type
%                         struct_to_save.track{i_type}{i_class}{i_feature} = ...
%                             cat(1,struct_to_save.track...
%                             {i_type}{i_class}{i_feature}(:,:,labelled_frames,1),...
%                             struct_to_save.track...
%                             {i_type}{i_class}{i_feature}(:,:,labelled_frames,2));
%                         struct_to_save.visibility{i_type}{i_class}{i_feature} = struct_to_save.visibility{i_type}{i_class}{i_feature}(:,labelled_frames,:)-1;
%                     end
%                 end
%             end
%             struct_to_save.labelled_frames = find(labelled_frames); % Frames that have some data.
%             struct_to_save.labels = userdata.labels; % Save info about the labels.
%             save(fullfile(path_name,file_name),'-struct','struct_to_save'); % Generating the MAT file.
%             userdata.is_data_saved = true; % FIXME: This is so we can generate a warning before closing the labeling gui if data is not saved.
%         end
%         set(handles.figure1,'userdata',userdata);
%         guidata(hObject,handles);
%     else
%         fprintf('There are no labelled videos!\n');
%     end
% end
% 
% function menu_file_load_Callback(hObject, eventdata, handles)
%     % hObject    handle to menu_file_load (see GCBO)
%     % eventdata  reserved - to be defined in a future version of MATLAB
%     % handles    structure with handles and user data (see GUIDATA)
%     [~,video_id] = getGUIStatus(handles);
%     if video_id > 0
%         [file_name,path_name] = uigetfile(handles.latest_path,'*.mat');
%         if ~isequal(file_name,0) && ~isequal(path_name,0)
%             try
%                 handles.latest_path = path_name;
%                 loaded_data = load(fullfile(path_name,file_name));
%                 handles = loadtrack(handles, loaded_data);
%                 guidata(hObject,handles);
%                 % Call one of the functions that refreshes the gui.
%                 listbox_files_Callback(handles.listbox_files,[],handles);
% 
%             catch error_type
%                 beep
%                 fprintf('Failed to merge structures!\n');
%                 if ~isempty(error_type.message);
%                     fprintf([error_type.message '\n']);
%                 end
%                 displayErrorGui(error_type);
%             end
%         end
%     else
%         fprintf('Please load videos first!\n');
%     end
% end
% 
% function menu_save_all_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_save_all (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% end


%% MISC

function uitoggletool1_ClickedCallback(hObject, eventdata, handles)
    % hObject    handle to uitoggletool1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    zoom on
end
function uitoggletool3_ClickedCallback(hObject, eventdata, handles)
    % hObject    handle to uitoggletool3 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    pan on
end

% --- Loads and applies information created with LocoMouse_Tracker
function handles = loadtrack(handles,loaded_data)
% Given loaded data this function updates the tree structures in handles
% and the userdata.data structure for the track and visibility.

%- deleted code in load_labels.m - %   

    [userdata, video_id] = getGUIStatus(handles);
% Loading values:
     
    if isempty(find(ismember(get(handles.popupmenu_distortion_correction_files,'String'),'Data')))
        set(handles.popupmenu_distortion_correction_files,'String',[get(handles.popupmenu_distortion_correction_files,'String');{'Data'}]);
    end
    
    % Debug data for the manipulation of tracks:
    % JF: these fields don't exist on the data I was trying to load:
%     fields_to_remove = {'data','final_tracks','tracks_tail'};
%     userdata.data(video_id).DebugData = loaded_data;
%     
%     for i_frm = 1:length(fields_to_remove)
%         if isfield(userdata.data(video_id).DebugData,fields_to_remove{i_frm})
%            userdata.data(video_id).DebugData = rmfield(userdata.data(video_id).DebugData,fields_to_remove{i_frm});
%         end
%     end
    
	userdata.data(video_id).flip = loaded_data.data.flip;
    userdata.data(video_id).scale = loaded_data.data.scale;
    userdata.data(video_id).split_line = loaded_data.data.split_line;
    userdata.data(video_id).bkg_path = loaded_data.data.bkg;
    
    userdata.data(video_id).ind_warp_mapping = loaded_data.data.ind_warp_mapping;
    userdata.data(video_id).inv_ind_warp_mapping = loaded_data.data.inv_ind_warp_mapping;
    if ~isempty(userdata.data(video_id).ind_warp_mapping)
        set(handles.popupmenu_distortion_correction_files,'Value',find(ismember(get(handles.popupmenu_distortion_correction_files,'String'),'Data')));
        set(handles.popupmenu_distortion_correction_files,'Enable','off');
    end
    userdata.data(video_id).calibration_popup_id = find(ismember(get(handles.popupmenu_distortion_correction_files,'String'),'Data'));
    
     % FR HR FL HR SN
            % load track

    userdata.labels{1, 2}{1, 1}.N_points = size(loaded_data.tracks_tail,2);    
    N_frames = size(loaded_data.tracks_tail,3);
	empty_labels = initializeEmptytrackVisibility(userdata, N_frames);
    LM_track = Convert_Track2Label(loaded_data.final_tracks,loaded_data.tracks_tail, empty_labels);
   
    userdata.data(video_id).LM_track    = LM_track;
    userdata.data(video_id).track_original = size(loaded_data.final_tracks,1) == 4;
    
    if isfield(loaded_data,'epochs')
        userdata.data(video_id).Good_Epochs = loaded_data.epochs;
        update_epochs(userdata.data(video_id).Good_Epochs,handles);
    else
        update_epochs([],handles);
    end
    
    if isfield(loaded_data,'corr_final_tracks') && isfield(loaded_data,'corr_tracks_tail')
        empty_labels = initializeEmptytrackVisibility(userdata, N_frames);
        userdata.data(video_id).track = Convert_Track2Label(loaded_data.corr_final_tracks,loaded_data.corr_tracks_tail, empty_labels);
    end
    
    if isfield(loaded_data,'BadMovie')
        userdata.data(video_id).BadMovie = loaded_data.BadMovie;
        set(handles.togglebutton_reject,'Value',userdata.data(video_id).BadMovie);
        togglebutton_reject_Callback(handles.togglebutton_reject, [], handles);
    end
    
    set(handles.figure1,'userdata',userdata);
    % Refresh the GUI:
    set(handles.popupmenu_type,'Value',1);
%     popupmenu_type_Callback([],[],handles);
    handles = resetGUI(handles);
end

% Adds or merges a label to the system:
function handles = addMergeLabels(handles,label_indexes, label)
% Checks whether to add or merge a label to the structure:
    userdata = getGUIStatus(handles);
    merge = true;
    N_videos = length(userdata.data);

    % Checking type:
    if label_indexes(1) > length(userdata.types)
        merge = false;
        % Type is new, add it:
        userdata.types = cat(2,userdata.types,label.type);
        userdata.classes = cat(2,userdata.classes,{cell(1,0)});
        handles.names = cat(2,handles.names,{cell(1,0)});
        userdata.labels = cat(2,userdata.labels,{cell(1,0)});
        userdata.plot_handles = cat(2,userdata.plot_handles,{cell(1,0)});
        for i_videos = 1:N_videos
            userdata.data(i_videos).track = cat(2,data(i_videos).track,{cell(1,0)});
            userdata.data(i_videos).visibility = cat(2,data(i_videos).visibility,{cell(1,0)});
        end
    end

    % Checking class:
    if label_indexes(2) > length(userdata.classes{label_indexes(1)})
        % Adding class:
        userdata.classes{label_indexes(1)} = cat(2,userdata.classes{label_indexes(1)},label.class);
        userdata.features{label_indexes(1)} = cat(2,userdata.features{label_indexes(1)},{cell(1,0)});
        userdata.labels{label_indexes(1)} = cat(2,userdata.labels{label_indexes(1)},{[]});
        userdata.plot_handles{label_indexes(1)} = cat(2,userdata.plot_handles{label_indexes(1)},{cell(1,0)});
        for i_videos = 1:N_videos
            userdata.data(i_videos).track{label_indexes(1)} = cat(2,userdata.data(i_videos).track{label_indexes(1)},{cell(1,0)});
            userdata.data(i_videos).visibility{label_indexes(1)} = cat(2,userdata.data(i_videos).visibility{label_indexes(1)},{cell(1,0)});
        end
        merge = false;
    end

    % Checking name:
    if label_indexes(3) >  length(userdata.features{label_indexes(1)}{label_indexes(2)})
        % Adding name:
        userdata.features{label_indexes(1)}{label_indexes(2)} = cat(2,userdata.features{label_indexes(1)}{label_indexes(2)},label.name);
        userdata.plot_handles{label_indexes(1)}{label_indexes(2)} = cat(2,userdata.plot_handles{label_indexes(1)}{label_indexes(2)},{cell(1,0)});
        for i_videos = 1:N_videos
            userdata.data(i_videos).track{label_indexes(1)} = cat(2,userdata.data(i_videos).track{label_indexes(1)},{cell(1,0)});
            userdata.data(i_videos).visibility{label_indexes(1)} = cat(2,userdata.data(i_videos).visibility{label_indexes(1)},{cell(1,0)});
        end
        merge = false;
    end

    if merge
        % Checking number of points:
        if label_indexes(4) ~= userdata.labels{label_indexes(1)}{label_indexes(2)}(label_indexes(3)).N_points
            % Say that number of points is different and cannot merge.
        end

        % Confirm merging:
        userdata.labels{label_indexes(1)}{label_indexes(2)}(label_indexes(3)) = label;
    else
        % Adding the label (the space should have been preallocated):
        userdata.labels{label_indexes(1)}{label_indexes(2)} = cat(2,userdata.labels{label_indexes(1)}{label_indexes(2)},label);
        PH = NaN(5,label.N_points,2);
        for i_points = 1:label.N_points
            PH = plotHandles(label.N_points,summer(label.N_points));
        end
        userdata.plot_handles{label_indexes(1)}{label_indexes(2)}{label_indexes(3)} = PH;

        % Adjusting the track and visibility structures:
        for i_videos = 1:N_videos
            userdata.data(i_videos).track{label_indexes(1)}{label_indexes(2)}{label_indexes(3)} =...
                NaN(2,label.N_points,userdata.data(i_videos).vid.NumberOfFrames,2);
            userdata.data(i_videos).visibility{label_indexes(1)}{label_indexes(2)}{label_indexes(3)} = ones(label.N_points,userdata.data(i_videos).vid.NumberOfFrames,2);
        end

    end
    set(handles.figure1,'userdata',userdata);
end

% ---
function [empty_track, empty_visibility] = initializeEmptytrackVisibility(userdata, Nframes)
    N_types = length(userdata.types);
    Nframes = int16(Nframes);
    % Initializing an empty structure:
    empty_track = cell(1,N_types);
    empty_visibility = cell(1,N_types);

    for i_type = 1:N_types
        N_classes_type = length(userdata.classes{i_type});
        empty_track{i_type} = cell(1,N_classes_type);
        empty_visibility{i_type} = cell(1,N_classes_type);

        for i_classes = 1:N_classes_type
            N_features_type_class = length(userdata.features{i_type}{i_classes});
            empty_track{i_type}{i_classes} = cell(1,N_features_type_class);
            empty_visibility{i_type}{i_classes} = cell(1,N_features_type_class);

            for i_features = 1:N_features_type_class
                empty_track{i_type}{i_classes}{i_features} = NaN(2,userdata.labels{i_type}{i_classes}(i_features).N_points,Nframes,2);
                empty_visibility{i_type}{i_classes}{i_features} = ones(userdata.labels{i_type}{i_classes}(i_features).N_points,Nframes,2);
                if all([i_type i_classes i_features]==[2 1 1])
                    empty_track{i_type}{i_classes}{i_features}(3:4,:,:,:) = NaN(2,userdata.labels{i_type}{i_classes}(i_features).N_points,Nframes,2);
                end
            end
        end
    end
end

% --- Apply track and visibility to data:
function [empty_track,empty_visibility] = addtrackVisibility(empty_track,empty_visibility,new_track,new_visibility,labelled_frames)
    empty_track(:,:,labelled_frames,:) = cat(4,new_track([1 2],:,:), new_track([3 4],:,:));
    empty_visibility(:,labelled_frames,:) = new_visibility + 1;
end


%% CreateFcn
function slider_frame_CreateFcn(hObject, ~, ~)
    % hObject    handle to sliderframe (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end
function edit_frame_CreateFcn(hObject, ~, ~)
    % hObject    handle to edit_frame (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function edit_start_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_start_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function edit_frame_step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function listbox_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function popupmenu_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function edit_i_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_i_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_j_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_j_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_i_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_i_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_j_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_j_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_h_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_h_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_w_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_w_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_h_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_h_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_w_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_w_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_split_line_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_split_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_output_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_output_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_scale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end
function popupmenu_class_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_distortion_correction_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_distortion_correction_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_background_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_n_points_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_n_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_background_mode_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to popupmenu_background_mode (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function edit_speed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
function slider_speed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end
function popupmenu_visible_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_visible_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_visible_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_visible_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_output_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_MovieEpochs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_MovieEpochs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_CurrEpochStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_CurrEpochStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_CurrEpochEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_CurrEpochEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

%% END


% --- Executes on selection change in popupmenu_model.
function popupmenu_model_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_model contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_model
end

% --- Executes during object creation, after setting all properties.
function popupmenu_model_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Sets the GUI on a wait status so no interaction is possible while it
% is computing something.
function handles = GUI_Status(handles,state)
try
    switch lower(state)
        case 'on'
                     
            set(handles.silenced_handles,'Enable','on');
            set(handles.figure1, 'pointer', handles.oldpointer)
            drawnow;
            
        case 'off'
                 
            handles.silenced_handles = findobj(handles.figure1,'Enable','on');
            set(handles.silenced_handles,'Enable','off');
            handles.oldpointer = get(handles.figure1, 'pointer');
            set(handles.figure1, 'pointer', 'watch')
            drawnow;
            
        otherwise
            error('state can only be ''on'' or ''off''.');
    end
catch err
    
    %%% FIXME: Display the error if it happens...
    set(handles.figure1,'pointer',handles.oldpointer);
    drawnow;
    
end
end
        
        








