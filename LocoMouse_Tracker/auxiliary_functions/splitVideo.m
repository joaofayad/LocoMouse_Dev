function [] = splitVideo(vid,N)

if ischar(vid)
    vid = VideoReader(vid);
end

step = floor(vid.NumberOfFrames/N);

for i = 1:N
    
    if i < N
    frames =  step*(i-1) + [1 step];
    else
        frames = [(N-1)*step + 1 Inf];
    end
    
    I = read(vid,frames);
    vid_i = VideoWriter(sprintf('video_split%d.avi',i),'Grayscale AVI');
    open(vid_i);
    writeVideo(vid_i,I);
    close(vid_i);
    
end
    