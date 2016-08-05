function newtrack = DE_SeAuTr_tracking(userdata,video_id,frames,newtrack,temp_size,win_size)
% function run in the parfor loop of the DE_SemiAutoTracking

    for t_frame_i = 1:size(frames,2)
        thisFrame = frames(t_frame_i);
        if sum(diff(frames)) > 0
            prevFrame = thisFrame-1;
        else
            prevFrame = thisFrame+1;
        end
        
        try
        
        [~,img0] = readMouseImage(userdata.data(video_id).vid,prevFrame,userdata.data(video_id).bkg,0,1,userdata.data(video_id).ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping));
        currPos  = newtrack(:,:,prevFrame);
        if any(isnan(currPos)) 
            newtrack(:,:,thisFrame) =currPos;
        else
            img0_idxX = [-temp_size:temp_size]+currPos(1);img0_idxX = img0_idxX(img0_idxX > 0 & img0_idxX <= userdata.data(video_id).vid.Width);
            img0_idxY = [-temp_size:temp_size]+currPos(2);img0_idxY = img0_idxY(img0_idxY > 0 & img0_idxY <= userdata.data(video_id).vid.Height);
            currTemp = imadjust(img0(img0_idxY,img0_idxX));

            [~,img1] = readMouseImage(userdata.data(video_id).vid,thisFrame,userdata.data(video_id).bkg,0,1,userdata.data(video_id).ind_warp_mapping,size(userdata.data(video_id).ind_warp_mapping));
            img1_idxX = [-win_size:win_size]+currPos(1);img1_idxX = img1_idxX(img1_idxX > 0 & img1_idxX <= userdata.data(video_id).vid.Width);
            img1_idxY = [-win_size:win_size]+currPos(2);img1_idxY = img1_idxY(img1_idxY > 0 & img1_idxY <= userdata.data(video_id).vid.Height);
            currwWin = imadjust(img1(img1_idxY,img1_idxX));
            result = conv2(double(currwWin),double(currTemp),'same');
            [v,i] = max(result(:));
            [y,x]  = ind2sub(size(result),i);
            x = x + min(img1_idxX);
            y = y + min(img1_idxY);
            if x > userdata.data(video_id).vid.Width
                x = userdata.data(video_id).vid.Width;
            elseif x < 1
                x=1;
            end

            if y > userdata.data(video_id).vid.Height
                y = userdata.data(video_id).vid.Height;
            elseif y < 1
                y=1;
            end
            newtrack(:,:,thisFrame) = [x;y];
%             disp(['coordinates chosen: ' num2str(x),'|',num2str(y)])
        end
        catch t_err
            disp()
        end
    end
end