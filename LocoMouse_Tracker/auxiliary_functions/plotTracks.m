plot(squeeze(final_tracks(1,:,:))')
hold on
plot(squeeze(tracks_tail(1,:,:))')

data.scale=1;
data.bkg = imread('E:\adaptation 8.25.14-8.29.14 Lory\day 4\l7creAF5\l7creAF5_bg.png');
data.vid = VideoReader('E:\adaptation 8.25.14-8.29.14 Lory\day 4\l7creAF5\l7creAF5_20_77_2_split_0.375_0.175_4_2.avi');
displayTracksRaw({data,final_tracks,tracks_tail,{OcclusionGrid/data.scale,bounding_box/data.scale}})