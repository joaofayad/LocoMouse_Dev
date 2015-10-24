function varargout = LocoMouse_Calibration(varargin)
% LOCOMOUSE_CALIBRATION MATLAB code for LocoMouse_Calibration.fig
%      LOCOMOUSE_CALIBRATION, by itself, creates a new LOCOMOUSE_CALIBRATION or raises the existing
%      singleton*.
%
%      H = LOCOMOUSE_CALIBRATION returns the handle to a new LOCOMOUSE_CALIBRATION or the handle to
%      the existing singleton*.
%
%      LOCOMOUSE_CALIBRATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LOCOMOUSE_CALIBRATION.M with the given input arguments.
%
%      LOCOMOUSE_CALIBRATION('Property','Value',...) creates a new LOCOMOUSE_CALIBRATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LocoMouse_Calibration_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LocoMouse_Calibration_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LocoMouse_Calibration

% Last Modified by GUIDE v2.5 15-Nov-2014 19:11:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LocoMouse_Calibration_OpeningFcn, ...
                   'gui_OutputFcn',  @LocoMouse_Calibration_OutputFcn, ...
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


% --- Executes just before LocoMouse_Calibration is made visible.
function LocoMouse_Calibration_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LocoMouse_Calibration (see VARARGIN)

% Choose default command line output for LocoMouse_Calibration
handles.output = hObject;

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
handles.supported_im_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_im_files(2:end,1)','un',false));
handles.supported_im_files{1,2} = 'All supported video files';

% Initialising suppoted video files:
sup_files = VideoReader.getFileFormats;
handles.N_supported_files = size(sup_files,2)+1;
handles.supported_files = cell(handles.N_supported_files,2);
handles.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
handles.supported_files(2:end,2) = {sup_files(:).Description};
handles.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_files(2:end,1)','un',false));
handles.supported_files{1,2} = 'All supported video files';

%% Initializing objects:
% Initializing the images:
handles.video_image = imshow([],'Parent',handles.axes_video);
set(handles.video_image,'CData',[]);
set(handles.axes_video,'CLim',[0 255]);
set(handles.axes_plot,'Visible','off');

% Initializing user data:
userdata.plot_handles = line(NaN(2,1),NaN(2,1),'LineStyle','-','LineWidth',...
    1,'Color','r','Visible','off','Parent',handles.axes_video,'Marker','*');
userdata.no_video = true;

% Initializing the split line:
handles.split_line = line(0,0,'Linestyle','-','Linewidth',...
    1,'Visible','off','Color','w','Parent',handles.axes_video);

% Initializing the color pushbutton:
set(handles.pushbutton_color,'BackgroundColor',[1 1 1]);

% Initializing the slider:
set(handles.slider_frame,'Min',1);
set(handles.slider_frame,'Max',100); % Any value just so it looks like something.
set(handles.slider_frame,'Value',1);

% Initialize imbw slider:
set(handles.slider_im2bw,'Value',0.5);

% Initializing the data:
set(handles.figure1,'userdata',userdata);
handles.latest_path = pwd;

% Assigning the click function to the window:
set(handles.video_image,'ButtonDownFcn',{@axes_frame_ButtonDownFcn,handles});

% Checking if data has been saved or not:
handles.is_data_saved = true;
resetGUI(handles);

% Update handles structure:

guidata(hObject, handles);

% UIWAIT makes LocoMouse_Calibration wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LocoMouse_Calibration_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider_frame_Callback(hObject, eventdata, handles)
% hObject    handle to slider_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
curr_slide_step = get(handles.slider_frame,'SliderStep');
value = get(handles.slider_frame,'Value');
userdata = get(handles.figure1,'userdata');

if curr_slide_step(1) == 0.5 && (userdata.data.current_frame_step == 1)
    if value < userdata.data.current_frame
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
function slider_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function slider_im2bw_Callback(hObject, eventdata, handles)
% hObject    handle to slider_im2bw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

value = get(handles.slider_im2bw,'Value');
set(handles.edit_im2bw,'String',num2str(value));
edit_im2bw_Callback([],[],handles);


% --- Executes during object creation, after setting all properties.
function slider_im2bw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_im2bw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_im2bw_Callback(hObject, eventdata, handles)
% hObject    handle to edit_im2bw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_im2bw as text
%        str2double(get(hObject,'String')) returns contents of edit_im2bw as a double

value = str2double(get(handles.edit_im2bw,'String'));
userdata = get(handles.figure1,'userdata');

if isnan(value)
    value = userdata.data.th;
else
    value = max(min(value,1),0);
    userdata.data.th = value;
end
set(handles.figure1,'userdata',userdata);
set(handles.slider_im2bw,'Value',value);
guidata(handles.figure1,handles);
displayImage(handles);


