% Calibrating the voltage to speed curve for the belts:
%% User defined parameters:

% Path for videos:
path_videos = 'F:\belt_calibration_videos_Hugo';
output_path = 'F:\belt_calibration_videos_Hugo';

% FIXME: Framerate should be from the video if the video has the correct
% value:
Calib.Volts = [0.5 1 1.5 2 3];
Calib.FrameRate = 330;
Calib.BeltLength = 0.3*pi;

% BB where to check the image:
Calib.top_belt_bb = [280 160 30 40];
Calib.bottom_belt_bb = [290 210 40 60];

% Threshold for the binary conversion:
Calib.th_top = 0.3;
Calib.th_bottom = 0.3;

% Threshold for the peak detection:
Calib.pk_th_top = 0.95;
Calib.pk_th_bottom = 0.95;

% Number of trials to consider (the motor takes time to reach top speed)
Calib.N_trials = 2; % At most, if it has less...

% Load video to memory or for loop (to avoid swapping):
Calib.load_full_video = true;

%% Actual code:
video_files = lsOSIndependent(fullfile(path_videos,'*.avi'));

N_videos = size(video_files,1);

data = struct('video_name',cell(1,N_videos),'peak_frames',cell(1,N_videos),'speed',cell(1,N_videos));

for i_video = 1:N_videos
    
    data(i_video).video_name = video_files(i_video,:);
    [data(i_video).peak_frames,data(i_video).speed] = calibrateBelts(fullfile(path_videos,data(i_video).video_name), Calib);
    
end

Calib.data = data; clear data;

speeds = zeros(2,N_videos);
for i_video = 1:N_videos
    speeds(1,i_video) = Calib.data(i_video).speed.top;
    speeds(2,i_video) = Calib.data(i_video).speed.bottom;
end

figure()
subplot(1,2,1)
plot(Calib.Volts,speeds(1,:));
title('Speed top belt');
[p_top] = polyfit(Calib.Volts,speeds(1,:),1);
href = refline(p_top(1), p_top(2));
set(href, 'Color', [1 0 0]);

subplot(1,2,2)
plot(Calib.Volts,speeds(2,:));
title('Speed bottom belt');
[p_bottom] = polyfit(Calib.Volts,speeds(1,:),1);
href = refline(p_bottom(1), p_bottom(2));
set(href, 'Color', [1 0 0]);


