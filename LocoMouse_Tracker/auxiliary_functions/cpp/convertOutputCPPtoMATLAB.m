function [] = convertOutputCPPtoMATLAB(file_list, data, output_fun, output_path)
% Converts the output of the cpp version of LocoMouse to mat files.

N_files = size(file_list,1);

for i_files = 1:N_files
    %     output_file = fullfile(output_path,sprintf('output_%s.yml',vid_name));
    %     output_file_mat = feval(output_fun,output_path,strtrim(file_list(1,:)));
    
    [~, file_name, ~] = fileparts(strtrim(file_list(i_files,:)));
    
    if ischar(data.flip)
        if strcmpi('LR',data.flip) % check if mouse comes from L or R based file name [GF]
            char_flip =  data.vid(end-4);
            
            if char_flip == 'R'
                data.flip = false;
            elseif char_flip == 'L';
                data.flip = true;
            else
                error('Could not determine which side the mouse is facing from the file name! File: %s', strtrim(file_list(1,:)));
            end
        else
            error('Wrong value for data.flip!');
        end
    end
    
    output_file = fullfile(output_path, ['output_' file_name '.yml']);
    
    output = readOpenCVYAML(output_file);
    %     delete(output_file);
    final_tracks_c = permute(cat(3,output.paw_tracks0,output.paw_tracks1,output.paw_tracks2,output.paw_tracks3,output.snout_tracks0),[2 3 1]);
    final_tracks_c(final_tracks_c(:)<0) = NaN;
    final_tracks_c = final_tracks_c + 1;
    if isfield(output,'tracks_tail')
        tracks_tail_c = reshape(output.tracks_tail,3,15,[]);
        tracks_tail_c(tracks_tail_c<0) = NaN;
        tracks_tail_c = tracks_tail_c + 1;
    else
        tracks_tail_c = NaN(3,1,size(final_tracks_c,3));
    end
    
    [final_tracks,tracks_tail] = convertTracksToUnconstrainedView(final_tracks_c,tracks_tail_c,size(data.ind_warp_mapping),data.ind_warp_mapping,data.flip,data.scale);
    debug = [];  
    % Saving tracking data:
    save(fullfile(output_path,[file_name '.mat']),'final_tracks','tracks_tail','final_tracks_c','tracks_tail_c','debug','data');
    
end