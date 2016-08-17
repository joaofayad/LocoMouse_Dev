
% --- Executes on button press in LoadSettings.
function LMGUI_LoadSettings_Callback(handles, tlfilename)
% hObject    handle to LoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[LMT_path,~,~] = fileparts(which('LocoMouse_Tracker'));
LMT_path = [LMT_path filesep 'GUI_Settings'];
if exist(LMT_path,'dir')~=7
    mkdir(LMT_path);
end

if isempty(tlfilename)
    L_filename = uigetfile([LMT_path filesep '*.mat']);
else
    L_filename = tlfilename;
end

if ischar(L_filename)
    load([LMT_path filesep L_filename],'t_values');

    tfigObj = fieldnames(t_values);
    
	for tf = 1:size(tfigObj,1)
        
        if isfield(handles,tfigObj{tf})
            switch handles.(tfigObj{tf}).Style
                case 'popupmenu'
                    if isfield(t_values.(tfigObj{tf}),'String')
                        if any(ismember(handles.(tfigObj{tf}).String,t_values.(tfigObj{tf}).String))
                            tval = find(ismember(handles.(tfigObj{tf}).String,t_values.(tfigObj{tf}).String));
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
                    set(handles.(tfigObj{tf}),'String',t_values.(tfigObj{tf}).String);
                    
                otherwise
                    tval = t_values.(tfigObj{tf}).Value;
            end

        set(handles.(tfigObj{tf}),'Value',tval);
        end
	end
end