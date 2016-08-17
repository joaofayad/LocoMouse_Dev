function varargout = debugTracker(varargin)
% DEBUGTRACKER MATLAB code for debugTracker.fig
%
% To use, call it as: 
% 
% For more information, check tutorial.m
%
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org)
% Last Modified: 17/11/2014

% Last Modified by GUIDE v2.5 28-Apr-2015 04:20:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @debugTracker_OpeningFcn, ...
    'gui_OutputFcn',  @debugTracker_OutputFcn, ...
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


% --- Executes just before debugTracker is made visible.
function debugTracker_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to debugTracker (see VARARGIN)

% Loading image by image and seeing if it is fast enough. If not, I'll have
% to read on how to do this with a buffer or eventually use the
% VideoReader functions.

% Choose default command line output for debugTracker
handles.output = hObject;
handles.data = varargin{1}{1};
handles.model = varargin{1}{2};
handles.final_tracks = varargin{1}{3};
handles.tail_tracks = varargin{1}{4}; % Makes no sense for track debug.
handles.ong_tracks = varargin{1}{5};
handles.ong_bounding_box_pos = varargin{1}{6};

% Debug variables:
debug = varargin{1}{7};
handles.candidate_locations_bottom = debug.tracks_bottom;
handles.M = debug.M;
handles.candidate_locations_joint = debug.tracks_top;
handles.M_top = debug.M_top;
handles.ong_vec = debug.nong_vect;
handles.unary = debug.Unary;
handles.pairwise = debug.Pairwise;
handles.xvel = debug.xvel;
handles.dmax = debug.occluded_distance;
handles.scale = 1;
handles.flip = handles.data.flip;
handles.bounding_box = debug.bounding_box;
handles.bounding_box_dim = debug.bounding_box_dim;

if ischar(handles.data.vid)
    handles.data.vid = VideoReader(handles.data.vid);
end

% Getting useful quantities:
[dim,handles.N_point_tracks, handles.Ndata] = size(handles.final_tracks);
handles.N_tracks_tail = size(handles.tail_tracks,2);

if length(handles.xvel) == handles.Ndata -1
    handles.xvel = [0;handles.xvel(:)];
end

if dim == 3
    % Expanding to 4 dim as it allows usage with unconstrained tracking.
    handles.final_tracks = handles.final_tracks([1 2 1 3],:,:);
end

% Displaying the first image just for development:
bkg = [];
[~,I] = readMouseImage(handles.data.vid,1,bkg,handles.flip,handles.scale,handles.data.ind_warp_mapping,size(handles.data.inv_ind_warp_mapping));
handles.image = imshow(sc(I,'gray'),'Parent',handles.axes1);

% Initializing the graphic objects:
c = [1 0 0;1 0 1;0 0 1;0 1 1;1 0.6941 0.3922]; % Point tracks; % These should be default across the system.
handles.plot_handles = zeros(1,handles.N_point_tracks);

% Tracks:
for i_obj = 1:handles.N_point_tracks
    handles.plot_handles(1,i_obj) = line(zeros(1,2),zeros(1,2),'Marker','o','Visible','on','Color',c(i_obj,:),'MarkerFaceColor',c(i_obj,:),'LineStyle','none');
    handles.plot_handles(2,i_obj) = line(zeros(1,2),zeros(1,2),'Marker','o','Visible','on','Color',c(i_obj,:),'MarkerFaceColor',c(i_obj,:),'LineStyle','none');
    handles.plot_handles_trajectory(1,i_obj) = line(zeros(1,2),zeros(1,2),'Marker','.','Visible','on','Color',c(i_obj,:),'MarkerFaceColor',c(i_obj,:),'LineStyle','-','LineWidth',4,'Visible','off');
    handles.plot_handles_trajectory(2,i_obj) = line(zeros(1,2),zeros(1,2),'Marker','.','Visible','on','Color',c(i_obj,:),'MarkerFaceColor',c(i_obj,:),'LineStyle','-','LineWidth',4,'Visible','off');
end

% ONG:
handles.N_ong_tracks = size(handles.ong_tracks,2);
handles.N_ong_vec_tracks = length(handles.ong_vec);
handles.plot_handles_ong(1,:) = line(handles.ong_tracks([1 1],:,1),handles.ong_tracks([2 2],:,1),'Marker','.','Color','w','LineStyle','none','Visible','off');
handles.plot_handles_ong_vec(1,:) = line(ones(1,handles.N_ong_vec_tracks),handles.ong_vec,'Marker','.','Color','w','LineStyle','none','Visible','off');
% handles.color_choice_ong = get(handles.plot_handles_ong,'Color');

% Candidates:
handles.N_candidates = cellfun(@(x)(size(x,1)-handles.N_ong_tracks),handles.unary);
handles.N_candidates_joint = cellfun(@(x)(size(x,2)),handles.candidate_locations_joint);
handles.N_candidates_max = max([handles.N_candidates_joint(:);handles.N_candidates(:)]);

handles.plot_handles_candidates(1,:) = line(ones(2,handles.N_candidates_max),ones(2,handles.N_candidates_max),'Marker','o','Color',[243 192 100]/255,'LineStyle','none');
handles.plot_handles_candidates(2,:) = line(ones(2,handles.N_candidates_max),ones(2,handles.N_candidates_max),'Marker','o','Color',[243 192 100]/255,'LineStyle','none');

