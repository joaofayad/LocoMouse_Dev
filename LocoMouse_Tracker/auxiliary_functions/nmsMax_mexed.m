function [D2_nms, scores,kp] = nmsMax_mexed(D2_coordinates,box_size, scores, coordinates, overlap)
% nmsMax_mexed performs non-maxima suppresion on 2D coordinates using the Pascal
% criterium of intersection_area/union_area > overlap -> suppression.
%
% USAGE: D2_nms = nmsMax_mexed(D2_coordinates, box_size, scores, overlap)
%
% INPUT:
% DD2_coordinates: 2D coordinates defined as: [i j]
% box_size: [h w]
% overlap: decision boundary for supression (between 0 and 1).
% coordinates: string specifying if coordinates are defined at the center
% of the box or at the top left corner (default: center);
%
% for each i suppress all j st j>i and area-overlap>overlap
%
% The core of the function is performed in C using a mex file
% implementation for speedups. There is some pre-processing done in MATLAB.
% Author: Joao Fayad (joao.fayad@neuro.fchampalimaud.org). Based on code
% from Piotr Dollar. 
% Last Modified: 17/11/2014


if isempty(D2_coordinates)
    D2_nms = [];
    scores = [];
    return;
end

[scores,ord] = sort(scores,'descend'); D2_coordinates = D2_coordinates(ord,:);

% if ~exist('coordinates','var')
%     coordinates = 'center';
% elseif isempty(coordinates)
%     coordinates = 'center';
% end
% 
% if ~any(strcmpi(coordinates,{'center','tlcorner'}))
%     error('coordinates must be either ''center'' or ''tlcorner''.');
% end
%
if ~exist('overlap','var')
    overlap = 0.5;
end

% Converting center coordinates to box limits:
box_size = box_size(:)';
n = size(D2_coordinates,1);
box_size = repmat(box_size,n,1);

if strcmpi(coordinates,'center')
    DD2_coordinates_s = D2_coordinates - floor(box_size./2);
else
    DD2_coordinates_s = D2_coordinates;
end

DD2_coordinates_e = DD2_coordinates_s + box_size;

kp = nmsMax_mex(DD2_coordinates_s', DD2_coordinates_e', box_size, scores, overlap);
kp = ~kp;
D2_nms = D2_coordinates(kp,:);
scores = scores(kp);