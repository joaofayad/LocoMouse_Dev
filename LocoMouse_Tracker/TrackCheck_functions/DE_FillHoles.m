
function tracks = DE_FillHoles(tracks,MaxHoleSize)
         
    

    for tPoint = 1:size(tracks,2)
        for tCoord = 1:size(tracks,1)
            tracks(tCoord,tPoint,:) = DE_FillNaNHoles(squeeze(tracks(tCoord,tPoint,:)),MaxHoleSize);
        end
    end

end