function track = DE_FillNaNHoles(track,MaxHoleSize)

    idx_NAN = find(isnan(track));
    nope = true;
    Episode = 0;
    NAN_EPISODES={};
    for tNAN = 1:length(idx_NAN)

        if nope
            Episode = Episode +1;
            NAN_EPISODES{Episode}=[];
        end
        NAN_EPISODES{Episode} = [NAN_EPISODES{Episode}; idx_NAN(tNAN)];

        if tNAN ~= length(idx_NAN)
            nope = (idx_NAN(tNAN+1) - idx_NAN(tNAN)) ~=  1;
        end
    end

    for tEpi = 1: Episode

        StartIDX = min(NAN_EPISODES{tEpi});
        EndIDX = max(NAN_EPISODES{tEpi});

        while isnan(track(StartIDX)) && StartIDX > 1
            StartIDX = StartIDX-1;
        end

        while isnan(track(EndIDX)) && EndIDX < size(track,1)
            EndIDX = EndIDX+1;
        end
        
        if isnan(track(StartIDX))
            track(StartIDX) = track(EndIDX);
        end
        
        if isnan(track(EndIDX))
            track(EndIDX) = track(StartIDX);
        end

        EP_length = (EndIDX-StartIDX)+1;
        
        if EP_length-2 <= MaxHoleSize
            if track(StartIDX) == track(EndIDX)
                track(StartIDX:EndIDX) = ones(EP_length,1)*track(EndIDX);
            else
                track(StartIDX:EndIDX) = track(StartIDX):(track(EndIDX)-track(StartIDX))/(EndIDX-StartIDX):track(EndIDX); 
            end
        end
        
    end
    
end