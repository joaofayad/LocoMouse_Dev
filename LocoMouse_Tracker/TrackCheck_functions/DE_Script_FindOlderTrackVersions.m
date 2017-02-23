AVIs = ls('C:\Users\Dennis\Documents\DATA_DarkvsLight_Overground\DARKNESS_160621\*.avi');

for t_avi_i = 1:size(AVIs,1)
    [~,fn,~] = fileparts(AVIs(t_avi_i,:));
    data_files = ls(['C:\Users\Dennis\Documents\DATA_DarkvsLight_Overground\LM_output\data\',fn,'*']);
    for tfile = 1:size(data_files,1)
        
        
            t_track_varNames = fieldnames(loaded_data);
            tracks_vers = strfind(t_track_varNames,'tracks_');
            t_track_ver = false(size(tracks_vers));
            for ver_i =1:size(tracks_vers,1)
                tracks_vers{ver_i} == 1
                if ~isempty(tracks_vers{ver_i} == 1)
                    t_track_ver(ver_i) = tracks_vers{ver_i} == 1;
                end
            end
            t_track_varNames{t_track_ver};
    end
%     data_files = reshape(data_files',[1 size(data_files,1)*size(data_files,2)]);
    
end
