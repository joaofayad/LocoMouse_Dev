	% convert labels to final_track format and save as final_tracks_TC
    % final_track format: [FR HR FL HR SN]

function [tracks, tracks_tail] = Convert_Label2Track(labels)
    
    tracks = NaN(4,5,size(labels{1}{1}{1}(1:2,1,:,1),3));
    for tli = 1:4
        tracks(1:2,tli,:) = labels{1}{1}{tli}(1:2,1,:,1);
        tracks(3:4,tli,:) = labels{1}{1}{tli}(1:2,1,:,2);
    end
    
    tracks(1:2,5,:) = labels{1}{2}{1}(1:2,1,:,1);
    tracks(3:4,5,:) = labels{1}{2}{1}(1:2,1,:,2);

    tracks_tail(1:2,:,:) = labels{2}{1}{1}(1:2,:,:,1);
    
    if size(labels{2}{1}{1},1) <= 2
        labels{2}{1}{1}(3:4,:,:,1) = NaN(size(labels{2}{1}{1}(1:2,:,:,1)));
    end
    
	tracks_tail(3:4,:,:) = labels{2}{1}{1}(3:4,:,:,1);    
    
end