% --- Executes during object creation, after setting all properties.
function edit_im2bw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_im2bw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_background_path_Callback(hObject, eventdata, handles)
% hObject    handle to edit_background_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_background_path as text
%        str2double(get(hObject,'String')) returns contents of edit_background_path as a double


% --- Executes during object creation, after setting all properties.
function edit_background_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_background_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_auto.
function pushbutton_auto_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.figure1,'Pointer','watch');
ht = findobj('Type','uicontrol','-and','Enable','on');
set(ht,'Enable','off');
drawnow
try
    userdata = get(handles.figure1,'userdata');
    t = get(handles.slider_im2bw,'Value');
    
    frame_vec = userdata.data.current_start_frame:userdata.data.current_frame_step:userdata.data.current_end_frame;
    
    [userdata.data.tracks([2 1],frame_vec,:),userdata.data.visibility(frame_vec),userdata.data.cos_theta(frame_vec)] = ...
        LocoMouse_CalibrationCorrespondences(userdata.vid,userdata.data.bkg,userdata.data.split_line,t,...
        frame_vec);
    userdata.data.tracks(:,frame_vec,:) = round(userdata.data.tracks(:,frame_vec,:));
    set(handles.figure1,'userdata',userdata);
    % Update tracks and visibility:
    % Update the plot of cos_theta vs X:
    updateCosTheta(userdata,handles.axes_plot)
    
    % Update the video frame:
    updatePosition(handles);
    plotBoxImage(handles);
catch err
    displayErrorGui(err);
end
set(ht,'Enable','on');
set(handles.figure1,'Pointer','arrow');
drawnow

% --- Executes on button press in pushbutton_calibrate.
function pushbutton_calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.figure1,'userdata');
set(handles.figure1,'Pointer','watch');
ht = findobj('Type','uicontrol','-and','Enable','on');
set(ht,'Enable','off');
drawnow
try
[userdata.data.ind_warp_mapping, userdata.data.inv_ind_warp_mapping] = ...
    LocoMouse_CalibrationMapFromCorrespondences(userdata.data.tracks,userdata.data.visibility,userdata.data.cos_theta,[userdata.data.vid.Height userdata.data.vid.Width]);
set(handles.figure1,'userdata',userdata);
set([handles.radiobutton_original handles.radiobutton_distorted],'Enable','on');
catch err
    displayErrorGui(err);
end
set(ht,'Enable','on');
set(handles.figure1,'Pointer','arrow');
drawnow;

function edit_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame as text
%        str2double(get(hObject,'String')) returns contents of edit_frame as a double

value = str2double(get(handles.edit_frame,'String'));
userdata = get(handles.figure1,'userdata');

if ~isnan(value)
    value = round(value);
    delta = mod(value-userdata.data.current_start_frame,userdata.data.current_frame_step);
    if delta ~= 0
        value = value-delta;
    end
    value = min(max(userdata.data.current_start_frame,value),get(handles.slider_frame,'Max'));
    set(handles.edit_frame,'String',num2str(value));
    set(handles.slider_frame,'Value',value);
    userdata.data.current_frame = value;
    set(handles.figure1,'UserData',userdata);
    displayImage(handles);
    updatePosition(handles);
    plotBoxImage(handles);
    drawnow;
else
    set(handles.edit_frame,'String',num2str(userdata.data.current_frame));
end
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function edit_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_step_Callback(hObject, eventdata, handles)
% hObject    handle to edit_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_step as text
%        str2double(get(hObject,'String')) returns contents of edit_step as a double

new_frame_step = str2double(get(handles.edit_step,'String'));
userdata = get(handles.figure1,'userdata');

if ~isnan(new_frame_step)
    % Getting current values for other frame parameters:
    current_start_frame = userdata.data.current_start_frame;
    current_frame = userdata.data.current_frame;
    
    % Updating the frame step:
    new_frame_step = round(new_frame_step);
    new_frame_step = min(max(1,new_frame_step),userdata.data.vid.NumberOfFrames-1);
    set(handles.edit_step,'String',num2str(new_frame_step));
    
    % Computing the new maximum point:
    new_max = userdata.data.vid.NumberOfFrames - mod(userdata.data.vid.NumberOfFrames-current_start_frame,new_frame_step);
    set(handles.slider_frame,'Max',new_max);
    % Updating the step:
    set(handles.slider_frame,'SliderStep',(new_frame_step/(new_max-current_start_frame))*[1 5]);
    % Updating the current frame so it lies within the possible values:
    set(handles.slider_frame,'Value',current_frame - mod(current_frame-current_start_frame,new_frame_step));
    userdata.data.current_frame_step = new_frame_step;
    set(handles.figure1,'UserData',userdata);
    displayImage(handles);
