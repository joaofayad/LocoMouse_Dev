function [final_tracks, tracks_tail, final_tracks_c, tracks_tail_c, debug, data] = cppToMATLABTracks(output_file,data)
output = readOpenCVYAML(output_file);
output_fields = {'paw_tracks0','paw_tracks1','paw_tracks2','paw_tracks3','snout_tracks0'};
tocat = cell(1,length(output_fields));

for i_fields = 1:length(output_fields)
    if isfield(output,output_fields{i_fields})
        tocat{i_fields} = output.(output_fields{i_fields});
    end
end

final_tracks_c = permute(cat(3,tocat{:}),[2 3 1]);
final_tracks_c(final_tracks_c(:)<0) = NaN;
final_tracks_c = final_tracks_c + 1;
if isfield(output,'tracks_tail')
    tracks_tail_c = reshape(output.tracks_tail,3,15,[]);
    tracks_tail_c(tracks_tail_c<0) = NaN;
    tracks_tail_c = tracks_tail_c + 1;
else
    tracks_tail_c = NaN(3,1,size(final_tracks_c,3));
end

[final_tracks, tracks_tail] = convertTracksToUnconstrainedView(final_tracks_c,tracks_tail_c,size(data.ind_warp_mapping),data.ind_warp_mapping,data.flip,data.scale);
debug = [];