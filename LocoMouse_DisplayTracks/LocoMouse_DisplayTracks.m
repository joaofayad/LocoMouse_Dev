function varargout = LocoMouse_DisplayTracks(varargin)
% LOCOMOUSE_DISPLAYTRACKS MATLAB code for LocoMouse_DisplayTracks.fig
% 
%
% For more information see tutorial.m
%
% Author: Joao Renato Kavamoto Fayad (joaofayad@gmail.com) 
% Last Modified: 13/11/2014

% Last Modified by GUIDE v2.5 24-Feb-2017 13:38:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LocoMouse_DisplayTracks_OpeningFcn, ...
                   'gui_OutputFcn',  @LocoMouse_DisplayTracks_OutputFcn, ...
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


% --- Executes just before LocoMouse_DisplayTracks is made visible.
function LocoMouse_DisplayTracks_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LocoMouse_DisplayTracks (see VARARGIN)

% Loading image by image and seeing if it is fast enough. If not, I'll have
% to read on how to do this with a buffer or eventually use the
% VideoReader functions.

% Output object:
handles.output = hObject;

%%% FIXME: These are LocoMouse constants and should be programatically set
%%% in some config file:
handles.N_point_tracks = 5;
handles.N_tail_points = 15;
handles.N_paws = 4;
handles.N_snout = 1;

[handles.root_path,~,~] = fileparts([mfilename('fullpath'),'*.m']);

if exist(fullfile(handles.root_path,'..','LocoMouse_GlobalSettings','colorscheme.mat'),'file')
    LM_Colors = load(fullfile(handles.root_path,'..','LocoMouse_GlobalSettings','colorscheme.mat'));
else
    warning('Could not find LocoMouse configuration files!');
    LM_Colors.PointColors = lines(handles.N_point_tracks);
    LM_Colors.TailColors = summer(handles.N_tail_points);
end

% Initializing the track list (Default across the system):
set(handles.popupmenu_tracks,'String',char({'FR Paw';'HR Paw';'FL Paw';'HL Paw';'Snout';'Tail'}));
set(handles.popupmenu_tracks,'Value',1);
set(handles.popupmenu_tracks,'Enable','off');

% Initializing the marker options:
marker_list = char({'+';'o';'*';'.';'x';'s';'d';'^';'v';'>';'<';'p';'h'});
set(handles.popupmenu_marker,'String',marker_list);
set(handles.popupmenu_marker,'Value',2);
set(handles.popupmenu_marker,'Enable','Off');

% Points are circles, tail points are asterisks:
handles.marker_choice = 2*ones(1,handles.N_point_tracks+1);
handles.marker_choice(:,end) = 3;

% Initializing the image:
set(handles.axes1,'Units','Pixel');
axes_size = round(get(handles.axes1,'Position'));
handles.image = imshow(uint8(zeros(axes_size(4),axes_size(3))),'Parent',handles.axes1);
set(handles.axes1,'Units','Normalized');

% Initializing the graphic objects:
handles.plot_handles = zeros(1,handles.N_point_tracks);

for i_obj = 1:handles.N_point_tracks
    c = LM_Colors.PointColors(i_obj,:);
    handles.plot_handles(1,i_obj) = line(NaN,NaN,'Marker','o','Visible','off','Color',c,'MarkerFaceColor',c,'LineStyle','none');
    handles.plot_handles(2,i_obj) = line(NaN,NaN,'Marker','o','Visible','off','Color',c,'MarkerFaceColor',c,'LineStyle','none');
end
clear c;
handles.color_choice = LM_Colors.PointColors';

% Initialising the tail plot handles:
handles.plot_handles_tail = zeros(2,handles.N_tail_points);

for i_tracks_tail = 1:handles.N_tail_points
    c = LM_Colors.TailColors(i_tracks_tail,:);
    handles.plot_handles_tail(1,i_tracks_tail) = line(NaN,NaN,'Marker','*','Color',c,'LineStyle','none');
    handles.plot_handles_tail(2,i_tracks_tail) = line(NaN,NaN,'Marker','*','Color',c,'LineStyle','none');
end
clear c;

%%% Initializing auxiliary variables:
% Supported video files:
sup_files = VideoReader.getFileFormats;
handles.N_supported_files = size(sup_files,2)+1;
handles.supported_files = cell(handles.N_supported_files,2);
handles.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
handles.supported_files(2:end,2) = {sup_files(:).Description};
handles.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_files(2:end,1)','un',false));
handles.supported_files{1,2} = 'All supported video files';

