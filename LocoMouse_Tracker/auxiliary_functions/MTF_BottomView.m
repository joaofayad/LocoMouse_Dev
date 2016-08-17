function [M, final_tracks] = MTF_BottomView(varargin)

% Perform bottom view tracking: Tracking is first solved for the bottom
% view case as that is the simplest and more reliable.
% FIXME: Code is a duplication of a part in MTF_rawdata()
%        when this function works, replace the MTF_rawdata() part
%        with a call to this function!
%   GETS:
    N_pointlike_tracks = varargin{1}; 
    N_frames = varargin{2};
    N_pointlike_features = varargin{3};
    model = varargin{4};
    Unary = varargin{5};
    Pairwise = varargin{6};
    Nong = varargin{7};
	point_features = varargin{8};
% original (MTF_rawdata) by Joao Fayad    
% edited by Dennis Eckmeier, 2016


    M = cell(N_pointlike_tracks,1);
    final_tracks = NaN(3,N_pointlike_tracks,N_frames);

    for i_point = 1:N_pointlike_features
        % The method used for tracking is not invariant to the order of
        % the features (i.e. the order of the columns on the unary
        % potential). Thus we run all possible combinations of inputs
        % and take the solution with higher score. In case of draw the
        % first one is picked.

        O = combinator(model.point.(point_features{i_point}).N_points,model.point.(point_features{i_point}).N_points,'p'); %FIXME: To generalize the code for other
        N_order = size(O,1);

        if N_order > 1
            m = cell(1,N_order);
            U = Unary(i_point,:);
            P = Pairwise(i_point,:);
            Cost = zeros(1,N_order);
            for i_o = 1:N_order
                u = cellfun(@(x)(x(:,O(i_o,:))),U,'un',false);
                m{i_o} = match2nd(u,P,[],Nong,0);
                c = computeMCost(m{i_o},u,P(1,:));
                Cost(i_o) = sum(c(:));
            end
            [~,imax] = max(Cost);
            M{i_point}(O(imax,:),:) = m{imax};
            clear U P T Cost m u c imax
        else
            M{i_point} =  match2nd (Unary(i_point,:), Pairwise(i_point,:), [],Nong, 0);
        end
    end
    clear O Norder
    M = cell2mat(M);
    
end