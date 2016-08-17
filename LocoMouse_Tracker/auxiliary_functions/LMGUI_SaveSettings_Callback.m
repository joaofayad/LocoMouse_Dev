% --- Executes on button press in SaveSettings.
function LMGUI_SaveSettings_Callback(handles, tsfilename)
% hObject    handle to SaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
LMT_path = [LMT_path filesep 'GUI_Settings'];
if exist(LMT_path,'dir')~=7
    mkdir(LMT_path);
end

if isempty(tsfilename)
    S_filename = uiputfile([LMT_path filesep '*.mat']);
    
else
    S_filename = tsfilename;    
end

if ischar(S_filename)
    if exist(S_filename)==2
        load([LMT_path filesep S_filename],'t_values');
    end

    tfigObj =  {'checkbox_LimitWindow'; ...
                'checkbox_ShowNewLabels'; ...
                'checkbox_Show_LM_Track'; ...
                'checkbox_overwrite_results'; ...
                'checkbox_ExpFigures'; ...
                'checkbox_display_split_line'; ...
                'BoundingBox_choice'; ...
                'MouseOrientation'; ...
                'popupmenu_model'; ...
                'popupmenu_calibration_files'; ...
                'popupmenu_background_mode'; ...
                'popupmenu_output_mode'; ...
                'edit_output_path'};

    if ischar(S_filename)
        for tfi = 1:size(tfigObj,1)

            if isfield(handles,tfigObj{tfi})

                switch handles.(tfigObj{tfi}).Style
                    case 'popupmenu'
                        t_values.(tfigObj{tfi}).String = handles.(tfigObj{tfi}).String{handles.(tfigObj{tfi}).Value};

                    case 'checkbox'
                        t_values.(tfigObj{tfi}).Value     = handles.(tfigObj{tfi}).Value;
                        
                    case 'edit'
                        t_values.(tfigObj{tfi}).String = handles.(tfigObj{tfi}).String;
                        
                    otherwise
                        t_values.(tfigObj{tfi}).Value     = handles.(tfigObj{tfi}).Value;
                end
            end
        end
        save([LMT_path filesep S_filename],'t_values'); disp(['Settings saved: ',S_filename])
    end
end