else
    set(handles.edit_frame,'String',num2str(userdata.data.current_frame_step));
end
set(handles.figure1,'UserData',userdata);
guidata(hObject,handles);
slider_frame_Callback(handles.slider_frame,eventdata,handles);


% --- Executes during object creation, after setting all properties.
function edit_step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_start_Callback(hObject, eventdata, handles)
% hObject    handle to edit_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_start as text
%        str2double(get(hObject,'String')) returns contents of edit_start as a double
new_start_frame = str2double(get(hObject,'String'));
userdata = get(handles.figure1,'userdata');
if ~isnan(new_start_frame)
    new_start_frame = round(new_start_frame);
    new_start_frame = min(max(1,new_start_frame),userdata.data.vid.NumberOfFrames-1);
    
    if userdata.data.current_frame < new_start_frame
        % If we're starting ahead, update the current frame:
        userdata.data.current_frame = new_start_frame;
        set(handles.edit_frame,'String',num2str(new_start_frame));
    end
    
    if (new_start_frame + userdata.data.current_frame_step) > userdata.data.vid.NumberOfFrames
        % If with the current step we go over the limit, update the
        % step.
        new_range = max(1,userdata.data.vid.NumberOfFrame-new_start_frame);
        userdata.data.current_frame_step = new_range;
        set(handles.edit_frame_step,'String',num2str(new_range));
    end
    
    delta = mod(userdata.data.current_frame-new_start_frame,userdata.data.current_frame_step);
    if delta ~= 0
        userdata.data.current_frame = userdata.data.current_frame - delta;
    end
    % We always have to edit the slider...
    new_max = userdata.data.vid.NumberOfFrames - mod(userdata.data.vid.NumberOfFrames-new_start_frame,userdata.data.current_frame_step);
    set(handles.slider_frame,'Min',new_start_frame,'Max',userdata.data.vid.NumberOfFrames - mod(userdata.data.vid.NumberOfFrames-new_start_frame,userdata.data.current_frame_step),'Value',userdata.data.current_frame);
    set(handles.edit_frame,'String',num2str(userdata.data.current_frame));
    set(handles.slider_frame,'SliderStep',userdata.data.current_frame_step/(new_max-new_start_frame+1)*[1 5]);
    set(handles.edit_start,'String',num2str(new_start_frame));
    userdata.data.current_start_frame = new_start_frame;
else
    set(handles.edit_frame_step,'String',num2str(userdata.data.current_start_frame));
end
set(handles.figure1,'UserData',userdata);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function add_video_Callback(hObject, eventdata, handles)
% hObject    handle to add_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file_name,path_name] = uigetfile(handles.supported_files,'Choose a upported video file',handles.latest_path,'MultiSelect','off');
set(handles.figure1,'Pointer','watch');
ht = findobj('Type','uicontrol','-and','Enable','on');
set(ht,'Enable','off');
drawnow
if ischar(file_name) && ischar(path_name)
    try
    userdata = get(handles.figure1,'userdata');
    userdata.vid = VideoReader(fullfile(path_name, file_name));
    userdata.no_video = false;
    set(handles.figure1,'userdata',userdata);
    handles = addVideoFile(handles,path_name,file_name);
    handles = resetGUI(handles);
    catch err
        displayErrorGui(err);
    end
end
handles = updateEnable(handles);
set(handles.figure1,'Pointer','arrow');
set(ht,'Enable','on');
drawnow
guidata(handles.figure1,handles)

function edit_split_line_Callback(hObject, eventdata, handles)
% hObject    handle to edit_split_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_split_line as text
%        str2double(get(hObject,'String')) returns contents of edit_split_line as a double

new_split_line = round(str2double(get(handles.edit_split_line,'String')));
if ~isnan(new_split_line)
    userdata = get(handles.figure1,'userdata');
    new_split_line = min(max(1,new_split_line),userdata.data.vid.Height);
    userdata.data.split_line = new_split_line;
    set(handles.figure1,'UserData',userdata);
    set(handles.split_line ,'Xdata',[1 userdata.data.vid.Width],'Ydata',[new_split_line new_split_line]);
    
    % Check if any of the tracks violate the new split line:
    change = false;
    TB = userdata.data.tracks(2,:,1);
    ind_bottom = TB < new_split_line;
    if any(ind_bottom(:))
        TB(ind_bottom) = new_split_line;
        userdata.data.tracks(2,:,1) = TB;
        change = true;
    end
    
    TS = userdata.data.tracks(2,:,2);
    ind_side = TS > new_split_line;
    
    if any(ind_side(:))
        TS(ind_side) = new_split_line;
        userdata.data.tracks(2,:,2) = TS;
        change = true;
    end
    
    if change
        set(handles.figure1,'UserData',userdata);
        plotBoxImage(handles,1);
        plotBoxImage(handles,2);
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