% Latest path loaded from:
handles.latest_path = pwd;

% Disable figure and other controls:
set(handles.axes1,'Visible','off');
set([handles.edit_frames, ...
    handles.edit_speed, ...
    handles.slider_frames,...
    handles.slider_speed,...
    handles.checkbox_background,...
    handles.checkbox_occlusion,...
    handles.togglebutton_play],'Enable','off');

% Load LocoMouse_Tracker Settings:
%%% FIXME: Load from same path or settings? It is easy to set the label
%%% anyway.
% [LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
% LMT_path = [LMT_path filesep 'GUI_Settings'];
% if exist(LMT_path,'dir')==7
%     if exist([LMT_path filesep 'GUI_Recovery_Settings.mat'],'file') == 2
%         LoadSettings_Callback([], [], handles, 'GUI_Recovery_Settings.mat')
%     end
% end

set(handles.pushbutton_color,'BackgroundColor',handles.color_choice(:,1),'Enable','off');

% Initializing Edits:
set(handles.edit_frames,'String','1');
set(handles.edit_speed,'String','30');

if ~isempty(varargin)
    data = varargin{1}{1};
    handles = loadVideo(handles,data.vid,data.flip);
    handles = loadBackground(handles,data.bkg);
    handles = loadTracks(handles,varargin{1}{2},varargin{1}{3});
    handles = resetTimer(handles);
    
    % Initialising the occlusion grid display:
    if length(varargin{1}) > 3
        handles.ong_tracks = varargin{1}{4}{1};
        handles.bounding_box = varargin{1}{4}{2};
        handles.N_ong_tracks = size(handles.ong_tracks,2);
        handles.plot_handles_ong = line(ones(2,handles.N_ong_tracks),ones(2,handles.N_ong_tracks),'Marker','+','Color','w','MarkerFaceColor','m','LineStyle','none','Visible','off');
        handles.color_choice_ong = get(handles.plot_handles_ong,'Color');
    else
        handles.ong_tracks = [];
        handles.N_ong_tracks = 0;
    end
    
    displayImage([],[],handles);
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LocoMouse_DisplayTracks wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LocoMouse_DisplayTracks_OutputFcn(hObject, eventdata, handles) 
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
set(handles.figure1,'UserData',{val});
displayImage([],[],handles);
set(handles.edit_frames,'String',num2str(val));
guidata(hObject, handles);

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
cf = get(handles.figure1,'UserData');cf = cf{1};
if ~isnan(value)
    value = round(value);
    value = min(max(1,value),handles.N_frames);
    set(handles.edit_frames,'String',num2str(value));
    set(handles.slider_frames,'Value',value);
    set(handles.figure1,'UserData',{value});
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
value = str2double(get(hObject,'String'));
restart = false;
if strcmpi(get(handles.timer,'Running'),'on')
    restart = true;
    stop(handles.timer);
end
cf = get(handles.figure1,'UserData');cf = cf{1};

if ~isnan(value)
    value = min(max(1,value),90);
    set(handles.edit_speed,'String',num2str(value));
    set(handles.slider_speed,'Value',value);
    set(handles.timer,'Period',str2double(sprintf('%.02f\n',1/value)));
    displayImage([], [], handles)
else
    set(handles.edit_frames,'String',num2str(cf));
end
guidata(hObject,handles);

if restart
    start(handles.timer);
end


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
    % Gray out edit stuff that should not be changed
    set([handles.edit_frames handles.pushbutton_color handles.slider_frames handles.popupmenu_tracks handles.popupmenu_marker],'Enable','off');
    start(handles.timer);
else
    stop(handles.timer);
    set([handles.edit_frames handles.pushbutton_color handles.slider_frames handles.popupmenu_tracks handles.popupmenu_marker],'Enable','on');
    cf = get(handles.figure1,'UserData');
    set(handles.slider_frames,'Value',cf{1});
    displayImage([],[],handles);
    set(hObject,'String','Play');
end

% --- Executes on selection change in popupmenu_tracks.
function popupmenu_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_tracks contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_tracks
val = get(hObject,'Value');
% Updating track data:
set(handles.popupmenu_marker,'Value',handles.marker_choice(val));
set(handles.pushbutton_color,'BackgroundColor',handles.color_choice(:,val));
% guidata(hObject,handles);

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


% --- Executes on selection change in popupmenu_marker.
function popupmenu_marker_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_marker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_marker contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_marker
track_number = get(handles.popupmenu_tracks,'Value');
marker_number = get(handles.popupmenu_marker,'Value');
marker_types = get(handles.popupmenu_marker,'String');
if track_number <= handles.N_point_tracks
set(handles.plot_handles([1 2],track_number),'Marker',marker_types(marker_number));
else
    set(handles.plot_handles_tail,'Marker',marker_types(marker_number));
end
handles.marker_choice(track_number) = marker_number;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_marker_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_marker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_color.
function pushbutton_color_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

new_color = uisetcolor;
if length(new_color) ~= 1 
    % Setting the color to the marker:
    track_number = get(handles.popupmenu_tracks,'Value');
    handles.color_choice(:,track_number) = new_color';
    if track_number > handles.N_point_tracks
        set(handles.plot_handles_tail,{'Color','MarkerFaceColor'},{handles.color_choice(:,track_number),handles.color_choice(:,track_number)});
    else
        set(handles.plot_handles(1:2,track_number),{'Color','MarkerFaceColor'},{handles.color_choice(:,track_number),handles.color_choice(:,track_number)});
    end
    
    % Setting the color to the button:
    set(handles.pushbutton_color,'Units','pixel')
    set(handles.pushbutton_color,'Units','normalized');
    set(handles.pushbutton_color,'BackgroundColor',new_color);
end
guidata(hObject,handles);



% --- Display Tracks
function displayImage(obj,event,handles)

% FIXME Flip image if flip is true. There is a function for this: fliplr()

current_frame = get(handles.figure1,'UserData');
current_frame = current_frame{1};
if current_frame > handles.N_frames
    current_frame = 1;
end

% Update image:
% uint8(sc()*255) %%% FIXME: Add the image enhancement as an option as it
% slows down playback.
I = read(handles.vid,current_frame); I = I(:,:,1);
if get(handles.checkbox_background,'Value') == 0
    I = I-handles.bkg;
end
I = double(I); I = uint8(I/max(I(:))*255);
set(handles.image,'CData',I);
updateMarkers(handles,current_frame);
set(handles.edit_frames,'String',num2str(current_frame));

% If timer is on, increment the frame counter:
if strcmpi(get(obj,'Type'),'timer')
    if strcmpi(get(obj,'Running'),'on')
        set(handles.figure1,'UserData',{current_frame+1});
    end
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if ~isempty(handles)
    if isfield(handles,'timer')
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
end
delete(hObject);


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox_occlusion.
function checkbox_occlusion_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_occlusion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_occlusion
 
if get(hObject,'Value')
    current_frame = get(handles.figure1,'UserData');current_frame = current_frame{1};
    if current_frame > handles.N_frames
        current_frame = 1;
    end
    if handles.N_ong_tracks > 0 && get(handles.checkbox_occlusion,'Value')
        
        ong = bsxfun(@minus,handles.bounding_box([1;2],current_frame),handles.ong_tracks);
        
        if handles.flip
            ong(1,:) = handles.vid.Width - ong(1,:) + 1;
        end
        
        set(handles.plot_handles_ong,{'XData','YData'},num2cell(ong)');
       
    end
    
    set(handles.plot_handles_ong,'Visible','on');
else
    set(handles.plot_handles_ong,'Visible','off');
end


% --- Executes on button press in checkbox_background.
function checkbox_background_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_background
cf = get(handles.figure1,'Userdata');
I = read(handles.vid,cf{1});I = I(:,:,1);
if get(hObject,'Value') == 0
    I = I-handles.bkg;
end
I = double(I); I = uint8(I/max(I(:))*255);
set(handles.image,'CData',I);

% --------------------------------------------------------------------
function menu_video_Callback(hObject, eventdata, handles)
% hObject    handle to menu_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function menu_export_Callback(hObject, eventdata, handles)
c_update_system_state = onCleanup(@()(displayImage([],[],handles)));

% Ask for file name and output directory:
[~,file_name,~] = fileparts(handles.vid.Name);
[file_name,path_name] = uiputfile([file_name '.mp4']);

if ~isequal(file_name,0) && ~isequal(path_name,0)
    % If video is playing, stop it:
    value = get(handles.togglebutton_play,'Value');
    if ~value
        stop(handles.timer);
        set([handles.edit_frames handles.pushbutton_color handles.slider_frames handles.popupmenu_tracks handles.popupmenu_marker],'Enable','on');
        % Set it to the first frame
        cf = get(handles.figure1,'UserData');
        cf{1} = 1;
        set(handles.slider_frames,'Value',cf{1});
        set(handles.figure1,'UserData',cf);
        set(handles.togglebutton_play,'String','Play');
    end
   
     % Disable GUI:
    set([handles.slider_frames handles.slider_speed handles.edit_frames handles.edit_speed handles.popupmenu_marker ...
        handles.popupmenu_tracks handles.pushbutton_color handles.checkbox_background handles.checkbox_occlusion ...
        handles.menu_video handles.pushbutton_color ...
        handles.togglebutton_play get(handles.uitoolbar1,'Children')'],'Enable','off');
    % Enable GUI on end of execution:
    c_handles = onCleanup(@()(set([handles.slider_frames handles.slider_speed handles.edit_frames ... 
        handles.edit_speed handles.popupmenu_marker handles.popupmenu_tracks handles.pushbutton_color...
        handles.checkbox_background handles.checkbox_occlusion handles.edit_frames handles.slider_frames ...
        handles.togglebutton_play handles.menu_video get(handles.uitoolbar1,'Children')'],'Enable','on')));
    fig = watchon;
    c_pointer = onCleanup(@()(watchoff(fig)));
    
    %Creating the video object:
    writerObj = VideoWriter(fullfile(path_name,file_name),'MPEG-4');
    writerObj.FrameRate = 30;
    writerObj.Quality = 100;
    open(writerObj);
    c_video = onCleanup(@()(close(writerObj)));

    % Play the video to entertain the user while the images are generated and
    % saved into the video object.
%     c_image = onCleanup(@()(delete('temp_fig.png')));
    for i_images = 1:handles.N_frames
        I = read(handles.vid,i_images);I = I(:,:,1); 
        if get(handles.checkbox_background,'Value') == 0
            I = I-handles.bkg;
        end
        I = double(I);
        I = uint8(I/max(I(:))*255);
        set(handles.image,'CData',I);
        updateMarkers(handles,i_images);
%         export_fig(handles.axes1,sprintf('ladder_%03d.png',i_images),'-native');
%         writeVideo(writerObj, imread('temp_fig.png'));
        writeVideo(writerObj, getframe(handles.axes1));
    end
end
guidata(hObject,handles);


% Auxiliary functions ====================================================
function [] = updateMarkers(handles,current_frame)
% Update marker positions:
set(handles.plot_handles(1,:),{'XData','YData'},num2cell(handles.point_tracks(:,[1 2],current_frame)));
set(handles.plot_handles(2,:),{'XData','YData'},num2cell(handles.point_tracks(:,[3 4],current_frame)));
% Update tail position:
if handles.N_tail_points > 0
    set(handles.plot_handles_tail(1,:),{'XData','YData'},num2cell(handles.tail_tracks(:,[1 2],current_frame)));
    set(handles.plot_handles_tail(2,:),{'XData','YData'},num2cell(handles.tail_tracks(:,[3 4],current_frame)));
end

% Update Occlusion grid positions:
if handles.N_ong_tracks > 0 && get(handles.checkbox_occlusion,'Value')
    ong = bsxfun(@minus,handles.bounding_box([1;2],current_frame),handles.ong_tracks);
    if handles.flip
        ong(1,:) = handles.vid.Width - ong(1,:) + 1;
    end
    set(handles.plot_handles_ong,{'XData','YData'},num2cell(ong'));
end


% --------------------------------------------------------------------
function menu_load_Callback(hObject, eventdata, handles)
% hObject    handle to menu_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%---- Updating the tracks
function handles = loadTracks(handles, final_tracks, tracks_tail, debug)
% Checking the number of frames: Should be the number of frames of the
% video except when the tracks have less data.
handles.point_tracks = final_tracks;
handles.N_frames = min(handles.vid.NumberOfFrames,size(handles.point_tracks,3));

if ~isempty(final_tracks)
    % For display it is easier to permute these:
    handles.point_tracks = permute(final_tracks,[2 1 3]);
    set(handles.plot_handles,'Visible','on');
else
    handles.point_tracks = [];
    set(handles.plot_handles,'Visible','off');
end

if ~isempty(tracks_tail)
        % For display it is more convenient to swap dim 1 and 2:
        handles.tail_tracks = permute(tracks_tail,[2 1 3]);
        set(handles.plot_handles_tail,'Visible','on');
else
    handles.tail_tracks = [];
    set(handles.plot_handles_tail,'Visible','off');
end

%Initialising the occlusion grid display:
if ~isempty(debug)
    handles.ong_tracks = debug.Occlusion_Grid_Bottom;
    handles.bounding_box = debug.bounding_box;
    handles.N_ong_tracks = size(debug.Occlusion_Grid_Bottom,2);
    handles.plot_handles_ong = line(ones(2,handles.N_ong_tracks),ones(2,handles.N_ong_tracks),'Marker','+','Color','w','MarkerFaceColor','m','LineStyle','none','Visible','off');
    handles.color_choice_ong = get(handles.plot_handles_ong,'Color');
    set(handles.checkbox_occlusion,'Enable','on');
else
    if isfield(handles,'plot_handles_ong')
        delete(handles.plot_handles_ong);
        set(handles.checkbox_occlusion,'Enable','off');
    end
    handles.ong_tracks = [];
    handles.N_ong_tracks = 0;
end


%---- Updating the background:
function handles = loadBackground(handles, bkg_name)

if ~exist(bkg_name,'file')
    warning('Could not load specified background file %s',bkg_name);
    
   [file_name,path_name] = uigetfile({'*.png','PNG Files'},'Choose a Background Image for the loaded data:',handles.latest_path,'MultiSelect','off');
   handles.latest_path = path_name;
   
   if isempty(file_name)
       bkg_name = 'compute';
   else
       bkg_name = fullfile(path_name,file_name);
   end
end

handles.bkg = bkg_name;

% Reading the background image:
if ischar(handles.bkg)
    if strcmpi(handles.bkg,'compute')
        N = 100; % Maximum number of frames for background.
        % Sometimes the videos are stored in colour format. Or at least
        % read like that by MATLAB.
        if ~strcmpi(handles.vid.VideoFormat,'grayscale')
            convert_rgb2gray = true;
        else
            convert_rgb2gray = false;
        end
        handles.N_frames = (handles.vid.Duration*handles.vid.FrameRate);
        if  handles.N_frames < N
            bkgi = rgb2gray(read(handles.vid,[1 handles.N_frames]));
            
            if convert_rgb2gray
                % Stacking the images and converting all as a single image:
                bkgi = rgb2gray(reshape(permute(bkgi,[1 2 4 3]),[handles.vid.Height handles.vid.Width*handles.N_frames size(bkg,3)]));
                % Reshaping into a tensor:
                handles.bkg = median(reshape(bkgi,[handles.vid.Height handles.vid.Width handles.N_frames]),3);
                clear bkgi;
            end
            
        else
            frames_to_read = 1:floor(handles.N_frames/N):N*floor(handles.N_frames/N);
            Bkg = uint8(zeros(handles.vid.Height,handles.vid.Width,N));
            for i_images = 1:N
                bkgi = read(handles.vid,frames_to_read(i_images));
                if convert_rgb2gray
                    bkgi = rgb2gray(bkgi);
                end
                Bkg(:,:,i_images) = bkgi;
            end
        end
        handles.bkg = median(Bkg,3);clear Bkg;
    else
        handles.bkg = imread(handles.bkg);
    end
end

%----- Updating the video information:
function handles = loadVideo(handles, vid_name, flip)

if ~exist(vid_name,'file')
   
   warning('Could not find the specified video file %s', vid_name);
   [file_name,path_name] = uigetfile(handles.supported_files,'Choose a Video File for the loaded data:',handles.latest_path,'MultiSelect','off');
   handles.latest_path = path_name;
   
   if ~ischar(file_name)
       error('To load tracks one must specify a video file');
   end
   
   vid_name = fullfile(path_name, file_name);
   
end

resetGUI(handles);

handles.vid = vid_name;
handles.bkg = [];% Remove checkbox
handles.flip = flip;
    
% Reading the video:
if ischar(handles.vid)
    handles.vid = VideoReader(handles.vid);
end
    
[handles.root_path,~,~] = fileparts([mfilename('fullpath'),'*.m']);

handles.N_frames = handles.vid.FrameRate * handles.vid.Duration;

% Displaying the first image to set the axis size:
handles = initializeGUIContent(handles);


% --------------------------------------------------------------------
function menu_track_and_video_Callback(hObject, eventdata, handles)
% hObject    handle to menu_track_and_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file_name,path_name] = uigetfile({'*.mat','MAT-files (*.mat)'},'Choose a MAT-File from the LocoMouse_Tracker:',handles.latest_path,'MultiSelect','off');

D = load(fullfile(path_name,file_name));

handles = loadVideo(handles,D.data.vid,D.data.flip);
handles = loadBackground(handles,D.data.bkg);
handles = loadTracks(handles,D.final_tracks,D.tracks_tail,D.debug);
handles = resetTimer(handles);
displayImage([],[],handles);

guidata(handles.figure1,handles);

% --------------------------------------------------------------------
function menu_locomouse_track_Callback(hObject, eventdata, handles)
% hObject    handle to menu_locomouse_track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_background_Callback(hObject, eventdata, handles)
% hObject    handle to menu_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% ==== reset the gui
function handles = resetGUI(handles)

% Stop and clear the timer:
if isfield(handles,'timer')
    if isvalid(handles.timer)
        if handles.timer.Running
            stop(handles.timer);
        end
        delete(handles.timer);
    end
end

% Remove plot handles data and visibility:
set(handles.plot_handles,'Visible','off');
set(handles.plot_handles_tail,'Visible','off');
set(handles.plot_handles,{'Xdata','Ydata','Zdata'},{NaN,NaN,0}); % If Z is zero the point is not plotted!
set(handles.plot_handles_tail,{'Xdata','Ydata','Zdata'},{NaN,NaN,0});

% Video Variables:
handles.N_frames = 0;

% ======
function handles = initializeGUIContent(handles)
set([handles.axes1 handles.figure1],'Units','Pixel');
fig_pos_pixel = get(handles.figure1,'Position');
old_axes_pos = get(handles.axes1,'Position');

old_x_size = get(handles.axes1,'Xlim') - 0.5;old_x_size = old_x_size(2);
old_y_size = get(handles.axes1,'Ylim') - 0.5;old_y_size = old_y_size(2);

delta_size = [handles.vid.Width handles.vid.Height] - [old_x_size old_y_size];


% Update the image to the new video:
I = read(handles.vid,1); I = I(:,:,1);
set(handles.image,'CData',I);
set(handles.axes1,'Xlim',[0.5 handles.vid.Width+0.5],'Ylim',[0.5 handles.vid.Height+0.5]);
set(handles.axes1,'Position',[old_axes_pos(1) old_axes_pos(2)+floor(delta_size(2)/2) handles.vid.Width handles.vid.Height]);

scr_size = get(0,'ScreenSize');
% Resizing the GUI:
new_width_heigh = fig_pos_pixel(3:4) + delta_size;

set(handles.figure1,'Position',[round(scr_size(3:4) - new_width_heigh)/2 new_width_heigh]);
set([handles.axes1 handles.figure1],'Units','Normalized');



% Initializing the image slider:
set(handles.slider_frames,'Max',handles.N_frames);
set(handles.slider_frames,'Min',1);
set(handles.slider_frames,'SliderStep',[1/(handles.N_frames-1) max(0.05,5/(handles.N_frames-1))]);
set(handles.slider_frames,'Value',1);

% Initializing the speed slider:
set(handles.slider_speed,'Min',1);
set(handles.slider_speed,'Max',90);
set(handles.slider_speed,'SliderStep',[5/60 10/60]);
set(handles.slider_speed,'Value',30);

% Initializing the user data (keeps the current frame number):
set(handles.figure1,'UserData',{1});

set([handles.edit_frames, ...
    handles.edit_speed, ...
    handles.slider_frames,...
    handles.slider_speed,...
    handles.checkbox_background,...
    handles.togglebutton_play,...
    handles.popupmenu_marker,...
    handles.popupmenu_tracks],'Enable','on');
    % FIXME: Maybe the background should be set depending on a valid
    % background existing.
    % handles.checkbox_occlusion,...
   

function handles = resetTimer(handles)
% Initializing the timer:
if isfield(handles,'timer')
    if isvalid(handles.timer)
        if handles.timer.Running
            stop(handles.timer);
        end
        delete(handles.timer);
    end
end
handles.timer = timer('Period',str2double(sprintf('%.02f',1/30)),'ExecutionMode','FixedSpacing','TasksToExecute',Inf,'BusyMode','Queue','TimerFcn',{@displayImage,handles},'UserData',{1});


