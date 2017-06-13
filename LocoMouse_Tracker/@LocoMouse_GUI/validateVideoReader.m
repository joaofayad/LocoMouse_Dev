function [] = validateVideoReader(gui)
% Determines which video files VideoReader supports.
sup_files = VideoReader.getFileFormats;

gui.N_supported_files = size(sup_files,2);
gui.N_supported_files_menu = gui.N_supported_files+1;
gui.supported_files = cell(gui.N_supported_files_menu,2);
gui.supported_files(2:end,1) = cellfun(@(x)(['*.',x]),{sup_files(:).Extension},'un',false)';
gui.supported_files(2:end,2) = {sup_files(:).Description};
gui.supported_files{1,1} = cell2mat(cellfun(@(x)([x ';']),gui.supported_files(2:end,1)','un',false));
gui.supported_files{1,2} = 'All supported video files';
end