% --- Executes on button press in pushbutton_split_line_add.
function pushbutton_split_line_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_split_line_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.figure1,'userdata');
set(handles.edit_split_line,'String',num2str(userdata.data.split_line+1));
edit_split_line_Callback(handles.edit_split_line,[],handles);

% --- Executes on button press in pushbutton_split_line_sub.
function pushbutton_split_line_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_split_line_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.figure1,'userdata');
set(handles.edit_split_line,'String',num2str(userdata.data.split_line-1));
edit_split_line_Callback(handles.edit_split_line,[],handles);

% --- Update position properties on the plot:
function updatePosition(handles)
% Updates position related properties of the GUI

userdata = get(handles.figure1,'userdata');
if userdata.no_video; return; end

pos = userdata.data.tracks(:,userdata.data.current_frame,:);
vis = userdata.data.visibility(userdata.data.current_frame);

if get(handles.radiobutton_distorted,'Value')
    pos = warpPointCoordinates(pos([2 1],:)',userdata.data.inv_ind_warp_mapping,size(userdata.data.inv_ind_warp_mapping));
    pos = reshape(pos(:,[2 1])',[2 1 2]);
end

set([handles.edit_j_bottom handles.edit_i_bottom],{'String'},...
    strsplit(num2str(pos(:,:,1)'),' ')');
set([handles.edit_j_top handles.edit_i_top],{'String'},...
    strsplit(num2str(pos(:,:,2)'),' ')');
set(handles.edit_split_line,'String',num2str(userdata.data.split_line));
set(handles.split_line,'Ydata',[userdata.data.split_line userdata.data.split_line]);

if vis
    set(handles.radiobutton_keep,'Value',1);
else
    set(handles.radiobutton_discard,'Value',1);
end


% --- Executes on button press in pushbutton_color.
function pushbutton_color_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.figure1,'userdata');
new_color = uisetcolor;
if length(new_color) ~= 1
    % Setting the color to the button:
    set(handles.split_line,'Color',new_color);
    set(handles.pushbutton_color,'BackgroundColor',new_color);
end
set(handles.figure1,'userdata',userdata);
guidata(hObject,handles);


function edit_j_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to edit_j_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_j_bottom as text
%        str2double(get(hObject,'String')) returns contents of edit_j_bottom as a double
new_j_bottom = str2double(get(handles.edit_j_bottom,'String'));
userdata = get(handles.figure1,'userdata');

if ~isnan(new_j_bottom)
    new_j_bottom = min(max(1,new_j_bottom),userdata.data.vid.Width);
    
    userdata.data.tracks(1,userdata.data.current_frame,1) = new_j_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    plotBoxImage(handles);
else
    set(handles.edit_j_bottom,'String',num2str(userdata.data.tracks(1,userdata.data.current_frame,1)));
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


% --- Executes on button press in pushbutton_j_bottom_sub.
function pushbutton_j_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_bottom,'String'));
set(handles.edit_j_bottom,'String',num2str(curr_j_value-1));
edit_j_bottom_Callback(handles.edit_j_bottom,[],handles);

% --- Executes on button press in pushbutton_j_bottom_add.
function pushbutton_j_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_bottom,'String'));
set(handles.edit_j_bottom,'String',num2str(curr_j_value+1));
edit_j_bottom_Callback(handles.edit_j_bottom,[],handles);

function edit_i_bottom_Callback(hObject, eventdata, handles)
% hObject    handle to edit_i_bottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_i_bottom as text
%        str2double(get(hObject,'String')) returns contents of edit_i_bottom as a double
new_i_bottom = str2double(get(handles.edit_i_bottom,'String'));
userdata = get(handles.figure1,'userdata');

if ~isnan(new_i_bottom)
    new_i_bottom = min(max(userdata.data.split_line+1,new_i_bottom),userdata.data.vid.Height);
    
    userdata.data.tracks(2,userdata.data.current_frame,1) = new_i_bottom;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    plotBoxImage(handles);
else
    set(handles.edit_i_bottom,'String',num2str(userdata.data.tracks(2,userdata.data.current_frame,1)));
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


% --- Executes on button press in pushbutton_i_bottom_sub.
function pushbutton_i_bottom_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_bottom_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_bottom,'String'));
set(handles.edit_i_bottom,'String',num2str(curr_i_value-1));
edit_i_bottom_Callback(handles.edit_i_bottom,[],handles);

