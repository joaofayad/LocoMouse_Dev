disp('Running DE_SemiAutoTracking ... ')
curr_template = [];
temp_size = 11;
win_size = 17;
PlayVid = false

new_track_bottom = NaN(4,N_pointlike_tracks,N_frames);
new_track_bottom(:,:,corrected_frames_i)=tracks_corr_w;
newtrack(:,:,corrected_frames_i)=tracks_corr_w;
et = tic;
for t_i = 1: length(corrected_frames_i)
           
        for t_label = 1:size(tracks_corr_w,2)
            if t_i+1 > length(corrected_frames_i)
                lastframe = N_frames-1;
            else
                lastframe = corrected_frames_i(t_i+1)-1;
            end

            frames2track = corrected_frames_i(t_i)+1:lastframe;
            result = DE_SeAuTr_tracking(userdata,video_id,frames2track,new_track_bottom(1:2,t_label,:),temp_size,win_size);
            newtrack(1:2,t_label,min(frames2track):max(frames2track)) = result(:,:,min(frames2track):max(frames2track));

            frames2track = lastframe:-1:corrected_frames_i(t_i)+1;
            result = DE_SeAuTr_tracking(userdata,video_id,frames2track,new_track_bottom(1:2,t_label,:),temp_size,win_size);
            newtrack(3:4,t_label,min(frames2track):max(frames2track)) = result(:,:,min(frames2track):max(frames2track));
        end
 
        disp([num2str(100/(length(corrected_frames_i)-1)*t_i),'% done.']);
end

if PlayVid
    col = {'r','m','b','c','g'};
    figure()
    for tfra = 1:5:N_frames
        imshow(readMouseImage(userdata.data(video_id).vid,tfra,userdata.data(video_id).bkg,0,1,userdata.data(video_id).ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping)));
        hold on
        for tLabel = 1:5
            Xout = warpPointCoordinates([newtrack(2,tLabel,tfra),newtrack(1,tLabel,tfra)], userdata.data(video_id).ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping));
            plot(Xout(2),Xout(1),'o','Color',col{tLabel})
            Xout = warpPointCoordinates([newtrack(4,tLabel,tfra),newtrack(3,tLabel,tfra)], userdata.data(video_id).ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping));
            plot(Xout(2),Xout(1),'x','Color',col{tLabel})
        end
        hold off
        pause(0.04)
    end
end

elapsedTime = toc(et);

disp(['elapsed time: ',num2str(floor(elapsedTime/60)),':',num2str(round(elapsedTime-(floor(elapsedTime/60)*60))),' min'])