handles.plot_handles_candidate_trajectories(1,:) = line(ones(2,handles.N_candidates_max),ones(2,handles.N_candidates_max),'Color',[243 192 100]/255,'LineStyle','-');
handles.plot_handles_candidate_trajectories(2,:) = line(ones(2,handles.N_candidates_max),ones(2,handles.N_candidates_max),'Color',[243 192 100]/255,'LineStyle','-');

% Transitions to and from ONG:
handles.plot_handles_transition_tofrom_ong = line(ones(2,handles.N_candidates_max),ones(2,handles.N_candidates_max),'Color','w','Linestyle','-','Visible','off');

% Bounding box: 
% Changed to 4 lines as the box on the original view is not a rectangle.
% handles.plot_handles_bounding_box = rectangle('Position', ones(1,4),'EdgeColor','y');

handles.plot_handles_bounding_box = zeros(1,4);
for i_box = 1:4
    handles.plot_handles_bounding_box(i_box) = line(0,0,'Color','y','Marker','*');
end

% Initializing the track list:
set(handles.popupmenu_tracks,'String',char({'FR Paw';'HR Paw';'FL Paw';'HL Paw';'Snout'}));
set(handles.popupmenu_tracks,'Value',1);

% Initializing the candidate numbering:
strValues = strtrim(cellstr(num2str(repmat(size(I),handles.N_candidates_max,1),'(%d,%d)')));
handles.candidate_numbers(1,:) = text(ones(handles.N_candidates_max,1),ones(handles.N_candidates_max,1),strValues,'VerticalAlignment','bottom','Color','k','BackgroundColor','w');
handles.candidate_numbers(2,:) = text(ones(handles.N_candidates_max,1),ones(handles.N_candidates_max,1),strValues,'VerticalAlignment','bottom','Color','k','BackgroundColor','w');
clear nums strValues I

% Initializing the image slider:
set(handles.slider_frames,'Min',1);
set(handles.slider_frames,'Max',handles.Ndata);
set(handles.slider_frames,'SliderStep',[1/handles.Ndata 0.05]);
set(handles.slider_frames,'Value',1);

% Initializing the speed slider:
set(handles.slider_speed,'Min',1);
set(handles.slider_speed,'Max',90);
set(handles.slider_speed,'SliderStep',[5/60 0.05]);
set(handles.slider_speed,'Value',30);

% Initializing Edits:
set(handles.edit_frames,'String','1');
set(handles.edit_speed,'String','30');
set(handles.edit_dmax,'String',num2str(handles.xvel(1)+handles.dmax));

% Initializing the user data:
setappdata(handles.figure1,'current_frame',1);
setappdata(handles.figure1,'bkg',bkg);
setappdata(handles.figure1,'image_type',true);

