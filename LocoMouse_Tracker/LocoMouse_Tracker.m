function varargout = LocoMouse_Tracker(varargin)
% LOCOMOUSE_TRACKER MATLAB code for LocoMouse_Tracker.fig
% The LocoMouse_Tracker GUI tracks a list of video files once it is given a
% background search method, a calibration file, a model file, an output
% folder parsing method and an output folder.
%
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org)
% Last Modified: 17/11/2014

% Last Modified by GUIDE v2.5 28-Oct-2016 13:52:19

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

% Initialising suppoted video files:
sup_files = VideoReader.getFileFormats;
handles.N_supported_files = size(sup_files,2)+1;
handles.supported_files = cell(handles.N_supported_files,2);
handles.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
handles.supported_files(2:end,2) = {sup_files(:).Description};
handles.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),handles.supported_files(2:end,1)','un',false));
handles.supported_files{1,2} = 'All supported video files';
set(handles.figure1,'UserData','');

% Getting the install path for LocoMouseTracker:
[handles.root_path,~,~] = fileparts([mfilename('fullpath'),'*.m']);

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

% Reading calibration files:
idx_list = rdir(fullfile(handles.root_path,'calibration_files','*.mat'),'',fullfile(handles.root_path,['calibration_files' filesep]));
idx_list = strrep({idx_list(:).name},'.mat','');
if isempty(idx_list)
    idx_list = {''};
end
set(handles.popupmenu_calibration_files,'String',idx_list);clear idx_list

% Reading model files:
model_list = rdir(fullfile(handles.root_path,'model_files','*.mat'),'',fullfile(handles.root_path,['model_files' filesep]));
model_list = strrep({model_list(:).name},'.mat','');
if isempty(model_list)
    model_list = {' '};
end
set(handles.popupmenu_model,'String',model_list);clear model_list

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

% Update handles structure
guidata(hObject, handles);

set(handles.figure1,'CloseRequestFcn',@LocoMouse_closeRequestFcn);

% Loading latest settings

[LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
LMT_path = [LMT_path filesep 'GUI_Settings'];
if exist(LMT_path,'dir')==7
    if exist([LMT_path filesep 'GUI_Recovery_Settings.mat'],'file') == 2
        LoadSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat')
    end
end

% UIWAIT makes LocoMouse_Tracker wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function LocoMouse_closeRequestFcn(hObject, eventdata)
handles = guidata(gcbo);
try
SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat')
catch error_close_gui
    error_report = getReport(error_close_gui,'extended');
    fprintf('Error closing GUI. Could not save settings.\n');
    disp(error_report);
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


% --- Executes on button press in pushbutton_add_file.
function pushbutton_add_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
current_search_path = getappdata(handles.figure1,'current_search_path');
[chosen_file,chosen_path] = uigetfile(handles.supported_files,'Choose supported video file',current_search_path);
chosen_fullfile = fullfile(chosen_path,chosen_file);

if ischar(chosen_file)
    setappdata(handles.figure1,'current_search_path',chosen_path);
    values = waitForProcess(handles,'off');
    % Valid file selection.
    
    % Search for repetitions:
    %%% FIXME: See how this was done in other GUIs
    
    % Try to read the file with video reader:
    try
        vid = VideoReader(chosen_fullfile);
        drawnow;
        clear vid
        waitForProcess(handles,'on',values);
    catch
        %%% Play error sound and write error message on log box!
        %        updateLog(handles.listbox_log,'Error: Could not open %s with VideoReader','r');
        fprintf('Error: Could not open %s with VideoReader!\n',chosen_fullfile);
        waitForProcess(handles,'on',values);
        return;
    end
    
    % Add file to file listbox:
    current_file_list = get(handles.listbox_files,'String');
    N_files = size(current_file_list,1);
    if N_files == 0
        handles = changeGUIEnableStatus(handles,'on');
    end
    current_file_list = cat(1,current_file_list,{chosen_fullfile});
    set(handles.listbox_files,'String',current_file_list);
    set(handles.listbox_files,'Value',length(current_file_list));
    clear current_file_list
end


% --- Executes on button press in pushbutton_add_folder.
function pushbutton_add_folder_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Valid file selection.
current_search_path = getappdata(handles.figure1,'current_search_path');
chosen_dir = uigetdir(current_search_path,'Choose directory with supported video files');
setappdata(handles.figure1,'current_search_path',current_search_path);

if ischar(chosen_dir)% Valid dir selection.
    values = waitForProcess(handles,'off');
    % List all supported video files in such dir:
    file_list = cell(handles.N_supported_files,1);
    isempty_file_type = true(1,handles.N_supported_files);
    
    % Starts at 2 since 1 is all files:
    for i_f = 2:handles.N_supported_files
        file_list{i_f} = getDataList(fullfile(chosen_dir,handles.supported_files{i_f}));
        isempty_file_type(i_f) = isempty(file_list{i_f});
    end
    if ~all(isempty_file_type)
        file_list = char(file_list(~isempty_file_type));
        N_candidate_files = size(file_list,1);
        kp = true(1,N_candidate_files);
        
        % Search for repetitions:
        %%% FIXME: See how this was done in other GUIs
        
        % Try to read the file with video reader:
        for i_f = 1:N_candidate_files
            file_name_f = strtrim(file_list(i_f,:));
            try
                vid = VideoReader(file_name_f);
                clear vid
                %                 fprintf('%s added successfully.\n',file_name_f);
            catch
                %%% Play error sound and write error message on log box!
                %        updateLog(handles.listbox_log,'Error: Could not open %s with VideoReader','r');
                fprintf('Error: Could not open %s with VideoReader!\n',file_name_f);
                kp(i_f) = false;
            end
        end
        file_list = file_list(kp,:);
        waitForProcess(handles,'on',values);
        if ~isempty(file_list)
            % Add file to file listbox:
            current_file_list = get(handles.listbox_files,'String');
            if size(current_file_list,1) == 0
                handles = changeGUIEnableStatus(handles,'on');
            end
            
            current_file_list = cat(1,current_file_list,file_list);
            set(handles.listbox_files,'String',current_file_list);
            set(handles.listbox_files,'Value',size(current_file_list,1));
            clear current_file_list file_list
            
            
        else
            fprintf('No supported video files found!\n');
        end
    else
        fprintf('No supported video files found!\n');
    end
end
guidata(handles.figure1,handles);

% --- Executes on button press in pushbutton_add_with_subfolders.
function pushbutton_add_with_subfolders_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_with_subfolders (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chosen_dir = uigetdir('','Choose directory with supported video files');

if ischar(chosen_dir)
    file_list = cell(handles.N_supported_files,1);
    kp_f = true(handles.N_supported_files,1);
    for i_f = 1:handles.N_supported_files
        d = rdir(fullfile(chosen_dir,'**',handles.supported_files{i_f}));d = {d(:).name};
        file_list{i_f} = char(d'); clear d
        N_candidate_files = size(file_list{i_f},1);
        fprintf('%d %s files found\n',N_candidate_files,handles.supported_files{i_f});
        kp_ff = true(1,N_candidate_files);
        for i_ff = 1:N_candidate_files
            file_name_ff = strtrim(strtrim(file_list{i_f}(i_ff,:)));
            try
                vid = VideoReader(file_name_ff);
                clear vid
                % fprintf('%s added successfully.\n',file_name_ff);
            catch
                %%% Play error sound and write error message on log box!
                %        updateLog(handles.listbox_log,'Error: Could not open %s with VideoReader','r');
                fprintf('Error: Could not open %s with VideoReader!\n',file_name_ff);
                kp_ff(i_ff) = false;
            end
        end
        file_list{i_f} = file_list{i_f}(kp_ff,:);
        if isempty(file_list{i_f})
            kp_f(i_f) = false;
        end
    end
    file_list = char(file_list(kp_f));
    current_list = get(handles.listbox_files,'String');
    if (isempty(current_list)) && (~isempty(file_list) > 0)
        handles = changeGUIEnableStatus(handles,'on');
    end
    set(handles.listbox_files,'String',cat(1,current_list,{file_list}));
end
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
tfile_list = get(handles.listbox_files,'String');
file_list = cell(size(tfile_list,1),1);
for tfl_i = 1:size(tfile_list,1)
    file_list{tfl_i} = strtrim(tfile_list(tfl_i,:));
end
clear('tfile_list');
Nfiles = size(file_list,1);

% Calibration file;
calibration_file_pos = get(handles.popupmenu_calibration_files,'Value');
calibration_file = get(handles.popupmenu_calibration_files,'String');calibration_file = calibration_file{calibration_file_pos};
handles = loadCalibrationFile(fullfile(handles.root_path,'calibration_files',[calibration_file '.mat']),handles);

% Model file:
model_file_pos = get(handles.popupmenu_model,'Value');
model_file = get(handles.popupmenu_model,'String');model_file = model_file{model_file_pos};
handles = loadModel(fullfile(handles.root_path,'model_files',[model_file '.mat']),handles);

% Output and background functions:
bkg_mode = get(handles.popupmenu_background_mode,'Value');
output_mode = get(handles.popupmenu_output_mode,'Value');
bkg_fun = get(handles.popupmenu_background_mode,'String');bkg_fun = bkg_fun{bkg_mode};
output_fun = get(handles.popupmenu_output_mode,'String');output_fun = output_fun{output_mode};

% Reading output path:
output_path = get(handles.edit_output_path,'String');

try
    if isempty(gcp('nocreate'))
        parpool('open');
    end
catch
    parpool('local');
end
drawnow;
fprintf('Processing %d video files:\n',Nfiles);

total_time = tic;

% Checking if running C++ code: [joaofayad]
bb_choice = get(handles.BoundingBox_choice,'Value');
[p_boundingBoxFunctions, ~, ~]=fileparts(which('computeMouseBox')); % find the folder containing BoundingBoxOptions.mat
load([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'ComputeMouseBox_cmd_string','ComputeMouseBox_option'); % load bounding box option information
if iscell(ComputeMouseBox_cmd_string{bb_choice})
    cpp = true;
    cpp_config_file = fullfile(handles.root_path,'auxiliary_functions','cpp',ComputeMouseBox_cmd_string{bb_choice}{2});
else
    cpp = false;
end

% Checking which side the mouse faces:
switch handles.MouseOrientation.Value
    case 2
        handles.data.flip = 'LR';
    case 3
        handles.data.flip = false;
    case 4
        handles.data.flip = true;
end

successful_tracking = true(1,Nfiles);

if cpp
    
    if (handles.MouseOrientation.Value == 1)
        error('Autodetect does not work with C++!');
    end
    
    % CPP code:
    data = handles.data;
    root_path = handles.root_path;
    overwrite_results = handles.checkbox_overwrite_results;
    export_figures = handles.checkbox_ExpFigures.Value;
    model = handles.model;
    for i_files = 1:Nfiles
        file_name = char(strtrim(file_list{i_files}));
        successful_tracking(i_files) = track_MATLB_CPP(data, model,model_file, calibration_file, root_path, file_name, output_fun, output_path, bkg_fun, overwrite_results, export_figures,[], cpp, cpp_config_file);
    end
else
    % MATLAB code:
    for i_files = 1:Nfiles
        file_name = char(strtrim(file_list{i_files}));
        successful_tracking(i_files) = track_MATLB_CPP(handles.data,handles.model,model_file,calibration_file, handles.root_path,file_name, output_fun, output_path, bkg_fun, handles.checkbox_overwrite_results,  handles.checkbox_ExpFigures.Value, handles.BoundingBox_choice.Value, cpp, '');
    end
end
fprintf('%d out of %d files correctly processed.\n',sum(successful_tracking),Nfiles);
fprintf('Total run time: ');
disp(datestr(datenum(0,0,0,0,0,toc(total_time)),'HH:MM:SS'))
disp('------------------[Tracking END]----');
set(handles.disable_with_start,'Enable','on');
set(handles.enable_with_start,'Enable','off');
                                                                                                    
function successful_tracking = track_MATLB_CPP(data, model,model_file, calibration_file, root_path, file_name,output_fun, output_path, bkg_fun, checkbox_overwrite_results,export_figures,bounding_box_choice,cpp,cpp_config_file)
try
    successful_tracking = true;
    % Going over the file list:
    % file_name = char(strtrim(file_list{i_files}));
    [~,trial_name,~] = fileparts(file_name);
    [out_path_data,out_path_image] = feval(output_fun,output_path,file_name);
    
    data_file_name = fullfile(out_path_data,[trial_name '.mat']);
    image_file_name = fullfile(out_path_image,[trial_name '.png']);
    %clear trial_name;
    
    % Check if data folder exists:
    if ~exist(out_path_data,'dir')
        mkdir(out_path_data);
    end
    % Check if image folder exists:
    if ~exist(out_path_image,'dir')
        mkdir(out_path_image);
    end
    
    if get(checkbox_overwrite_results,'Value') || ...
            (~exist(data_file_name,'file') && ~exist(image_file_name,'file'))
        % If not overwriting results, checking if files exist.
        bkg_file = feval(bkg_fun,file_name);
        if isempty(bkg_file)
            bkg_file = 'compute';
        end
        
        % Attempting to track:
            current_file_time = tic;
            fprintf('Tracking %s ...\n',file_name)
            data.bkg = bkg_file;
            data.vid = file_name;
               
        if cpp
            if ispc
                cpp_exect = fullfile(root_path,'auxiliary_functions','cpp','Locomouse.exe');
                calib = rmfield(data,{'vid','bkg','flip'});
                [final_tracks_c, tracks_tail_c,data,debug] = locomouse_tracker_cpp_wrapper(data,root_path,model, calib, data.flip, model_file, calibration_file, cpp_exect, cpp_config_file, output_path);
            else
                error('Only windows is supported so far. Compile the C++ code in the current platform and insert the call here.');
            end
         else
            [final_tracks_c,tracks_tail_c,data,debug] = MTF_rawdata(data, model, bounding_box_choice);
        end
       
        [final_tracks,tracks_tail] = convertTracksToUnconstrainedView(final_tracks_c,tracks_tail_c,size(data.ind_warp_mapping),data.ind_warp_mapping,data.flip,data.scale);
        
        % Saving tracking data:
        save(data_file_name,'final_tracks','tracks_tail','final_tracks_c','tracks_tail_c','debug','data');
        
        % Saving data plot figures
        if export_figures
            MTF_export_figures(final_tracks_c, tracks_tail_c, data_file_name, data);
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
            fprintf('WARNING: Outdated fieldname "mirror_line" should be renamed to "split_line".')
            disp(full_file_path);
        end
        if ~isfield(data,'scale')
            data.scale = 1;
        end
        handles.data = data;
    end
    
catch load_error
    fprintf('Error: Could not load %s with MATLAB.\n',full_file_path);
    disp(getReport(load_error.message,'extended'));
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
    handles.pushbutton_cluster];
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
        db_file_path = fullfile(handles.root_path,'model_files',load_file);
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
        db_file_path = fullfile(handles.root_path,'calibration_files',load_file);
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

%%FIXME: Where could we configure the cluster folders?
locomouse_cpp_cluster_root = '/mirror/LocoMouse_cpp';
locomouse_cpp_models = fullfile(locomouse_cpp_cluster_root, 'model_files');
locomouse_cpp_calibration = fullfile(locomouse_cpp_cluster_root, 'calibration_files');
locomouse_cpp_config = fullfile(locomouse_cpp_cluster_root, 'configuration_files');
job_name = 'test_cluster_job';

if ~exist('/mirror/','dir')
%     error('Could not find the /mirror/ directory. Exporting to the cluster must be done from the cluster master node only!');
end
file_list = get(handles.listbox_files,'String');

% Calibration file;
calibration_file_pos = get(handles.popupmenu_calibration_files,'Value');
calibration_file = get(handles.popupmenu_calibration_files,'String');
calibration_file = calibration_file{calibration_file_pos};

% Model file:
model_file_pos = get(handles.popupmenu_model,'Value');
model_file = get(handles.popupmenu_model,'String');
model_file = model_file{model_file_pos};

model_file_yml = fullfile(locomouse_cpp_models);
calibration_file_yml = fullfile(locomouse_cpp_calibration);

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
        success = copyfile(calibration_file_yml_matlab,model_file_yml);
        if ~success
%             error('Error copying calibration yml file. Check for writing permissions!');
        end
    else
        handles = loadCalibrationFile(fullfile(handles.root_path,'calibration_files',[calibration_file '.mat']),handles);
        exportLocoMouseModelToOpenCV(model_file_yml,rmfield(handles.data,{'vid','bkg','flip'}));
    end
end

% Output and background functions:
bkg_mode = get(handles.popupmenu_background_mode,'Value');
output_mode = get(handles.popupmenu_output_mode,'Value');

bkg_fun = get(handles.popupmenu_background_mode,'String');
bkg_fun = bkg_fun{bkg_mode};

output_fun = get(handles.popupmenu_output_mode,'String');
output_fun = output_fun{output_mode};

% Reading output path:
output_path = get(handles.edit_output_path,'String');

% Checking which side the mouse faces:
switch handles.MouseOrientation.Value
    case 2
        flip_char = 'LR';
    case 3
        flip_char = 'R';
    case 4
        flip_char = 'L';
end

% Checking C++ locomouse mode: [joaofayad]
bb_choice = get(handles.BoundingBox_choice,'Value');
[p_boundingBoxFunctions, ~, ~]=fileparts(which('computeMouseBox')); % find the folder containing BoundingBoxOptions.mat
load([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'ComputeMouseBox_cmd_string','ComputeMouseBox_option'); % load bounding box option information
if iscell(ComputeMouseBox_cmd_string{bb_choice})
    cpp_config_file = fullfile(locomouse_cpp_config,ComputeMouseBox_cmd_string{bb_choice}{2});
else
    error('The cluster can only run the C++ version of the code.');
end

disp('----------------[Submitting job to cluster]----');
SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat');

% Create a job
openLavaJobArray(job_name, file_list, bkg_fun, flip_char, config_file, model_file_yml, calibration_file_yml);

function [] = openLavaJobArray(job_name, file_list, bkg_fun, flip_char, config_file, model_file, calibration_file, video_files, bkg_files, side_chars)

% Generate a file with the videos
[video_files, bkg_files, side_chars] = filesForOpenLavaJob(job_name, file_list, bkg_fun, flip_char);

job_fid = fopen(sprintf('%s.job',job_name),'w');

fprintf(job_fid,'#BSUB -o %s.out\n',job_name);
fprintf(job_fid,'#BSUB -e %s.err\n',job_name);
fprintf(job_fid,'#!/bin/bash\n');
fprintf(job_fid,'#echo $LSB_JOBINDEX\n');
fprintf(job_fid,'file_name=$(sed "${LSB_JOBINDEX}q;d" %s)',video_files);
fprintf(job_fid,'bkg_name=$(sed "${LSB_JOBINDEX}q;d" %s)', bkg_files);
fprintf(job_fid,'side_char=$(sed "$(LSB_JOBINDEX}q;d" %s)',side_chars);
fprintf(job_fid,'echo "$file_name"\n');
fprintf(job_fid,'./LocoMouse %s ${file_name} ${bkg_name} %s %s ${side_char}',config_file,model_file,calibration_file);


%%% Printing files necessary for cluster job
function [] = filesForOpenLavaJob(job_name, file_list, bkg_fun, char_flip)
%time = fix(clock);
job_dir = fullfile('/mirror',job_name);
if ~exist(job_dir,'dir')
    mkdir(job_dir);
end

video_files = fullfile(job_dir,fprintf('%s_video_list',job_name));
bkg_files = fullfile(job_dir,fprintf('%s_bkg_list',job_name));
side_chars = fullfile(job_dir,fprintf('%s_side_list',job_name));

videos_fid = fopen(video_files,'w');
bkg_fid = fopen(bkg_files,'w');
side_fid = fopen(side_chars,'w');

if any([videos_fid, bkg_fid, side_fid] < 0)
    error('Could not create the auxiliary files for the openlava job. Check writing permissions!');
end

cleanfid = onCleanup(@()(fclose([videos_fid bkg_fid side_fid])));

for i_files = 1:length(file_list)
    fprintf(videos_fid,file_list{i_files});
    
    feval(bkg_fun,file_list{i_files});
    fprintf(bkg_fid,bkg_file);
    
    % Compute side from file name:
    if length(char_flip) > 1
        fprintf(side_fid,file_list{i_files}(end-4));
    else
        fprintf(side_fid,char_flip);
    end
end









