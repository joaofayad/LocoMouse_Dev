function varargout = newlabel(varargin)
% NEWLABEL MATLAB code for newlabel.fig
%      NEWLABEL, by itself, creates a new NEWLABEL or raises the existing
%      singleton*.
%
%      H = NEWLABEL returns the handle to a new NEWLABEL or the handle to
%      the existing singleton*.
%
%      NEWLABEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEWLABEL.M with the given input arguments.
%
%      NEWLABEL('Property','Value',...) creates a new NEWLABEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before newlabel_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to newlabel_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help newlabel

% Last Modified by GUIDE v2.5 24-Oct-2014 17:25:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @newlabel_OpeningFcn, ...
                   'gui_OutputFcn',  @newlabel_OutputFcn, ...
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


% --- Executes just before newlabel is made visible.
function newlabel_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to newlabel (see VARARGIN)

% Choose default command line output for newlabel
handles.output = hObject;

% Initialize button press:
handles.output = false;
handles.n_points = 1;
handles.output_class = '';
handles.output_name = '';

% Reading available types:
handles.types = varargin{1};
handles.classes = varargin{2};
handles.names = varargin{3};

% Initializing the types structure: We only support line and point...
set(handles.popupmenu_type,'String',handles.types);

% Initializing the classes:
set(handles.popupmenu_class,'String',cat(2,handles.classes{1},'New Class'));

% Update handles structure
guidata(hObject, handles);

% Execute Type selection for the first type:
popupmenu_type_Callback([],[],handles);

% Setting default button to the add button:
set(handles.figure1,'Visible','on');
drawnow;
uicontrol(handles.edit_name);

% UIWAIT makes newlabel wait for user response (see UIRESUME)
uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = newlabel_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if handles.output
    
    val_type = get(handles.popupmenu_type,'Value');
    type_name = get(handles.popupmenu_type,'String');
    type_name = type_name{val_type};
    
    if strcmpi(get(handles.edit_class,'Enable'),'on')
        class_name = get(handles.edit_class,'String');
    else
        val_class = get(handles.popupmenu_class,'Value');
        class_name = get(handles.popupmenu_class,'String');
        class_name = class_name{val_class};
    end
    
    feature_name = get(handles.edit_name,'String');
    
    n_points = str2double(get(handles.edit_n_points,'String'));
else
    type_name = '';
    class_name = '';
    feature_name = '';
    n_points = 0;
end
varargout{1} = handles.output;
varargout{2} = type_name;
varargout{3} = class_name;
varargout{4} = feature_name;
varargout{5} = n_points;
delete(handles.figure1)

% --- Executes on selection change in popupmenu_type.
function popupmenu_type_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_type
value = get(handles.popupmenu_type,'Value');
current_type = handles.types{value};

switch lower(current_type)
    case 'point'
        set(handles.edit_n_points,'String','1','Enable','off');
        handles.n_points = 1;
    case 'line'
        set(handles.edit_n_points,'Enable','on');
    otherwise
        sprintf('Class %s has no specific rules. These must be defined on the code!',current_type);
        handles.output = false;
        guidata(handles.figure1,handles);
        uiresume;
        return;
end
set(handles.popupmenu_class,'Value',1,'String',cat(2,handles.classes{value},'New Class'));
popupmenu_class_Callback([],[],handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_class_Callback(hObject, eventdata, handles)
% hObject    handle to edit_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_class as text
%        str2double(get(hObject,'String')) returns contents of edit_class as a double

new_class = get(handles.edit_class,'String');
type = get(handles.popupmenu_type,'Value');

if any(strcmpi(new_class,handles.classes{type}))
    fprintf('Class name %s already exists!\n',new_class);
    set(handles.edit_class,'String','');
end

% --- Executes during object creation, after setting all properties.
function edit_class_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_class.
function popupmenu_class_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_class contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_class

value = get(handles.popupmenu_class,'Value');
list = get(handles.popupmenu_class,'String');

if value == length(list)
    set(handles.edit_class,'Enable','on');
else
    set(handles.edit_class,'Enable','off');
end
edit_name_Callback([],[],handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_class_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_name_Callback(hObject, eventdata, handles)
% hObject    handle to edit_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_name as text
%        str2double(get(hObject,'String')) returns contents of edit_name as a double

new_name = get(handles.edit_name,'String');
type = get(handles.popupmenu_type,'Value');
class = get(handles.popupmenu_class,'Value');

if class <= length(handles.classes{type})
    if any(strcmpi(new_name,handles.names{type}{class}))
        fprintf('There is a already a feature named %s for this class.\n',new_name);
        set(handles.edit_name,'String','');
    end
end

% --- Executes during object creation, after setting all properties.
function edit_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_n_points_Callback(hObject, eventdata, handles)
% hObject    handle to edit_n_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_n_points as text
%        str2double(get(hObject,'String')) returns contents of edit_n_points as a double

temp = str2double(get(handles.edit_n_points,'String'));
if isnan(temp)
    fprintf('Number of points must be a number!\n');
elseif temp < 1
    fprintf('Number of points must be at least 1.\n');
elseif temp > 20
    fprintf('To avoid memory issues the labels are capped at 20 points.\n');
else
    temp = round(temp);
    handles.n_points = temp;

end
set(handles.edit_n_points,'String',num2str(handles.n_points));
guidata(handles.figure1,handles);

% --- Executes during object creation, after setting all properties.
function edit_n_points_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_n_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume;

% --- Executes on button press in pushbutton_add.
function pushbutton_add_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make sure values are not empty and are not repeated:
handles.output = true;
guidata(handles.figure1,handles);
uiresume;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume;
