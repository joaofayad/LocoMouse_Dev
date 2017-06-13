classdef (Sealed) LocoMouse_GUI < handle
    properties (Access = private)
        % User defined values for appearance:
        default_height = 20
        default_padding = 10
        default_spacing = 5
        
        root_path % Path where the GUI files are stored
        current_path % Current path for file browsing
        
        % Supported VideoReader parameters:
        N_supported_files
        N_supported_files_menu
        supported_files
        
        % Layout variables:
        layout = struct()
        
        % The GUI directory structure:
        directories = {...
            'calibration_files',...
            'model_files',...
            'background_parse_functions',...
            'output_parse_functions',...
            fullfile('auxiliary_functions','cpp'),...
            'boundingBoxFunctions',...
            'GUI_Settings'}
        
        field_names = {...
            'calibration_path',...
            'model_path',...
            'background_parse_path',...
            'output_parse_path',...
            'cpp_root_path',...
            'bounding_box_path',...
            'settings_path'}
        
        
        % Directory structure:
        calibration_path
        model_path
        background_parse_path
        output_parse_path
        cpp_root_path
        bounding_box_path
        settings_path
        
        % uicontrols
        popupmenu_output_mode
        popupmenu_background
        popupmenu_calibration
        popupmenu_model
        edit_output_path
        popupmenu_mouse_side
        popupmenu_parameters
        checkbox_overwrite
        checkbox_save_figures
        toggle_startstop
        
        listbox_videos
        listbox_menu
        listbox_menu_options = zeros(1,5);
        
        % GUI Menus
        file_menu
        file_menu_options = zeros(1,4);
        settings_menu
        
        % Freezing GUI:
        old_pointer = 'arrow'
        handles_to_enable
        
        % Tracking
        data = struct()
        compute = true
        
    end
    
    properties (Access = protected)
        % Main window:
        Window
        
    end
    
    methods (Access = public)
        
        function gui = LocoMouse_GUI()
            % Class constructor: Initializes GUI layout and validates GUI
            % install dir.
            try
                gui.Window = figure(...
                    'Name','LocoMouse_Traker',...
                    'NumberTitle', 'off', ...
                    'MenuBar', 'none', ...
                    'Toolbar', 'none', ...
                    'HandleVisibility', 'off',...
                    'closeRequestFcn',{@closeGUI,gui});
                
                gui.validateDirStructure();
                gui.validateVideoReader();
                gui.createLayout();
                gui.populateOptions();
                loadRecoverySettings(gui)
                
                clear gui;
                
            catch construction_error
                if isvalid(gui.Window)
                    close(gui.Window)
                end
                rethrow(construction_error);
            end
        end
        
        function compute = Compute(gui)
            compute =  gui.compute;
        end
        
    end
    
    methods (Access = protected)
        
        validateDirStructure(gui)
        
        validateVideoReader(gui)
        
        createLayout(gui)
        
        %createMenus(gui)
        
        populateOptions(gui)
        
        loadRecoverySettings(gui)
        
        waitForProcess(gui,state)
        
        saveSettings(gui, file_name)
        
        loadSettings(gui, file_name)
       
        track(gui)
        
        function [] = ErrorMsg(gui, MException_var, error_template, error_contents)
            % Prevents GUI from crashing, displaying error messages.
            % MException_var: error info returned by catch
            % error_template: A string template with C-style placeholders
            % (e.g. %s, %d).
            % error_contents: A Cell with the values for the
            % placeholders in error_template.
            
            if ~iscell(error_contents)
                error_contents = {error_contents};
            end
            
            gui.waitForProcess('on');
            fprintf([error_template '\n'], error_contents{:});
            error_report = getReport(MException_var,'extended');
            disp(error_report);
            
        end
        
        
    end
end


function [] = closeGUI(~, ~, gui)
    try 
        gui.saveSettings(fullfile(gui.settings_path,'GUI_Recovery_Settings_v2.mat'));
    catch error_close_gui
        gui.ErrorMsg(error_close_gui,'Error closing GUI, could not save settings.',[]);
    end
    
    delete(gui.Window);
    gui.delete();
    clear gui
end


