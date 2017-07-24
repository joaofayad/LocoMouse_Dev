function varargout = LocoMouse_Tracker(varargin)
% LOCOMOUSE_TRACKER MATLAB code for LocoMouse_Tracker.fig
% The LocoMouse_Tracker GUI tracks a list of video files once it is given a
% background search method, a calibration file, a model file, an output
% folder parsing method and an output folder.
%
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org)
% Last Modified: 17/11/2014

% Last Modified by GUIDE v2.5 28-Jun-2017 19:34:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LocoMouse_Tracker_OpeningFcn, ...
    'gui_OutputFcn',  @LocoMouse_Tracker_OutputFcn, ...
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


% --- Executes just before LocoMouse_Tracker is made visible.
function LocoMouse_Tracker_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LocoMouse_Tracker (see VARARGIN)

% Choose default command line output for LocoMouse_Tracker
handles.output = hObject;

%%% FIXME: 
% Getting the install path for LocoMouseTracker:
[handles.root_path,~,~] = fileparts([mfilename('fullpath'),'*.m']);

handles.calibration_path = fullfile(handles.root_path,'calibration_files',filesep);
handles.model_path = fullfile(handles.root_path,'model_files',filesep);
handles.background_parse_path = fullfile(handles.root_path,'background_parse_functions',filesep);
handles.output_parse_path = fullfile(handles.root_path,'output_parse_functions',filesep);
handles.bounding_box_path = fullfile(handles.root_path,'boundingBoxFunctions',filesep);

% Initialising supported video files:
sup_files = VideoReader.getFileFormats;
handles.N_supported_files = size(sup_files,2);
handles.N_supported_files_menu = handles.N_supported_files+1;
handles.supported_files = cell(handles.N_supported_files_menu,2);
handles.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
handles.supported_files(2:end,2) = {sup_files(:).Description};
handles.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_files(2:end,1)','un',false));
handles.supported_files{1,2} = 'All supported video files';
set(handles.figure1,'UserData','');

% Getting the install path for LocoMouseTracker:
[handles.root_path,~,~] = fileparts([mfilename('fullpath'),'*.m']);

%%% FIXME: Encapsulate the pre-processing of such options into simpler
%%% functions:

% Reading background parsing modes:
readOptionList(fullfile(handles.root_path,'background_parse_functions'), '*.m', handles.popupmenu_background_mode);
readOptionList(fullfile(handles.root_path,'output_parse_functions'), '*.m', handles.popupmenu_output_mode);
readOptionList(fullfile(handles.root_path,'calibration_files'), '*.mat', handles.popupmenu_calibration_files);
readOptionList(fullfile(handles.root_path,'model_files'), '*.mat', handles.popupmenu_model);

% Initializing the output folder to the current path:
set(handles.edit_output_path,'String',pwd);
set(handles.figure1,'userdata',pwd);

% Set of handles that are disabled uppon tracking:
handles.disable_with_start = [  handles.pushbutton_start ...
    handles.pushbutton_add_background_mode ...
    handles.pushbutton_add_calibration_file ...
    handles.pushbutton_add_file ...
    handles.pushbutton_add_folder ...
    handles.pushbutton_add_model ...
    handles.pushbutton_add_output_mode ...
    handles.pushbutton_add_with_subfolders ...
    handles.pushbutton_browse_output ...
    handles.pushbutton_remove ...
    handles.pushbutton_clear_filelist ...
    handles.popupmenu_background_mode ...
    handles.popupmenu_calibration_files ...
    handles.popupmenu_model ...
    handles.popupmenu_output_mode ...
    handles.edit_output_path ...
    handles.checkbox_overwrite_results ...
    handles.checkbox_ExpFigures ...
    handles.BoundingBox_choice ...
    handles.MouseOrientation ...
    handles.LoadSettings ...
    handles.SaveSettings ...
    ];

handles.enable_with_start = handles.pushbutton_stop;

handles.disable_while_running = get(handles.figure1,'Children');

% Making sure any ctrl+c deletes the gui to prevent further malfunctioning:
setappdata(handles.figure1,'current_search_path',pwd);

set(handles.figure1,'CloseRequestFcn',@LocoMouse_closeRequestFcn);

