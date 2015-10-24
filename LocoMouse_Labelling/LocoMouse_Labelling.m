function varargout = LocoMouse_Labelling(varargin)
% LOCOMOUSE_LABELLING MATLAB code for LocoMouse_Labelling.fig
%      LOCOMOUSE_LABELLING, by itself, creates a new LOCOMOUSE_LABELLING or raises the existing
%      singleton*.
%
%      H = LOCOMOUSE_LABELLING returns the handle to a new LOCOMOUSE_LABELLING or the handle to
%      the existing singleton*.
%
%      LOCOMOUSE_LABELLING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LOCOMOUSE_LABELLING.M with the given input arguments.
%
%      LOCOMOUSE_LABELLING('Property','Value',...) creates a new LOCOMOUSE_LABELLING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LocoMouse_Labelling_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LocoMouse_Labelling_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LocoMouse_Labelling

% Last Modified by GUIDE v2.5 04-Nov-2014 22:24:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LocoMouse_Labelling_OpeningFcn, ...
    'gui_OutputFcn',  @LocoMouse_Labelling_OutputFcn, ...
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


% --- Executes just before LocoMouse_Labelling is made visible.
function LocoMouse_Labelling_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LocoMouse_Labelling (see VARARGIN)

% Choose default command line output for LocoMouse_Labelling
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%% Setting up the supported image and video formats:
% This code relies on imread and VideoReader.
% Builing the lists to use when browsing for files:
sup_im_files = imformats;
extensions = {};
descriptions = {};
for i_temp = 1:length(sup_im_files)
    extensions = [extensions sup_im_files(i_temp).ext];
    for i_d = 1:length(sup_im_files(i_temp).ext)
        descriptions = [descriptions sup_im_files(i_temp).description];
    end
end
handles.N_supported_im_files = length(extensions)+1;
handles.supported_im_files = cell(handles.N_supported_im_files,2);
handles.supported_im_files(2:end,1) = cellfun(@(x)(['*.',x]),extensions,'un',false)';
handles.supported_im_files(2:end,2) = descriptions';

% Initialising suppoted video files:
sup_files = VideoReader.getFileFormats;
handles.N_supported_files = size(sup_files,2)+1;
handles.supported_files = cell(handles.N_supported_files,2);
handles.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
handles.supported_files(2:end,2) = {sup_files(:).Description};
handles.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_files(2:end,1)','un',false));
handles.supported_files{1,2} = 'All supported video files';

% FIXME: Adjust this on GUIDE on a screen with larger resolution.
set(handles.popupmenu_background,'Units','normalized');
P = get(handles.popupmenu_distortion_correction_files,'Position');
set(handles.popupmenu_background,'Position',[P(1) 0.35 P(3:end)]);
set(handles.popupmenu_background,'Enable','on');


%% Initializing objects:
set(handles.popupmenu_background,'String',{'No background image.'});
set(handles.popupmenu_distortion_correction_files,'String',{'No correction file.'});

% Default class and label names: 
% ------------- Parameters used in the locomouse tracker ------------------
default_feature_names = {'Front Right Paw','Hind Right Paw','Front Left Paw','Hind Left Paw','Snout','Tail'};
default_class_names = {'Paw','Paw','Paw','Paw','Snout','Tail'};
default_feature_type = {'Point','Point','Point','Point','Point','Line'};
default_feature_boxes = {[30 20;30 30],[30 20;30 30],[30 20;30 30],[30 20;30 30],[30 30;30 30],[30 30;30 30]};
default_feature_colors = {[1 0 0],[1 0 1],[0 0 1],[0 1 1],[1 0.6941 0.3922],summer(8)};
default_number_of_points = {1,1,1,1,1,7};
% default_feature_marker = {'.','.','.','.','.','.'};

% userdata.labels = struct('type',default_feature_type, ...
%     'class',default_class_names,...
%     'name', default_feature_names,...
%     'box_size',cat(1,default_feature_boxes),...
%     'N_points',default_number_of_points);    
% ------------------------------------------------------------------------

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
    userdata.plot_handles{i_type} = cell(1,N_classes_type);
    
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
        userdata.plot_handles{i_type}{i_class} = cell(1,N_features_class_type); 
        for i_features = 1:N_features_class_type
            userdata.plot_handles{i_type}{i_class}{i_features} = ...
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

% Initializing the color pushbutton:
set(handles.pushbutton_color,'BackgroundColor',get(userdata.plot_handles{1}{1}{1}(1),'Color'));

% Initializing the box size:
set([handles.edit_h_bottom handles.edit_w_bottom handles.edit_h_side handles.edit_w_side],{'String'},...
    cellfun(@(x)(num2str(x)),num2cell(userdata.labels{1}{1}(1).box_size(:)),'un',0));

% Initializing the slider:
set(handles.slider_frame,'Min',1);
set(handles.slider_frame,'Max',100); % Any value just so it looks like something.
set(handles.slider_frame,'Value',1);

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

% UIWAIT makes LocoMouse_Labelling wait for user response (see UIRESUME)
guidata(hObject,handles)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = LocoMouse_Labelling_OutputFcn(hObject, ~, handles)
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

% --- Executes on slider movement.
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

% --- Executes during object creation, after setting all properties.
function slider_frame_CreateFcn(hObject, ~, ~)
% hObject    handle to sliderframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


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
    displayImage(handles);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,1);
    plotBoxImage(handles,2);
    drawnow;
else
    set(handles.edit_frame,'String',num2str(userdata.data(video_id).current_frame));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_frame_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox_invisible.
function checkbox_invisible_Callback(hObject, ~, handles)
% hObject    handle to checkbox_invisible (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_invisible

value = get(hObject,'Value');

[current_frame,box_data, current_box] = getGUIStatus(handles);

if value == 1
    set(box_data(current_box).handles,'Visible','off');
    box_data(current_box).visibility(current_frame) = false;
else
    set(box_data(current_box).handles,'Visible','on');
    box_data(current_box).visibility(current_frame) = true;
end
set(handles.figure1,'UserData',{current_frame, box_data});
guidata(hObject,handles);


% --- Executes on button press in checkbox_display_split_line.
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

% --- Given current positions, plots the visible boxes.
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
PH = cat(2,userdata.plot_handles{:});PH = cat(2,PH{:});
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
    % Plotting all tracks:
    % Looping types:
    for i_type = 1:N_types
        N_classes_type = length(userdata.classes{i_type});
        for i_class = 1:N_classes_type
            N_features_class_type = length(userdata.features{i_type}{i_class});
            for i_feature = 1:N_features_class_type
                points_to_plot = 1:userdata.labels{i_type}{i_class}(i_feature).N_points;
                for i_point = points_to_plot
                    userdata = plotBoxImage_proper(userdata,video_id,[i_type i_class i_feature i_point],warp, i_view);
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
        userdata = plotBoxImage_proper(userdata, video_id, [lind(1:3) i_point],warp, i_view);
    end
end
set(handles.figure1,'userdata',userdata);

% --- Plots a single box:
function [userdata] = plotBoxImage_proper(userdata, video_id, lind,warp, i_view)
box_size_k = userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(:,i_view);

tracks_k = userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}...
    (:,lind(4),userdata.data(video_id).current_frame,i_view);