% --- Executes on button press in pushbutton_i_bottom_add.
function pushbutton_i_bottom_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_bottom_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_bottom,'String'));
set(handles.edit_i_bottom,'String',num2str(curr_i_value+1));
edit_i_bottom_Callback(handles.edit_i_bottom,[],handles);

% --- Executes on button press in pushbutton_i_top_add.
function pushbutton_i_top_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_top_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_top,'String'));
set(handles.edit_i_top,'String',num2str(curr_i_value+1));
edit_i_top_Callback(handles.edit_i_top,[],handles);

% --- Executes on button press in pushbutton_i_top_sub.
function pushbutton_i_top_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_i_top_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_i_value = str2double(get(handles.edit_i_top,'String'));
set(handles.edit_i_top,'String',num2str(curr_i_value-1));
edit_i_top_Callback(handles.edit_i_top,[],handles);


function edit_i_top_Callback(hObject, eventdata, handles)
% hObject    handle to edit_i_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_i_top as text
%        str2double(get(hObject,'String')) returns contents of edit_i_top as a double
new_i_top = str2double(get(handles.edit_i_top,'String'));
userdata = get(handles.figure1,'userdata');

if ~isnan(new_i_top)
    new_i_top = min(max(1,new_i_top),userdata.data.split_line);
    
    userdata.data.tracks(2,userdata.data.current_frame,2) = new_i_top;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
    plotBoxImage(handles);
else
    set(handles.edit_i_top,'String',num2str(userdata.data.tracks(1,userdata.data.current_frame,2)));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_i_top_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_i_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_j_top_add.
function pushbutton_j_top_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_top_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_top,'String'));
set(handles.edit_j_top,'String',num2str(curr_j_value+1));
edit_j_top_Callback(handles.edit_j_top,[],handles);

% --- Executes on button press in pushbutton_j_top_sub.
function pushbutton_j_top_sub_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_j_top_sub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curr_j_value = str2double(get(handles.edit_j_top,'String'));
set(handles.edit_j_top,'String',num2str(curr_j_value-1));
edit_j_top_Callback(handles.edit_j_top,[],handles);


function edit_j_top_Callback(hObject, eventdata, handles)
% hObject    handle to edit_j_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_j_top as text
%        str2double(get(hObject,'String')) returns contents of edit_j_top as a double
new_j_top = str2double(get(handles.edit_j_top,'String'));
userdata = get(handles.figure1,'userdata');

if ~isnan(new_j_top)
    new_j_top = min(max(1,new_j_top),userdata.data.vid.Width);
    
    userdata.data.tracks(1,userdata.data.current_frame,2) = new_j_top;
    set(handles.figure1,'UserData',userdata);
    updatePosition(handles);
%     updateVisibility(handles);
    plotBoxImage(handles);
else
    set(handles.edit_j_top,'String',num2str(userdata.data.tracks(1,userdata.data.current_frame,2)));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_j_top_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_j_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox_display_split_line.
function checkbox_display_split_line_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_display_split_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_display_split_line

if get(handles.checkbox_display_split_line,'Value')
    set(handles.split_line,'Visible','on');
else
    set(handles.split_line,'Visible','off');
end

% --- Executes on button press in checkbox_display_background.
function checkbox_display_background_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_display_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_display_background
userdata = get(handles.figure1,'userdata');
if get(handles.checkbox_display_background,'Value')
    userdata.data.bkg = [];
else
    userdata.data.bkg = imread(userdata.data.bkg_path);
end
set(handles.figure1,'userdata',userdata);
displayImage(handles);


% -- Processes selected video file
function handles = addVideoFile(handles,path_name,file_name)
% Store the path in case more files are to be added...
handles.latest_path = path_name;
userdata = get(handles.figure1,'userdata');

vid = VideoReader(fullfile(path_name,file_name));
set(handles.axes_video,'Clim',[0 255]);
set(handles.video_image,'CData',read(vid,1));
% Updating the image size:
set(handles.axes_video,'Units','normalized');
set(handles.axes_video,'Xlim',[0.5 vid.Width+0.5]);
set(handles.axes_video,'Ylim',[0.5 vid.Height+0.5]);
set(handles.video_image,'Xdata',[1 vid.Width],'Ydata',[1 vid.Height]);

[~,fname,~] = fileparts(file_name);

% Initializing the data structure for this video:
userdata.data = initializeUserDataStructure(vid);
set(handles.figure1,'userdata',userdata);

% Checking if there is background file on the folder:
% If for some reason the bkg path is not the same as the one loaded we
% still check the current folder:
impath = fullfile(vid.Path,[fname '.png']);
if exist(impath,'file')
    % Adding a new background image:
    userdata.data.bkg_path = impath;
    set(handles.checkbox_display_background,'Value',0);
    set(handles.figure1,'userdata',userdata);
