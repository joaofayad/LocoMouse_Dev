function D = importLocoMouseYAML(yaml_file)
fid = fopen(yaml_file,'r');

if fid < 0
    error('Failed to read input file %s.',yaml_file);
end

% Prevents problems when code crashes.
safe_fid = onCleanup(@()(fclose(fid)));

line = fgetl(fid);

if ~strcmpi(line,'%YAML:1.0')
    error('This function reads only YAML:1.0 files. Such files should have the appropriate "%YAML:1.0" header.');
end

line = fgetl(fid);
fields = strsplit(line,':');
if strcmpi(fields{1},'N_opencv_matrices')
    N_opencv_matrices = str2double(fields{2});
    M = readOpenCVMat(fid,N_opencv_matrices);
    
    % Assigning M to the correct fields of D:
    D.M = cat(1,M{1:2}) + 1;
    D.M_top = cat(1,M{3:7}) + 1;
    
    rest_of_file = fscanf(fid,'%c',inf);
else
    rest_of_file = fscanf(fid,'%c',inf);
    rest_of_file = cat(1,sprintf('%s\n',line),rest_of_file);
end

S = YAML.load(rest_of_file);

% Transform the YAML structure into the expected MATLAB structure:
% Note: C++ coordinates start at 0.
D.occluded_distance = S.occluded_distance;
D.bounding_box = [S.bb_x_avg(:) S.bb_yb_avg(:) S.bb_yt_avg(:)]' + 1;
D.bounding_box_dim = [S.BB_bottom.width;S.BB_bottom.height;S.BB_top.height];
D.Occlusion_Grid_Bottom = bsxfun(@minus,D.bounding_box_dim(1:2),reshape(S.ONG.x_y_coordinates,2,S.ONG.points));
D.xvel = diff(S.bb_x_avg(:))';
D.Occlusion_Vect_Top = S.ONG_top.z_coordinates(:)' + 1;
D.nong_vect = D.Occlusion_Vect_Top + 1;
D.Unary = cell(2,S.N_frames);
D.Pairwise = cell(2,S.N_frames);
D.tracks_bottom = cell(2,S.N_frames);
D.tracks_top = cell(5,S.N_frames);
% D.occluded_distance = S.occluded_distance;

Nong_bottom = size(D.Occlusion_Grid_Bottom,2);

x_offset = D.bounding_box(1,:) - S.BB_bottom.width + 1;
yb_offset = D.bounding_box(2,:) - S.BB_bottom.height + 1;
yt_offset = D.bounding_box(3,:) - S.BB_top.height + 1;

for i_frames = 1:S.N_frames
    % Paws:
    [D.tracks_bottom{1,i_frames},D.tracks_top(1:4,i_frames)] = getTracks(S.candidates_paw_bottom_top_matched{i_frames},D.M(1:4,i_frames),x_offset(i_frames),yb_offset(i_frames), yt_offset(i_frames));
      
    %Snout:
    [D.tracks_bottom{2,i_frames}, D.tracks_tail(5,i_frames)] = getTracks(S.candidates_paw_bottom_top_matched{i_frames},D.M(5,i_frames), x_offset(i_frames), yb_offset(i_frames), yt_offset(i_frames));
   
    % Unary:
    D.Unary{1,i_frames} = getMatrix(S.Unary_paws(i_frames));
    D.Unary{2,i_frames} = getMatrix(S.Unary_snout(i_frames));
    
    % Pairwise:
    if i_frames < S.N_frames
        D.Pairwise{1,i_frames} = getPairwise(S.Pairwise_paws(i_frames));
    end
    
    if i_frames < S.N_frames
        D.Pairwise{2,i_frames} = getPairwise(S.Pairwise_snout(i_frames));
    end
        
end
clear tracks_bottom;

function M = readOpenCVMat(fid, N)

M = cell(1,N);

for i_mat = 1:N
    
    % Matrix name:
    line = fgetl(fid);
    fields = strsplit(line,': ');
    
    load_error = false;
    if length(fields) < 2
        load_error = true;
    elseif ~strcmpi(fields{2},'!!opencv-matrix')
        load_error = true;
    end
    
    if load_error
        error('Failed to read opencv-matrix. Check if the number of matrices is properly defined.');
    end
    
    row_line = strsplit(fgetl(fid),': ');
    N_rows = str2double(row_line{2});
    
    col_line = strsplit(fgetl(fid),': ');
    N_cols = str2double(col_line{2});
    
    data_line = strsplit(fgetl(fid),': ');
    data_type = data_line{2};
    
    %Data lines:
    M{i_mat} = zeros(N_cols,N_rows); % C++ is row major!
    
    if strcmpi(data_type, 'u')
        M{i_mat} = uint8(M{i_mat});
    end
    
    line = fgetl(fid);
    fields = strsplit(line,': ');
    first_line_num = sscanf(fields{2}(2:end),'%f,',inf);
    N_first_line = length(first_line_num);
    
    M{i_mat}(1:N_first_line) = first_line_num;
    
    if N_first_line < numel(M{i_mat})
        M{i_mat}((N_first_line+1):end) = fscanf(fid,'%f,',inf);
        fgetl(fid); %rest of last line
    end
    
    M{i_mat} = M{i_mat}';
