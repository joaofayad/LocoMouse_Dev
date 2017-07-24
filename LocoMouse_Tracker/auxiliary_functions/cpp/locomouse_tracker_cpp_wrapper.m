function [final_tracks_c, tracks_tail_c,data,debug] = ...
    locomouse_tracker_cpp_wrapper(...
    data,...
    model_file_yml,...
    calibration_file_yml,...
    flip,...
    output_path,...
    cpp_params)

% Reads the inputs in the MATLAB format for LocoMouse_Tracker and parses
% them to be used for the C++ code.

% FIXME: Wrap this inside a function everytime such check is done
% [joaofayad]
char_flip = 'R';
if ischar(flip)
    if strcmpi('LR',flip) % check if mouse comes from L or R based file name [GF]
        char_flip =  data.vid(end-4);
    end
elseif flip
    char_flip = 'L';
end

if char_flip == 'L'
    data.flip = true;
elseif char_flip == 'R'
    data.flip = false;
else
    error('Flip character is neither L nor R (found: %c)',char_flip);
end

if ispc
    % This is needed to avoid the last backslash of the path to escape the
    % quotations needed for paths with spaces in them.
    output_path = formatPathForCppCall(output_path);
end

result = system(sprintf('"%s" "%s" "%s" "%s" "%s" "%s" "%s" %s "%s"',...
    cpp_params.cpp_binary,...
    cpp_params.cpp_mode,...
    cpp_params.config_file,...
    data.vid,...
    data.bkg,...
    model_file_yml,...
    calibration_file_yml,...
    char_flip,...
    output_path));

if result ~= 0
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
% Deals with the way windows paths and MATLAB strings can generate
% conflicts due to the use of backslash to escape characters.
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