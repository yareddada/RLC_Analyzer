function varargout = rlc_analyzer(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rlc_analyzer_OpeningFcn, ...
                   'gui_OutputFcn',  @rlc_analyzer_OutputFcn, ...
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


function rlc_analyzer_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.series = 0;
handles.parallel = 1;
handles.current_circuit = handles.series;

handles.neper_frequency = 0;
handles.resonant_radian_frequency = 0;
handles.damped_frequency = 0;
handles.s1 = 0;
handles.s2 = 0;

handles.damp_type = -1;
handles.underdamped = 0;
handles.overdamped = 1;
handles.critdamped = 2;

handles.resistance =str2double(get(handles.R_text_edit, 'String'));
handles.inductance = str2double(get(handles.L_text_edit, 'String'))/10^3;
handles.capacitance = str2double(get(handles.C_text_edit, 'String'))/10^6;

handles.tabs = uitabgroup(handles.tab_container);
handles.results_tab = uitab(handles.tabs,'Title','Results');
handles.graph_tab = uitab(handles.tabs,'Title','Graph');
handles.results_table =  uitable(handles.results_tab, 'ColumnWidth',{200 200 100}, 'Position',[1 0 500 550]);

handles.results_table.ColumnName = {'Metrics','Value','Units'};
handles.graph = axes(handles.graph_tab);

update_model(hObject, eventdata, handles);
update_view(hObject, eventdata, handles);

draw_circuit(hObject, eventdata, handles);


function update_model(hObject, eventdata, handles)
handles.resonant_radian_frequency = 1/(handles.inductance*handles.capacitance)^.5;
if handles.current_circuit == handles.series
    handles.neper_frequency = handles.resistance /(2*handles.inductance);
else
    handles.neper_frequency = 1/(2*handles.resistance*handles.capacitance); 
end

handles.damped_frequency = (handles.resonant_radian_frequency^2 - handles.neper_frequency^2)^.5;
handles.s1 = -handles.neper_frequency + (handles.neper_frequency^2 - handles.resonant_radian_frequency^2)^.5;
handles.s2 = -handles.neper_frequency - (handles.neper_frequency^2 - handles.resonant_radian_frequency^2)^.5;

if isreal(handles.s1) && isreal(handles.s2)
    if handles.s1 == handles.s2
        handles.damp_type = handles.critdamped;
    else
        handles.damp_type = handles.overdamped;
    end
else
    handles.damp_type = handles.underdamped;
end
guidata(hObject, handles);


function update_view(hObject, eventdata, handles)
handles = guidata(hObject);
draw_results(hObject, eventdata, handles);
draw_graph(hObject, eventdata, handles);


function draw_results(hObject, eventdata, handles)
type = '';
switch handles.current_circuit;
    case handles.series
        type = 'Series';
    case handles.parallel
        type = 'Parallel';
end

damping = '';
switch handles.damp_type;
case handles.overdamped % User selects peaks.
   damping = 'Overdamped';
case handles.underdamped % User selects peaks.
   damping = 'Underdamped';
case handles.critdamped % User selects peaks.
   damping = 'Critically Damped';
end
handles.results_data = {
                    'R', handles.resistance,'Ohms';...
                    'L', handles.inductance, 'Henries';...
                    'C', handles.capacitance, 'Farads'
                    'RLC Type', type, '';...
                    'Neper Frequency', handles.neper_frequency, 'rad/s';...
                    'Resonant Radian Frequency', handles.resonant_radian_frequency, 'rad/s';...
                    'Damped Frequency', handles.damped_frequency, 'rad/s';...
                    's1', handles.s2, 'rad/s';...
                    's2',handles.s1, 'rad/s';...
                    'Damping', damping, ''};
               
handles.results_table.Data =  handles.results_data;
guidata(hObject, handles);

function save_state_csv(filename, pathname, table, col)
myTable =  cell2table(table, 'VariableNames', col);
writetable(myTable,[strcat(pathname,filename)],'WriteRowNames',true);


function draw_graph(hObject, eventdata, handles)
f = handles.damped_frequency;
T = 1/f;
if isreal(T)
t = 0:T/10:15*T;
y = exp(-handles.neper_frequency*t).*(cos(handles.damped_frequency*t)+sin(handles.damped_frequency*t));
p = plot(handles.graph, t, y);
p.LineWidth = 3;
else
    cla(handles.graph);
end


function varargout = rlc_analyzer_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function menu_file_Callback(hObject, eventdata, handles)


function menu_save_Callback(hObject, eventdata, handles)
[FileName,PathName] = uiputfile('*.csv','Save RLC As');
save_state_csv(FileName, PathName, handles.results_data, handles.results_table.ColumnName);


function menu_load_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile('*.csv','Select an RCL csv');
temp = readtable(strcat(PathName, FileName));
handles.resistance = str2double(temp.Value{1});
handles.capacitance = str2double(temp.Value{2});
handles.inductance = str2double(temp.Value{3});
switch temp.Value{4};
    case 'Series'
        handles.current_circuit = handles.series;
    case 'Parallel'
        handles.current_circuit = handles.parallel;
end
set(handles.select_menu, 'Value', handles.current_circuit+1);
guidata(hObject, handles);
handles = guidata(hObject);
draw_circuit(hObject, eventdata, handles);
update_model(hObject, eventdata, handles);
update_view(hObject, eventdata, handles);




function select_menu_Callback(hObject, eventdata, handles)
str = get(hObject, 'String');
val = get(hObject,'Value');
switch str{val};
case 'Series' % User selects peaks.
   handles.current_circuit = handles.series;
case 'Parallel' % User selects membrane.
   handles.current_circuit = handles.parallel;
end
% Save the handles structure.
draw_circuit(hObject, eventdata, handles);
update_model(hObject, eventdata, handles);
update_view(hObject, eventdata, handles);


function draw_circuit(hObject, eventdata, handles)
axes(handles.type_axes)
if handles.current_circuit == handles.series
    matlabImage = imread('./img/series.png');
else
    matlabImage = imread('./img/parallel.png');
end
image(matlabImage)
axis off
axis image


function select_menu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function calculate_button_Callback(hObject, eventdata, handles)
update_model(hObject, eventdata, handles);
update_view(hObject, eventdata, handles);


function R_text_edit_Callback(hObject, eventdata, handles)
resistance = str2double(get(hObject, 'String'));
if isnan(resistance)
    set(hObject, 'String', 0);
    errordlg('Input must be a number','Error');
end

handles.resistance = resistance;
guidata(hObject,handles);
update_model(hObject, eventdata, handles);
update_view(hObject, eventdata, handles);


function R_text_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function L_text_edit_Callback(hObject, eventdata, handles)
inductance = str2double(get(hObject, 'String'));
if isnan(inductance)
    set(hObject, 'String', 0);
    errordlg('Input must be a number','Error');
end

handles.inductance = inductance/10^3;
guidata(hObject,handles)
update_model(hObject, eventdata, handles);
update_view(hObject, eventdata, handles);


function L_text_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function C_text_edit_Callback(hObject, eventdata, handles)
capacitance = str2double(get(hObject, 'String'));
if isnan(capacitance)
    set(hObject, 'String', 0);
    errordlg('Input must be a number','Error');
end

handles.capacitance = capacitance/10^6;
guidata(hObject,handles)
update_model(hObject, eventdata, handles);
update_view(hObject, eventdata, handles);


function C_text_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function menu_about_Callback(hObject, eventdata, handles)
% hObject    handle to menu_about (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiwait(msgbox({'Made by Team StEthan for ENGR 222 Winter 2017';'';'Testing and Logistics:                       Stephen Poanessa';'Programming and Documentation:   Ethan Lew';'';'My software never has bugs. It just develops random features.';'';'""Legacy code" often differs from its suggested alternative by actually working and scaling."-Bjarne Stroustrup, C++ Creator' } ,'About','modal'));


% --------------------------------------------------------------------
function menu_help_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_help_bug_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_bug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
web('https://github.com/EthanJamesLew/RLC_Analyzer/issues', '-browser');


% --------------------------------------------------------------------
function menu_help_git_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_git (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
web('https://github.com/EthanJamesLew/RLC_Analyzer', '-browser');


% --------------------------------------------------------------------
function menu_file_exit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);
