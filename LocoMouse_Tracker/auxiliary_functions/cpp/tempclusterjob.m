function [] = tempclusterjob(cpp_output_path, video_file, background_file, flip_char, temp_mat_file)

data = load(temp_mat_file);
data.vid = video_file;
data.bkg = background_file;
data.flip = flip_char == 'L';

[~,output_file_name,~] = fileparts(video_file);
cpp_output_file = fullfile(cpp_output_path,sprintf('output_%s.yml',output_file_name));
debug_cpp_output_file = fullfile(cpp_output_path,sprintf('debug_%s.yml',output_file_name));

mat_output_file = [cpp_output_file(1:end-3) 'mat'];
mat_output_file = strrep(mat_output_file,'output_','');

[final_tracks, tracks_tail, final_tracks_c, tracks_tail_c,debug,data] = cppToMATLABTracks(cpp_output_file,data);
save(mat_output_file,'final_tracks','tracks_tail','final_tracks_c','tracks_tail_c','debug','data');

delete(cpp_output_file);

if exist(debug_cpp_output_file,'file')
    delete(debug_cpp_output_file);
end
