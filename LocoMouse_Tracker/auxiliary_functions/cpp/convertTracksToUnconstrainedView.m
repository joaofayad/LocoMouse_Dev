function [tracks_unconstrained,tracks_tail_unconstrained] = convertTracksToUnconstrainedView(final_tracks,tracks_tail,image_size,IDX,flip,scale)
% CONVERTTRACKSTOUNCONSTRAINEDVIEW Transforms the tracks from the
% constrained to unconstrained view format.
%
% To transform an image for tracking the order of steps should be:
% - Remove Background
% - Apply calibration transformation
% - Scale/Flip if needed (commutative)
%
% The reverse transformation of this function should thus apply these steps
% in reverse order.

% Scaling the tracks:
if scale ~= 1
    final_tracks = round(final_tracks/scale);
    tracks_tail = round(tracks_tail/scale);
end

if isempty(IDX)
    IDX  = 1:prod(image_size);
end

% disp(['flip: ' num2str(flip)])
if flip
    % Vertical flip of tracks: 
    final_tracks(1,:,:) = size(IDX,2) - final_tracks(1,:,:) + 1;
    tracks_tail(1,:,:) = size(IDX,2) - tracks_tail(1,:,:) + 1;
    
    % Correcting L/R paw label:
    track_label = [3 4 1 2];
    
    if size(final_tracks,2) > 4
        track_label = [track_label 5:size(final_tracks,2)];
    end
    
    final_tracks = final_tracks(:,track_label,:);
end

[~, Ntracks, Nframes] = size(final_tracks);

% Smoothed data can't be tranformed with this function.
final_tracks = round(final_tracks);
tracks_tail = round(tracks_tail);

if size(final_tracks,1) == 3
    final_tracks = final_tracks([1 2 1 3],:,:);
end
final_tracks = reshape(final_tracks,2,[]);

ind = sub2ind(image_size,final_tracks(2,:),final_tracks(1,:));
i = NaN(1,length(ind));
j = NaN(1,length(ind));
[i(~isnan(ind)),j(~isnan(ind))] = ind2sub(image_size,IDX(ind(~isnan(ind))));
tracks_unconstrained = reshape([j;i],4,Ntracks,Nframes);

Ntracks_tail = size(tracks_tail,2);
if Ntracks_tail > 0
    try
        if size(tracks_tail,1) == 4
            disp('WHY is size(tracks_tail,1) == 4 ??')
            tracks_tail = reshape(tracks_tail,2,[]);
        elseif size(tracks_tail,1) == 3
            tracks_tail = reshape(tracks_tail([1 2 1 3],:,:),2,[]);
        end
    catch tError
        disp(getReport(tError,'extended'));
    end
        
    ind = sub2ind(image_size,tracks_tail(2,:),tracks_tail(1,:));
    i = NaN(1,length(ind));
    j = NaN(1,length(ind));
    [i(~isnan(ind)),j(~isnan(ind))] = ind2sub(image_size,IDX(ind(~isnan(ind))));
    tracks_tail_unconstrained = reshape([j;i],4,Ntracks_tail,Nframes);
else
    tracks_tail_unconstrained = [];
end
 