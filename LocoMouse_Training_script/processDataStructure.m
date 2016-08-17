function [data,L] = processDataStructure(dataset, i_videos)
% processDataStructure  Extracts information from the dataset to prepare
% the data structure for extracting labels or evaluating detectors.
[~,video_name,~] = fileparts(dataset.training_vid{i_videos});
vid_is_char = ischar(dataset.training_vid{i_videos});
vid_is_videoreader = strcmpi(class(dataset.training_vid{i_videos}),'videoreader');

if vid_is_char
    data.vid = VideoReader(fullfile(dataset.path, dataset.training_vid{i_videos}));
elseif vid_is_videoreader
    data.vid = dataset.training_vid{i_videos};
else
    error('Could not read video data for video %d',i_videos);
end

% Loading labelled data:
if isempty(dataset.training_labels{i_videos}) && vid_is_char
    L = load(fullfile(dataset.path,sprintf('%s_labelling.mat',video_name)));
    fprintf('Loaded labelling file %s\n', sprintf('%s_labelling.mat',video_name));
    
    prop_check = {'vid', 'bkg_path' , 'calibration_path'};
    
    for i_prop = 1:length(prop_check)
        
        if exist(L.(prop_check{i_prop}),'file')
           fprintf('Found file %s for property %s.\n',L.(prop_check{i_prop}),prop_check{i_prop});
        else
            fprintf('Could not find file %s for property %s.\n',L.(prop_check{i_prop}),prop_check{i_prop});
            if (any(L.(prop_check{i_prop}) == ':') || any(L.(prop_check{i_prop}) == '\')) && isunix
                fprintf('Seems like a Windows path. Parsing as such.\n');
                last_pos = find(L.(prop_check{i_prop}) == '\',1,'last');
                fname = L.(prop_check{i_prop})(:,last_pos+1:end);
            elseif (any(L.(prop_check{i_prop}) == '/')) && ispc
                fprintf('Seems like a Linux or MacOS path. Parsing as such.\n');
                last_pos = find(L.(prop_check{i_prop}) == '/',1,'last');
                fname = L.(prop_check{i_prop})(:,last_pos+1:end);
            else
                [~,name,ext] = fileparts(L.(prop_check{i_prop}));
                fname = [name ext]; clear name ext
            end
            
            fprintf('Searching for file %s in current dataset path...',fname);
            
            if exist(fullfile(dataset.path,fname),'file') && ~isempty(fname)
                fprintf('FOUND!\n');
                L.(prop_check{i_prop}) = fullfile(dataset.path,fname);
            else
                fprintf('NOT FOUND!\n');
                if i_prop == 1
                    error('Algorithm cannot continue without a vid file!');
                else
                    L.(prop_check{i_prop}) = '';
                    warning('Training will be performed without using %s.',prop_check{i_prop});
                end
            end
            fprintf('\n');
        end
        
    end
    
elseif vid_is_char
    if exist(fullfile(dataset.path,dataset.training_labels{i_videos}),'file')
        L = load(fullfile(dataset.path,dataset.training_labels{i_videos}));
    else
        error('Could not load labelling file for %s!\n',dataset.training_vid{i_videos});
    end
else
    error('Could not load labelling file for video file %d!\n',dataset.training_vid{i_videos});
end

if ischar(dataset.bkg{i_videos})
    switch dataset.bkg{i_videos}
        case 'compute'
            data.bkg = computeMedianBackground(data.vid);
        case ''
            if exist(L.bkg_path,'file')
                data.bkg = imread(L.bkg_path);
            else
                warning('%s: Could not find background file. Training without background subtraction!\n',L.bkg_path);
                data.bkg = '';
            end
        otherwise
            data.bkg = imread(dataset.bkg{i_videos});
    end
    
else
    data.bkg = dataset.bkg{i_videos};
end

dataset.bkg{i_videos} = data.bkg;

% Loading calibration files it they exist:
if exist(L.calibration_path,'file')
    CAL = load(L.calibration_path);
    data.ind_warp_mapping = CAL.ind_warp_mapping;
    data.inv_ind_warp_mapping = CAL.inv_ind_warp_mapping;
    % NOTE: We will use the split line from the labelling as this might
    % have been edited.
    clear CAL
else
    data.ind_warp_mapping = [];
    data.inv_ind_warp_mapping = [];
end