% Initializing the timer:
handles.timer = timer('Period',str2double(sprintf('%.02f',1/30)),'ExecutionMode','FixedSpacing','TasksToExecute',Inf,'BusyMode','Queue','TimerFcn',{@displayImage,handles},'UserData',{1});
displayImage([],[],handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes debugTracker wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = debugTracker_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider_frames_Callback(hObject, eventdata, handles)
% hObject    handle to slider_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = round(get(hObject,'Value'));
setappdata(handles.figure1,'current_frame',val);
displayImage([],[],handles);
set(handles.edit_frames,'String',num2str(val));
guidata(hObject, handles);
drawnow;

% --- Executes during object creation, after setting all properties.
function slider_frames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function edit_frames_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frames as text
%        str2double(get(hObject,'String')) returns contents of edit_frames as a double
value = str2double(get(hObject,'String'));
cf = getappdata(handles.figure1,'current_frame');
if ~isnan(value)
    value = round(value);
    value = min(max(1,value),handles.Ndata);
    set(handles.edit_frames,'String',num2str(value));
    set(handles.slider_frames,'Value',value);
    
    cf = value;
    setappdata(handles.figure1,'current_frame',cf);
    displayImage([], [], handles)
else
    set(handles.edit_frames,'String',num2str(cf));
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_frames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider_speed_Callback(hObject, eventdata, handles)
% hObject    handle to slider_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = get(hObject,'Value');
restart = false;
if strcmpi(get(handles.timer,'Running'),'on')
    restart = true;
    stop(handles.timer);
end
set(handles.timer,'Period',str2double(sprintf('%.02f\n',1/val)));
set(handles.edit_speed,'String',num2str(val));
if restart
    start(handles.timer);
end

% --- Executes during object creation, after setting all properties.
function slider_speed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_speed_Callback(hObject, eventdata, handles)
% hObject    handle to edit_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_speed as text
%        str2double(get(hObject,'String')) returns contents of edit_speed as a double


% --- Executes during object creation, after setting all properties.
function edit_speed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in togglebutton_play.
function togglebutton_play_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_play
value = get(hObject,'Value');

if value
    set(hObject,'String','Stop');
    %     set(handles.timer,'TimerFcn',{@displayImage,handles})
    start(handles.timer);
else
    stop(handles.timer);
    cf = getappdata(handles.figure1,'current_frame');
    set(handles.slider_frames,'Value',cf);
    set(hObject,'String','Play');
end

% --- Executes on selection change in popupmenu_tracks.
function popupmenu_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_tracks contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_tracks
current_frame = str2double(get(handles.edit_frames,'String'));
current_track = get(handles.popupmenu_tracks,'Value');

% Updating visibilities:
set(handles.plot_handles,'Visible','off');
set(handles.plot_handles(1:2,current_track),'Visible','on');
set(handles.plot_handles_trajectory,'Visible','off')
set(handles.plot_handles_trajectory(current_track),'Visible','on');

% Updating positions
updatePositionMarker(handles, current_track, current_frame);
updatePositionCandidates(handles, current_track, current_frame);
if get(handles.checkbox_transitions,'Value') == 1
    updateTrajectory(handles,current_track, current_frame);
end
set(handles.figure1,'Userdata',{current_frame});

% --- Executes during object creation, after setting all properties.
function popupmenu_tracks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Display Tracks
function displayImage(obj,event,handles)
% Get current frame number:
userdata = getappdata(handles.figure1);

if userdata.current_frame > handles.Ndata
    userdata.current_frame = 1;
end

% Get current track number:
current_track = get(handles.popupmenu_tracks,'Value');
if current_track > 4
    current_point = 2;
else
    current_point = 1;
end

% TODO: sort error with the background (the second time one ticks the box
% it gives throws an error because for some reason the size of the
% background changes

if get(handles.uipanel_detection_map,'SelectedObject') ~= handles.radiobutton_no_map
    bkg = handles.data.bkg;
else
    bkg = userdata.bkg; 
end

[Ioriginal,Idistorted] = readMouseImage(handles.data.vid,userdata.current_frame,bkg,handles.flip,handles.scale,handles.data.ind_warp_mapping,size(handles.data.inv_ind_warp_mapping));

if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_original_image
    I = Ioriginal;
else
    I = Idistorted;
end

% Update image:
if get(handles.uipanel_detection_map,'SelectedObject') ~= handles.radiobutton_no_map
    
    I_cell = cell(2,1);
    [I_cell{[2 1]}] = splitImage(I,handles.data.split_line);
    
    switch get(handles.uipanel_detection_map,'SelectedObject')
        case handles.radiobutton_paw_map
            model_name = 'paw';
            type_name = 'point';
            display('A')
        case handles.radiobutton_snout_map
            model_name = 'snout';
            type_name = 'point';
        case handles.radiobutton_tail_map
            model_name = 'tail';
            type_name = 'line';
    end
    
    I_cell{1} = conv2(double(I_cell{1}),handles.model.(model_name).w{1},'same') - handles.model.(model_name).rho{1};    
    I_cell{1}(I_cell{1}<0) = 0;
    I_cell{2} = conv2(double(I_cell{2}),handles.model.(model_name).w{2},'same') - handles.model.(model_name).rho{2};

    I_cell{2}(I_cell{2}<0) = 0;
    I = sc(cat(1,I_cell{[2 1]}),'prob');
    
else
    I = sc(I,'gray');
end
set(handles.image,'CData',I);clear I;

% Update current track marker position on current and previous frame:
updatePositionMarker(handles,current_track,userdata.current_frame);

% Update location of current candidates:
updatePositionCandidates(handles,current_track,userdata.current_frame);

% If displaying in trajectory mode, update trajectories:
if get(handles.checkbox_transitions,'Value') == 1
    updateTrajectory(handles,current_track,userdata.current_frame);
end

% Update location of ONG:
if handles.N_ong_tracks > 0 && get(handles.checkbox_ong,'Value') == 1
    % ONG is defined on distorted view...
    pos = bsxfun(@minus,handles.ong_bounding_box_pos([1;2],userdata.current_frame),handles.ong_tracks)';
    
    if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_original_image
        pos(:,[2 1]) = warpPointCoordinates(pos(:,[2 1]), ...
            handles.data.ind_warp_mapping, ...
            size(handles.data.ind_warp_mapping),handles.flip);
        % The tracks are defined on the original images but handles.ong_vec
        % is defined on the corrected images. To correctly plot
        % handles.ong_vec we must always warp one of the coordinates...
        pos_z_x = warpPointCoordinates(handles.final_tracks([2 1],current_track,userdata.current_frame)',...
            handles.data.inv_ind_warp_mapping, ...
            size(handles.data.inv_ind_warp_mapping),handles.flip);
        % The vertical coordinate is garbage:
        pos_z = [handles.ong_vec' repmat(pos_z_x(2),handles.N_ong_vec_tracks,1)]; clear pos_z_x
        % Warping to the original image:
        pos_z(:,[2 1]) = warpPointCoordinates(pos_z, ...
            handles.data.ind_warp_mapping, ...
            size(handles.data.ind_warp_mapping),handles.flip);
    else
        % As defined during the tracker...
        pos_z = [repmat(get(handles.plot_handles(1,current_track),'Xdata'),1,handles.N_ong_vec_tracks);handles.ong_vec]';
    end
    
    set(handles.plot_handles_ong(1,:),{'XData','YData'},num2cell(pos));
    set(handles.plot_handles_ong_vec,{'XData','YData'},mat2cell(pos_z,size(pos_z,1),ones(1,2)));
end

% if handles.N_tracks_tail > 0
%     set(handles.plot_handles_tail(1,:),{'XData','YData'},num2cell(handles.tail_tracks([1 2],:,userdata.current_frame)'));
%     set(handles.plot_handles_tail(2,:),{'XData','YData'},num2cell(handles.tail_tracks([1 3],:,userdata.current_frame)'));
% end

% TODO: this has to have into account whether the view is distorted or not (HGM)
% Draw bounding box
if( get(handles.checkbox_bounding_box,'Value'))

    corners = zeros(4,2);% BR BL TR TL
    
    corners(1,:) = [handles.bounding_box(1,userdata.current_frame) handles.bounding_box_dim(2)];
    corners(2,:) = [handles.bounding_box(1,userdata.current_frame)-handles.bounding_box_dim(1) handles.bounding_box_dim(2)];
    corners(3,:) = [handles.bounding_box(1,userdata.current_frame) handles.bounding_box_dim(2)-handles.bounding_box_dim(2)];
    corners(4,:) = [handles.bounding_box(1,userdata.current_frame)-handles.bounding_box_dim(1) handles.bounding_box_dim(2)-handles.bounding_box_dim(2)];
    corners(:,2) = corners(:,2) + handles.data.split_line; 
    
    % Check for need to warp:
    if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_original_image
        corners(:,[2 1]) = warpPointCoordinates(corners(:,[2 1]), ...
            handles.data.ind_warp_mapping, ...set(handles.plot_handles_bounding_box, {'Xdata','Ydata'}, boxlines);
            size(handles.data.ind_warp_mapping),handles.flip);
    end
    
    % Turning corners into lines:
    boxlines = [corners(1,1) corners(2,1) corners(1,2) corners(2,2);...
                corners(1,1) corners(3,1) corners(1,2) corners(3,2);...
                corners(2,1) corners(4,1) corners(2,2) corners(4,2);...
                corners(3,1) corners(4,1) corners(3,2) corners(4,2)];
    boxlines = mat2cell(boxlines,ones(1,4),2*ones(1,2));    
        
    set(handles.plot_handles_bounding_box, {'Xdata','Ydata'}, boxlines);
end

% Updating the Edits:
set(handles.edit_frames,'String',num2str(userdata.current_frame));
set(handles.edit_dmax,'String',num2str(handles.xvel(userdata.current_frame)+handles.dmax));
if strcmpi(get(obj,'Type'),'timer')
    if strcmpi(get(obj,'Running'),'on')
        setappdata(handles.figure1,'current_frame',userdata.current_frame+1);
    end
end
    

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if ~isempty(handles)
    if isvalid(handles.timer)
        if strcmpi(get(handles.timer,'Running'),'on')
            stop(handles.timer)
        end
        try
            delete(handles.timer);
        catch
            warning('There was a problem deleting the timer. Check it manually');
        end
    end
end
drawnow;
pause(0.01);
delete(hObject);


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox_ong.
function checkbox_ong_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_ong (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_ong
val = get(hObject,'Value');
if val == 1
    set(handles.plot_handles_ong(1,:),'Visible','on');
    set(handles.plot_handles_ong_vec,'Visible','on');
else
    set(handles.plot_handles_ong(1,:),'Visible','off');
    set(handles.plot_handles_ong_vec,'Visible','off');
end
if strcmpi(handles.timer.Running,'off')
    displayImage([],[],handles);
end

% --- Executes on selection change in popupmenu_candidates.
function popupmenu_candidates_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_candidates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_candidates contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_candidates

% Getting the state of the system:
current_candidate = get(hObject,'Value');
current_frame = str2num(get(handles.edit_frames,'String'));
current_track = get(handles.popupmenu_tracks,'Value');
if current_track > 4
    current_point = 2;
else
    current_point = 1;
end
% Get ong coordinate.

if current_candidate > handles.N_candidates(current_point,current_frame)
    % Occluding point, set it to the assigned ONG:
else
    % Set the point to a different candidate: (Only Bottom view so far...)
    handles.final_tracks(1:2,current_track,current_frame) =  handles.candidate_locations_bottom{current_point,current_frame}(1:2,current_candidate);
    handles.M(current_track,current_frame) = current_candidate;
end

% Update the display:
set(handles.figure1,'UserData',{current_frame});
displayImage([],[],handles);
guidata(handles.figure1,handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_candidates_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_candidates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dmax_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dmax as text
%        str2double(get(hObject,'String')) returns contents of edit_dmax as a double


% --- Executes during object creation, after setting all properties.
function edit_dmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Function that updates the position and visibility of a current set of
% markers:
function updatePositionMarker(handles,current_track,current_frame)
% Bottom view:
% if handles.flip
%     track_map = [3 4 1 2 5];
%     current_track = track_map(current_track);
% end

pos = handles.final_tracks(:,current_track,current_frame);

% Warp the points if needed:
if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_distorted_image
    Xin = [pos(2) pos(1);pos(4) pos(3)];
    pos = warpPointCoordinates(Xin, ...
        handles.data.inv_ind_warp_mapping, ...
        size(handles.data.inv_ind_warp_mapping),handles.flip);
    pos = [pos(1,2);pos(1,1);pos(2,2);pos(2,1)];
end
pos = pos';

% Plotting candidates:
if current_track > 4
    current_point = 2;
else
    current_point = 1;
end

if any(isnan(pos(1:2)))
    pos(1:2) = (handles.ong_tracks(:,handles.M(current_track,current_frame)-size(handles.candidate_locations_bottom{current_point,current_frame},2))+handles.ong_bounding_box_pos(1:2,current_frame))';
    set(handles.plot_handles(1,current_track),'MarkerFaceColor','none')
else
    set(handles.plot_handles(1,current_track),'MarkerFaceColor',get(handles.plot_handles(1,current_track),'Color'));
end
set(handles.plot_handles(1,current_track),{'XData','YData'},num2cell(pos(1:2)));

% Side View:
if isnan(pos(4))
    pos(3) = pos(1);
    Zpos = handles.M_top(current_track,current_frame)-size(handles.candidate_locations_joint{current_track,current_frame},2);
    if Zpos > 0
        pos(4) = handles.ong_vec(Zpos);
    else
        pos(4) = NaN;
    end
    set(handles.plot_handles(2,current_track),'MarkerFaceColor','none');
else
    set(handles.plot_handles(2,current_track),'MarkerFaceColor',get(handles.plot_handles(1,current_track),'Color'));
end
set(handles.plot_handles(2,current_track),{'XData','Ydata'},num2cell(pos(3:4)));

% --- Updates the location of candidates:
function updatePositionCandidates(handles,current_track,current_frame)

% if handles.flip
%     track_map = [3 4 1 2 5];
%     current_track = track_map(current_track);
% end


% Checking the current_point
if current_track > 4
    current_point = 2;
else
    current_point = 1;
end

% Update location of current candidates:
set(handles.plot_handles_candidates(1,1:handles.N_candidates(current_point,current_frame)),'Visible','on');

pos = handles.candidate_locations_bottom{current_point,current_frame}(1:2,:)';
% Warping if needed:
if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_original_image
    pos(:,[2 1]) = warpPointCoordinates(pos(:,[2 1]), ...
        handles.data.ind_warp_mapping, ...
        size(handles.data.ind_warp_mapping),handles.flip);
end
pos = num2cell(pos);
set(handles.plot_handles_candidates(1,1:handles.N_candidates(current_point,current_frame)),{'Xdata','Ydata'},pos);
set(handles.plot_handles_candidates(1,handles.N_candidates(current_point,current_frame)+1:end),'Visible','off')

% Update Z candidates for current track:
N_candidates_z = size(handles.candidate_locations_joint{current_track,current_frame},2);

if N_candidates_z > 0
    pos_z = handles.candidate_locations_joint{current_track,current_frame}([1 3],:)';
    if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_original_image
        pos_z(:,[2 1]) = warpPointCoordinates(pos_z(:,[2 1]), ...
            handles.data.ind_warp_mapping, ...
            size(handles.data.ind_warp_mapping),handles.flip);
        
    end
    pos_z = num2cell(pos_z);
    set(handles.plot_handles_candidates(2,1:N_candidates_z),{'Xdata','YData'},pos_z);
    set(handles.plot_handles_candidates(2,1:N_candidates_z),'Visible','on');
end
set(handles.plot_handles_candidates(2,N_candidates_z+1:end),'Visible','off');

% Update candidate labelling:
if handles.N_candidates(current_point,current_frame) > 0
    % If there are candidates:
    if get(handles.uipanel_candidate_options,'SelectedObject') == handles.radiobutton_scores
        % If showing scores, format the string to a single value:
        strValues_bottom = strtrim(cellstr(num2str(handles.candidate_locations_bottom{current_point,current_frame}(3,:)','%.02f')));
        
        if get(handles.checkbox_detection_scores,'Value') == 1
            % If displaying candidate info, set the properties right:
            set(handles.candidate_numbers(1,1:handles.N_candidates(current_point,current_frame)),{'Position'},mat2cell(bsxfun(@plus,cell2mat(pos),[5 0]),ones(handles.N_candidates(current_point,current_frame),1),2));
            set(handles.candidate_numbers(1,1:handles.N_candidates(current_point,current_frame)),{'String'},mat2cell(strValues_bottom,ones(handles.N_candidates(current_point,current_frame),1),size(strValues_bottom,2)));
        end
        
        if N_candidates_z > 0
            % If there are Z candidates, format z string accordingly:
            strValues_z = strtrim(cellstr(num2str(handles.candidate_locations_joint{current_track,current_frame}(4,:)','%.02f')));
            
            if get(handles.checkbox_detection_scores,'Value') == 1
                set(handles.candidate_numbers(2,1:N_candidates_z),{'String'},mat2cell(strValues_z,ones(N_candidates_z,1),size(strValues_bottom,2)));
                set(handles.candidate_numbers(2,1:N_candidates_z),{'Position'},mat2cell(bsxfun(@plus,cell2mat(pos_z),[5 0]),ones(N_candidates_z,1),2));
            end
            
        else
            strValues_z = '';
        end
    else
        % If showing image positions, format string for two integer values:
        strValues_bottom = strtrim(cellstr(num2str(handles.candidate_locations_bottom{current_point,current_frame}(1:2,:)','(%d,%d)')));
        
        if get(handles.checkbox_detection_scores,'Value') == 1
            set(handles.candidate_numbers(1,1:handles.N_candidates(current_point,current_frame)),{'Position'},mat2cell(bsxfun(@plus,cell2mat(pos),[5 0]),ones(handles.N_candidates(current_point,current_frame),1),2));
            set(handles.candidate_numbers(1,1:handles.N_candidates(current_point,current_frame)),{'String'},mat2cell(strValues_bottom,ones(handles.N_candidates(current_point,current_frame),1),size(strValues_bottom,2)));
        end
        
        if N_candidates_z > 0
            strValues_z = strtrim(cellstr(num2str(handles.candidate_locations_joint{current_track,current_frame}(3,:)','%d')));
            set(handles.candidate_numbers(2,1:N_candidates_z),{'Position'},mat2cell(bsxfun(@plus,cell2mat(pos_z),[5 0]),ones(N_candidates_z,1),2));
            set(handles.candidate_numbers(2,1:N_candidates_z),{'String'},mat2cell(strValues_z,ones(N_candidates_z,1),size(strValues_bottom,2)));
        else
            strValues_z = '';
        end
    end
else
    strValues_bottom = '';
    strValues_z = '';
end

% Updating Visibility:
if get(handles.checkbox_detection_scores,'Value')
    set(handles.candidate_numbers(1,1:handles.N_candidates(current_point,current_frame)),'Visible','on');
    set(handles.candidate_numbers(2,1:N_candidates_z),'Visible','on');
end

set(handles.candidate_numbers(1,handles.N_candidates(current_point,current_frame)+1:end),'Visible','off');
set(handles.candidate_numbers(2,N_candidates_z+1:end),'Visible','off');

% Update candidate popup list:
set(handles.popupmenu_candidates,'String',[strValues_bottom;'ONG']);
set(handles.popupmenu_candidates_top,'String',[strValues_z;'ONG']);

    

% --- Executes on button press in checkbox_transitions.
function checkbox_transitions_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_transitions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_transitions
current_track = get(handles.popupmenu_tracks,'Value');
current_frame = str2double(get(handles.edit_frames,'String'));
val = get(hObject,'Value');
set(handles.figure1,'UserData',{current_frame});

if val == 1
    % Turning visibility on:
    set(handles.plot_handles_trajectory(:,current_track),'Visible','on');
    set(handles.plot_handles_candidate_trajectories,'Visible','on');
    set(handles.plot_handles_transition_tofrom_ong,'Visible','on');
else
    % Turning visibility off:
    set(handles.plot_handles_trajectory,'Visible','off');
    set(handles.plot_handles_candidate_trajectories,'Visible','off');
    set(handles.plot_handles_transition_tofrom_ong,'Visible','off');
end
displayImage([],[],handles);


% --- Update marker positions in trajectory mode:
function updateTrajectory(handles,current_track,current_frame)
% Setting all transitions to invisible. The right ones will be set to
% visible afterwards.

% if handles.flip
%     track_map = [3 4 1 2 5];
%     current_track = track_map(current_track);
% end

% Check when to plot the transitions:
if current_frame > 1
    frame_vec = [current_frame-1 current_frame];
    % Update Actual track position:
    pos = squeeze(handles.final_tracks(:,current_track,frame_vec))';
    
    % Warp the points if needed:
    if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_distorted_image
        Xin = [pos(1,2) pos(1,1);pos(1,4) pos(1,3);pos(2,2) pos(2,1);pos(2,4) pos(2,3)];
        pos = warpPointCoordinates(Xin, ...
            handles.data.inv_ind_warp_mapping, ...
            size(handles.data.inv_ind_warp_mapping),handles.flip);
%         pos = [pos(1,2);pos(1,1);pos(2,2);pos(2,1)];
        pos = [pos(1,2) pos(3,2);pos(1,1) pos(3,1);pos(2,2) pos(4,2);pos(2,1) pos(4,1)];
        pos = pos';
    end
    

    % Get current point:
    if current_track > 4
        current_point = 2;
    else
        current_point = 1;
    end
    
    % Check if any of the points is missing:
    % The index of the corresponding nan point is available on the M
    % matries.
    ong_track = false(2,2);
    for i_frame = 1:2
        % Bottom:
        if any(isnan(pos(i_frame,1:2)))
            pos(i_frame,1:2) = handles.ong_tracks(:,handles.M(current_track,frame_vec(i_frame))-size(handles.candidate_locations_bottom{current_point,frame_vec(i_frame)},2),frame_vec(i_frame))';
            ong_track(1,i_frame) = true;
        end
        
        % Top:
        N_candidates_top = size(handles.candidate_locations_joint{current_track,frame_vec(i_frame)},2);
        if N_candidates_top > 0
            % 3
            if any(isnan(pos(i_frame,1:2)))
                pos(i_frame,3) = handles.ong_tracks(2,handles.M(current_track,frame_vec(i_frame))-size(handles.candidate_locations_bottom{current_point,frame_vec(i_frame)},2),frame_vec(i_frame))';
            end
            
            if isnan(pos(i_frame,4))
                pos(i_frame,4) = handles.ong_vec(:,handles.M_top(current_track,frame_vec(i_frame))-N_candidates_top)';
                ong_track(2,i_frame) = true;
            end
        else
            pos(i_frame,3:4) = NaN;
        end
        
    end
    
    % Bottom view:
    set(handles.plot_handles_trajectory(1,current_track),{'XData','YData'},mat2cell(pos(:,1:2),2,ones(1,2)));
    % Side view: (not yet with ONG)
    set(handles.plot_handles_trajectory(2,current_track),{'XData','YData'},mat2cell(pos(:,3:4),2,ones(1,2)));
    
    % Determining ONG transitions for bottom view:
    valid_transitions = full(handles.pairwise{current_point,current_frame-1}(:,handles.M(current_track,current_frame-1))>0);
    
    % Separating candidate and ong transitions:
    transitions_to_candidates = valid_transitions(1:handles.N_candidates(current_point,current_frame));
    transitions_to_ong = valid_transitions(handles.N_candidates(current_point,current_frame)+1:end);
    clear valid_transitions
    ong_point = find(transitions_to_ong);
    n_ong_point = length(ong_point);
    
    % Plotting candidate transitions, with valid in full line and invalid in
    % dotted line:
    CL = handles.candidate_locations_bottom{current_point,current_frame}(1:2,:)';
    % Warping if needed:
    if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_original_image
        CL(:,[2 1]) = warpPointCoordinates(CL(:,[2 1]), ...
            handles.data.ind_warp_mapping, ...
            size(handles.data.ind_warp_mapping),handles.flip);
    end
    
    P = repmat(pos(1,1:2)',1,handles.N_candidates(current_point,current_frame))';
    set(handles.plot_handles_candidate_trajectories(1,1:handles.N_candidates(current_point,current_frame)),{'XData','YData'},mat2cell([P(:,1) CL(:,1) P(:,2) CL(:,2)],ones(1,handles.N_candidates(current_point,current_frame)),2*ones(1,2)));
    set(handles.plot_handles_candidate_trajectories(1,1:handles.N_candidates(current_point,current_frame)),'Visible','on');
    set(handles.plot_handles_candidate_trajectories(1,transitions_to_candidates),'LineStyle','-')
    set(handles.plot_handles_candidate_trajectories(1,~transitions_to_candidates),'LineStyle',':');
    set(handles.plot_handles_candidate_trajectories(1,handles.N_candidates(current_point,current_frame)+1:end),'Visible','off');
    
    % Plotting the Euclidean distance to each point:
    if get(handles.checkbox_detection_scores,'Value') ~= 1
        D = pdist2(pos(1,1:2),CL);
        strValues = strtrim(cellstr(num2str(D','%.02f')));
        set(handles.candidate_numbers(1,1:handles.N_candidates(current_point,current_frame)),{'String'},strValues);
    end
    
    % Plotting the connection to ONG:
    P = repmat(pos(1,1:2)',1,n_ong_point)';
    ONG = (handles.ong_bounding_box_pos([1;2],current_frame) - handles.ong_tracks(:,ong_point))';
     % Warping if needed:
    if get(handles.uipanel_image_type,'SelectedObject') == handles.radiobutton_original_image
        ONG(:,[2 1]) = warpPointCoordinates(ONG(:,[2 1]), ...
            handles.data.ind_warp_mapping, ...
            size(handles.data.ind_warp_mapping),handles.flip);
    end
    
    set(handles.plot_handles_transition_tofrom_ong(1:n_ong_point),{'XData','YData'},mat2cell([P(:,1) ONG(:,1) P(:,2) ONG(:,2)],ones(1,n_ong_point),2*ones(1,2)));
    set(handles.plot_handles_transition_tofrom_ong(1:n_ong_point),'Visible','on');
    set(handles.plot_handles_transition_tofrom_ong(n_ong_point+1:end),'Visible','off');
    
    % Plotting transitions on side view:
    N_candidates_side = size(handles.candidate_locations_joint{current_track,current_frame},2);
    if N_candidates_side > 0
        matchind = findMatchingXY(handles.candidate_locations_joint{current_track,current_frame}(1:2,:),handles.final_tracks(1:2,current_track,current_frame));
        CL = handles.candidate_locations_joint{current_track,current_frame}([1 3],matchind)';
        P = repmat(pos(1,3:4)',1,sum(matchind))';
        if get(handles.checkbox_detection_scores,'Value') ~= 1
            D = pdist2(pos(1,4),CL(:,2));
            strValues = strtrim(cellstr(num2str(D','%.02f')));
            set(handles.candidate_numbers(2,1:sum(matchind)),{'String'},strValues);
        end
        set(handles.plot_handles_candidate_trajectories(2,1:sum(matchind)),{'XData','YData'},mat2cell([P(:,1) CL(:,1) P(:,2) CL(:,2)],ones(1,sum(matchind)),2*ones(1,2)));
        set(handles.plot_handles_candidate_trajectories(2,1:sum(matchind)),'Visible','on');
    else
        matchind = 0;
    end
    set(handles.plot_handles_candidate_trajectories(2,sum(matchind)+1:end),'Visible','off');
    
    
else
    set(handles.plot_handles_trajectory(1:2),{'Xdata','Ydata'},num2cell(NaN(2,2)));
    set(handles.plot_handles_candidate_trajectories(1,:),{'Xdata','Ydata'},num2cell(NaN(handles.N_candidates_max,2)));
    set(handles.plot_handles_candidate_trajectories(2,:),{'Xdata','Ydata'},num2cell(NaN(handles.N_candidates_max,2)))
    set(handles.plot_handles_transition_tofrom_ong,{'Xdata','Ydata'},num2cell(NaN(handles.N_candidates_max,2)));
end

% -- Finds points with a given set of X Y coordinates:
function matchind = findMatchingXY(points, xycoordinates,mode)
% mode == true means logical indexing (default).
if ~exist('mode','var')
    mode = true;
end

matchind = all(bsxfun(@eq,points,xycoordinates),1);

if ~mode
    matchind = find(matchind);
end


% --- Executes on selection change in popupmenu_candidates_top.
function popupmenu_candidates_top_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_candidates_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_candidates_top contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_candidates_top
current_candidate = get(hObject,'Value');
current_frame = str2num(get(handles.edit_frames,'String'));
current_track = get(handles.popupmenu_tracks,'Value');

if current_track > 4
    current_point = 2;
else
    current_point = 1;
end
% Get ong coordinate.

if current_candidate > handles.N_candidates(current_point,current_frame)
    % Occluding point, set it to the assigned ONG:
else
    % Set the point to a different candidate: (Only Bottom view so far...)
    handles.final_tracks(4,current_track,current_frame) =  handles.candidate_locations_joint{current_point,current_frame}(4,current_candidate);
end

% Update the display:
if strcmpi(handles.timer.isrunning,'off')
displayImage([],[],handles);
end
guidata(handles.figure1,handles);



% --- Executes during object creation, after setting all properties.
function popupmenu_candidates_top_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_candidates_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dmax_z_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dmax_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dmax_z as text
%        str2double(get(hObject,'String')) returns contents of edit_dmax_z as a double


% --- Executes during object creation, after setting all properties.
function edit_dmax_z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dmax_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_detection_scores.
function checkbox_detection_scores_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_detection_scores (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_detection_scores
if get(hObject,'Value')
    set(handles.candidate_numbers,'Visible','on');
    set([handles.radiobutton_scores handles.radiobutton_coordinates],'Enable','On');
else
    set(handles.candidate_numbers,'Visible','off');
    set([handles.radiobutton_scores handles.radiobutton_coordinates],'Enable','Off');
end
if strcmpi(handles.timer.Running,'off')
    displayImage([],[],handles);
end

% --- Executes on button press in checkbox_bounding_box.
function checkbox_bounding_box_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_bounding_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_bounding_box
if get(hObject,'Value')
    set(handles.plot_handles_bounding_box,'Visible','on');
else
    set(handles.plot_handles_bounding_box,'Visible','off');
end
if strcmpi(handles.timer.Running,'off')
    displayImage([],[],handles);
end

% --- Executes when selected object is changed in uipanel_image_type.
function uipanel_image_type_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_image_type 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch hObject
    case handles.radiobutton_original_image
        image_type = true;
        set(handles.image,{'Xdata','Ydata'},{[1 handles.data.vid.Width],[1 handles.data.vid.Height]});
        set(handles.axes1,'Xlim',[0 handles.data.vid.Width]+0.5);
        set(handles.axes1,'Ylim',[0 handles.data.vid.Height]+0.5);
    case handles.radiobutton_distorted_image
        image_type = false;
        set(handles.image,{'Xdata','Ydata'},{[1 size(handles.data.ind_warp_mapping,2)],[1 size(handles.data.ind_warp_mapping,1)]});
        set(handles.axes1,'Xlim',[0 size(handles.data.ind_warp_mapping,2)]+0.5);
        set(handles.axes1,'Ylim',[0 size(handles.data.ind_warp_mapping,1)]+0.5);
end
setappdata(handles.figure1,'image_type',image_type);
if strcmpi(handles.timer.Running,'off')
    displayImage([],[],handles);
end
guidata(handles.figure1,handles);


% --- Executes on button press in checkbox_background.
function checkbox_background_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_background

if get(hObject,'Value') == 0
    bkg = handles.data.bkg;
else
    bkg = [];
end

setappdata(handles.figure1,'bkg',bkg);
if strcmpi(handles.timer.Running,'off')
    displayImage([],[],handles);
end
guidata(handles.figure1, handles);


% --- Executes when selected object is changed in uipanel_detection_map.
function uipanel_detection_map_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_detection_map 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if eventdata.NewValue ~= handles.radiobutton_no_map
    set(handles.checkbox_background,'Enable','Off');
else
    set(handles.checkbox_background,'Enable','on');
end

if strcmpi(handles.timer.Running,'off')
displayImage([],[],handles);
end


% --- Executes on button press in pushbutton_candidate_color.
function pushbutton_candidate_color_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_candidate_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_occlusion_color.
function pushbutton_occlusion_color_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_occlusion_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in uipanel_candidate_options.
function uipanel_candidate_options_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_candidate_options 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if strcmpi(handles.timer.Running,'off')
displayImage([],[],handles);
end


