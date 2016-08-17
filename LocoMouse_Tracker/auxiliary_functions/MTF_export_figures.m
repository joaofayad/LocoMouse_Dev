function [] = MTF_export_figures(final_tracks, tracks_tail, seq_name,data)
% MTF_export_figures(final_tracks, tail_tracks)
% Expects "constrained" pixel coordinates.
% Plots the tracks resulting from the MTF tracker. The default plots are:
%
% X vs time/frame for 4 paws.
% X vs Z for FR FL
% X vs Z for HR HL
% Z vs time for FR FL
% Z vs time for HR HL
% Y vs X for tail
% Z vs X for tail

[seq_path,seq_name,~] = fileparts(seq_name);
vid = VideoReader(data.vid);
f2t = 1/vid.FrameRate;
% plotting tracks:
tp = fileparts(which('MTF_export_figures'));
tfs = strfind(tp,filesep);

load([tp(1:tfs(end-1)) 'LocoMouse_GlobalSettings' filesep 'colorscheme.mat']);

Legend = {'FR','HR','FL','HL','Tail','Snout'};
N_images = size(final_tracks,3);



% X vs time or frame for 4 paws.
fig1 = figure();
hold on
for i_paw = 1:4
    plot([1:N_images]*f2t,squeeze(final_tracks(1,i_paw,:)),'-','Color',PointColors(i_paw,:),'LineWidth',2);
end
title('Paws: x over time')
xlabel('time [s]')
ylabel('x position [px]')
legend(Legend(1:4),'Location','NorthWest');
set(fig1, 'Position', get(0,'Screensize')); % Maximize figure.

% Z vs time for FR FL
% Z vs time for HR HL
pairs = [1 2;3 4];
fig2 = figure();
for i_pairs = 1:2
    subplot(2,1,i_pairs)
    xlabel('time [s]')
    ylabel('z position [px]')
    hold on
    plot([1:N_images]*f2t,squeeze(final_tracks(3,pairs(i_pairs,1),:)),'-','Color',PointColors(pairs(i_pairs,1),:),'LineWidth',2);
    plot([1:N_images]*f2t,squeeze(final_tracks(3,pairs(i_pairs,2),:)),'-','Color',PointColors(pairs(i_pairs,2),:),'LineWidth',2);
    legend(Legend(pairs(i_pairs,:)),'Location','NorthWest');
    switch i_pairs
        case 1
            title('Front paws Paws: height over time')

        case 2
            title('Hind paws Paws: height over time')
    end
    axis ij tight
end
set(fig2, 'Position', get(0,'Screensize')); % Maximize figure.

% Y vs X for tail
type = {'X vs Z','X vs Y'};
fig3 = figure();

idx = {[1 2],[1 3]};
for i_tail = 1:2
    subplot(2,1,i_tail)
    for t_p = 1:size(tracks_tail,2)
        plot(squeeze(tracks_tail(idx{i_tail}(1),t_p,:))',squeeze(tracks_tail(idx{i_tail}(2),t_p,:))','-','LineWidth',2,'Color',TailColors(t_p,:));
        hold on
    end
    legend(type{i_tail},'Location','NorthEast');
    
	xlabel('x position [px]')
    switch type{i_tail}
        case 'X vs Z'
            title('Tail: side view')
             ylabel('z position [px]')
        case 'X vs Y'
            title('Tail: bottom view')
             ylabel('y position [px]')
    end
 
end
set(fig3, 'Position', get(0,'Screensize')); % Maximize figure.

fig4 = figure();
title('Snout')
    subplot(3,1,1)
    plot(squeeze(final_tracks(1,5,:)),'-','LineWidth',2,'Color',PointColors(5,:))
    title('Snout')
    ylabel('X')
    subplot(3,1,2)
    plot(squeeze(final_tracks(2,5,:)),'-','LineWidth',2,'Color',PointColors(5,:))
    ylabel('Y')
    subplot(3,1,3)
    plot(squeeze(final_tracks(3,5,:)),'-','LineWidth',2,'Color',PointColors(5,:))
    ylabel('Z')
    xlabel('frame')
set(fig4, 'Position', get(0,'Screensize')); % Maximize figure.
             
drawnow;

if exist('export_fig')==2 % DE
    export_fig(fig1,sprintf('%s_x_vs_t.png',[seq_path filesep seq_name]),'-native');
    export_fig(fig2,sprintf('%s_Time_vs_Z.png',[seq_path filesep seq_name]),'-native');
    export_fig(fig3,sprintf('%s_%s.png',[seq_path filesep seq_name],Legend{5}),'-native');
    export_fig(fig4,sprintf('%s_%s.png',[seq_path filesep seq_name],Legend{6}),'-native');
else
	saveas(fig1,sprintf('%s_x_vs_t.png',[seq_path filesep seq_name]));
    saveas(fig2,sprintf('%s_Time_vs_Z.png',[seq_path filesep seq_name]));
    saveas(fig3,sprintf('%s_%s.png',[seq_path filesep seq_name],Legend{5}));
    saveas(fig4,sprintf('%s_%s.png',[seq_path filesep seq_name],Legend{6}));
    saveas(gcf,sprintf('%s_x_vs_t.png',seq_name));
    warning('Figures were exported using saveas(). Results may be better using export_fig(). See https://github.com/altmany/export_fig')
end

close(fig1,fig2,fig3,fig4)