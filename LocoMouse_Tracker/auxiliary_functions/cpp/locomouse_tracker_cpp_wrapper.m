function [final_tracks_c, tracks_tail_c,data,debug] = locomouse_tracker_cpp_wrapper(data,root_path, model, calib, flip, model_file, calibration_file, cpp_exec, config_file, output_path)
% Reads the inputs in the MATLAB format for LocoMouse_Tracker and parses
% them to be used for the C++ code.
[~,model_file_name,~] = fileparts(model_file);
[~,calibration_file_name,~] = fileparts(calibration_file);

model_file_yml = fullfile(root_path,'model_files',[model_file_name,'.yml']);
calibration_file_yml = fullfile(root_path,'calibration_files',[calibration_file_name,'.yml']);

if ~exist(model_file_yml,'file')
    exportLocoMouseModelToOpenCV(model_file_yml,model);
end

if ~exist(calibration_file_yml,'file')
    exportLocoMouseCalibToOpenCV(calibration_file_yml,calib);
end

char_flip = 'R';
if ischar(flip)
        if strcmpi('LR',flip) % check if mouse comes from L or R based file name [GF]
            char_flip =  data.vid(end-4);
        end  
elseif flip
    char_flip = 'L';
end

if char_flip == 'L';
    data.flip = true;
elseif char_flip == 'R'
    data.flip = false;
else
    error('Flip character is neither L nor R (found: %c)',char_flip);
end

% Running CPP code
if ispc
    % This is needed to avoid the last backslash of the path to escape the
    % quotations needed for paths with spaces in them.
    output_path = formatPathForCppCall(output_path); 
end

result = system(sprintf('"%s" "%s" "%s" "%s" "%s" "%s" %s "%s"',cpp_exec,config_file,data.vid,data.bkg,model_file_yml,calibration_file_yml,char_flip, output_path));
if result < 0
    error('Cpp code failed!');
end
[~,vid_name,~] = fileparts(data.vid);
output_file = fullfile(output_path,sprintf('output_%s.yml',vid_name));
debug_file = fullfile(output_path,sprintf('debug_%s.yml',vid_name));

[final_tracks_c, tracks_tail_c] = cppToMATLABTracks(output_file);
delete(output_file);



 if exist(debug_file,'file')
%     
%     debug = importLocoMouseYAML(debug_file);
     delete(debug_file);
 end
%     
% else
    debug = [];
% end

function path = formatPathForCppCall(path)

if isempty(path)
    path = '.';
    return;
end

if strcmpi(path,'.')
    return;
end

if strcmpi(path,'\\') || strcmpi(path,'//')
    return;
end

if (path(end) == '\' || path(end) == '/')
    path = [path path(end)];
    return;
end

path = [path filesep filesep];
return;