if warp
    % If flip is one, tracks must first be unwarped to be flipped:
    if userdata.data(video_id).flip
        tracks_k(1) = userdata.data(video_id).vid.Width - tracks_k(1);
    end
    tracks_k = warpPointCoordinates(tracks_k([2 1])',userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).inv_ind_warp_mapping));
    tracks_k = tracks_k([2 1])';
    if userdata.data(video_id).flip
        tracks_k(1) = userdata.data(video_id).vid.Width - tracks_k(1);
    end
end

visibility_k = userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}...
    (lind(4),userdata.data(video_id).current_frame,i_view);

if all(~isnan(tracks_k)) &&  visibility_k > 1
    % Updating center coordinate:
    set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(1,lind(4),i_view),...
        'Xdata',tracks_k(1),...
        'Ydata',tracks_k(2),...
        'Visible','on');
    
    % tracks_i is defined in xy reference.
    i = tracks_k(2);
    j = tracks_k(1);
    
    h = box_size_k(1)./userdata.data(video_id).scale;
    w = box_size_k(2)./userdata.data(video_id).scale;
    
    li = i - floor(h/2);
    lj = j - floor(w/2);
    
    corners_xy = [lj li;lj+w-1 li;lj+w-1 li+h-1;lj li+h-1]';
    xdata = {corners_xy(1,[1 2]);corners_xy(1,[2 3]);corners_xy(1,[3 4]);corners_xy(1,[4 1])};
    ydata = {corners_xy(2,[1 2]);corners_xy(2,[2 3]);corners_xy(2,[3 4]);corners_xy(2,[4 1])};
    
    set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
        {'Xdata','Ydata'},[xdata ydata]);
    if visibility_k == 3
        linestyle = ':';
    else
        linestyle = '-';
    end
    set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
        'Visible','on',...
        'LineStyle',linestyle);
else
    set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),i_view),...
        {'Xdata','Ydata'},mat2cell(NaN(4,4),ones(4,1),2*ones(1,2)));
    set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),i_view),...
        'Visible','off')
end


% --- Gets the positioin of the click from the mouse on the figure.
function axes_frame_ButtonDownFcn(hObject,eventdata,handles)
% hObject    handle to axes_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

p = get(handles.axes_frame,'CurrentPoint');
p = round(p(1,1:2));

if p(2) > str2double(get(handles.edit_split_line,'String'))
    view = 1; % Bottom
else
    view = 2; % Side
end

[userdata,video_id,lind] = getGUIStatus(handles);

% If showing corrected images, p needs to be warped back to original:
if handles.radiobutton_corrected == get(handles.uipanel_distortion,'SelectedObject')
    p = warpPointCoordinates(p,userdata(video_id).data.inv_ind_warp_mapping   ,size(userdata(video_id).data.ind_warp_mapping));
end

userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,view) = p';
% If invisible set to visible
if userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,view) == 1
    if view == 1
        set(handles.popupmenu_visible_bottom,'Value',2);
    else
        set(handles.popupmenu_visible_side,'Value',2);
    end
end
userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,view) = 2;
set(handles.figure1,'UserData',userdata);
updatePosition(handles);
plotBoxImage(handles,view);
% handles.is_data_saved = false;
% handles = displayImage(handles);
guidata(handles.figure1,handles);

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

switch eventdata.Key
    case 'rightarrow'
        frame = str2double(get(handles.edit_frame,'String'));
        frame = frame + 1;
        set(handles.edit_frame,'String',num2str(frame));
        
    case 'leftarrow'
        frame = str2double(get(handles.edit_frame,'String'));
        frame = frame - 1;
        set(handles.edit_frame,'String',num2str(frame));
        %     case 'uparr'
        %     case 'subtract'
        %     otherwise
        %         '???';
        %
end

edit_frame_Callback(hObject, eventdata, handles)

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
% if ~handles.is_data_saved
%     % Say that the data has not been saved and ask if the user wants to
%     % save it.
%     button = questdlg('Labels have not been saved. Are you sure you want to close the GUI?','Closing MouseLabelling GUI','Yes','No','Yes');
%     if strcmpi(button,'Yes')
%         uiresume(handles.figure1);
%     end
% else
%     uiresume(handles.figure1);
% end

% --------------------------------------------------------------------
function uitoggletool1_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uitoggletool1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zoom on


% --------------------------------------------------------------------
function uitoggletool3_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uitoggletool3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pan on


