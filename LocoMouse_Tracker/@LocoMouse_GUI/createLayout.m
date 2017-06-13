function [] = createLayout(gui)
    % Design of the GUI Layout
    
    % Main box that holds the two vertical layouts:
    gui.layout.main = uix.HBox('Parent',gui.Window);
    
    % Two vertical Layouts
    gui.layout.settings = uix.VBox(...
        'Parent',gui.layout.main,...
        'Padding', gui.default_padding,...
        'Spacing', gui.default_spacing);
    
    gui.layout.text = uix.VBox(...
        'Parent',gui.layout.main,...
        'Padding', gui.default_padding,...
        'Spacing', gui.default_spacing);
    
    % Create Each of the layout columns:
    createFirstColumn();
    
    createSecondColumn();
    
    % Adjustig the widhts:
    %%% FIXME: not sure if adding padding*2 was a chance hack or is actually
    %%% what is happening. [joaofayad]
    N_subcolumns = length(gui.layout.settings_grid.Widths);
    first_column_width = ...
        sum(gui.layout.settings_grid.Widths) + ...
        gui.layout.settings_grid.Spacing * (N_subcolumns-1) + ...
        gui.layout.settings.Padding*2;
    
    gui.layout.main.Widths = [first_column_width -1];
    
    % Create Window Menus:
    createMenus();
    
    return;
    
    %% Auxiliary functions:
    
    % ==== Layout for the first column:
    function [] = createFirstColumn()
        % The first column of the GUI is a combination of a grid and other
        % uicontrols outside of the grid:
        
        % The Grid:
        gui.layout.settings_grid = uix.Grid(...
            'Parent',gui.layout.settings,...
            'Spacing', gui.default_spacing);
        
        N_controls_per_column = 10;
        
        % First Column
        uicontrol(gui.layout.settings_grid,...
            'Style','text',...
            'String','Output Mode:',...
            'HorizontalAlignment','Left');
        
        gui.popupmenu_output_mode = uicontrol(gui.layout.settings_grid,...
            'Style','popupmenu',...
            'String',{' '});
        
        uicontrol(gui.layout.settings_grid,...
            'Style','text',...
            'String','Background Mode:',...
            'HorizontalAlignment','Left');
        
        gui.popupmenu_background = uicontrol(gui.layout.settings_grid,...
            'Style','popupmenu',...
            'String',{' '});
        
        uicontrol(gui.layout.settings_grid,...
            'Style','text',...
            'String','Calibration File:',...
            'HorizontalAlignment','Left');
        
        gui.popupmenu_calibration = uicontrol(gui.layout.settings_grid,...
            'Style','popupmenu',...
            'String',{' '});
        
        uicontrol(gui.layout.settings_grid,...
            'Style','text',...
            'String','Model:',...
            'HorizontalAlignment','Left');
        
        gui.popupmenu_model = uicontrol(gui.layout.settings_grid,...
            'Style','popupmenu',...
            'String',{' '});
        
        uicontrol(gui.layout.settings_grid,...
            'Style','text',...
            'String','Output Path:',...
            'HorizontalAlignment','Left');
        
        gui.edit_output_path = uicontrol(gui.layout.settings_grid,...
            'Style','Edit',...
            'String','');
        
        % Second Column:
        uix.Empty('Parent',gui.layout.settings_grid);
        
        uicontrol(gui.layout.settings_grid,...
            'Style','Pushbutton',...
            'String','Add',...
            'CallBack',{...
            @pushbutton_AddFiles,...
            gui,...
            gui.popupmenu_output_mode,...
            '*.m',...
            'Choose M-File that parses the input file name and generates an output file name',...
            gui.output_parse_path});
        
        uix.Empty('Parent',gui.layout.settings_grid);
        
        uicontrol(gui.layout.settings_grid,...
            'Style','Pushbutton',...
            'String','Add',...
            'CallBack', {...
            @pushbutton_AddFiles,...
            gui,...
            gui.popupmenu_background,...
            '*.m',...
            'Choose M-File that parses the input file name and generates an background file name',...
            gui.background_parse_path});
        
        uix.Empty('Parent',gui.layout.settings_grid);
        
        uicontrol(gui.layout.settings_grid,...
            'Style','Pushbutton',...
            'String','Add',...
            'CallBack',{...
            @pushbutton_AddFiles,...
            gui,...
            gui.popupmenu_calibration,...
            '*.mat',...
            'Choose MAT-File with the Calibration parameters',...
            gui.calibration_path});
        
        uix.Empty('Parent',gui.layout.settings_grid);
        uicontrol(gui.layout.settings_grid,...
            'Style','Pushbutton',...
            'String','Add',...
            'CallBack',{...
            @pushbutton_AddFiles,...
            gui,...
            gui.popupmenu_model,...
            '*.mat',...
            'Choose MAT-File with the Model parameters',...
            gui.model_path});
        
        uix.Empty('Parent',gui.layout.settings_grid);
        uicontrol(gui.layout.settings_grid,...
            'Style','Pushbutton',...
            'String','Browse',...
            'CallBack',{@pushbutton_BrowseFiles, gui});
        
        % Defining column widths:
        set(gui.layout.settings_grid,...
            'Widths',[8 3]*gui.default_height);
        
        % Remaining Controls outside of grid:
        uicontrol(gui.layout.settings,...
            'Style','text',...
            'String','Mouse Orientation:',...
            'HorizontalAlignment','Left');
        
        %%% FIXME: Ideally the tracking function should already take as
        %%% input what to do regarding mouse side given the GUI selection.
        %%% Plus that should not dependd in any way from the implementation
        %%% of these options in the GUI. Make a callback for the popupmenu
        %%% or a method for the gui class that simply returns the boolean
        %%% to whether flip the mouse or not to the tracking function.
        mouse_side_options = {...
        'auto detect orientation',...
        'L/R filename convention',...
        'mouse faces right',...
        'mouse faces left'};
        
        gui.popupmenu_mouse_side = uicontrol(gui.layout.settings,...
            'Style','popupmenu',...
            'String',mouse_side_options);
           
        
        uicontrol(gui.layout.settings,...
            'Style','text',...
            'String','Parameter Settings:',...
            'HorizontalAlignment','Left');
        
        gui.popupmenu_parameters = uicontrol(gui.layout.settings,...
            'Style','popupmenu',...
            'String',{' '});
        
        gui.checkbox_overwrite = uicontrol(gui.layout.settings,...
            'Style','checkbox',...
            'String','Overwrite existing resutls',...
            'Value',0);
        
        gui.checkbox_save_figures = uicontrol(gui.layout.settings,...
            'Style','checkbox',...
            'String','Save data figures',...
            'Value',0);
        
        gui.toggle_startstop = uicontrol(gui.layout.settings,...
            'Style','Toggle Button',...
            'String','Start',...
            'Enable','off',...
            'Callback',{@toggle_StartStop, gui});
        
        % Adjusting heights: After defining all controls make sure the
        % heights are properly set so the GUI is useful.
        gui.layout.settings.Heights(1) = ...
            N_controls_per_column * gui.default_height + ...
            (N_controls_per_column - 1) * gui.default_spacing;
        
        gui.layout.settings.Heights(2:end) = gui.default_height;
        
        %%% FIXME: As heights were modified manually we must modify the height of
        %%% the figure to guarantee all buttons are visible. Check the y coordinate
        %%% of the last uicontrol to be put on the window.
        if (gui.toggle_startstop.Position(2) < gui.default_padding +1)
            
            gui.Window.Position(4) = ...
                gui.Window.Position(4) + ...
                gui.default_padding + ...
                1- gui.toggle_startstop.Position(2);
            
        end
        
    end
    
    % === Layout for the second column:
    function [] = createSecondColumn()
        gui.listbox_videos = uicontrol(gui.layout.text,...
            'Style','Listbox',...
            'Min',0,...
            'Max',2,...
            'Enable','off');
        
        % Create the menu properties:
        N_properties = 5;
        gui.listbox_menu = uicontextmenu('Parent',gui.Window);
        
        gui.listbox_menu_options = zeros(1,N_properties);
        
        gui.listbox_menu_options(1) = uimenu(gui.listbox_menu,...
            'Label','Add File',...
            'Callback',{@menu_AddFile, gui});
        
        gui.listbox_menu_options(2) = uimenu(gui.listbox_menu,...
            'Label','Add Directory',...
            'Callback',{@menu_AddFolders,gui, false});
        
        gui.listbox_menu_options(3) = uimenu(gui.listbox_menu,...
            'Label','Add Directory with Sub-Directories',...
            'Callback',{@menu_AddFolders,gui, true});
        
        gui.listbox_menu_options(4) = uimenu(gui.listbox_menu,...
            'Label','Remove',...
            'Separator','on',...
            'Enable','off',...
            'Callback',{@menu_RemoveFile, gui});
        
        gui.listbox_menu_options(5) = uimenu(gui.listbox_menu,...
            'Label','Clear',...
            'Enable','off',...
            'Callback',{@menu_Clear, gui});
        
        set(gui.listbox_videos,'UIContextMenu',gui.listbox_menu);
        
        gui.listbox_videos.addlistener('String',...
            'PostSet',@listbox_post);
        
        function [] = listbox_post(~, ~)
            % listbox PostSet callback
            if isempty(gui.listbox_videos.String) && strcmpi(gui.listbox_videos.Enable,'on')
                set([gui.listbox_videos, gui.toggle_startstop, gui.listbox_menu_options(4:5) gui.file_menu_options(4)],'Enable','off');
                return;
            end
            
            if ~isempty(gui.listbox_videos.String) && strcmpi(gui.listbox_videos.Enable,'off')
                set([gui.listbox_videos, gui.toggle_startstop, gui.listbox_menu_options(4:5) gui.file_menu_options(4)],'Enable','on');
                return;
            end
        end
        
    end
    
    % === Layout of the figure Menus:
    function [] = createMenus()
        gui.file_menu = uimenu(gui.Window,'Label','File');
        gui.file_menu_options = zeros(1,4);
        gui.file_menu_options(1) = uimenu(gui.file_menu,...
            'Label','Add File',...
            'Accelerator','F',...
            'CallBack',{@menu_AddFile, gui});
        
        gui.file_menu_options(2) = uimenu(gui.file_menu,...
            'Label','Add Directory',...
            'Separator','on',...
            'Accelerator','D',...
            'CallBack',{@menu_AddFolders, false});
        
        gui.file_menu_options(3) = uimenu(gui.file_menu,...
            'Label','Add Directory with Sub-Directories',...
            'Accelerator','W',...
            'CallBack',{@menu_AddFolders, true});
        
        gui.file_menu_options(4) = uimenu(gui.file_menu,...
            'Label','Clear List',...
            'Separator','on',...
            'Accelerator','R',...
            'Enable','off',...
            'CallBack',{@menu_Clear, gui});
        
        gui.settings_menu = uimenu(gui.Window,'Label','Settings');
        
        uimenu(gui.settings_menu,...
            'Label','Save Settings',...
            'CallBack',{@menu_SaveSettings, gui});
        
        uimenu(gui.settings_menu,...
            'Label','Load Settings',...
            'CallBack',{@menu_LoadSettings,gui});
    end
    
    
