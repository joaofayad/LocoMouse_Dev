function [peaks, speed] = calibrateBelts(file_name, Calib)
% Calibrates the voltage to speed ratio for the split belt.
vid = VideoReader(file_name);
N_frames = vid.Duration*vid.FrameRate;

video_boxes = cell(1,2);

if Calib.load_full_video

    V = squeeze(read(vid,[1 N_frames]));
    
    video_boxes{1} = cropVideo(V,Calib.top_belt_bb);
    video_boxes{2} = cropVideo(V,Calib.bottom_belt_bb);
    clear V;

else
    
    video_boxes{1} = uint8(zeros(Calib.top_belt_bb(4),Calib.top_belt_bb(3)));
    video_boxes{2} = uint8(zeros(Calib.bottom_belt_bb(4),Calib.bototm_belt_bb(3)));
        
    for i_frames = 1:N_frames
        
        I = readFrame(vid);
        video_boxes{1}(:,:,i_frames) = imcrop(I,Calib.top_belt_bb);
        video_boxes{2}(:,:,i_frames) = imcrop(I,Calib.bottom_belt_bb);
        
    end
end

video_boxes{1} = video_boxes{1} > Calib.th_top*255;
video_boxes{2} = video_boxes{2} > Calib.th_bottom*255;

video_boxes{1} = sum(reshape(video_boxes{1},size(video_boxes{1},1)*size(video_boxes{1},2),N_frames),1);
video_boxes{2} = sum(reshape(video_boxes{2},size(video_boxes{2},1)*size(video_boxes{2},2),N_frames),1);

peaks.top = peakdet_mean(video_boxes{1},Calib.pk_th_top * max(video_boxes{1}));
peaks.bottom = peakdet_mean(video_boxes{2},Calib.pk_th_bottom * max(video_boxes{2}));

N_peaks_top = min(length(peaks.top),Calib.N_trials);
N_peaks_bottom = min(length(peaks.bottom),Calib.N_trials);
    
speed.top_frames = mean(diff(peaks.top(end-N_peaks_top+1:end)));
speed.bottom_frames = mean(diff(peaks.bottom(end-N_peaks_bottom+1:end)));

speed.top = Calib.BeltLength/(speed.top_frames/Calib.FrameRate);
speed.bottom = Calib.BeltLength/(speed.bottom_frames/Calib.FrameRate);

function V = cropVideo(V,bb)

V = V(bb(2):bb(2)+bb(4),bb(1):bb(1)+bb(3),:);

function peak = peakdet_mean(signal, th)

log_signal = signal > th;

diff_log = diff(log_signal);

st = find(diff_log == 1);
en = find(diff_log == -1);

if en(1) < st(1)
    en = en(2:end);
end

if length(st) > length(en)
    st = st(1:end-1);
end

peak = (st+en)/2;