% --- Executes on selection change in popupmenu_track.
function popupmenu_track_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_track contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_track
plotBoxImage(handles);
updatePosition(handles);
updateVisibility(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_track_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
    set(handles.image,'Xdata',[1 userdata.data(video_id).vid.Width],'Ydata',[1 userdata.data(video_id).vid.Height]);
    
    % Updating the vertical flip:
    set(handles.checkbox_vertical_flip,'Value',userdata.data(video_id).flip);
    
    % Updating the split line:
    if isnan(userdata.data(video_id).split_line)
        new_split_line = round(userdata.data(video_id).vid.Height/2);
        userdata.data(video_id).split_line = new_split_line;
        set(handles.edit_split_line,'String',num2str(new_split_line));
        set(handles.split_line ,'Xdata',[1 userdata.data(video_id).vid.Width],'Ydata',[new_split_line new_split_line],'Visible','on');
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
if ~isempty(video_list)
    video_id = get(handles.listbox_files,'Value');
else
    video_id = 0;
end
userdata = get(handles.figure1,'UserData');
lind = [get(handles.popupmenu_type,'Value') ...
    get(handles.popupmenu_class,'Value') ...
    get(handles.popupmenu_name,'Value')...
    get(handles.popupmenu_n_points,'Value')];

% --- Update position properties on the plot:
function updatePosition(handles)
% Updates position related properties of the GUI

[userdata, video_id, lind] = getGUIStatus(handles);
if video_id == 0; return; end
pos = userdata.data(video_id).tracks{lind(1)}...
    {lind(2)}{lind(3)}(:,lind(4),userdata.data(video_id).current_frame,:);

vis = userdata.data(video_id).visibility{lind(1)}...
    {lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,:);
% Check if the image is original or distorted:

if get(handles.uipanel_distortion,'SelectedObject') == handles.radiobutton_corrected
    % If flip is one, tracks must first be unwarped to be flipped:
    if userdata.data(video_id).flip
        pos(1,:,:,:) = userdata.data(video_id).vid.Width - pos(1,:,:,:);
    end
    tracks_k = warpPointCoordinates(cat(2,pos([2 1],:,:,1),pos([2 1],:,:,2))',userdata.data(video_id).inv_ind_warp_mapping,size(userdata.data(video_id).inv_ind_warp_mapping));
    pos = cat(4,tracks_k(1,[2 1])',tracks_k(2,[2 1])');
    if userdata.data(video_id).flip
        pos(1,:,:,:) = userdata.data(video_id).vid.Width - pos(1,:,:,:);
    end
end

set([handles.edit_j_bottom handles.edit_i_bottom],{'String'},...
    strsplit(num2str(pos(:,:,:,1)'),' ')');
set([handles.edit_j_side handles.edit_i_side],{'String'},...
    strsplit(num2str(pos(:,:,:,2)'),' ')');
set(handles.edit_split_line,'String',num2str(userdata.data(video_id).split_line));
set(handles.split_line,'Ydata',[userdata.data(video_id).split_line userdata.data(video_id).split_line]);
set(handles.edit_scale,'String',num2str(userdata.data(video_id).scale));
set(handles.popupmenu_visible_bottom,'Value',vis(:,:,1));
set(handles.popupmenu_visible_side,'Value',vis(:,:,2));

function updateVisibility(handles)
[userdata,video_id,lind] = getGUIStatus(handles);

vis = userdata.data(video_id).visibility{lind(1)}...
    {lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,:);

set(handles.popupmenu_visible_bottom,'Value',vis(:,:,1));
set(handles.popupmenu_visible_side,'Value',vis(:,:,2));

% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_save_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[userdata,video_id] = getGUIStatus(handles);
if video_id > 0
    struct_to_save = userdata.data(video_id);
    [~,name,~] = fileparts(struct_to_save.vid.Name);
    [file_name,path_name] = uiputfile({'*.mat','MAT-files (*.mat)'},'Select File for Save As',fullfile(handles.latest_path,sprintf('%s_labelling.mat',name)));
    
    if ~isequal(file_name,0) && ~isequal(path_name,0)
        handles.latest_path = path_name;
        
        % Removing the VideoReader structure and putting it as a path:
        struct_to_save.vid = fullfile(struct_to_save.vid.Path,struct_to_save.vid.Name);
        % For now there is no specific choice of background image, thus there
        % is no need to save its name either.
        struct_to_save.start_frame = struct_to_save.current_start_frame; % save start frame
        struct_to_save.frame_step = struct_to_save.current_frame_step; % save step frame
               
        struct_to_save = rmfield(struct_to_save,{'current_frame','current_frame_step','current_start_frame','bkg',...
            'calibration_popup_id','background_popup_id','ind_warp_mapping','inv_ind_warp_mapping',});% removing fields that are no longer saved.
        % Processing the tracks to a format that is compatible witht the
        % rest of the code. Unfortunately the most useful format for
        % analysis is [x;y;z] or [x;y;x2;z], which makes indexing the 
        % bottom view slightly more complicated.
        labelled_frames = false(1,userdata.data(video_id).vid.NumberOfFrames);
        N_types = length(userdata.types);
        
        % Extracting the visibility:
        for i_type = 1:N_types
            N_class_type = length(userdata.classes{i_type});
            for i_class = 1:N_class_type
                labelled_frames = labelled_frames | ...
                    any(any(cell2mat(struct_to_save.visibility{i_type}{i_class}')>1,1),3);
            end
        end
        
        
        for i_type = 1:N_types
            N_class_type = length(userdata.classes{i_type});
            
            for i_class = 1:N_class_type
                N_feature_class_type = length(userdata.features{i_type}{i_class});
                
                for i_feature = 1:N_feature_class_type
                    struct_to_save.tracks{i_type}{i_class}{i_feature} = ...
                        cat(1,struct_to_save.tracks...
                        {i_type}{i_class}{i_feature}(:,:,labelled_frames,1),...
                        struct_to_save.tracks...
                        {i_type}{i_class}{i_feature}(:,:,labelled_frames,2));
                    struct_to_save.visibility{i_type}{i_class}{i_feature} = struct_to_save.visibility{i_type}{i_class}{i_feature}(:,labelled_frames,:)-1;
                end
            end
        end
        struct_to_save.labelled_frames = find(labelled_frames); % Frames that have some data.
        struct_to_save.labels = userdata.labels; % Save info about the labels.
        save(fullfile(path_name,file_name),'-struct','struct_to_save'); % Generating the MAT file.
        userdata.is_data_saved = true; % FIXME: This is so we can generate a warning before closing the labeling gui if data is not saved.
    end
    set(handles.figure1,'userdata',userdata);
    guidata(hObject,handles);
else
    fprintf('There are no labelled videos!\n');
end

% --------------------------------------------------------------------
function menu_file_load_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[~,video_id] = getGUIStatus(handles);
if video_id > 0
    [file_name,path_name] = uigetfile(handles.latest_path,'*.mat');
    if ~isequal(file_name,0) && ~isequal(path_name,0)
        try
            handles.latest_path = path_name;
            loaded_data = load(fullfile(path_name,file_name));
            handles = loadLabelling(handles, loaded_data);
            guidata(hObject,handles);
            % Call one of the functions that refreshes the gui.
            listbox_files_Callback(handles.listbox_files,[],handles);
            
        catch error_type
            beep
            fprintf('Failed to merge structures!\n');
            if ~isempty(error_type.message);
                fprintf([error_type.message '\n']);
            end
            displayErrorGui(error_type);
        end
    end
else
    fprintf('Please load videos first!\n');
end

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


% --- Executes during object creation, after setting all properties.
function edit_start_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_start_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

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
    displayImage(handles);
else
    set(handles.edit_frame,'String',num2str(userdata.data(video_id).current_frame_step));
end
set(handles.figure1,'UserData',userdata);
guidata(hObject,handles);
slider_frame_Callback(handles.slider_frame,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function edit_frame_step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_files.
function listbox_files_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_files contents as cell array
%#        contents{get(hObject,'Value')} returns selected item from listbox_files
[~,video_id] = getGUIStatus(handles);
if video_id > 0
    % Reset the GUI with the current video:
    handles = resetGUI(handles);
    updatePosition(handles);
    displayImage(handles)
    plotBoxImage(handles,1);
    plotBoxImage(handles,2);
    guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function listbox_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_add_file.
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

% --- Executes on button press in pushbutton_add_folder.
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

% [userdata,~] = getGUIStatus(handles);
% if  ischar(path_name)
%     % Store the path in case more files are to be added...
%     handles.latest_path = path_name;
%     current_file_list = get(handles.listbox_files,'String');
%     
%     %%% FIXME: See on the tracking gui how to determine the accepted video
%     %%% files instead of looking for avi only.
%     file_name = dir(fullfile(path_name,'*.avi'));
%     file_name = {file_name(:).name};
%     
%     if iscell(file_name)
%         file_name = cellfun(@(x)(fullfile(path_name,x)),file_name,'un',false);
%         isrepeated = cellfun(@(x)(any(strcmpi(current_file_list,x))),file_name);
%         if any(isrepeated)
%             fprintf('The following files were already on the list:\n');
%             fprintf('%s\n',file_name{isrepeated});
%         end
%         file_name = file_name(~isrepeated);
%         
%         % Initialize the tracking structure for such videos:
%         N_files = length(file_name);
%     else
%         file_name = fullfile(path_name,file_name);
%         isrepeated = any(strcmpi(file_name,current_file_list));
%         if isrepeated
%             fprintf('%s is already on list!\n',file_name);
%             N_files = 0;
%             file_name = {};
%         else
%             N_files = 1;
%             file_name = {file_name};
%         end
%         
%     end
%     
%     for i_files = 1:N_files
%         % Initialize the tracking structure for the videos:
%         vid = VideoReader(file_name{i_files});
%         userdata.data = cat(2,userdata.data,initializeUserDataStructure(vid,handles));
%         %         if ~isempty(userdata.data(end).bkg)
%         %             set(handles.checkbox_display_background,'Enable','on');
%         %             set(handles.checkbox_display_background,'Value',1);
%         %         else
%         %             set(handles.checkbox_display_background,'Enable','off');
%         %         end
%         clear vid;
%     end
%     
%     if isempty(current_file_list)
%         % Enabling the GUI:
%         changeGUIActiveState(handles);
%     end
%     set(handles.listbox_files,'String',cat(1,current_file_list,file_name{:}));
%     set(handles.figure1,'UserData',userdata);
%     guidata(hObject,handles);
%     listbox_files_Callback(handles.listbox_files,eventdata,handles);
% end

% --- Executes on button press in pushbutton_remove.
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

% --- Executes on selection change in popupmenu_type.
function popupmenu_type_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_type

label_type = get(handles.popupmenu_type,'Value');
[userdata,~,lind] = getGUIStatus(handles);

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

% --- Executes during object creation, after setting all properties.
function popupmenu_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_name.
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

% --- Executes during object creation, after setting all properties.
function popupmenu_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_add_label.
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


% --- Executes on button press in pushbutton_delete_label.
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
    delete(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:))
    userdata.plot_handles{lind(1)}{lind(2)}(lind(3)) = [];
    userdata.labels{lind(1)}{lind(2)}(lind(3)) = [];
    Nfeatures = length(userdata.features{lind(1)}{lind(2)});
    
    if video_id > 0
        for i_videos = 1:length(userdata)
            % Removing track and visibility data:
            userdata.data(video_id).tracks{lind(1)}{lind(2)}(lind(3)) = [];
            userdata.data(video_id).visibility{lind(1)}{lind(2)}(lind(3)) = [];
        end
    end
    if Nfeatures == 0
        % If no names left, remove class:
        userdata.features{lind(1)}(lind(2)) = [];
        userdata.classes{lind(1)}(lind(2)) = [];
        userdata.plot_handles{lind(1)}(lind(2)) = [];
        userdata.labels{lind(1)}(lind(2)) = [];
        if video_id > 0
            for i_videos = 1:length(userdata)
                % Removing track and visibility data:
                userdata.data(video_id).tracks{lind(1)}{lind(2)} = [];
                userdata.data(video_id).visibility{lind(1)}{lind(2)} = [];
            end
        end
        
        Nclasses = length(userdata.features{lind(1)});
        
        if Nclasses == 0
            % If no classes left, remove type:
            userdata.features(lind(1)) = [];
            userdata.classes(lind(1)) = [];
            userdata.types(lind(1)) = [];
            userdata.plot_handles(lind(1)) = [];
            userdata.labels(lind(1)) = [];
            
            if video_id > 0
                for i_videos = 1:length(userdata)
                    % Removing track and visibility data:
                    userdata.data(video_id).tracks(lind(1)) = [];
                    userdata.data(video_id).visibility(lind(1)) = [];
                end
            end
            Ntype = length(userdata.features);
            
            if Ntype == 0
                % If no type is left, remove type:
                userdata.features = [];
                userdata.classes = [];
                userdata.plot_handles = [];
                userdata.labels = [];
                
                % Updating GUI visuals:
                set([handles.popupmenu_type handles.popupmenu_class...
                    handles.popupmenu_name handles.popupmenu_n_points...
                    handles.pushbutton_delete_label handles.checkbox_display_all_tracks...
                    handles.checkbox_all_points handles.pushbutton_color],'Enable','off');
                set([handles.popupmenu_type handles.popupmenu_n_points...
                    handles.popupmenu_class handles.popupmenu_name],'String',' ');
                set(handles.pushbutton_color,'BackgroundColor',[1 1 1]);
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


% --- Executes on button press in pushbutton_color.
function pushbutton_color_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[userdata,~,lind] = getGUIStatus(handles);
new_color = uisetcolor;
if length(new_color) ~= 1
    % Setting the color to the button:
    set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),:),'Color',new_color);
    set(handles.pushbutton_color,'BackgroundColor',new_color);
end
set(handles.figure1,'userdata',userdata);
guidata(hObject,handles);


% --- Executes on button press in checkbox_display_all_tracks.
function checkbox_display_all_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_display_all_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_display_all_tracks
plotBoxImage(handles,1);
plotBoxImage(handles,2);


% --- Executes on button press in checkbox_display_background.
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
displayImage(handles);
guidata(hObject,handles);

% --- Executes on button press in checkbox_vertical_flip.
function checkbox_vertical_flip_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_vertical_flip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_vertical_flip
[userdata,video_id,lind] = getGUIStatus(handles);
% Regardless of state, it will be flipped:
userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(1,:,:,:) = userdata.data(video_id).vid.Width - userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(1,:,:,:) + 1;
% Save current state in memory so its not lost when changing videos:
userdata.data(video_id).flip = get(hObject,'Value');
set(handles.figure1,'UserData',userdata);
displayImage(handles);
updatePosition(handles);
plotBoxImage(handles,1); % Plots labelling for bottom view
plotBoxImage(handles,2); % Plots labelling for side view
guidata(handles.figure1,handles);

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
    
    userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,1) = new_i_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,1);
else
    set(handles.edit_i_bottom,'String',num2str(userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,1)));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_i_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_i_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

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
    
    userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,1) = new_j_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,1);
else
    set(handles.edit_j_bottom,'String',num2str(userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,1)));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_j_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_j_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



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
    
    userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,2) = new_i_side;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,2);