end

function [tracks_bottom,tracks_top] = getTracks(struct,M, x_bias, y_bias, z_bias)
N_candidates = length(struct);
tracks_bottom = zeros(3,N_candidates);

tracks_top = cell(size(M,1),1);

for i_tb = 1:N_candidates
    tracks_bottom(1,i_tb) = struct(i_tb).Candidate_bottom.Point_x + x_bias;
    tracks_bottom(2,i_tb) = struct(i_tb).Candidate_bottom.Point_y + y_bias;
    tracks_bottom(3,i_tb) = struct(i_tb).Candidate_bottom.Score;
end

for i_tt = 1:size(M,1)
    
    if M(i_tt) <= N_candidates
        tracks_top{i_tt} = zeros(4,struct(M(i_tt)).n_candidates_top);
        tracks_top{i_tt}(1:2,:) = repmat(tracks_bottom(1:2,M(i_tt)),1,struct(M(i_tt)).n_candidates_top);
        tracks_top{i_tt}(3,:) = struct(M(i_tt)).Candidates_top + z_bias;
        tracks_top{i_tt}(4,:) = struct(M(i_tt)).Scores_top;
    else
        tracks_top{i_tt} = zeros(4,0);
    end
end

function P = getPairwise(pairwise_mat_struct)
% C++ index starts at 0
P = sparse(pairwise_mat_struct.row_index+1,pairwise_mat_struct.col_index+1,pairwise_mat_struct.data);

function M = getMatrix(mymat_struct)
% C++ index starts at 0!
M = reshape(mymat_struct.data,mymat_struct.n_rows,mymat_struct.n_cols);



% read_loop = true;
% identation = 0;
% while(read_loop)
%
%     line = fgetl(fid);
%
%     if line == -1
%         %EOF
%         read_loop = false;
%         continue;
%     end
%
%     % Exclude comments:
%     comment = find(line == '%');
%     if ~isempty(comment)
%         line = line(1:comment(1));
%     end
%
%     % Detecting field type:
%     fields = strsplit(line,':');
%
%     switch fields{1}
%         case 'N_frames'
%             S.N_frames = str2double(fields{2});
%         case 'BB_top'
%             S.BB_top = readBB();
%         case 'BB_bottom'
%             S.BB_bottom = readBB();
%         case 'bb_x_avg'
%             S.bb_x_avg = readArray(fields{2},fid);
%         case 'bb_yt_avg'
%             S.bb_yt_avg = readArray(fields{2},fid);
%         case 'bb_yb_avg'
%             S.bb_yb_avg = readArray(fields{2},fid);
%         case 'ONG'
%             S.ONG = readONG_bottom(fid);
%         case 'ONG_top'
%             S.ONG_top = readONG_top(fid);
%         case 'candidates_paw_bottom_top_matched'
%             if isfield(S.N_frames)
%                 N_frames = S.N_frames;
%             else
%                 N_frames = -1;
%             end
%             S.candidates_paw_bottom_top_matched = readCandidatesMatched(fid,N_frames);
%         otherwise
%             'wtf';
%     end
% end
%
%
%
% function array = readArray(first_line, fid)
% array = sscanf(first_line(2:end),'%f,');
% if ~any(first_line == ']');
%     array = cat(1,array,fscanf(fid,'%f,'));
%     fgetl(fid); % clears rest of line
% end
%
% function ONG = readONG_top(fid)
% % points:
% fields = strsplit(fgetl(fid),':');
% ONG.points = str2double(fields{2});
% % z_coordinates:
% fields = strsplit(fgetl(fid),': ');
% ONG.z_coordinates = readArray(fields{2},fid);
%
% function ONG = readONG_bottom(fid)
% % points:
% fields = strsplit(fgetl(fid),':');
% ONG.points = str2double(fields{2});
% % x_y_coordinates:
% fields = strsplit(fgetl(fid),': ');
% ONG.x_y_coordinates = reshape(readArray(fields{2},fid),2,ONG.points);
%
% function candidates_matched = readCandidatesMatched(fid,N_frames)
% if N_frames > 0
%     candidates_matched = cell(1,N_frames);
%
%     for i_candidates = 1:N_frames
%
%         candidates_matched{i_candidates} = readCandidateList(fid);
%
%     end
% else
%     candidates_matched = {};
%     % Implement loop that checks for the existence of a candidate
%
% end
%
% function candidates = readCandidateList(fid)
% % candidate_frame_i
% line = fgetl(fid);
% % length of candidate_list:
% fields = strsplit(fgetl(fid),': ');
% N_candidates = str2double(fields{2});
%
% candidates = struct('candidate_bottom',cell(1,N_candidates),'
%
% for i_candidates = 1:N_candidates
% end
%
%
%
