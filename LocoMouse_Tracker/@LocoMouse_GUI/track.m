function [] = track(gui)
    % Reading the Settings from the GUI and calling the actual tracking
    % function.
    try
    disp('----------------[Tracking START]----');
    %SaveSettings_Callback(hObject, eventdata, handles, 'GUI_Recovery_Settings.mat');
    gui.saveSettings(fullfile(gui.root_path,'GUI_Settings','GUI_Recovery_Settigns.mat'));
    
    [video_list, Nfiles] = getVideoList(gui);
    
    calibration_file = getCalibration(gui);
    
    % Model file:
    model_file = getModel(gui);
    
    % Output and background functions:
    bkg_fun = getFileName(gui.popupmenu_background);
    output_fun = getFileName(gui.popupmenu_output_mode);
    
    % Reading output path:
    output_path = get(gui.edit_output_path,'String');
    
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
    bb_choice = get(gui.popupmenu_parameters,'Value');
    [p_boundingBoxFunctions, ~, ~] = fileparts(which('computeMouseBox')); % find the folder containing BoundingBoxOptions.mat
    load([p_boundingBoxFunctions,filesep,'BoundingBoxOptions.mat'],'ComputeMouseBox_cmd_string','ComputeMouseBox_option'); % load bounding box option information
    if iscell(ComputeMouseBox_cmd_string{bb_choice})
        cpp = true;
        cpp_config_file = fullfile(gui.cpp_root_path,ComputeMouseBox_cmd_string{bb_choice}{2});
    else
        cpp = false;
    end
    
    %%% FIXME: Function should be defined when the popupmenu is defined.
    % Checking which side the mouse faces:
    switch gui.popupmenu_mouse_side.Value
        case 2
            gui.data.flip = 'LR';
        case 3
            gui.data.flip = false;
        case 4
            gui.data.flip = true;
    end
    
    successful_tracking = true(1,Nfiles);
    
    if cpp
        
        if (gui.popupmenu_mouse_side.Value == 1)
            error('Autodetect does not work with C++!');
        end
        
        % CPP code:
        data = handles.data;
        root_path = handles.root_path;
        overwrite_results = handles.checkbox_overwrite_results;
        export_figures = handles.checkbox_ExpFigures.Value;
        model = handles.model;
        parfor i_files = 1:Nfiles
            file_name = char(strtrim(video_list{i_files}));
            successful_tracking(i_files) = track_MATLB_CPP(data, model,model_file, calibration_file, root_path, file_name, output_fun, output_path, bkg_fun, overwrite_results, export_figures,[], cpp, cpp_config_file);
        end
    else
        % MATLAB code:
        for i_files = 1:Nfiles
            if ~gui.Compute()
                error('FDX');
            end
            file_name = char(strtrim(video_list{i_files}));
            successful_tracking(i_files) = track_MATLB_CPP(gui.data,gui.data.model,model_file,calibration_file, gui.root_path,file_name, output_fun, output_path, bkg_fun, gui.checkbox_overwrite,  gui.checkbox_save_figures.Value, gui.popupmenu_parameters.Value, cpp, '', gui);
        end
    end
    
    fprintf('%d out of %d files correctly processed.\n',sum(successful_tracking),Nfiles);
    fprintf('Total run time: ');
    disp(datestr(datenum(0,0,0,0,0,toc(total_time)),'HH:MM:SS'))
    disp('------------------[Tracking END]----');
    catch error_msg
        gui.ErrorMsg(error_msg, 'Failed to initialize Tracking',[]);
    end
    
    
end

function successful_tracking = track_MATLB_CPP(data, model,model_file, calibration_file, root_path, file_name,output_fun, output_path, bkg_fun, checkbox_overwrite_results,export_figures,bounding_box_choice,cpp,cpp_config_file, gui)
    try
        
        if ~exist('gui','var')
            gui.compute = true;
        end
           
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
                [final_tracks_c,tracks_tail_c,data,debug] = MTF_rawdata(data, model, bounding_box_choice, gui);
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
        disp('----------------------');
        gui.ErrorMsg(tracking_error,'Failed to track file %s.',data.vid);
        disp('----------------------');
        successful_tracking = false;
    end
end


function [video_list, Nfiles] = getVideoList(gui)
    % Gets the video_list as a cell of string.
    
    tvideo_list = get(gui.listbox_videos,'String');
    video_list = cell(size(tvideo_list,1),1);
    for tfl_i = 1:size(tvideo_list,1)
        video_list{tfl_i} = strtrim(tvideo_list(tfl_i,:));
    end
    Nfiles = size(video_list,1);
    
end

function file_name = getFileName(handle)
    
    pos = get(handle,'Value');
    list = get(handle,'String');
    file_name = list{pos};
    
end

function calibration_file = getCalibration(gui)
    % Loads the calibration settings
    calibration_file = getFileName(gui.popupmenu_calibration);
    calibration_file = fullfile(gui.calibration_path,[calibration_file '.mat']);
    
    loadCalibrationFile(calibration_file, gui);
    
    
end

function loadCalibrationFile(full_file_path, gui)
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
        gui.data = data;
    end
    
    % Setting the old or new string according to how the computations went:
    % set(handles.edit_output_path,'String',get(handles.figure1,'UserData'));
end

function model_file = getModel(gui)
    % Model file:
    model_file = getFileName(gui.popupmenu_model);
    model_file = fullfile(gui.model_path,[model_file '.mat']);
    
    loadModel(model_file,gui);
end

function loadModel(full_file_path, gui)
    model = load(full_file_path);
    % Since there is no model file type we must check we have all the right
    % fields:
    if isfield(model,'model')
        model = model.model;
    end
    ModelFieldNames      = fieldnames(model);
    ExpectedModel        = [{'line'}  {'tail'} ; ...
        {'point'} {'paw'} ; ...
        {'point'} {'snout'}];
    
    failed = false;
    if ~any(ismember(ModelFieldNames,'line')) || ~any(ismember(ModelFieldNames,'point'))
        for emt = 1:size(ExpectedModel,1)
            if any(ismember(ModelFieldNames,ExpectedModel(emt,2)))
                if any(ismember(fieldnames(eval(['model.' char(ExpectedModel(emt,2))])),'w')) && any(ismember(fieldnames(eval(['model.' char(ExpectedModel(emt,2))])),'rho'))
                    eval(['model.',char(ExpectedModel(emt,1)),'.',char(ExpectedModel(emt,2)),' = model.',char(ExpectedModel(emt,2)),';']);
                else
                    failed = true;
                end
            else
                failed = true;
            end
            
        end
    end
    if failed
        error('LocoMouse_Tracker() / loadModel() :: Model file useless.')
    else
        if ~isfield(model.point.paw,'N_points')
            model.point.paw.N_points =4;
        end
        if ~isfield(model.point.snout,'N_points')
            model.point.snout.N_points =1;
        end
        gui.data.model = model;
    end
end