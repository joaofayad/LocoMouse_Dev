function [] = populateOptions(gui)
    % Lists the existing option files for the listbox menus;
    
    file_types = {'*.mat','*.mat','*.m','*.m'};
    popupmenu_handles = {...
        gui.popupmenu_calibration,...
        gui.popupmenu_model,...
        gui.popupmenu_background,...
        gui.popupmenu_output_mode};
    
    dir_paths = {...
        gui.calibration_path,...
        gui.model_path,...
        gui.background_parse_path,...
        gui.output_parse_path};
    
    for i_set = 1:length(file_types)
        readOptionList(...
            dir_paths{i_set},...
            file_types{i_set},...
            popupmenu_handles{i_set});
    end
    
    % Mouse side orientation:
    mouse_side_options = {...
        'auto detect orientation',...
        'L/R filename convention',...
        'mouse faces right',...
        'mouse faces left'};
    
    set(gui.popupmenu_mouse_side,...
        'String',mouse_side_options);
    
    % Output path:
    set(gui.edit_output_path,'String',gui.current_path);
    
    % Settings:
    bb_settings = load(...
        fullfile(gui.bounding_box_path,'BoundingBoxOptions.mat'),...
        'ComputeMouseBox_option');
    
    set(gui.popupmenu_parameters,...
        'String',bb_settings.ComputeMouseBox_option);
    
end

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
    set(menu_handle,'String',file_list);
    
end