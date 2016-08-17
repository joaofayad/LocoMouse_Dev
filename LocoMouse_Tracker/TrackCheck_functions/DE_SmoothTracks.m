% tracks = DE_SmoothTracks(tracks,fs,FillIns) 
% takes tracks in format of final_tracks and returns tracks smoothed using 
% a running average. The window is calculated based on the sampling rate.
% Dennis Eckmeier, 2016

function tracks = DE_SmoothTracks(tracks,fs,FillIns,MaxHoleSize)

    if fs > 60
        tspan = floor(fs/20);

        if mod(tspan,2)
            tspan = tspan+1;
        end
        
        for tPoint = 1:size(tracks,2)
            for tCoord = 1:size(tracks,1)
                FilledTrack = DE_FillNaNHoles(squeeze(tracks(tCoord,tPoint,:)),MaxHoleSize);
                s_track = smooth(FilledTrack,tspan);
                if FillIns
                    tracks(tCoord,tPoint,:) = s_track;
                else
                    tracks(tCoord,tPoint,~isnan(squeeze(tracks(tCoord,tPoint,:)))) = s_track(~isnan(squeeze(tracks(tCoord,tPoint,:))));
                end

%                 figure
%                  plot([FilledTrack, s_track, squeeze(tracks(tCoord,tPoint,:))])
            end
        end
    else
        disp('Sampling rate too low.')
    end
    
end