else
    set(handles.edit_i_side,'String',num2str(userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,lind(4),userdata.data(video_id).current_frame,2)));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_i_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_i_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



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
    
    userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,2) = new_j_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    updateVisibility(handles);
    plotBoxImage(handles,2);
else
    set(handles.edit_j_side,'String',num2str(userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(1,lind(4),userdata.data(video_id).current_frame,2)));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_j_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_j_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_i_side_add.
function pushbutton_i_side_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_side_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_side,'String'));
set(handles.edit_i_side,'String',num2str(curr_i_value+1));
edit_i_side_Callback(handles.edit_i_side,[],handles);

% --- Executes on button press in pushbutton_j_side_add.
function pushbutton_j_side_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_side_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_side,'String'));
set(handles.edit_j_side,'String',num2str(curr_j_value+1));
edit_j_side_Callback(handles.edit_j_side,[],handles);

% --- Executes on button press in pushbutton_i_side_sub.
function pushbutton_i_side_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_side_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_side,'String'));
set(handles.edit_i_side,'String',num2str(curr_i_value-1));
edit_i_side_Callback(handles.edit_i_side,[],handles);

% --- Executes on button press in pushbutton_j_side_sub.
function pushbutton_j_side_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_side_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_side,'String'));
set(handles.edit_j_side,'String',num2str(curr_j_value-1));
edit_j_side_Callback(handles.edit_j_side,[],handles);

% --- Executes on button press in pushbutton_i_bottom_add.
function pushbutton_i_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_bottom,'String'));
set(handles.edit_i_bottom,'String',num2str(curr_i_value+1));
edit_i_bottom_Callback(handles.edit_i_bottom,[],handles);

% --- Executes on button press in pushbutton_j_bottom_add.
function pushbutton_j_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_bottom,'String'));
set(handles.edit_j_bottom,'String',num2str(curr_j_value+1));
edit_j_bottom_Callback(handles.edit_j_bottom,[],handles);

% --- Executes on button press in pushbutton_i_bottom_sub.
function pushbutton_i_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_bottom,'String'));
set(handles.edit_i_bottom,'String',num2str(curr_i_value-1));
edit_i_bottom_Callback(handles.edit_i_bottom,[],handles);

