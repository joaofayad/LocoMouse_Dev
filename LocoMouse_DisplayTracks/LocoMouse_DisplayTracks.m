function varargout = LocoMouse_DisplayTracks(varargin)
% LOCOMOUSE_DISPLAYTRACKS MATLAB code for LocoMouse_DisplayTracks.fig
% 
%
% For more information see tutorial.m
%
% Author: Joao Renato Kavamoto Fayad (joaofayad@gmail.com) 
% Last Modified: 13/11/2014

% Last Modified by GUIDE v2.5 17-Nov-2014 18:38:05

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

% Choose default command line output for LocoMouse_DisplayTracks
handles.output = hObject;
data = varargin{1}{1};
handles.vid = data.vid;
handles.bkg = data.bkg;
handles.flip = data.flip;
% Reading the video:
if ischar(handles.vid)
    handles.vid = VideoReader(handles.vid);
end

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
        
        if handles.vid.NumberOfFrames < N
            bkgi = rgb2gray(read(handles.vid,[1 handles.vid.NumberOfFrames]));
            
            if convert_rgb2gray
                % Stacking the images and converting all as a single image:
                bkgi = rgb2gray(reshape(permute(bkgi,[1 2 4 3]),[handles.vid.Height handles.vid.Width*handles.vid.NumberOfFrames size(bkg,3)]));
                % Reshaping into a tensor:
                handles.bkg = median(reshape(bkgi,[handles.vid.Height handles.vid.Width handles.vid.NumberOfFrames]),3);
                clear bkgi;
            end
            
        else
            frames_to_read = 1:floor(handles.vid.NumberOfFrames/N):N*floor(handles.vid.NumberOfFrames/N);
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

handles.point_tracks = varargin{1}{2};
if ~isempty(handles.point_tracks)
% For display it is easier to permute these:
handles.point_tracks = permute(handles.point_tracks,[2 1 3]);
end
% Getting data sizes:
[handles.N_point_tracks,~,~] = size(handles.point_tracks);

% Displaying the first image to set the axis size:
handles.image = imshow(read(handles.vid,1),'Parent',handles.axes1);
set(handles.image,'CData',read(handles.vid,1));

% Setting the axis size so that image is displayed with original size.
% Setting the height so that the gui figure stretches accordingly:
im_norm_size = get(handles.axes1,'Position');
fig_pix_size = get(handles.figure1,'Position');
new_height = handles.vid.Height / im_norm_size(4);
% Setting the new height. Note that since the axis units are normalized it
% will also stretch accordingly.
set(handles.figure1,'Position',[fig_pix_size(1) fig_pix_size(2:3) new_height]);

% Setting the width:
set(handles.axes1,'Units','pixel');
im_pix_size = get(handles.axes1,'Position');
set(handles.axes1,'Position',[im_pix_size(1) im_pix_size(2) handles.vid.Width handles.vid.Height]);
% Adjusting figure width:
new_width = handles.vid.Width/im_norm_size(3);
% Getting screen size:
scr_size = get(0,'ScreenSize');
% Resizing the GUI:
set(handles.figure1,'Position',[round(scr_size(3:4) - [new_width new_height])/2 new_width new_height]);
set(handles.axes1,'Units','normalized');

% Initialising the tail plot handles:
if length(varargin{1}) > 2
    handles.tail_tracks = varargin{1}{3};
    handles.N_tail_tracks = size(handles.tail_tracks,2);
    Cmap_tail = summer(handles.N_tail_tracks);Cmap_tail = Cmap_tail(end:-1:1,:);
    handles.plot_handles_tail = zeros(2,handles.N_tail_tracks);
    for i_tracks_tail = 1:handles.N_tail_tracks
        handles.plot_handles_tail(1,i_tracks_tail) = line(1,1,'Marker','*','Color',Cmap_tail(i_tracks_tail,:),'LineStyle','none');
        handles.plot_handles_tail(2,i_tracks_tail) = line(1,1,'Marker','*','Color',Cmap_tail(i_tracks_tail,:),'LineStyle','none');
    end
    clear Cmap_tail
    if ~isempty(handles.tail_tracks)
        % For display it is more convenient to swap dim 1 and 2:
        handles.tail_tracks = permute(handles.tail_tracks,[2 1 3]);
    end
else
    handles.tail_tracks = [];
    handles.N_tail_tracks = 0;
end

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

% Initializing the graphic objects:
handles.plot_handles = zeros(1,handles.N_point_tracks);
c = [1 0 0;1 0 1;0 0 1;0 1 1;1 0.6941 0.3922]; % Point tracks; % These should be default across the system.
if size(c,1) < handles.N_point_tracks+1
    c = [c;lines(handles.N_point_tracks-size(c,1)+1)];