end

if ~isempty(userdata.data(end).bkg) % Check if background was loaded
    set(handles.checkbox_display_background,'Enable','on');
    set(handles.checkbox_display_background,'Value',1);
else
    set(handles.checkbox_display_background,'Enable','off');
end

% set the end frame:
set(handles.edit_end,'String',num2str(userdata.data.current_end_frame));

guidata(handles.figure1,handles);
clear vid path_name;

function data = initializeUserDataStructure(vid)
% Initializes an empty data structure and checks the current folders for
% labels, background and other information.
tracks = NaN(2,vid.NumberOfFrames,2);
visibility = false(1,vid.NumberOfFrames);
cos_theta = NaN(1,vid.NumberOfFrames);

data = struct('current_frame',1,'current_frame_step',1,...
    'current_start_frame',1,...
    'current_end_frame',vid.NumberOfFrames,...
    'visibility',visibility,...
    'background_popup_id',1,...
    'tracks',tracks,...
    'split_line',NaN,'vid',vid,...
    'bkg',[],'bkg_path','',...
    'ind_warp_mapping',[],...
    'inv_ind_warp_mapping',[],...
    'th',0.5,...
    'cos_theta',cos_theta);
clear tracks vis


% --- Executes on button press in checkbox_display_bw_image.
function checkbox_display_bw_image_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_display_bw_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_display_bw_image
displayImage(handles);

% --- Re-renders the whole GUI. Useful when switching between videos.
function handles = resetGUI(handles)
% Check if there is any video selected, if so display first image:
% Getting the video ID on the list:
userdata = get(handles.figure1,'userdata'); 
if ~userdata.no_video
    % Updating the image size:
    set(handles.axes_video,'Units','normalized');
    set(handles.axes_video,'Xlim',[0.5 userdata.data.vid.Width+0.5]);
    set(handles.axes_video,'Ylim',[0.5 userdata.data.vid.Height+0.5]);
    set(handles.video_image,'Xdata',[1 userdata.data.vid.Width],'Ydata',[1 userdata.data.vid.Height]);
    
    % Updating the split line:
    if isnan(userdata.data.split_line)
        new_split_line = round(userdata.data.vid.Height/2);
        userdata.data.split_line = new_split_line;
        set(handles.edit_split_line,'String',num2str(new_split_line));
        set(handles.checkbox_display_split_line,'Value',1);
        set(handles.split_line ,'Xdata',[1 userdata.data.vid.Width],'Ydata',[new_split_line new_split_line],'Visible','on');
    end
        
    if isempty(userdata.data.bkg_path)
        set(handles.checkbox_display_background,'Enable','off');
    else
        set(handles.checkbox_display_background,'Enable','on');
        set(handles.checkbox_display_background,'Value',0);
        userdata.data.bkg = imread(userdata.data.bkg_path);
        set(handles.figure1,'UserData',userdata);
    end
    
    % Checking the distortion options:
    set(handles.uipanel_distortion,'SelectedObject', handles.radiobutton_original)
    if isempty(userdata.data.ind_warp_mapping)
        set([handles.radiobutton_distorted handles.radiobutton_original],'Enable','off');
        set([handles.radiobutton_distorted handles.radiobutton_original],'Enable','off');
    else
        set([handles.radiobutton_distorted handles.radiobutton_original],'Enable','on');
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
    set(handles.slider_frame,'Max',userdata.data.vid.NumberOfFrames);
    set(handles.slider_frame,'SliderStep',(userdata.data.current_frame_step/userdata.data.vid.NumberOfFrames)*[1 5]);
    set(handles.slider_frame,'Value',userdata.data.current_frame);
    
    % Updating the im2bw lider:
    set(handles.slider_im2bw,'Value',userdata.data.th);
    
    % Updating the frame options:
    set(handles.edit_frame,'String',num2str(userdata.data.current_frame));
    set(handles.edit_start,'String',num2str(userdata.data.current_start_frame));
    set(handles.edit_step,'String',num2str(userdata.data.current_frame_step));
    
    displayImage(handles);
    updatePosition(handles);
    set(userdata.plot_handles,'Xdata',NaN(1,2),'Ydata',NaN(1,2));
    plotBoxImage(handles);
    
    % Saving the handles
    set(handles.figure1,'UserData',userdata);
    guidata(handles.figure1,handles);
else
    % Resetting the appearance:
    hedit = findobj('Style','edit');
    set(hedit,'String','NaN','Enable','off');
    
    set(userdata.plot_handles,'Visible','off');
    set(handles.video_image,'CData',[]);
    plot(NaN,NaN,'Parent',handles.axes_plot);
    set(handles.axes_plot,'Visible','off');
