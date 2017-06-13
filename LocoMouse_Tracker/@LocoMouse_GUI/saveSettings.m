function saveSettings(gui, tsfilename)
    % Load GUI Settings.
    %
    % Original Author: Dennis Eckmeier
    % Modified by: Joao Fayad (joaofayad@gmail.com)
    
%     if isempty(tsfilename)
%         [S_filename, S_path] = uiputfile(fullfile(gui.settings_path,'*.mat'));
%         S_filename = fullfile(S_path, S_filename);
%     else
%         S_filename = tsfilename;
%     end
%     
%     if ~ischar(S_filename)
%         return;
%     end
    if isempty(tsfilename)
        return; % Warning?
    end

    if exist(tsfilename,'file')
        load(tsfilename,'t_values');
    end
    
    tfigObj =  {'checkbox_LimitWindow'; ...
        'checkbox_ShowNewLabels'; ...
        'checkbox_Show_LM_Track'; ...
        'checkbox_overwrite'; ...
        'checkbox_save_figures'; ...
        'checkbox_display_split_line'; ...
        'popupmenu_parameters'; ...
        'popupmenu_mouse_side'; ...
        'popupmenu_model'; ...
        'popupmenu_calibration'; ...
        'popupmenu_background'; ...
        'popupmenu_output_mode'; ...
        'edit_output_path'};
    
    t_values = struct();
    
    if ischar(tsfilename)
        for tfi = 1:size(tfigObj,1)
            
            if isprop(gui,tfigObj{tfi})
                
                switch gui.(tfigObj{tfi}).Style
                    case 'popupmenu'
                        t_values.(tfigObj{tfi}).String = gui.(tfigObj{tfi}).String{gui.(tfigObj{tfi}).Value};
                        
                    case 'checkbox'
                        t_values.(tfigObj{tfi}).Value     = gui.(tfigObj{tfi}).Value;
                        
                    case 'edit'
                        t_values.(tfigObj{tfi}).String = gui.(tfigObj{tfi}).String;
                        
                    otherwise
                        t_values.(tfigObj{tfi}).Value     = gui.(tfigObj{tfi}).Value;
                end
            end
        end
        save(tsfilename,'t_values'); disp(['Settings saved: ',tsfilename])
    end
end