end

%% CallBacks used by the GUI controls:

% === PushButton CallBacks:
function [] = pushbutton_AddFiles(~, ~, gui, popup_menu, file_type, message, out_dir)
    
    start_path = fullfile(gui.current_path,file_type);
    
    [load_file, load_path] = uigetfile(start_path, message);
    
    if ischar(load_file)
        
        % Check if file already exists:
        list = get(popup_menu,'String');
        [~,fname,~] = fileparts(load_file);
        already_on_list = strcmpi(fname,list);
        
        if any(already_on_list)
            N = find(already_on_list);
            set(popup_menu,'Value',N);
            warning('%s is already on the list!\n',fname);
        else
            file_path = fullfile(load_path, load_file);
            success = copyfile(file_path, out_dir);
            if ~success
                error('Could not copy %s to local folder!\n',file_path)
            else
                % Refresh the popup list:
                list{length(list)+1} = fname;
            end
            set(popup_menu,'String',list);
            set(popup_menu,'Value',length(list));
        end
    end
    
    gui.current_path = load_path;
    
end

function [] = pushbutton_BrowseFiles(~, ~, gui)
    out_path = uigetdir(get(gui.edit_output_path,'String'));
    if ischar(out_path)
        set(gui.edit_output_path,'String',out_path);
    end
