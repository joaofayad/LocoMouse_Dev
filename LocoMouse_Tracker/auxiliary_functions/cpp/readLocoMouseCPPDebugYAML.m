function [] = readLocoMouseCPPDebugYAML(debug_yml_file)
% Reads the debug_yml_file and convert to matlab structures that can be
% loaded by the LocoMouse_Debugger.

fid = fopen(debug_yml_file);

if fid < 0
    error('Could not open file!');
end

safeopen = onCleanup(@()(fclose(fid)));
l = getline(fid);

if ~strcmpi(l,'%YAML:1.0')
    error('File should be a YAML file version 1.0');
end

% N_frames:
N_frames = getVal(getline(fid),':','N_frames','Error loading N_frames');

getVal(getline(fid),':','BB_top','Error loading BB_top');

bb_props = {'x','y','width','height'};

BB_top = zeros(1,4);
BB_bottom = zeros(1,4);

for i_props = 1:4
    BB_top(i_props) = getVal(getline(fid),':',bb_props{i_props},['Error loading BB_top ' bb_props{i_props}]);    
end

for i_props = 1:4
    BB_bottom(i_props) = getVal(getline(fid),':',bb_props{i_props},['Error loading BB_top ' bb_props{i_props}]);    
end

bb_x_avg = zeros(1,N_frames);
bb_yt_avg = zeros(1,N_frames);
bb_yb_avg = zeros(1,N_frames);


getVal(getline(fid),':','bb_x_avg','Error loading bb_x_avg');
for i_frames = 1:N_frames
    bb_x_avg(i_frames) = getVal(getline(fid),'-','   ','Error loading bb_x_avg');
end

getVal(getline(fid),':','bb_yt_avg','Error loading bb_x_avg');
for i_frames = 1:N_frames
    bb_yt_avg(i_frames) = getVal(getline(fid),'-','   ','Error loading bb_yt_avg');
end

getVal(getline(fid),':','bb_yb_avg','Error loading bb_x_avg');
for i_frames = 1:N_frames
    bb_yb_avg(i_frames) = getVal(getline(fid),'-','   ','Error loading bb_yb_avg');
end

getVal(getline(fid),':','ONG','Error loading ONG');

ONG = zeros(2,0);
for i_frames = 1:N_frames
    
end


function val = getVal(string,delimiter,expected,error_msg)
lcell = strsplit(string,delimiter);
if strcmpi(lcell{1},expected)
    error(error_msg);
end
val = str2double(lcell{2});




