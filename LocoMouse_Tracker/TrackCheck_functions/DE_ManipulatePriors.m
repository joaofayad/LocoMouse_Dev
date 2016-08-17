newUnary = {};

for t_i = 1:length(corrected_frames_i) % corrected_frames_i: indices of frames that have corrections
        t_frame = corrected_frames_i(t_i); 
        t_nonNaN = ~isnan(tracks_corr_w(1,1:4,t_i)) | ~isnan(tracks_corr_w(2,1:4,t_i)); % tracks_corr_w: contains the corrected, warped coordinates
        t_score = sum(track_bottom{1,t_frame}(3,:)); % sum of the scores is the new score
        
        % make changes in track_bottom
        track_bottom{1,t_frame} = [tracks_corr_w(1:2,t_nonNaN,t_i); ...
                                   ones(1,size(tracks_corr_w(1:2,t_nonNaN,t_i),2),1) * t_score];
        if any(isnan(tracks_corr_w(1:2,5,t_i)))
            track_bottom{2,t_frame} = [];
        else
            track_bottom{2,t_frame} = [tracks_corr_w(1:2,5,t_i); t_score];
        end
        
        % generate new Unary entries for each paw and corrected frame
        t_score = sum(Unary{1,t_frame}(:));
        tpaws = find(t_nonNaN);
        
        for t_p = 1: length(tpaws)
            newUnary{t_i,tpaws(t_p)} = zeros(1+Nong,4);
            newUnary{t_i,tpaws(t_p)}(1,tpaws(t_p)) = t_score; % frame t_i for paw t_p gets new score set.
        end
        
        tpaws = find(~t_nonNaN);
        for t_p = 1: length(tpaws)
            newUnary{t_i,tpaws(t_p)} = zeros(Nong+1,4);
        end
        
        if isempty(track_bottom{2,t_frame})
            Unary{2,t_frame} = zeros(Nong+1,1);
        else
            Unary{2,t_frame} = [t_score;zeros(Nong,1)];
        end                
end
    clear t_i t_p t_score tpaws t_nonNaN t_frame
    % change Pairwise
    for t_i = 1:length(corrected_frames_i)
        t_frame = corrected_frames_i(t_i);
%         [R_tf,~] = ind2sub(size(Unary{1,t_frame}),find(Unary{1,t_frame}));
%         NPos_tf = length(R_tf(diff(sort(R_tf)) > 0))+1;
        NPos_tf = 1+Nong;
        if t_frame ~= N_frames
            NPos_nf = size(Unary{1,t_frame+1},1);
            newPairwise_tf = zeros(NPos_nf,NPos_tf);
            newPairwise_tf(:,1) = ones(NPos_nf,1)*0.75;
            Pairwise{1,t_frame} = newPairwise_tf;
            
            NPos_nf = size(Unary{2,t_frame+1},1);
            Pairwise{2,t_frame} = ones(NPos_nf,1)*0.75;
        end
        if t_frame > 1
            NPos_pf = size(Unary{1,t_frame-1},1);
            newPairwise_pf = zeros(NPos_tf,NPos_pf);
            Pairwise{1,t_frame-1} = newPairwise_pf;
            
            NPos_pf = size(Unary{2,t_frame-1},1);
            Pairwise{2,t_frame-1} = zeros(1,NPos_nf)*0.75;
        end
    end
    
    % retrack with the new labels
    for t_p = 1:4
        for t_i = 1:length(corrected_frames_i)
            Unary{1,corrected_frames_i(t_i)} = newUnary{t_i,t_p};
        end
%         [M, retracked_track] = MTF_BottomView(N_pointlike_tracks,N_frames,N_pointlike_features, model, Unary, Pairwise, Nong, point_features);
    end
    