% --- Executes on button press in pushbutton_j_bottom_sub.
function pushbutton_j_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_bottom,'String'));
set(handles.edit_j_bottom,'String',num2str(curr_j_value-1));
edit_j_bottom_Callback(handles.edit_j_bottom,[],handles);

function edit_h_side_Callback(hObject, eventdata, handles)
% hObject    handle to edit_h_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_h_side as text
%        str2double(get(hObject,'String')) returns contents of edit_h_side as a double
new_h = str2double(get(hObject,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);
if ~isnan(new_h) && video_id > 0
    new_h = min(max(new_h,1),userdata.data(video_id).vid.Height*2);
    set(handles.edit_h_side,'String',num2str(new_h));
    userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(1,2) = new_h;
    set(handles.figure1,'userdata',userdata);
    plotBoxImage(handles,2);
else
    set(handles.edit_h_side,'String',num2str(userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(1,2)));
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_h_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_h_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_w_side_Callback(hObject, eventdata, handles)
% hObject    handle to edit_w_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_w_side as text
%        str2double(get(hObject,'String')) returns contents of edit_w_side as a double
new_w = str2double(get(hObject,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);
if ~isnan(new_w) && video_id > 0
    new_w = min(max(new_w,1),userdata.data(video_id).vid.Width*2);
    set(handles.edit_w_side,'String',num2str(new_w));
    userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(2,2) = new_w;
    set(handles.figure1,'userdata',userdata);
    plotBoxImage(handles,2);
else
    set(handles.edit_w_side,'String',num2str(userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(2,2)));
end
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function edit_w_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_w_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_h_side_add.
function pushbutton_h_side_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_h_side_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_h = str2double(get(handles.edit_h_side,'String'))+1;
set(handles.edit_h_side,'String',num2str(new_h));
edit_h_side_Callback(handles.edit_h_side,[],handles);

% --- Executes on button press in pushbutton_h_side_sub.
function pushbutton_h_side_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_h_side_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_h = str2double(get(handles.edit_h_side,'String'))-1;
set(handles.edit_h_side,'String',num2str(new_h));
edit_h_side_Callback(handles.edit_h_side,[],handles);

% --- Executes on button press in pushbutton_w_side_add.
function pushbutton_w_side_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_w_side_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_w = str2double(get(handles.edit_w_side,'String'))+1;
set(handles.edit_w_side,'String',num2str(new_w));
edit_w_side_Callback(handles.edit_w_side,[],handles);

% --- Executes on button press in pushbutton_w_side_sub.
function pushbutton_w_side_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_w_side_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_w = str2double(get(handles.edit_w_side,'String'))-1;
set(handles.edit_w_side,'String',num2str(new_w));
edit_w_side_Callback(handles.edit_w_side,[],handles);

function edit_h_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to edit_h_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_h_bottom as text
%        str2double(get(hObject,'String')) returns contents of edit_h_bottom as a double
new_h = str2double(get(hObject,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);
if ~isnan(new_h) && video_id > 0
    new_h = min(max(new_h,1),userdata.data(video_id).vid.Height*2);
    set(handles.edit_h_bottom,'String',num2str(new_h));
    bs = userdata.labels{lind(1)}{lind(2)}(1).box_size;
    bs(1,1) = new_h;
    for i_l = 1:length(userdata.labels{lind(1)}{lind(2)})
        userdata.labels{lind(1)}{lind(2)}(i_l).box_size = bs;
    end
    set(handles.figure1,'userdata',userdata);
    plotBoxImage(handles,1);
else
    set(handles.edit_h_bottom,'String',num2str(userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(1,1)));
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_h_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_h_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_w_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to edit_w_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_w_bottom as text
%        str2double(get(hObject,'String')) returns contents of edit_w_bottom as a double
new_w = str2double(get(hObject,'String'));
[userdata,video_id,lind] = getGUIStatus(handles);
if ~isnan(new_w) && video_id > 0
    new_w = min(max(new_w,1),userdata.data(video_id).vid.Width*2);
    set(handles.edit_w_bottom,'String',num2str(new_w));
    userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(2,1) = new_w;
    set(handles.figure1,'userdata',userdata);
    plotBoxImage(handles,1);
else
    set(handles.edit_w_bottom,'String',num2str(userdata.labels{lind(1)}{lind(2)}(lind(3)).box_size(2,1)));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_w_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_w_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_h_bottom_add.
function pushbutton_h_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_h_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_h = str2double(get(handles.edit_h_bottom,'String'))+1;
set(handles.edit_h_bottom,'String',num2str(new_h));
edit_h_bottom_Callback(handles.edit_h_bottom,[],handles);

% --- Executes on button press in pushbutton_h_bottom_sub.
function pushbutton_h_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_h_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_h = str2double(get(handles.edit_h_bottom,'String'))-1;
set(handles.edit_h_bottom,'String',num2str(new_h));
edit_h_bottom_Callback(handles.edit_h_bottom,[],handles);

% --- Executes on button press in pushbutton_w_bottom_add.
function pushbutton_w_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_w_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_w = str2double(get(handles.edit_w_bottom,'String'))+1;
set(handles.edit_w_bottom,'String',num2str(new_w));
edit_w_bottom_Callback(handles.edit_w_bottom,[],handles);

% --- Executes on button press in pushbutton_w_bottom_sub.
function pushbutton_w_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_w_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_w = str2double(get(handles.edit_w_bottom,'String'))-1;
set(handles.edit_w_bottom,'String',num2str(new_w));
edit_w_bottom_Callback(handles.edit_w_bottom,[],handles);


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
    
    % Check if any of the tracks violate the new split line:
    change = false;
    TB = userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,:,:,1);
    ind_bottom = TB < new_split_line;
    if any(ind_bottom(:))
        TB(ind_bottom) = new_split_line;
        userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,:,:,1) = TB;
        change = true;
    end
    
    TS = userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,:,:,2);
    ind_side = TS > new_split_line;
    
    if any(ind_side(:))
        TS(ind_side) = new_split_line;
        userdata.data(video_id).tracks{lind(1)}{lind(2)}{lind(3)}(2,:,:,2) = TS;
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

% --- Executes during object creation, after setting all properties.
function edit_split_line_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_split_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_i_split_line_add.
function pushbutton_i_split_line_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_split_line_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[userdata,video_id] = getGUIStatus(handles);
set(handles.edit_split_line,'String',num2str(userdata.data(video_id).split_line+1));
edit_split_line_Callback(handles.edit_split_line,[],handles);

% --- Executes on button press in pushbutton_i_split_line_sub.
function pushbutton_i_split_line_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_split_line_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[userdata,video_id] = getGUIStatus(handles);
set(handles.edit_split_line,'String',num2str(userdata.data(video_id).split_line-1));
edit_split_line_Callback(handles.edit_split_line,[],handles);


function changeGUIActiveState(handles)
% Disables/Enables the set of GUI features that depend on the existence of
% a video.

userdata = getGUIStatus(handles);