% Loading latest settings
[LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
LMT_path = [LMT_path filesep 'GUI_Settings'];
if exist(LMT_path,'dir')==7
    if exist([LMT_path filesep 'GUI_Recovery_Settings.mat'],'file') == 2
        LoadSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat')
    end
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LocoMouse_Tracker wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%--- Reading popup-menu list options:
function [] = readOptionList(option_path, file_search_stem, menu_handle)

if option_path(end) ~= filesep
    option_path = cat(2,option_path,filesep);
end

% Reading background parsing modes:
file_list = rdir(fullfile(option_path,file_search_stem),'',option_path);
[~,~,ext] = fileparts(file_search_stem);
file_list = strrep({file_list(:).name},ext,'');

if isempty(file_list)
    file_list = {''};
end
set(menu_handle,'String',file_list);clear bkg_list;


% --- Template to handle errors:
function [] = ErrorMsg(error_struct, error_message)
fprintf(error_message);
error_report = getReport(error_struct,'extended');
disp(error_report);
% waitForProcess(handles,'on');


% --- Function to execute when closing LocoMouse_Tracker:
function [] = LocoMouse_closeRequestFcn(hObject, eventdata)
handles = guidata(gcbo);
try
    SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat')
catch error_close_gui
    ErrorMsg(error_close_gui, 'Error closing GUI. Could not save settings.\n');
end
delete(gcbo)

% --- Outputs from this function are returned to the command line.
function varargout = LocoMouse_Tracker_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;


% --- Executes on selection change in listbox_files.
function listbox_files_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_files contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_files


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

% --- Adds a video file to the list of files to track
function [handles, success] = addVideoFiles(handles, file_list)

N_files_in = size(file_list,1);
success = true(1,N_files_in);

for i_files = 1:N_files_in
    try
        fname = strtrim(file_list(i_files,:));
        vid = VideoReader(fname);
        drawnow;
        clear vid
        
    catch error_open_file
        
        success(i_files) = false;
        ErrorMsg(error_open_file,sprintf('LocoMouse_Tracker Error: Failed to add Video File %s.\nMATLAB Error Report:\n', fname));
        
    end
end

% Add files to listbox:
if ~any(success)
    fprintf('Could not add any video files!\n');
    return;
end

file_list = file_list(success,:);

current_file_list = get(handles.listbox_files,'String');
current_file_list = cat(1,current_file_list,{file_list});
set(handles.listbox_files,'String',current_file_list);
set(handles.listbox_files,'Value',length(current_file_list));

fprintf('Added %d out of %d found video files.\n',sum(success),N_files_in);

% --- Add a Video Directory:
function handles = addVideoDir(handles, chosen_dir, search_subdirs)

% List all supported video files in such dir:
file_list = cell(handles.N_supported_files,1);
keep_file_type = true(1,handles.N_supported_files);

if search_subdirs
    chosen_dir = fullfile(chosen_dir,'**');
end

% Starts at 2 since 1 is all files:
for i_f = 1:handles.N_supported_files
    d = rdir(fullfile(chosen_dir,handles.supported_files{i_f + 1}));d = {d(:).name};
    file_list{i_f} = char(d'); clear d
    keep_file_type(i_f) = ~isempty(file_list{i_f});
end

if ~any(keep_file_type)
    fprintf('No supported files found in %s.\n', chosen_dir);
    return;
end

file_list = char(file_list(keep_file_type,:));

% Adding the video files:
[handles,success] = addVideoFiles(handles, file_list);


% --- Executes on button press in pushbutton_add_file.
function pushbutton_add_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
values = waitForProcess(handles,'off');

try
    current_search_path = getappdata(handles.figure1,'current_search_path');
    [chosen_file,chosen_path] = uigetfile(handles.supported_files,'Choose supported video file',current_search_path);
    
    if ischar(chosen_file)
        setappdata(handles.figure1,'current_search_path',chosen_path);
        file_path = fullfile(chosen_path,chosen_file);
        handles = addVideoFiles(handles, file_path);
    end
    
catch error_struct
    ErrorMsg(error_struct,sprintf('Failed to add video %s', file_path));
end

waitForProcess(handles,'on',values);
guidata(hObject,handles);


% --- Executes on button press in pushbutton_add_folder.
function pushbutton_add_folder_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Valid file selection.

% Disable the GUI:
values = waitForProcess(handles,'off');

try
    
    current_search_path = getappdata(handles.figure1,'current_search_path');
    chosen_dir = uigetdir(current_search_path,'Choose directory with supported video files');
    
    if ischar(chosen_dir)% Valid dir selection.
        setappdata(handles.figure1,'current_search_path',current_search_path);
        handles = addVideoDir(handles, chosen_dir, false);
    end
    
catch error_structure

    ErrorMsg(error_structure, sprintf('Failed to add videos on dir %s', chosen_dir));
    
end

% Enable the GUI:
waitForProcess(handles,'on',values);
guidata(handles.figure1,handles);


% --- Executes on button press in pushbutton_add_with_subfolders.
function pushbutton_add_with_subfolders_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_with_subfolders (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Disable the GUI:
values = waitForProcess(handles,'off');

try
    
    current_search_path = getappdata(handles.figure1,'current_search_path');
    chosen_dir = uigetdir(current_search_path,'Choose directory with supported video files');
    
    if ischar(chosen_dir)% Valid dir selection.
        setappdata(handles.figure1,'current_search_path',current_search_path);
        handles = addVideoDir(handles, chosen_dir, true);
    end
    
catch error_structure

    ErrorMsg(error_structure, sprintf('Failed to add videos on dir %s', chosen_dir));
    
end

% Enable the GUI:
waitForProcess(handles,'on',values);
guidata(handles.figure1,handles);


% --- Executes on selection change in popupmenu_output_mode.
function popupmenu_output_mode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_output_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_output_mode


% --- Executes during object creation, after setting all properties.
function popupmenu_output_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_background_mode.
function popupmenu_background_mode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_background_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_background_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_background_mode


% --- Executes during object creation, after setting all properties.
function popupmenu_background_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_background_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_log.
function listbox_log_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_log contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_log


% --- Executes during object creation, after setting all properties.
function listbox_log_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_start.
function pushbutton_start_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Geting the video file list:
disp('----------------[Tracking START]----');
SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat');

set(handles.disable_with_start,'Enable','off');
set(handles.enable_with_start,'Enable','on');
% reset_gui_state = onCleanup(@()());
drawnow;

% Reading info from the GUI: 
gui_status = readGUIStatus(handles);

% Load the calibration: The calibration matrix is saved with the output so
% all the parameters are in the result.
handles = loadCalibrationFile(...
    fullfile(...
    handles.calibration_path,[gui_status.calibration_file '.mat']),...
    handles);


% Opening the parallel pool:
try
    if isempty(gcp('nocreate'))
        parpool('open');
    end
catch
    parpool('local');
end
drawnow;

% FIXME: CPP Is triggered by having a cell defining the background
% method. This is a hack to comply with former design, but should be
% redesigned to be less error prone and more flexible.
is_cpp = iscell(gui_status.bb_cmd_string);

if ~exist(gui_status.output_path,'dir')
    mkdir(gui_status.output_path);
end

N_files = length(gui_status.file_list);
successful_tracking = true(1,N_files);
fprintf('Processing %d video files:\n', N_files);
total_time = tic;

if is_cpp
    
    % Configure the CPP tracker:
    [cpp_params,...
    model_file_yml,...
    calibration_file_yml,...
    handles] = configureLocoMouse_Cpp(handles, gui_status);
    
    % CPP code: remove from handles structure to avoid excessive data
    % transfer to parfor.
    data = handles.data;
    
    parfor i_files = 1:N_files
        file_name = char(strtrim(gui_status.file_list{i_files}));
        successful_tracking(i_files) = track_MATLAB_CPP(...
            data,...
            model_file_yml,...
            calibration_file_yml,...
            file_name,...
            gui_status.flip,...
            gui_status.output_fun,...
            gui_status.output_path,...
            gui_status.bkg_fun,...
            gui_status.CreateBackgroundImage, ...
            gui_status.overwrite_results,...
            gui_status.export_figures,...
            true,... % Is cpp
            cpp_params);
    end
else
    % Configure the MATLAB tracker:
    [matlab_params,...
        handles] = configureLocoMouse_MATLAB(handles, gui_status);
    
    % MATLAB code:
    for i_files = 1:N_files
        file_name = char(strtrim(gui_status.file_list{i_files}));
        successful_tracking(i_files) = track_MATLAB_CPP(...
            handles.data,...
            handles.model,...
            '',...
            file_name,...
            gui_status.flip,...
            gui_status.output_fun,...
            gui_status.output_path,...
            gui_status.bkg_fun,...
            gui_status.CreateBackgroundImage,...
            gui_status.overwrite_results,...
            gui_status.export_figures,...
            false,... %Not cpp
            matlab_params); % No need for cpp_params
    end
end

fprintf('%d out of %d files correctly processed.\n',sum(successful_tracking),N_files);
fprintf('Total run time: ');
disp(datestr(datenum(0,0,0,0,0,toc(total_time)),'HH:MM:SS'))
disp('------------------[Tracking END]----');
set(handles.disable_with_start,'Enable','on');
set(handles.enable_with_start,'Enable','off');



% === Configuring MATLAB and C++ algorithms:
function [matlab_params,...
    handles] = configureLocoMouse_MATLAB(handles, gui_status)

% Loading the model:
handles = loadModel(fullfile(handles.root_path,'model_files',[gui_status.model_file '.mat']),handles);

% MATLAB parameters:
matlab_params.bb_cmd_string = gui_status.bb_cmd_string;
matlab_params.bb_weights = gui_status.bb_weights;


function [cpp_params,...
    model_file_yml,...
    calibration_file_yml,...
    handles] = configureLocoMouse_Cpp(handles, gui_status)
% FIXME: CPP Is triggered by having a cell defining the background
% method. This is a hack to comply with former design, but should be
% redesigned to be less error prone and more flexible.

cpp_params.cpp_root_path = fullfile(...
    handles.root_path,...
    'auxiliary_functions',...
    'cpp',...
    filesep);

cpp_params.config_file = fullfile(...
    cpp_params.cpp_root_path,...
    gui_status.bb_cmd_string{3});

cpp_params.cpp_mode = gui_status.bb_cmd_string{2};

[~,model_file_name,~] = fileparts(gui_status.model_file);
[~,calibration_file_name,~] = fileparts(gui_status.calibration_file);

% Converting the MAT files for model and calibration into YML files to
% be loaded using the OpenCV library in C++.
model_file_yml = fullfile(...
    handles.root_path,...
    'model_files',...
    [model_file_name,'.yml']);

calibration_file_yml = fullfile(...
    handles.root_path,...
    'calibration_files',...
    [calibration_file_name,'.yml']);

if ~exist(model_file_yml,'file')
    handles = loadModel(fullfile(handles.root_path,'model_files',[gui_status.model_file '.mat']),handles);
    exportLocoMouseModelToOpenCV(model_file_yml, handles.model);
end

if ~exist(calibration_file_yml,'file')
    %%% FIXME: The calibration is not stored by itself. Instead it is mixed
    %%% in the handles.data structure. As it is, other fields that do not
    %%% belong to the calibration will be processed and return warnings.
    exportLocoMouseCalibToOpenCV(calibration_file_yml, handles.data);
end

% CPP parameters:
if ispc()
    cpp_params.cpp_binary = fullfile(...
        cpp_params.cpp_root_path,...
        'Locomouse.exe');
    
elseif isunix()
    cpp_params.cpp_binary = fullfile(...
        cpp_params.cpp_root_path,...
        'LocoMouse');
else
    error('C++ algorithms are not supported on this platform.');
end

if isstring(gui_status.flip) && strcmpi(gui_status.flip,'compute')
    error('Autodetect does not work with C++!');
end


function successful_tracking = track_MATLAB_CPP(data,...
                                                model,...
                                                calibration_file,...
                                                file_name,...
                                                flip,...
                                                output_fun,...
                                                output_path,...
                                                bkg_fun,...
                                                make_bkg,...
                                                overwrite_results,...
                                                export_figures,...
                                                is_cpp,...
                                                params)
try
    successful_tracking = true;
    % Going over the file list:
    % file_name = char(strtrim(file_list{i_files}));
    [~,trial_name,~] = fileparts(file_name);
    [out_path_data,out_path_image] = feval(output_fun,output_path,file_name);
       
    data_file_name = fullfile(out_path_data,[trial_name '.mat']);
    image_file_name = fullfile(out_path_image,[trial_name '.png']);

    if overwrite_results || ...
        (~exist(data_file_name,'file') && ~exist(image_file_name,'file'))
        
        % CHECK FOR BACKGROUND IMAGE AND CREATE ONE IF NECESSARY
        % Checks if indicated file exists, then checks if sameName file
        % exists. If both are negative, it creates a background image with
        % the sameName convention.
        
        bkg_file = feval(bkg_fun,file_name);
        sameName_file = feval('sameName',file_name);
        
        if ~exist(bkg_file,'file')
            disp(['Did not find a background image using the ''',bkg_fun,''' convention.'])

            if exist(sameName_file,'file')
                disp(['Found a background image using the ''sameName'' convention and using that!'])
                bkg_fun = 'sameName';
                bkg_file = feval(bkg_fun,file_name);

            elseif make_bkg
                disp('Creating Background image from video.')
                % [DE playing with different automatic background settings...]
                
                vid = VideoReader(file_name);
                if vid.Duration*vid.FrameRate > 1000
                    FramesToUse = [(vid.Duration*vid.FrameRate)-1000 Inf]; % using the last 1000 frames
                else
                    FramesToUse = [2 Inf]; % or all of them
                end     

                Bkg = read(vid,FramesToUse);
                if length(size(Bkg)) > 3
                    Bkg = squeeze(Bkg(:,:,1,:));
                end     

            % this appears to have the least mouse in it:
                Bkg = prctile(Bkg,15,3);

                disp(['writing generated background file (15th percentile) ' vid.Name(1:end-3) 'png'])
                imwrite(Bkg,[vid.Path filesep vid.Name(1:end-3) 'png'])

                bkg_fun = 'sameName';
                bkg_file = feval(bkg_fun,file_name);
                clear vid FramesToUse
            else
                error('No background image provided.')
            end
        end
        
        % ATTEMPTING TO TRACK:
        current_file_time = tic;
        fprintf('Tracking %s ...\n',file_name)
        data.bkg = bkg_file;
        data.vid = file_name;
        
        if is_cpp
            [final_tracks_c, tracks_tail_c,data,debug_info] = ...
                locomouse_tracker_cpp_wrapper(...
                    data,...
                    model,...
                    calibration_file,...
                    flip,...
                    output_path,...
                    params);
                
        else
            [final_tracks_c,tracks_tail_c,data,debug_info] = ...
                MTF_rawdata(...
                data,...
                model,...
                params);
            
        end
        
        [final_tracks,tracks_tail] = convertTracksToUnconstrainedView(final_tracks_c,tracks_tail_c,size(data.ind_warp_mapping),data.ind_warp_mapping,data.flip,data.scale);
        
        % Saving tracking data:
        if ~exist(out_path_data,'dir') % Make data folder if necessary
            mkdir(out_path_data);
        end
        
        save(data_file_name,'final_tracks','tracks_tail','final_tracks_c','tracks_tail_c','debug_info','data');
        
        % Saving data plot figures
        if export_figures
            % Check if image folder exists:
            if ~exist(out_path_image,'dir')
                mkdir(out_path_image);
            end
            MTF_export_figures(final_tracks_c, tracks_tail_c, image_file_name, data);
        end
        
        % FIXME Performing swing and stance detection:
        
        % --- ending it:
        clear data;
        disp('----------------------');
        disp('Done. Elapsed time: ')
        disp(datestr(datenum(0,0,0,0,0,toc(current_file_time)),'HH:MM:SS'));
        disp('----------------------');
    else
        fprintf('%s has already been tracked. To re-track check the "Overwrite existing results" box.\n',file_name);
    end
catch tracking_error
    error_report = getReport(tracking_error,'extended');
    disp('----------------------');
    disp(error_report);
    disp('----------------------');
    successful_tracking = false;
end


% --- Executes on button press in pushbutton_stop.
function pushbutton_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.disable_with_start,'Enable','on');
set(handles.enable_with_start,'Enable','off');
guidata(handles.figure1,handles);

% --- Executes on button press in pushbutton_add_output_mode.
function pushbutton_add_output_mode_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_output_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_add_background_method.
function pushbutton_add_background_method_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_background_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox_overwrite_results.
function checkbox_overwrite_results_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_overwrite_results (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_overwrite_results


% --------------------------------------------------------------------
function menu_menu_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_help_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_output_Callback(hObject, eventdata, handles)
% hObject    handle to menu_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_3_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_add_model.
function pushbutton_browse_output_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
out_path = uigetdir(get(handles.edit_output_path,'String'));
if ischar(out_path)
    set(handles.edit_output_path,'String',out_path);
end
guidata(handles.figure1,handles);

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


% --- Executes during object creation, after setting all properties.
function edit_output_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_output_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Function that loads a calibration file and performs a few basic checks:
function handles = loadCalibrationFile(full_file_path,handles)
try
    data = load(full_file_path);
    % Since there is no model file type we must check we have all the right
    % fields:
    name_fields = {'ind_warp_mapping','inv_ind_warp_mapping','mirror_line','split_line'};
    
    tfields = fieldnames(data);
    tfoundfield = false(1,size(name_fields,2));
    for i_f = 1:size(name_fields,2)
        tfoundfield(i_f) =any(ismember(name_fields(i_f),tfields));
    end
    allfields = all(tfoundfield([1,2])) && any(tfoundfield([3 4]));
    if ~allfields
        error('ERROR: Incomplete calibration file.')
    else
        if tfoundfield(3) && ~tfoundfield(4)
            data.split_line = data.mirror_line;
            fprintf('WARNING: Outdated fieldname "mirror_line" should be renamed to "split_line".\n')
            disp(full_file_path);
        end
        if ~isfield(data,'scale')
            data.scale = 1;
        end
        handles.data = data;
    end
    
catch load_error
    fprintf('Error: Could not load %s with MATLAB.\n',full_file_path);
    disp(getReport(load_error,'extended'));
    beep;
end
% Setting the old or new string according to how the computations went:
% set(handles.edit_output_path,'String',get(handles.figure1,'UserData'));


% --- Executes on button press in pushbutton_remove.
function pushbutton_remove_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

current_list = get(handles.listbox_files,'String');
current_pos = get(handles.listbox_files,'Value');
current_list(current_pos,:) = [];
N_files = size(current_list,1);
if N_files  == 0
    % If list is empty disable the list and the remove button:
    handles = changeGUIEnableStatus(handles,'off');
elseif current_pos > N_files
    current_pos = size(current_list,1);
end
set(handles.listbox_files,'String',current_list);
set(handles.listbox_files,'Value',current_pos);
guidata(handles.figure1,handles);

% --- Enabling/Disabling the GUI properties that depend on the existence of
% at least one file on the file list.
function handles = changeGUIEnableStatus(handles,set_value)
handle_list = [ handles.pushbutton_remove, ...
    handles.pushbutton_clear_filelist, ...
    handles.pushbutton_start, ...
    handles.listbox_files,...
    handles.pushbutton_cluster, ...
    handles.pushbutton_cluster_output
    ];
set(handle_list,'Enable',set_value);


% --- Executes on selection change in popupmenu_calibration_files.
function popupmenu_calibration_files_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_calibration_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_calibration_files contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_calibration_files


% --- Executes during object creation, after setting all properties.
function popupmenu_calibration_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_calibration_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_add_model.
function pushbutton_add_model_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[load_file, load_path] = uigetfile('*.mat','Choose MAT file with LocoMouse model');

if ischar(load_file)
    % Check if file already exists:
    list = get(handles.popupmenu_model,'String');
    [~,fname,~] = fileparts(load_file);
    already_on_list = strcmpi(fname,list);
    
    if any(already_on_list)
        N = find(already_on_list);
        set(handles.popupmenu_model,'Value',N);
        warning('%s is already on the model list!\n',fname);
    else
        file_path = fullfile(load_path, load_file);
        db_file_path = fullfile(handles.model_path,load_file);
        succ = copyfile(file_path,db_file_path);
        if ~succ
            error('Could not copy %s to local folder!\n',file_path)
            %             warning('Could not copy %s to local folder. Attempting to proceed with current location...\n');
            %             list{length(list)+1} = file_path;
        else
            % Refresh the popup list:
            list{length(list)+1} = fname;
        end
        set(handles.popupmenu_model,'String',list);
        set(handles.popupmenu_model,'Value',length(list));
    end
    guidata(handles.figure1,handles);
end

function popupmenu_model_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of popupmenu_model as text
%        str2double(get(hObject,'String')) returns contents of popupmenu_model as a double


% --- Executes during object creation, after setting all properties.
function popupmenu_model_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_add_background_mode.
function pushbutton_add_background_mode_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_background_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_add_calibration_file.
function pushbutton_add_calibration_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_calibration_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[load_file, load_path] = uigetfile('*.mat','Choose MAT file with LocoMouse model');

if ischar(load_file)
    % Check if file already exists:
    list = get(handles.popupmenu_calibration_files,'String');
    [~,fname,~] = fileparts(load_file);
    already_on_list = strcmpi(fname,list);
    
    if any(already_on_list)
        N = find(already_on_list);
        set(handles.popupmenu_calibration_files,'Value',N);
        warning('%s is already on the model list!\n',fname);
    else
        file_path = fullfile(load_path, load_file);
        db_file_path = fullfile(handles.calibration_path,load_file);
        succ = copyfile(file_path,db_file_path);
        if ~succ
            error('Could not copy %s to local folder!\n',file_path)
        else
            % Refresh the popup list:
            list{length(list)+1} = fname;
        end
        set(handles.popupmenu_calibration_files,'String',list);
        set(handles.popupmenu_calibration_files,'Value',length(list));
    end
    handles.latest_path = load_path;
    guidata(handles.figure1,handles);
end

% --- Executes when waiting for a process to happen:
function values = waitForProcess(handles,state,values)
% handles   the handles to the objects of the gui
% state     'on' or 'off'
% Function that disables/enables a GUI during/after execution.
% values should have the

switch state
    case 'on'
        if ~exist('values','var')
            error('var must be provided if state is ''off''.');
        end
        set(handles.figure1,'Pointer','arrow');
        set(handles.disable_while_running,{'Enable'},values);
        drawnow;
    case 'off'
        values = get(handles.disable_while_running,'Enable');
        set(handles.figure1,'Pointer','watch');
        set(handles.disable_while_running,'Enable','off');
        drawnow;
    otherwise
        error('Unknown option!');
end

if ~isempty(get(handles.listbox_files,'String'))
    changeGUIEnableStatus(handles,'on');
end

% --- Executes on selection change in MouseOrientation.
function MouseOrientation_Callback(hObject, eventdata, handles)
% hObject    handle to MouseOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MouseOrientation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MouseOrientation


% --- Executes during object creation, after setting all properties.
function MouseOrientation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MouseOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in BoundingBox_choice.
function BoundingBox_choice_Callback(hObject, eventdata, handles)
% hObject    handle to BoundingBox_choice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BoundingBox_choice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BoundingBox_choice


% --- Executes during object creation, after setting all properties.
function BoundingBox_choice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BoundingBox_choice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

[p_boundingBoxFunctions, ~, ~]=fileparts(which('computeMouseBox'));
if isempty(p_boundingBoxFunctions)
    error('INITIALIZATION ERROR: computeMouseBox.m is missing.')
end
load([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'ComputeMouseBox_option');
set(hObject,'String',ComputeMouseBox_option);

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in SaveSettings.
function SaveSettings_Callback(hObject, eventdata, handles, tsfilename)
if exist('tsfilename')~=1
    tsfilename = [];
end
LMGUI_SaveSettings_Callback(handles, tsfilename);

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over SaveSettings.
function SaveSettings_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to SaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in LoadSettings.
function LoadSettings_Callback(hObject, eventdata, handles, tlfilename)
if exist('tlfilename')~=1
    tlfilename = [];
end
LMGUI_LoadSettings_Callback(handles, tlfilename);


% --- Executes on button press in checkbox_ExpFigures.
function checkbox_ExpFigures_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_ExpFigures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_ExpFigures


% --- Executes on button press in pushbutton_clear_filelist.
function pushbutton_clear_filelist_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clear_filelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listbox_files,'String',{});
handles = changeGUIEnableStatus(handles,'off');


% --- Executes on button press in pushbutton_cluster.
function pushbutton_cluster_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cluster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%FIXME: Check how to make sure whe have access to the cluster on the
%%current machine.

% if ~isunix
%     error('LocoMouse_Tracker supports sending jobs to a OpenLava framework running on Linux only. For more details see the documentation.');
% end

% FIXME: OpenLava Server configurations should be performed in some config
% file.
cluster_opts.root = '/mirror/LocoMouse';
cluster_opts.mirror_folder = '/mirror';
cluster_opts.job_name = 'test_cluster_job';
cluster_opts.models = fullfile(cluster_opts.root, 'model_files');
cluster_opts.calibration = fullfile(cluster_opts.root, 'configuration_files');
cluster_opts.config = fullfile(cluster_opts.root, 'calibration_files');
cluster_opts.job_path = fullfile(cluster_opts.root,cluster_opts.job_name);

% if ~exist(cluster_opts.job_path,'dir')
%     mkdir(cluster_opts.job_path);
% end
% 
% if ~exist(cluster_opts.mirror_folder,'dir')
%     error('Could not find "/mirror". LocoMouse_Tracker expects an OpenLava installation with a particular configuration. For more details see the documentation.');
% end

gui_status = readGUIStatus(handles);

% FIXME: Implement function that makes all the model, calib, and config
% files available to the cluster.
job_file = configureCluster(handles, cluster_opts, gui_status);

N_files = size(gui_status.file_list,1);

% Submit the job array:
disp('----------------[Submitting job to cluster]----');
if N_files == 1
    system(sprintf('bsub < %s',job_file));
else
    system(sprintf('bsub -J "LocoMouse_Tracker[%d-%d]" < %s',1,N_files,job_file));
end

SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat');

% --- Executes on button press in pushbutton_cluster_output.
function pushbutton_cluster_output_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cluster_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%%% FIXME: WTF is this function?

% Calibration file;
calibration_file_pos = get(handles.popupmenu_calibration_files,'Value');
calibration_file = get(handles.popupmenu_calibration_files,'String');
calibration_file = calibration_file{calibration_file_pos};
handles = loadCalibrationFile(fullfile(handles.calibration_path,[calibration_file '.mat']),handles);

% 
% % Model file:
% model_file_pos = get(handles.popupmenu_model,'Value');
% model_file = get(handles.popupmenu_model,'String');
% model_file = model_file{model_file_pos};
% handles = loadModel(fullfile(handles.root_path,'model_files',[model_file '.mat']),handles);

output_fun = get(handles.popupmenu_output_mode,'String');
output_mode = get(handles.popupmenu_output_mode,'Value');
output_fun = output_fun{output_mode};

if ~exist(model_file_yml,'file')
    model_file_yml_matlab = fullfile(handles.root_path,'model_files',[model_file '.yml']);
    if exist(model_file_yml_matlab,'file')
        success = copyfile(model_file_yml_matlab,model_file_yml);
        if ~success
            %             error('Error copying model yml file. Check for writing permissions!');
        end
    else
        handles = loadModel(fullfile(handles.root_path,'model_files',[model_file '.mat']),handles);
        exportLocoMouseModelToOpenCV(model_file_yml,handles.model);
    end
end

if ~exist(calibration_file_yml,'file')
    calibration_file_yml_matlab = fullfile(handles.root_path,'calibration_files',[calibration_file '.yml']);
    
    if exist(calibration_file_yml_matlab,'file')
        success = copyfile(calibration_file_yml_matlab,calibration_file_yml);
        if ~success
            %             error('Error copying calibration yml file. Check for writing permissions!');
        end
    else
        handles = loadCalibrationFile(fullfile(handles.root_path,'calibration_files',[calibration_file '.mat']),handles);
        
        % Check for compatibility:
        rm_list = {'vid','bkg','flip'};
        data = handles.data;
        for i_data = 1:length(rm_list)
            if isfield(data,rm_list{i_data})
                data = rm(data,rm_list{i_data});
            end
        end
        exportLocoMouseCalibToOpenCV(calibration_file_yml,data);
    end

end

% =========
function [bb_cmd_string, bb_weight] = boundingBoundingBoxChoice(handles)
% Parses the bounding box information (including the choice between MATLAB
% and C++ algorithms).

% Load the config file BoundingBoxOptions.mat
bb_choice = get(handles.BoundingBox_choice,'Value');
[p_boundingBoxFunctions, ~, ~] = fileparts(which('computeMouseBox'));

load(fullfile(p_boundingBoxFunctions,'BoundingBoxOptions.mat'),...
    'ComputeMouseBox_cmd_string',...
    'ComputeMouseBox_option',...
    'WeightSettings');

bb_cmd_string = ComputeMouseBox_cmd_string{bb_choice};
if bb_choice <= length(WeightSettings)
    bb_weight = WeightSettings{bb_choice};
else
    bb_weight = [];
end

% % FIXME: CPP Is triggered by having a cell defining the background
% % method. This is a hack to comply with former design, but should be
% % redesigned to be less error prone and more flexible.
% is_cpp = iscell(bb_cmd_string);
% cpp_params = [];
% 
% % if is_cpp
% %     % CPP parameters:
% %     cpp_params.cpp_root_path = fullfile(...
% %         handles.root_path,...
% %         'auxiliary_functions',...
% %         'cpp',...
% %         filesep);
% %     
% %     cpp_params.config_file = fullfile(...
% %         cpp_params.cpp_root_path,...
% %         bb_cmd_string{3});
% %     
% %     cpp_params.cpp_mode = bb_cmd_string{2};
% %     
% %     if ispc()
% %         cpp_params.cpp_binary = fullfile(...
% %             cpp_params.cpp_root_path,...
% %             'Locomouse.exe');
% %         
% %     else
% %         warning('C++ algorithm are only supported in Windows at the moment.');
% %     end
% %   
% % end


% === Reading the GUI options:
function gui_status = readGUIStatus(handles)
% Parses the options chosen on the GUI and "translates" those options into
% the appropriate internal variables for tracking.

% Options that influence how tracking is performed:
gui_status = struct('bb_cmd_string','',...
    'model_file','',...
    'calibration_file','',...
    'bkg_fun','',...
    'output_fun','',...
    'output_path','',...
    'flip',[],...
    'CreateBackgroundImage',0,...
    'file_list','',...
    'export_figures',false,...
    'overwrite_results',false);

% File list:
tfile_list = get(handles.listbox_files,'String');

if iscell(tfile_list)
    gui_status.file_list = tfile_list;
    
else
    gui_status.file_list = cell(size(tfile_list,1),1);
    for tfl_i = 1:size(tfile_list,1)
        gui_status.file_list{tfl_i} = strtrim(tfile_list(tfl_i,:));
    end
end
clear('tfile_list');

% BB option (also if MATLAB or C++ algorithm):
[gui_status.bb_cmd_string,...
    gui_status.bb_weights] = boundingBoundingBoxChoice(handles);

% Load and configure the Calibration:
calibration_file_pos = get(handles.popupmenu_calibration_files,'Value');
calibration_file = get(handles.popupmenu_calibration_files,'String');
gui_status.calibration_file = calibration_file{calibration_file_pos};

% Load and confiture the Model:
model_file_pos = get(handles.popupmenu_model,'Value');
model_file = get(handles.popupmenu_model,'String');
gui_status.model_file = model_file{model_file_pos};

% Configure Mouse orientation:
% Checking which side the mouse faces:
gui_status.flip_function = [];
gui_status.flip_char = '';
switch handles.MouseOrientation.Value
    case 1
        gui_status.flip = 'compute';
    case 2
        gui_status.flip = 'LR';
        gui_status.flip_function = @(file_name)(file_name(find(file_name == '.',1,'last') - 1));
    case 3
        gui_status.flip = false;
        gui_status.flip_char = 'R';
    case 4
        gui_status.flip = true;
        gui_status.flip_char = 'L';
end

% Configure Output function:
output_mode = get(handles.popupmenu_output_mode,'Value');
output_fun = get(handles.popupmenu_output_mode,'String');
gui_status.output_fun = output_fun{output_mode};

% Configure Bkg Mode function:
bkg_mode = get(handles.popupmenu_background_mode,'Value');
bkg_fun = get(handles.popupmenu_background_mode,'String');
gui_status.bkg_fun = bkg_fun{bkg_mode};

% Configure Output path:
gui_status.output_path = get(handles.edit_output_path,'String');

% Configure Background Image creation:
gui_status.CreateBackgroundImage = handles.CreateBackgroundImage.Value;

% Configure overwirte results:
gui_status.overwrite_results = handles.checkbox_overwrite_results.Value;

% Configure export figures:
gui_status.export_figures = handles.checkbox_ExpFigures.Value;


% %%% OLD CODE THAT MUST BE REUSED SOMEWHERE
% GUI_STATUS.cpp_config_file = cpp_config_file; 
% GUI_STATUS.background_function = bkg_fun{bkg_mode};
% GUI_STATUS.output_function = output_fun{output_mode};
% GUI_STATUS.output_path = get(handles.edit_output_path,'String');
% GUI_STATUS.flip_char = flip_char;
% GUI_STATUS.model_file.mat = fullfile(handles.model_path,[model_file '.mat']);
% GUI_STATUS.model_file.yml = fullfile(handles.model_path,[model_file '.yml']);
% GUI_STATUS.calibration_file.mat = fullfile(handles.calibration_path, [calibration_file '.mat']);
% GUI_STATUS.calibration_file.yml = fullfile(handles.calibration_path, [calibration_file '.yml']);
% GUI_STATUS.video_list = get(handles.listbox_files,'String');
% 
% %%% FIXME: Make the mouse option a function of the file name in other
% %%% places of the code.
% if length(flip_char) > 1
%     GUI_STATUS.flip_function = @(file_name)(file_name(find(file_name == '.',1,'last') - 1));
% else
%     GUI_STATUS.flip_function = [];
% end

function job_file = configureCluster(handles, cluster_opts, GUI_STATUS)
% Copy yml files to the cluster folders so it is accessible to all workers:
% 
% model_file_mat = fullfile(...
%     handles.root_path,...
%     'model_files',...
%     [GUI_STATUS.model_file '.mat']);
% 
% model_file_yml = model_file_mat;
% model_file_yml(end-2:end) = 'yml';
% 
% calibration_file_mat = fullfile(...
%     handles.root_path,...
%     'calibration_files',...
%     [GUI_STATUS.calibration_file '.mat']);
% 
% calibration_file_yml = calibration_file_mat;
% calibration_file_yml(end-2:end) = 'yml';
% 
% % Check if one needs to convert files to yml:
% if ~exist(model_file_yml,'file')
%     exportLocoMouseModelToOpenCV(model_file_yml,load(model_file_mat));
% end
% 
% if ~exist(calibration_file_yml,'file')
%     exportLocoMouseCalibToOpenCV(calibration_file_yml,...
%         load(calibration_file_mat));
% end

[cpp_params,...
    model_file_yml,...
    calibration_file_yml,...
    handles] = configureLocoMouse_Cpp(handles, GUI_STATUS);

files_to_copy = {calibration_file_yml,...
                 model_file_yml,...
                 cpp_params.config_file};

field_list = {'calibration', 'models', 'config'};

destination_folders = {cluster_opts.calibration,...
                       cluster_opts.models,...
                       cluster_opts.config};

for i_files = 1:3
    
    success = copyfile(files_to_copy{i_files}, destination_folders{i_files});
    
    if success < 0
        error('Failed to copy configuration file %s file to cluster folder %s',files_to_copy{i_files}, destination_folders{i_files});
    end
    
    [~,fname,ext] = fileparts(files_to_copy{i_files});
    cluster_opts.(sprintf('%s_cluster_file_path',field_list{i_files})) = fullfile(cluster_opts.(field_list{i_files}),[fname ext]);
    
end

% Create the file to convert yml results to mat results:
GUI_STATUS.model_file_mat = fullfile(...
    handles.root_path,...
    'model_files',...
    [GUI_STATUS.model_file '.mat']);

GUI_STATUS.calibration_file_mat = fullfile(...
    handles.root_path,...
    'calibration_files',...
    [GUI_STATUS.calibration_file '.mat']);

convertResults(cpp_params, cluster_opts, GUI_STATUS);

% Create the auxiliary files:
[video_file, background_file, side_file] = filesForOpenLavaJob(cluster_opts, GUI_STATUS);

% Create the job file:
job_file = openLavaJobArray(cluster_opts,...
                            cpp_params,...
                            GUI_STATUS,...
                            video_file,...
                            background_file,...
                            side_file);


% ------ Converts the ylm c++ results into matfiles after each job 
function convertResults(cpp_params, cluster_opts, GUI_STATUS)

C = load(GUI_STATUS.calibration_file_mat);
M = load(GUI_STATUS.model_file_mat);

data.split_line = C.split_line;
data.mirror_line = data.split_line;

if isfield(C,'scale')
    data.scale = C.scale;
else
    data.scale = 1;
end

data.model = M;
data.IDX = C.ind_warp_mapping;
data.ind_warp_mapping = C.ind_warp_mapping;
data.inv_ind_warp_mapping = C.inv_ind_warp_mapping;
data.flip = GUI_STATUS.flip;
data.vid = [];
data.bkg = [];

% Saving temporary mat file to load when post-processing the tracking
% results:
save(fullfile(cluster_opts.job_path,sprintf('%s.mat',cluster_opts.job_name)),'-struct','data');

% Copying the the track conversions to a folder all nodes can access:
track_conversion_files = {'convertTracksToUnconstrainedView.m','cppToMATLABTracks.m','tempclusterjob.m'};
N_files = length(track_conversion_files);
success = zeros(1,N_files);

for i_files = 1:N_files
    
    success(i_files) = copyfile(...
        fullfile(cpp_params.cpp_root_path,...
                 track_conversion_files{i_files}),...
                 cluster_opts.job_path);
end

% Deleting auxiliary files if something goes wrong:
if any(success == 0)
    for i_files = 1:N_files
        if success(i_files)
        delete(fullfile(cluster_opts.job_path,track_conversion_files{i_files}));
        end
    end
    
    error('Could not copy the .m files to convert yml results to mat! Expected files under %s are %s, %s, %s.',handles.cpp_root_path,track_conversion_files{:});
    
end

function job_file = openLavaJobArray(cluster_opts, cpp_params, GUI_STATUS, video_file, background_file, side_file)

job_name_stem = fullfile(cluster_opts.job_path,cluster_opts.job_name);

% If .err and .out files exist, delete them:
if exist(sprintf('%s.out',job_name_stem),'file')
    delete(sprintf('%s.out',job_name_stem));
end

if exist(sprintf('%s.err',job_name_stem),'file')
    delete(sprintf('%s.err',job_name_stem));
end

job_file = sprintf('%s.job',job_name_stem);

job_fid = fopen(job_file,'w');

if job_fid < 0
    error('Could not create .job file. Check writing permissions!');
end

safefid = onCleanup(@()(fclose(job_fid)));

fprintf(job_fid,'#BSUB -o %s.out\n',job_name_stem);
fprintf(job_fid,'#BSUB -e %s.err\n',job_name_stem);
fprintf(job_fid,'#!/bin/bash\n');
fprintf(job_fid,'#echo $LSB_JOBINDEX\n');
fprintf(job_fid,'file_name=$(sed "${LSB_JOBINDEX}q;d" %s)\n',video_file);
fprintf(job_fid,'bkg_name=$(sed "${LSB_JOBINDEX}q;d" %s)\n', background_file);
fprintf(job_fid,'side_char=$(sed "${LSB_JOBINDEX}q;d" %s)\n',side_file);
fprintf(job_fid,'echo "$file_name"\n');
fprintf(job_fid,'"%s" %s "%s" "${file_name}" "${bkg_name}" "%s" "%s" "${side_char}" "%s";\n',...
    fullfile(cluster_opts.root,'LocoMouse'),...
    cpp_params.cpp_mode,...
    cluster_opts.config_cluster_file_path,...
    cluster_opts.models_cluster_file_path,...
    cluster_opts.calibration_cluster_file_path,...
    GUI_STATUS.output_path);

% Calling a MATLAB script to convert yml results to mat.
fprintf(job_fid,'matlab -nodesktop -nodisplay -r "cd ''%s''; tempclusterjob(''%s'',''$file_name'',''$bkg_name'',''$side_char'',''%s'');quit;"',...
    cluster_opts.job_path ,...
    GUI_STATUS.output_path,...
    fullfile(cluster_opts.job_path, sprintf('%s.mat',cluster_opts.job_name)));


function [video_file, background_file, side_file] = filesForOpenLavaJob(cluster_opts, GUI_STATUS)

% Printing video files:
video_file = fullfile(cluster_opts.job_path, sprintf('%s_video_list.txt',cluster_opts.job_name));
printFileList(video_file, GUI_STATUS.file_list,[]);

% Printing Background files:
background_file = fullfile(cluster_opts.job_path, sprintf('%s_background_list.txt',cluster_opts.job_name));
printFileList(background_file, GUI_STATUS.file_list, GUI_STATUS.bkg_fun);

% Printing side files:
side_file = fullfile(cluster_opts.job_path, sprintf('%s_side_list.txt',cluster_opts.job_name));

if isempty(GUI_STATUS.flip_function)
    
    side_char_list = repmat(GUI_STATUS.flip_char,size(GUI_STATUS.file_list,1),1);
    if isunix
        side_char_list = num2cell(side_char_list,2);
    elseif ismac 
        error('MAC is not supported. Correct to see how MAC behaves!');
    end
        
    printFileList(side_file, side_char_list, []);
else
    
    printFileList(side_file, GUI_STATUS.file_list, GUI_STATUS.flip_function);
end


%%% Printing files necessary for cluster job
function [] = printFileList(txt_file_path, file_list,pre_processing_fun)

fid = fopen(txt_file_path,'w');

if fid < 0
    error('Could not create text file %s', txt_file_path);
end

cleanfid = onCleanup(@()(fclose(fid)));

N_files = size(file_list,1);

for i_files = 1:N_files
    
    if ischar(file_list)
        file_name = strtrim(file_list(i_files,:));
    elseif iscell(file_list)
        file_name = file_list{i_files};
    end
    
    if ~isempty(pre_processing_fun)
        file_name = feval(pre_processing_fun,file_name);
    end
    
    fprintf(fid,[file_name '\n']);
end


% --- Executes on button press in CreateBackgroundImage.
function CreateBackgroundImage_Callback(hObject, eventdata, handles)
% hObject    handle to CreateBackgroundImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CreateBackgroundImage
