function varargout = subsystemGUI(varargin)
% SUBSYSTEMGUI MATLAB code for subsystemGUI.fig
%      SUBSYSTEMGUI, by itself, creates a new SUBSYSTEMGUI or raises the existing
%      singleton*.
%
%      H = SUBSYSTEMGUI returns the handle to a new SUBSYSTEMGUI or the handle to
%      the existing singleton*.
%
%      SUBSYSTEMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SUBSYSTEMGUI.M with the given input arguments.
%
%      SUBSYSTEMGUI('Property','Value',...) creates a new SUBSYSTEMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before subsystemGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to subsystemGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help subsystemGUI

% Last Modified by GUIDE v2.5 19-Apr-2018 09:11:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @subsystemGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @subsystemGUI_OutputFcn, ...
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


% --- Executes just before subsystemGUI is made visible.
function subsystemGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to subsystemGUI (see VARARGIN)

% Center GUI window on screen
set(handles.figure1, 'Units', 'pixels');
screenSize = get(0, 'ScreenSize');
position = get(handles.figure1, 'Position');
position(1) = (screenSize(3) - position(3))/2;
position(2) = (screenSize(4) - position(4))/2;
set(handles.figure1, 'Position', position);

% Populate the listbox with Subsystem names
try
    subsystems = find_system(varargin{1}, 'BlockType', 'SubSystem', ...
        'IsSimulinkFunction', 'off', ...
        'SFBlockType', 'NONE');
    % Remove any newlines
    for i = 1:length(subsystems)
        subsystems{i} = strrep(subsystems{i}, char(10), '');
    end
catch
    subsystems = '';
end
set(handles.listbox1, 'String', subsystems);

% Choose default command line output for subsystemGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes subsystemGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = subsystemGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 varargout{1} = ''; % Default is to return nothing
 
% Get listbox value to return
if strcmp(handles.output, 'OK')
    indexSelected = get(handles.listbox1, 'Value');
    subsystemList = get(handles.listbox1, 'String');
    if ~isempty(subsystemList) % List may be empty
        selection = subsystemList{indexSelected};
        varargout{1} = selection;
    end
end

delete(handles.figure1);

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output = get(hObject,'String');

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else
    % Close the figure
    delete(hObject);
end

% Hint: delete(hObject) closes the figure
%delete(hObject);