end

% --- Gets the positioin of the click from the mouse on the figure.
function axes_frame_ButtonDownFcn(hObject,eventdata,handles)
% hObject    handle to axes_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.radiobutton_distorted == get(handles.uipanel_distortion,'SelectedObject')
return;
end
userdata = get(handles.figure1,'userdata');
if ~userdata.no_video
    p = get(handles.axes_video,'CurrentPoint');
    p = round(p(1,1:2));
    
    if p(2) > str2double(get(handles.edit_split_line,'String'))
        view = 1; % Bottom
    else
        view = 2; % Side
    end
    
    % Updates the plot on the current view (original or distorted). Checks
    % if there is warping needed to save the data, as that is always saved
    % in the original view.
    IJ = cell2mat(get(userdata.plot_handles,{'Xdata','Ydata'})');
    IJ(:,view) = p';
    set(userdata.plot_handles,...
        'Xdata',IJ(1,:),...
        'Ydata',IJ(2,:),...
        'Visible','on');
    
    % If showing corrected images, p needs to be warped back to original:
%     if handles.radiobutton_distorted == get(handles.uipanel_distortion,'SelectedObject')
%         p(:,[2 1]) = warpPointCoordinates(p(:,[2 1]),userdata.data.ind_warp_mapping   ,size(userdata.data.ind_warp_mapping));
%     end
    
        
    userdata.data.tracks(:,userdata.data.current_frame,view) = p';
    % cos_theta always computed in original coordinates...
    pos = squeeze(userdata.data.tracks(:,userdata.data.current_frame,:));
    if ~any(isnan(pos(:)))
        set(handles.radiobutton_keep,'Value',1);
        V = pos(:,2) - pos(:,1);
        userdata.data.cos_theta(userdata.data.current_frame) = V(1)./(sqrt(sum(V(:).^2)));
        userdata.data.visibility(userdata.data.current_frame) = true;
        updateCosTheta(userdata, handles.axes_plot);
    end
    set(handles.figure1,'UserData',userdata);
    
    % Plotting the points:
        % Updating center coordinate:
    
    updatePosition(handles);
    
    % handles.is_data_saved = false;
    % handles = displayImage(handles);
    guidata(handles.figure1,handles);
end


function [] = displayImage(handles)
% This function reads the current frame from the video and updates it on
% the GUI.

userdata = get(handles.figure1,'userdata');
[Iorg,Idist] = readMouseImage(userdata.data.vid,...
    userdata.data.current_frame,...
    userdata.data.bkg,...
    false,...
    1,...
    userdata.data.ind_warp_mapping,...
    size(userdata.data.inv_ind_warp_mapping));

if get(handles.uipanel_distortion,'SelectedObject') == handles.radiobutton_original
    % Updating the image size:
    I = Iorg;    
else
    
    I = Idist;
end

if get(handles.checkbox_display_bw_image,'Value')
    th = get(handles.slider_im2bw,'Value');
    I = uint8(im2bw(I,th))*255;
end

set(handles.video_image,'CData',I);

% --- Executes on button press in pushbutton_add_background.
function pushbutton_add_background_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Browse supported file formats:
[file_name,path_name] = uigetfile(handles.supported_im_files,'Choose a supported background file',handles.latest_path,'MultiSelect','off');

if ~isequal(file_name,0) && ~isequal(path_name,0)
    userdata = get(handles.figure1,'userdata');
    file_full_path = fullfile(path_name,file_name);clear path_name file_name
    userdata.data.bkg = imread(file_full_path);
    userdata.data.bkg_path = file_full_path;
    set(handles.figure1,'userdata',userdata);
    set(handles.checkbox_display_background,'Value',0,'Enable','on');
    checkbox_display_background_Callback([],[],handles);
end
guidata(handles.figure1,handles);

% ---- Plotting the positions:
function plotBoxImage(handles)

userdata = get(handles.figure1,'userdata');

vis = userdata.data.visibility(userdata.data.current_frame);
pos = userdata.data.tracks(:,userdata.data.current_frame,:);    
if vis
    pos = userdata.data.tracks(:,userdata.data.current_frame,:);
    
    if get(handles.radiobutton_distorted,'Value')
        pos = warpPointCoordinates(pos([2 1],:)',userdata.data.inv_ind_warp_mapping,size(userdata.data.inv_ind_warp_mapping));        
        pos = reshape(pos(:,[2 1])',[2 1 2]);
    end
    set(userdata.plot_handles,'Visible','on');
else
    set(userdata.plot_handles,'Visible','off');
end
set(userdata.plot_handles,'Xdata',squeeze(pos(1,:))',...
        'Ydata',squeeze(pos(2,:))');

% --- Executes when selected object is changed in uipanel_keep_discard.
function uipanel_keep_discard_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_keep_discard 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.figure1,'userdata');
if userdata.no_video;return;end

if eventdata.NewValue == handles.radiobutton_keep
    userdata.data.visibility(userdata.data.current_frame) = true;
else
    userdata.data.visibility(userdata.data.current_frame) = false;
end
set(handles.figure1,'userdata',userdata);
plotBoxImage(handles);
updateCosTheta(userdata,handles.axes_plot);
guidata(handles.figure1,handles)

% --- updating the cos plot:
function [] = updateCosTheta(userdata,axes)
plot(squeeze(userdata.data.tracks(1,userdata.data.visibility,1)),userdata.data.cos_theta(userdata.data.visibility),'.','Parent',axes);


% --- Executes when selected object is changed in uipanel_distortion.
function uipanel_distortion_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_distortion 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.figure1,'userdata');

if eventdata.NewValue == handles.radiobutton_original
    im_size = size(userdata.data.inv_ind_warp_mapping);
    set([handles.edit_i_bottom handles.edit_i_top...
        handles.edit_j_bottom handles.edit_j_top ...
        handles.pushbutton_i_bottom_add...
        handles.pushbutton_i_bottom_sub...
        handles.pushbutton_i_top_add...
        handles.pushbutton_i_top_sub...
        handles.pushbutton_j_bottom_add...
        handles.pushbutton_j_bottom_sub...
        handles.pushbutton_j_top_add...
        handles.pushbutton_j_top_sub...
        ],'Enable','on');
else
    im_size = size(userdata.data.ind_warp_mapping);
    set([handles.edit_i_bottom handles.edit_i_top...
        handles.edit_j_bottom handles.edit_j_top ...
        handles.pushbutton_i_bottom_add...
        handles.pushbutton_i_bottom_sub...
        handles.pushbutton_i_top_add...
        handles.pushbutton_i_top_sub...
        handles.pushbutton_j_bottom_add...
        handles.pushbutton_j_bottom_sub...
        handles.pushbutton_j_top_add...
        handles.pushbutton_j_top_sub...
        ],'Enable','off');
end

set(handles.axes_video,'Units','normalized');
set(handles.axes_video,'Xlim',[0.5 im_size(2)+0.5]);
set(handles.axes_video,'Ylim',[0.5 im_size(1)+0.5]);
set(handles.video_image,'Xdata',[1 im_size(2)],'Ydata',[1 im_size(1)]);
set(handles.split_line,'Xdata',[1 im_size(2)]);
updatePosition(handles);
displayImage(handles);
plotBoxImage(handles);


% --------------------------------------------------------------------
function save_calibration_Callback(hObject, eventdata, handles)
% hObject    handle to save_calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.figure1,'userdata');
if userdata.no_video;return;end


[~,name,~] = fileparts(userdata.data.vid.Name);
[file_name,path_name] = uiputfile({'*.mat','MAT-files (*.mat)'},'Select File for Save As',fullfile(handles.latest_path,sprintf('%s_calibration.mat',name)));
if ~isequal(file_name,0) && ~isequal(path_name,0)
    handles.latest_path = path_name;
    struct_to_save.ind_warp_mapping = userdata.data.ind_warp_mapping;
    struct_to_save.inv_ind_warp_mapping = userdata.data.inv_ind_warp_mapping;
    struct_to_save.split_line = userdata.data.split_line;
    save(fullfile(path_name,file_name),'-struct','struct_to_save'); % Generating the MAT file.
end
set(handles.figure1,'userdata',userdata);
guidata(hObject,handles);



function edit_end_Callback(hObject, eventdata, handles)
% hObject    handle to edit_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_end as text
%        str2double(get(hObject,'String')) returns contents of edit_end as a double


% --- Executes during object creation, after setting all properties.
function edit_end_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function handles = updateEnable(handles)

userdata = get(handles.figure1,'userdata');
% Check if to turn on or off:

types_to_off = {'Edit','Slider','Pushbutton','Checkbox'};
hfind = [];
for i_types = 1:length(types_to_off)
    hfind = [hfind;findobj('Style',types_to_off{i_types})];
end

if userdata.no_video
    %off
     set(hfind,'Enable','off');
     
     % Setting the radiobuttons as well:
     hrb = findobj('Type','radiobutton');
     set(hrb,'Enable','off');
else
    %on
     set(hfind,'Enable','on');
    % Setting only the visibility radio buttons on:
    set([handles.radiobutton_keep handles.radiobutton_discard],'Enable','on');
end