handle_list = [handles.slider_frame ...
    handles.edit_frame ...
    handles.edit_frame_step ...
    handles.edit_start_frame ...
    handles.edit_i_bottom...
    handles.edit_i_side ...
    handles.edit_j_bottom ...
    handles.edit_j_side ...
    handles.pushbutton_i_bottom_add ...
    handles.pushbutton_i_bottom_sub...
    handles.pushbutton_i_split_line_add ...
    handles.pushbutton_i_bottom_sub...
    handles.pushbutton_i_side_add...
    handles.pushbutton_i_side_sub...
    handles.pushbutton_j_bottom_add...
    handles.pushbutton_j_bottom_sub...
    handles.pushbutton_j_side_add...
    handles.pushbutton_j_side_sub...
    handles.checkbox_display_all_tracks...
    handles.checkbox_vertical_flip handles.checkbox_vertical_flip...
    handles.popupmenu_visible_bottom handles.popupmenu_visible_side...
    handles.pushbutton_remove handles.listbox_files...
    handles.edit_split_line handles.pushbutton_i_split_line_sub ...
    handles.checkbox_display_split_line...
    handles.pushbutton_color_split_line...
    handles.pushbutton_w_bottom_add...
    handles.pushbutton_w_bottom_sub...
    handles.pushbutton_h_bottom_add...
    handles.pushbutton_h_bottom_sub...
    handles.pushbutton_w_side_add...
    handles.pushbutton_w_side_sub...
    handles.pushbutton_h_side_add...
    handles.pushbutton_h_side_sub...
    handles.edit_h_bottom...
    handles.edit_h_side...
    handles.edit_w_bottom...
    handles.edit_w_side...
    handles.pushbutton_add_distortion_correction...
    handles.pushbutton_add_background];

curr_status = get(handle_list(1),'Enable');
switch curr_status
    case 'on'
        set(handle_list,'Enable','off');
        set(handles.image,'Cdata',[]);
        % Disabling the plot handles:
        PH = cat(2,userdata.plot_handles{:});PH = cat(2,PH{:});
        PH = cat(3,cell2mat(PH));
        set([PH(:);handles.split_line],'Visible','off');
        % Setting the visibility to off on popups:
        set([handles.popupmenu_visible_bottom ...
            handles.popupmenu_visible_side],'Value',1);
        % Setting the edits to NaN:
        set([handles.edit_i_side handles.edit_i_bottom ...
            handles.edit_j_side handles.edit_j_bottom ...
            handles.edit_split_line],'String','NaN');
        % Setting frame stuff to 1:
        set([handles.edit_frame handles.edit_frame_step ...
            handles.edit_frame_step],'String','1');
        % Setting the file list to empty cell so we can add multiple files:
        set(handles.listbox_files,'String',cell(0));
        
    case 'off'
        set(handle_list,'Enable','on');
end
guidata(handles.figure1,handles)

% ---
function [] = displayImage(handles)
% This function reads the current frame from the video and updates it on
% the GUI.
[userdata,video_id,~] = getGUIStatus(handles);
[Iorg,Idist] = readMouseImage(userdata.data(video_id).vid,...
    userdata.data(video_id).current_frame,...
    userdata.data(video_id).bkg,...
    get(handles.checkbox_vertical_flip,'Value'),...
    userdata.data(video_id).scale,...
    userdata.data(video_id).ind_warp_mapping,...
    size(userdata.data(video_id).inv_ind_warp_mapping));

if get(handles.uipanel_distortion,'SelectedObject') == handles.radiobutton_original
    set(handles.image,'CData',Iorg);
else
    set(handles.image,'CData',Idist);
end
drawnow;

% ---
function data = initializeUserDataStructure(userdata,vid)
% Initializes an empty data structure and checks the current folders for
% labels, background and other information.
[empty_tracks, empty_visibility] = initializeEmptyTracksVisibility(userdata,vid.NumberOfFrames); 
data = struct('current_frame',1,'current_frame_step',1,...
    'current_start_frame',1,...
    'visibility',{empty_visibility},...
    'background_popup_id',1,...
    'tracks',{empty_tracks},...
    'split_line',NaN,'vid',vid,'bkg',[],'bkg_path','',...
    'flip',false,'scale',1,'ind_warp_mapping',[],...
    'calibration_popup_id',1,...
    'inv_ind_warp_mapping',[],...
    'calibration_path','');
clear empty_tracks empty_visibility

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

% --- Executes on selection change in popupmenu_visible_bottom.
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
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),1),'Visible','off');
    case 2
        % Visible:
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),1),'Visible','on');
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),1),'LineStyle','-');
    case 3
        % Partially visible:
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),1),'Visible','on');
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),1),'LineStyle',':');
end
userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}(lind(4), userdata.data(video_id).current_frame,1) = vis_val;
set(handles.figure1,'UserData',userdata);
plotBoxImage(handles,1);
guidata(handles.figure1,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_visible_bottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_visible_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_visible_side.
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
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),2),'Visible','off');
    case 2
        % Visible:
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),2),'Visible','on');
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),2),'LineStyle','-');
    case 3
        % Partially visible:
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(:,lind(4),2),'Visible','on');
        set(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(2:5,lind(4),2),'LineStyle',':');
