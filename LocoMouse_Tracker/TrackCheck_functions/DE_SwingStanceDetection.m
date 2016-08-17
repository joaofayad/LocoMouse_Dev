%[SwiSta] = DE_SwingStanceDetection(labels)
% 
% TAKES: 
% Labels from the LocoMouse_TrackCheck format.
% RETURNS:
% Start frames of identified swings and stances.
% NEEDS:
% - inpaint_nans()
% - DE_SwiStaDet_X() [original code outsourced into different function files]
% - DE_SwiStaDet_NewDataPoints() [original code outsourced into different function files]

% Dennis Eckmeier, 2015
% Based on correcmatfinal_wild_400_04_018_mutant.m by Carey lab

function [SwiSta] = DE_SwingStanceDetection(labels)

    [final_tracks, ~] = Convert_Label2Track(labels);
            
    frames=(1:size(final_tracks,3))';
    
	preX=squeeze(final_tracks(1,:,:))'; % X-values for all paws and snout
       
	[minpkx,maxpkx,x_zero]      = DE_SwiStaDet_X(preX,frames);
  	[new_swings, new_stances]   = DE_SwiStaDet_NewDataPoints(x_zero, minpkx, maxpkx);
        
    SwiSta.swing = cell(1,4);
    SwiSta.stance = cell(1,4);
    for n = 1:4      
        SwiSta.swing{n}  = frames(cell2mat(new_swings(:,n)));
        SwiSta.stance{n} = frames(cell2mat(new_stances(:,n)));
    end
    
end