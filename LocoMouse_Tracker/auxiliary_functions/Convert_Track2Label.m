% converts tracks from LocoMouse_Tracker into the label format
% 'labels' needs to be created using initializeEmptytrackVisibility(userdata, size(tracks,3));

function [labels]= Convert_Track2Label(tracks,tracks_tail, labels)
   
    for tli = 1:4
        labels{1}{1}{tli}(1:2,1,:,1) = tracks(1:2,tli,:);
        labels{1}{1}{tli}(1:2,1,:,2) = tracks(3:4,tli,:);
    end
        labels{1}{2}{1}(1:2,1,:,1) = tracks(1:2,5,:);
        labels{1}{2}{1}(1:2,1,:,2) = tracks(3:4,5,:);
               
try
        labels{2}{1}{1}(1:2,:,:,1) = tracks_tail(1:2,:,:);
        labels{2}{1}{1}(3:4,:,:,1) = tracks_tail(3:4,:,:);        
catch
    disp('meh')
end

end