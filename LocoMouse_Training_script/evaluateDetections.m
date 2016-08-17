function [labels, detection_scores] = evaluateDetections(detections, ground_truth, box_size, threshold)
% EVALUATEDETECTIONS    Checks if the detected boxes are true of false
% positives. Returns unmatched boxes as false negatives.
%
% In this scenario the size of the bounding box is fixed, thus we only need
% to compare the distance between the centers of the detected boxes and
% ground truth.
%
% INPUT:
% detections: a 2xN matrix with the 2D coordinates of N detections.
%
% ground_truth: a 2xG matrix with the 2D coordinates of the G ground
% truth boxes.
%
% box_size: the size of the bounding box. 
%
% threshold: Decision threshold of how close a detected center should be of
% the ground truth to be considered a positive detection. It is defined as
% a percentage of the box size (e.g. if box_size is [10 20] and threshold
% is 0.5, any detection within the sub box of size [5 10] is considered to
% be a true detection).
%
% OUTPUT:
%
% label: a binary NxF matrix which is true/false for true/false positives.
%
% overlap_score: a NxF matrix with the pascal detection score (i.e.
% Area_Intersection/Area_Union)
%
% false_negatives: a binary G-vector which is true when a given ground
% truth box had no detections.

[~,Ngt] = size(ground_truth);

Ndect = size(detections,2);

labels = false(Ndect,Ngt);
detection_scores = zeros(Ndect,Ngt);

if Ndect > 0
    box2 = prod(box_size)*2;
    
    GT_s = bsxfun(@minus,ground_truth,floor(box_size/2));
    GT_e = bsxfun(@plus,GT_s,box_size);
    
    Det_s = bsxfun(@minus,detections,floor(box_size/2));
    Det_e = bsxfun(@plus,Det_s,box_size);
    
    for i_gt = 1:Ngt
        for i_dec = 1:Ndect
            % Overlap:
            iw = min(GT_e(1,i_gt),Det_e(1,i_dec)) - max(GT_s(1,i_gt),Det_s(1,i_dec));
            if iw <= 0, continue; end
            ih = min(GT_e(2,i_gt),Det_e(2,i_dec)) - max(GT_s(2,i_gt),Det_s(2,i_dec));
            if ih <= 0, continue; end
            
            o = iw * ih;
            u = box2 - o;
            detection_scores(i_dec, i_gt) = o/u;
            if detection_scores(i_dec, i_gt) > threshold
                labels(i_dec, i_gt) = true;
            end
        end
    end
end