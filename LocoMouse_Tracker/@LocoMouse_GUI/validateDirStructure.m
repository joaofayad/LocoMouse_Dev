function [] = validateDirStructure(gui)
% Validate GUI install directory structure:

gui.root_path = fullfile(fileparts([mfilename('fullpath'),'*.m']),'..');
gui.current_path = gui.root_path;

N_directories = length(gui.directories);
N_field_names = length(gui.field_names);

if (N_directories ~= N_field_names)
    error('Directory structure was not setup properly! Adjust class definition.');
end

for i_set = 1:length(gui.directories)
    [success, dir_path] = validatePath(gui.field_names{i_set}, gui.directories{i_set});
    
    if ~success
        error('%s does not exist! The LocoMouse_GUI structure is not setup properly.',dir_path);
    end
end

    function [success,dir_path] = validatePath(input_field_name, input_path)
        % Makes sure a crucial path exist.
        success = true;
        dir_path = fullfile(gui.root_path,input_path,filesep);
        if ~exist(dir_path, 'dir')
            success = false;
        else
            gui.(input_field_name) = dir_path;
        end
        
        
    end

end