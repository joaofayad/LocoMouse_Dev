function [tracks_unconstrained,tracks_tail_unconstrained] = convertTracksToUnconstrainedView(final_tracks,tracks_tail,image_size,IDX,flip,scale)
% CONVERTTRACKSTOUNCONSTRAINEDVIEW Transforms the tracks from the
% constrained to unconstrained view format.


if scale ~= 1
    % Scaling the tracks:
    final_tracks = round((1/scale)*final_tracks);
    tracks_tail = round((1/scale)*tracks_tail);
end

if isempty(IDX)
    IDX  = 1:prod(image_size);
end

[~, Ntracks, Nframes] = size(final_tracks);

if size(final_tracks,1) == 3
    final_tracks = final_tracks([1 2 1 3],:,:);
end
final_tracks = reshape(final_tracks,2,[]);

ind = sub2ind(image_size,final_tracks(2,:),final_tracks(1,:));
i = NaN(1,length(ind));
j = NaN(1,length(ind));
[i(~isnan(ind)),j(~isnan(ind))] = ind2sub(image_size,IDX(ind(~isnan(ind))));
tracks_unconstrained = reshape([j;i],4,Ntracks,Nframes);

Ntracks = size(tracks_tail,2);
if Ntracks > 0
    tracks_tail = reshape(tracks_tail([1 2 1 3],:,:),2,[]);
    ind = sub2ind(image_size,tracks_tail(2,:),tracks_tail(1,:));
    i = NaN(1,length(ind));
    j = NaN(1,length(ind));
    [i(~isnan(ind)),j(~isnan(ind))] = ind2sub(image_size,IDX(ind(~isnan(ind))));
    tracks_tail_unconstrained = reshape([j;i],4,Ntracks,Nframes);
else
    tracks_tail_unconstrained = [];
end
 