end

% === Toggle CallBacks:
function [] = toggle_StartStop(~, ~, gui)
    
    if gui.toggle_startstop.Value
        % Updating the GUI
        gui.toggle_startstop.String = 'Stop';
        gui.waitForProcess('off');
        gui.Window.Pointer = gui.old_pointer;
        gui.toggle_startstop.Enable = 'on';
        drawnow;
        
        % Pre-process the tracking
        gui.compute = true;
        gui.track();
        gui.waitForProcess('on');
        gui.toggle_startstop.String = 'Start';
        
    else
        gui.compute = false;
        gui.toggle_startstop.String = 'Start';
        gui.waitForProcess('on');
        drawnow;
    end
    
    
end

% === Menu CallBacks:
function [] = menu_AddFile(~,~,gui)
    % Callback to add selected files to the GUI
    
    try
        [chosen_file,chosen_path] = uigetfile(gui.supported_files,...
            'Choose supported video file',gui.current_path,...
            'Multiselect','on');
        
        if ischar(chosen_path)
            gui.current_path = chosen_path;
            
            if ischar(chosen_file)
                chosen_file = {chosen_file};
            end
            
            file_path = cellfun(@(x)(fullfile(chosen_path,x)),...
                chosen_file,...
                'un',false);
            
            file_path = char(file_path');
            
            addVideoFiles(file_path, gui);
        end
        
    catch error_struct
        ErrorMsg(gui, error_struct,sprintf('Failed to add video %s', file_path));
    end
    
    %         waitForProcess(handles,'on',values);
end

function [] = menu_AddFolders(~, ~, gui, with_sub_folders)
    % Callback to add files contained in selected folders to the GUI.
   gui.waitForProcess('off');
    
    try
        
        chosen_dir = uigetdir(gui.current_path,...
            'Choose directory with supported video files');
        
        if ischar(chosen_dir)% Valid dir selection.
            gui.current_path = chosen_dir;
            addVideoDir(gui, chosen_dir, with_sub_folders);
        end
        
    catch error_structure
        
        gui.ErrorMsg(gui, error_structure, 'Failed to add videos on dir %s', {chosen_dir});
        
    end
    
    % Enable the GUI:
    gui.waitForProcess('on');
end

function [] = menu_RemoveFile(~, ~, gui)
    % Callback to remove selected files from the GUI
    current_list = get(gui.listbox_videos,'String');
    current_pos = get(gui.listbox_videos,'Value');
    current_list(current_pos,:) = [];
    N_files = size(current_list,1);
    current_pos = min(max(current_pos(1) - 1,1), N_files);
    
    %         if N_files  == 0
    %             % If list is empty disable the list and the remove button:
    %             handles = changeGUIEnableStatus(handles,'off');
    %         else
    
    set(gui.listbox_videos,'String',current_list);
    set(gui.listbox_videos,'Value',current_pos);
end

function [] = menu_Clear(~, ~, gui)
    % Callback to clear all the files added to the GUI.
    
    set(gui.listbox_videos,'String',{});
    %         handles = changeGUIEnableStatus(handles,'off');
end


function menu_LoadSettings(~, ~, gui)
    
    [L_filename, L_path] = uigetfile(fullfile(gui.settings_path,'*.mat'));
    if ~ischar(L_filename)
        return;
    end
    
    gui.loadSettings(fullfile(L_path, L_filename));
end

function menu_SaveSettings(~, ~, gui)
    
    [S_filename, S_path] = uiputfile(fullfile(gui.settings_path,'*.mat'));
    if ~ischar(S_filename)
        return;
    end
   
    gui.saveSettings(fullfile(S_path, S_filename));
end

% === Auxiliary functions:
% Auxiliaty function for adding videos:
function success = addVideoFiles(file_list, gui)
    
    N_files_in = size(file_list,1);
    success = true(1,N_files_in);
    
    for i_files = 1:N_files_in
        try
            fname = strtrim(file_list(i_files,:));
            VideoReader(fname);
            drawnow;
            
        catch error_open_file
            
            success(i_files) = false;
            ErrorMsg(gui, error_open_file,sprintf('LocoMouse_Tracker Error: Failed to add Video File %s.\nMATLAB Error Report:\n', fname));
            
        end
    end
    
    % Add files to listbox:
    if ~any(success)
        fprintf('Could not add any video files!\n');
        return;
    end
    
    file_list = file_list(success,:);
    
    current_file_list = get(gui.listbox_videos,'String');
    current_file_list = cat(1,current_file_list,{file_list});
    set(gui.listbox_videos,'String',current_file_list);
    set(gui.listbox_videos,'Value',length(current_file_list));
    
    fprintf('Added %d out of %d found video files.\n',sum(success),N_files_in);
end

function [] = addVideoDir(gui, chosen_dir, search_subdirs)
    
    % List all supported video files in such dir:
    file_list = cell(gui.N_supported_files,1);
    keep_file_type = true(1,gui.N_supported_files);
    
    if search_subdirs
        chosen_dir = fullfile(chosen_dir,'**');
    end
    
    % Starts at 2 since 1 is all files:
    for i_f = 1:gui.N_supported_files
        d = rdir(fullfile(chosen_dir,gui.supported_files{i_f + 1}));d = {d(:).name};
        file_list{i_f} = char(d'); clear d
        keep_file_type(i_f) = ~isempty(file_list{i_f});
    end
    
    if ~any(keep_file_type)
        fprintf('No supported files found in %s.\n', chosen_dir);
        return;
    end
    
    file_list = char(file_list(keep_file_type,:));
    
    % Adding the video files:
    addVideoFiles(file_list, gui);
end


