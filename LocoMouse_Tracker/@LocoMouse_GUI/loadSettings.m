function [] = loadSettings(gui, file_name)
    % Load GUI Settings.
    %
    % Original Author: Dennis Eckmeier
    % Modified by: Joao Fayad (joaofayad@gmail.com)
        
%     if isempty(file_name)
%         [L_filename, L_path] = uigetfile(fullfile(gui.settings_path,'*.mat'));
%         
%         L_filename = fullfile(L_path, L_filename);
%         
%     else
%         L_filename = file_name;
%     end
%     
%     if ~ischar(L_filename)
%         return;
%     end
    
    if ~exist(file_name, 'file')
        error('Could not load %s, file does not exist.',file_name);
    end


    load(file_name,'t_values');
    
    if ~exist('t_values','var')
        error('%s does not contain valid LocoMouse_Tracker data.');
    end
    
    tfigObj = fieldnames(t_values);
    
    for tf = 1:size(tfigObj,1)
        
        if ~isprop(gui,tfigObj{tf})
            warning('%s: GUI has no such property',tfigObj{tf});
            continue;
        end
        
        switch gui.(tfigObj{tf}).Style
            case 'popupmenu'
                if isfield(t_values.(tfigObj{tf}),'String')
                    if any(ismember(gui.(tfigObj{tf}).String,t_values.(tfigObj{tf}).String))
                        tval = find(ismember(gui.(tfigObj{tf}).String,t_values.(tfigObj{tf}).String));
                    else
                        warning(['Non-existend setting for ',tfigObj{tf},'!'])
                        tval=1;
                    end
                else
                    tval = t_values.(tfigObj{tf}).Value;
                end
                
            case 'checkbox'
                tval = t_values.(tfigObj{tf}).Value;
                
            case 'edit'
                set(gui.(tfigObj{tf}),'String',t_values.(tfigObj{tf}).String);
                
            otherwise
                tval = t_values.(tfigObj{tf}).Value;
        end
        
        set(gui.(tfigObj{tf}),'Value',tval);
    end
end