end
userdata.data(video_id).visibility{lind(1)}{lind(2)}{lind(3)}(lind(4),userdata.data(video_id).current_frame,2) = vis_val;
set(handles.figure1,'UserData',userdata);
plotBoxImage(handles,2);
guidata(handles.figure1,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_visible_side_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_visible_side (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_color_split_line.
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


% --------------------------------------------------------------------
function menu_save_all_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



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
        %         userdata.data(video_id).tracks = userdata.data(video_id).tracks*val;
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
    displayImage(handles);
end
guidata(handles.figure1,handles);


% --- Executes during object creation, after setting all properties.
function edit_scale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_class.
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


% --- Executes during object creation, after setting all properties.
function popupmenu_class_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_add_background.
function pushbutton_add_background_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Browse supported file formats:
[file_name,path_name] = uigetfile(fullfile(handles.latest_path,'*.png'),'MultiSelect','off');

if ~isequal(file_name,0) && ~isequal(path_name,0)
    file_full_path = fullfile(path_name,file_name);clear path_name file_name
    handles = addBackgroudImage(file_full_path,handles);
end
guidata(handles.figure1,handles);

% --- Executes on button press in pushbutton_add_distortion_correction.
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

% --- Executes on selection change in popupmenu_distortion_correction_files.
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
    
    userdata.data(video_id).calibration_popup_id = 1;
    set(handles.figure1,'userdata',userdata);
end



% --- Executes during object creation, after setting all properties.
function popupmenu_distortion_correction_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_distortion_correction_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_background.
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
        displayImage(handles);
        guidata(handles.figure1,handles);
    catch ET
        fprintf('Failed to assign chosen background!\n');
        displayErrorGui(ET);
    end
end


% --- Executes during object creation, after setting all properties.
function popupmenu_background_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel_distortion.
function uipanel_distortion_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_distortion
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
% Update image:
displayImage(handles);
% Update boxes:
plotBoxImage(handles,1);
plotBoxImage(handles,2);
% Update the i and j locations of points:
[userdata,~,lind] = getGUIStatus(handles);
tp = get(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(1,lind(4),:),{'Xdata','Ydata'});
set([handles.edit_j_bottom handles.edit_i_bottom],{'String'},...
    cellfun(@num2str,tp(1,:)','un',0));
set([handles.edit_j_side handles.edit_i_side],{'String'},...
    cellfun(@num2str,tp(2,:)','un',0));

% -- Processes selected video file, checks if it is already loaded and if
% not checks for existing background and lablling files:
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
if any(isrepeated)
    fprintf('The following files were already on the list:\n');
    fprintf('%s\n',file_name{isrepeated});
end
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
    vid = VideoReader(file_name{i_files});
    % Initializing the data structure for this video:
    d = initializeUserDataStructure(userdata, vid);
    
    if video_id == 1
        % If the structure had been properly initialized as empty this
        % check would not have been needed.
        userdata.data = d;
    else
        userdata.data(video_id) = d;
    end
    
    set(handles.figure1,'userdata',userdata);
    [~,fname,~] = fileparts(file_name{i_files});
    % Checking if there are labelling files to load for this video:
    lab_path = fullfile(vid.Path,[fname '_labelling.mat']);
    
    if exist(lab_path,'file')
        % Attempt to load label file.
        handles = loadLabelling(handles, load(lab_path),true);
    end
    userdata = get(handles.figure1,'userdata');
    % If for some reason the bkg path is not the same as the one loaded we
    % still check the current folder:
    if isempty(userdata.data(video_id).bkg_path)
        % Check if there is a background image with the same name:
        impath = fullfile(vid.Path,[fname '.png']);
        if exist(impath,'file')
            % Adding a new background image:
            [handles,N] = addBackgroudImage(impath,handles);
            userdata.data(video_id).bkg_path = impath;
            userdata.data(video_id).bkg = imread(impath);
            userdata.data(video_id).background_popup_id = N;
            set(handles.figure1,'userdata',userdata);
        end
    end
    
    if isempty(userdata.data(video_id).calibration_path)
        % Check if there is a calibration file with the same name:
        calpath = fullfile(vid.Path,[fname '_calibration.mat']);
        if exist(calpath,'file')
            % Adding a new background image:
            [handles,N] = addDistortionCorrection(handles,calpath);
            userdata.data(video_id).calibration_path = calpath;
            userdata.data(video_id).calibration_popup_id = N;
            L = load(calpath);
            userdata.data(video_id).ind_warp_mapping = L.ind_warp_mapping;
            userdata.data(video_id).inv_ind_warp_mapping = L.inv_ind_warp_mapping;
            userdata.data(video_id).split_line = L.split_line;
            set(handles.figure1,'userdata',userdata);
            edit_split_line_Callback([],[],handles);
        end
    end
    
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


% --- Deals with a potentially new background image:
function [handles,N] = addBackgroudImage(file_full_path,handles)
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

% --- Loads labelling created with this GUI:
function handles = loadLabelling(handles, loaded_data,merge_all)
% Given loaded data this function updates the tree structures in handles
% and the userdata.data structure for the tracks and visibility.

if ~exist('merge_all','var');
    merge_all = false;
end

try
    [userdata, video_id] = getGUIStatus(handles);
    % Loading values:
    if all(mod(loaded_data.labelled_frames, loaded_data.frame_step))
        % Labelling follows the step pattern:
        userdata.data(video_id).current_frame = loaded_data.start_frame;
        userdata.data(video_id).current_frame_step = loaded_data.frame_step;
        userdata.data(video_id).current_start_frame = loaded_data.start_frame;
    else
        % Labelling does not follow pattern, steps
        % cannot be trusted:
        userdata.data(video_id).current_frame = loaded_data.labelled_frames(1);
        userdata.data(video_id).current_frame_step = 1;
        userdata.data(video_id).current_start_frame = loaded_data.labelled_frames(1);
    end
    userdata.data(video_id).flip = loaded_data.flip;
    userdata.data(video_id).scale = loaded_data.scale;
    userdata.data(video_id).split_line = loaded_data.split_line;
    userdata.data(video_id).bkg_path = loaded_data.bkg_path;
    userdata.data(video_id).calibration_path = loaded_data.calibration_path;
    
    if exist(userdata.data(video_id).bkg_path,'file');
        set(handles.figure1,'userdata',userdata);
        [handles,N] = addBackgroudImage(userdata.data(video_id).bkg_path,handles);
        userdata.data(video_id).bkg = imread(userdata.data(video_id).bkg_path);
        userdata.data(video_id).background_popup_id = N;

    else
        fprintf('Warning: Could not find the background file %s defined in the labelling file!\nSearching for background in the video folder...\n',userdata.data(video_id).bkg_path);
        userdata.data(video_id).bkg_path = '';
        userdata.data(video_id).bkg = [];
        userdata.data(video_id).background_popup_id = 1; % Supposed to be already, but jut in case;
        if ~isempty(userdata.data(video_id).bkg_path)
            fprintf('Warning: Could not find the background file %s defined in the labelling file!\nSearching for background in the video folder...\n',userdata.data(video_id).idx_path);
        end
    end
    
    if exist(userdata.data(video_id).calibration_path,'file')
        % Load IDX:
        set(handles.figure1,'userdata',userdata);
        [handles,N] = addDistortionCorrection(handles,userdata.data(video_id).calibration_path);
        userdata.data(video_id).calibration_popup_id = N;
        L = load(userdata.data(video_id).calibration_path);
        userdata.data(video_id).ind_warp_mapping = L.ind_warp_mapping;
        userdata.data(video_id).inv_ind_warp_mapping = L.inv_ind_warp_mapping;
        userdata.data(video_id).split_line = L.split_line;
        set(handles.figure1,'userdata',userdata);
        edit_split_line_Callback([],[],handles);
    else
        if ~isempty(userdata.data(video_id).calibration_path)
            fprintf('Warning: Could not find the background file %s defined in the labelling file!\nSearching for background in the video folder...\n',userdata.data(video_id).idx_path);
        end
        userdata.data(video_id).calibration_path = '';
        userdata.data(video_id).ind_warp_mapping = [];
        userdata.data(video_id).inv_ind_warp_mapping = [];
        userdata.data(video_id).calibration_popup_id = 1;
    end
    
    % Checking if we have the new format or the old format:
    if iscell(loaded_data.labels)
        % New format:
        N_loaded_types = length(loaded_data.labels);
        i_types = 1;
        while i_types <= N_loaded_types
            N_loaded_class_type = length(loaded_data.labels{i_types});
            i_class = 1;
            
            while i_class <= N_loaded_class_type
                N_features_class_type = length(loaded_data.labels{i_types}{i_class});
                i_feature = 1;
                
                while i_feature <= N_features_class_type
                    L = loaded_data.labels{i_types}{i_class}(i_feature);
                    % Compare type:
                    match_type = strcmpi(L.type,userdata.types);
                    if any(match_type)
                        type_index = find(match_type);
                        match_class = strcmpi(L.class,userdata.classes{type_index});
                        if any(match_class)
                            class_index = find(match_class);
                            match_feature = strcmpi(L.name,userdata.features{type_index}{class_index});
                            if any(match_feature)
                                % Check if number of points is the same:
                                feature_index = find(match_feature);
                                if L.N_points == userdata.labels{type_index}{class_index}(feature_index).N_points
                                    if ~merge_all
                                        % Warn the user that data will be
                                        % replaced, offer option for merging
                                        % all.
                                        answ = questdlg('Existing label information will be replaced by loaded information. Do you wish to proceed?',...
                                            'Delete Label','Yes','No','No');
                                        if strcmpi(answ,'yes')
                                            merge_all = true;
                                        else
                                            return;
                                        end
                                    end
                                    userdata.labels{type_index}{class_index}(feature_index) = L; 
                                    [userdata.data(video_id).tracks{type_index}{class_index}{feature_index},...
                                    userdata.data(video_id).visibility{type_index}{class_index}{feature_index}] = ...
                                        addTracksVisibility(zeros(size(userdata.data(video_id).tracks{type_index}{class_index}{feature_index})),...
                                                            zeros(size(userdata.data(video_id).visibility{type_index}{class_index}{feature_index})),...
                                                            loaded_data.tracks{type_index}{class_index}{feature_index},...
                                                            loaded_data.visibility{type_index}{class_index}{feature_index},...
                                                            loaded_data.labelled_frames);
                                    set(handles.figure1,'userdata',userdata);
                                    i_feature = i_feature + 1; % Move to another feature;
                                else
                                    % Decide what to do if these don't
                                    % match.
                                end
                            else
                                % Add feature:
                                N_existing_features = length(userdata.labels{type_index}{class_index});
                                handles = addMergeLabels(handles,[type_index class_index N_existing_features+1 1], L);
                                % Refreshingn userdata:
                                userdata = get(handles.figure1,'userdata');
                                i_feature = i_feature + 1; % Move to another feature;
                            end
                        else
                            % Add new class:
                            N_existing_classes = length(userdata.labels{type_index});
                            handles = addMergeLabels(handles,[type_index N_existing_classes+1 1 1], L);
                            % Refreshingn userdata:
                            userdata = get(handles.figure1,'userdata');
                        end
                    else
                        % Add new type:
                        N_existing_types = length(userdata.labels);
                        handles = addMergeLabels(handles,[N_existing_types+1 1 1 1], L);
                        % Refreshingn userdata:
                        userdata = get(handles.figure1,'userdata');
                    end
                end
                i_class = i_class + 1; % Move to another class;
            end
            i_types = i_types + 1; % Move to another type;
        end
        
    else
        % Old format:
        N_loaded_labels = length(loaded_data.labels);
        
        types_loaded = {loaded_data.labels(:).type};
        classes_loaded = {loaded_data.labels(:).class};
        names_loaded = {loaded_data.labels(:).name};
        
        % Merging loaded data with existing structure:
        for i_labels = 1:N_loaded_labels
            
            % Matching type:
            match_type = strcmpi(types_loaded{i_labels},userdata.types);
            
            if any(match_type)
                % Matching class
                match_class = strcmpi(classes_loaded{i_labels},userdata.classes{match_type});
                
                if any(match_class)
                    % Matching name:
                    match_name = strcmpi(names_loaded{i_labels},userdata.features{match_type}{match_class});
                    
                    if any(match_name)
                        % Feature is fully matched, overwrite:
                        
                        % Label is the same, overwrite:
                        userdata.data(video_id).tracks{match_type}{match_class}{match_name}(:,:,loaded_data.labelled_frames,:) = cat(4,loaded_data.tracks{i_labels}([1 2],:,:),loaded_data.tracks{i_labels}([3 4],:,:));
                        % Not a very smart move, but internally on the
                        % labelling code its better to add 1 to the
                        % visibility values so they directly correspond
                        % to the drop down menu. On saving, subtract 1.
                        % Carefull when initializing the visibility, should
                        % never be set to 0.
                        userdata.data(video_id).visibility{match_type}{match_class}{match_name}(:,loaded_data.labelled_frames,:) = loaded_data.visibility{i_labels}+1;
                        set(handles.figure1,'userdata',userdata);
                        continue;
                    else
                        % Add new feature to current type and class:
                        display('Found label with name %s that does not match the class and type of existing label with the same name! Label was ignored.',names_loaded{i_labels});
                        
                    end
                    
                else
                    % Add new class to matched type:
                    display('Found label with class %s that does not match any class of type %s for existing labels! Label was ignored.',classes_loaded{i_labels}, names_loaded{i_labels});
                end
            else
                % Adding new type:
                display('Found label with type %s that does not match any supported class types! Label was ignored.',types_loaded{i_labels});
            end
            
        end
    end
    
    % Refresh the GUI:
    set(handles.popupmenu_type,'Value',1);
    popupmenu_type_Callback([],[],handles);
    
catch error_type
    fprintf('Failed to load data!\n');
    displayErrorGui(error_type);
end

% --- Adding distortion correction file
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

% --- Executes on selection change in popupmenu_n_points.
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

% Updating Color pushbutton:
pb_color = get(userdata.plot_handles{lind(1)}{lind(2)}{lind(3)}(1,value),'Color'); % It should always be the same for all plot handles...
set(handles.pushbutton_color,'BackgroundColor',pb_color);



% --- Executes during object creation, after setting all properties.
function popupmenu_n_points_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_n_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_all_points.
function checkbox_all_points_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_all_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_all_points
plotBoxImage(handles,1);
plotBoxImage(handles,2);

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
        userdata.data(i_videos).tracks = cat(2,data(i_videos).tracks,{cell(1,0)});
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
        userdata.data(i_videos).tracks{label_indexes(1)} = cat(2,userdata.data(i_videos).tracks{label_indexes(1)},{cell(1,0)});
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
        userdata.data(i_videos).tracks{label_indexes(1)} = cat(2,userdata.data(i_videos).tracks{label_indexes(1)},{cell(1,0)});
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
    
    % Adjusting the tracks and visibility structures:
    for i_videos = 1:N_videos
        userdata.data(i_videos).tracks{label_indexes(1)}{label_indexes(2)}{label_indexes(3)} =...
            NaN(2,label.N_points,userdata.data(i_videos).vid.NumberOfFrames,2);
        userdata.data(i_videos).visibility{label_indexes(1)}{label_indexes(2)}{label_indexes(3)} = ones(label.N_points,userdata.data(i_videos).vid.NumberOfFrames,2);
    end
    
end
set(handles.figure1,'userdata',userdata);


% ---
function [empty_tracks, empty_visibility] = initializeEmptyTracksVisibility(userdata, Nframes)
N_types = length(userdata.types);
% Initializing an empty structure:
empty_tracks = cell(1,N_types);
empty_visibility = cell(1,N_types);

for i_type = 1:N_types
    N_classes_type = length(userdata.classes{i_type});
    empty_tracks{i_type} = cell(1,N_classes_type);
    empty_visibility{i_type} = cell(1,N_classes_type);
    
    for i_classes = 1:N_classes_type
        N_features_type_class = length(userdata.features{i_type}{i_classes});
        empty_tracks{i_type}{i_classes} = cell(1,N_features_type_class);
        empty_visibility{i_type}{i_classes} = cell(1,N_features_type_class);
        
        for i_features = 1:N_features_type_class
            empty_tracks{i_type}{i_classes}{i_features} = NaN(2,userdata.labels{i_type}{i_classes}(i_features).N_points,Nframes,2);
            empty_visibility{i_type}{i_classes}{i_features} = ones(userdata.labels{i_type}{i_classes}(i_features).N_points,Nframes,2);
        end
    end
end

% --- Apply tracks and visibility to data:
function [empty_tracks,empty_visibility] = addTracksVisibility(empty_tracks,empty_visibility,new_tracks,new_visibility,labelled_frames)
empty_tracks(:,:,labelled_frames,:) = cat(4,new_tracks([1 2],:,:), new_tracks([3 4],:,:));
empty_visibility(:,labelled_frames,:) = new_visibility + 1;