end
for i_obj = 1:handles.N_point_tracks
    handles.plot_handles(1,i_obj) = line(zeros(1,2),zeros(1,2),'Marker','o','Visible','on','Color',c(i_obj,:),'MarkerFaceColor',c(i_obj,:),'LineStyle','none');
    handles.plot_handles(2,i_obj) = line(zeros(1,2),zeros(1,2),'Marker','o','Visible','on','Color',c(i_obj,:),'MarkerFaceColor',c(i_obj,:),'LineStyle','none');
    handles.color_choice(:,i_obj) = get(handles.plot_handles(1,i_obj),'Color')';
end
handles.color_choice = c;clear c;
% handles.color_choice(:,handles.N_point_tracks+1) = get(handles.plot_handles_tail(1),'Color')';

% Initializing the track list (Default across the system): 
set(handles.popupmenu_tracks,'String',char({'FR Paw';'HR Paw';'FL Paw';'HL Paw';'Mouth';'Tail'}));
set(handles.popupmenu_tracks,'Value',1);

% Initializing the image slider:
set(handles.slider_frames,'Max',handles.vid.NumberOfFrames);
set(handles.slider_frames,'Min',1);
set(handles.slider_frames,'SliderStep',[1/handles.vid.NumberOfFrames 0.05]);
set(handles.slider_frames,'Value',1);

% Initializing the speed slider:
set(handles.slider_speed,'Min',1);
set(handles.slider_speed,'Max',90);
set(handles.slider_speed,'SliderStep',[5/60 0.05]);
set(handles.slider_speed,'Value',30);

% Initializing the marker options:
set(handles.popupmenu_marker,'String',char({'+';'o';'*';'.';'x';'s';'d';'^';'v';'>';'<';'p';'h'}))
set(handles.popupmenu_marker,'Value',2);
handles.marker_choice = 2*ones(1,handles.N_point_tracks+1);
handles.marker_choice(:,end) = 3;

% Initializing the color pushbutton:
set(handles.pushbutton_color,'BackgroundColor',handles.color_choice(1,:));

% Initializing Edits:
set(handles.edit_frames,'String','1');
set(handles.edit_speed,'String','30');

% Initializing the user data (keeps the current frame number):
set(handles.figure1,'UserData',{1});

% Initializing the timer:
handles.timer = timer('Period',str2double(sprintf('%.02f',1/30)),'ExecutionMode','FixedSpacing','TasksToExecute',Inf,'BusyMode','Queue','TimerFcn',{@displayImage,handles},'UserData',{1});
displayImage([],[],handles);

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
    value = min(max(1,value),handles.vid.NumberOfFrames);
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
if current_frame > handles.vid.NumberOfFrames
    current_frame = 1;
end

% Update image:
% uint8(sc()*255) %%% FIXME: Add the image enhancement as an option as it
% slows down playback.
I = read(handles.vid,current_frame);
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
    if current_frame > handles.vid.NumberOfFrames
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
I = read(handles.vid,cf{1});
if get(hObject,'Value') == 0
    I = I-handles.bkg;
end
I = double(I); I = uint8(I/max(I(:))*255);
set(handles.image,'CData',I);

% --------------------------------------------------------------------
function menu_export_Callback(hObject, eventdata, handles)
% hObject    handle to menu_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
        handles.menu_export handles.pushbutton_color ...
        handles.togglebutton_play get(handles.uitoolbar1,'Children')'],'Enable','off');
    % Enable GUI on end of execution:
    c_handles = onCleanup(@()(set([handles.slider_frames handles.slider_speed handles.edit_frames ... 
        handles.edit_speed handles.popupmenu_marker handles.popupmenu_tracks handles.pushbutton_color...
        handles.checkbox_background handles.checkbox_occlusion handles.edit_frames handles.slider_frames ...
        handles.togglebutton_play handles.menu_export get(handles.uitoolbar1,'Children')'],'Enable','on')));
    fig = watchon;
    c_pointer = onCleanup(@()(watchoff(fig)));
    
    % Creating the video object:
    writerObj = VideoWriter(fullfile(path_name,file_name),'MPEG-4');
    writerObj.FrameRate = 30;
    % writerObj.ColorChannels = 1;
    writerObj.Quality = 100;
    open(writerObj);
    c_video = onCleanup(@()(close(writerObj)));

    % Play the video to entertain the user while the images are generated and
    % saved into the video object.
%     c_image = onCleanup(@()(delete('temp_fig.png')));
    for i_images = 1:handles.vid.NumberOfFrames
        I = read(handles.vid,i_images); 
        if get(handles.checkbox_background,'Value') == 0
            I = I-handles.bkg;
        end
        I = double(I);
        I = uint8(I/max(I(:))*255);
        set(handles.image,'CData',I);
        updateMarkers(handles,i_images);
%         export_fig(handles.axes1,'temp_fig.png','-native')
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
if handles.N_tail_tracks > 0
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
