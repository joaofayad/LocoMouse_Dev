function Iout = trimBoxes(Iin,box_size)
% Trims the iamge(s) in Iin
%
% INPUT:
% Iin: Any tensor of size IxJxN. Usually N will be the number of images or
% 3 times the number of images for RGB.
% box_size: New box_size as a 2-vector. At least one of the entries must be
% smaller than the original image size for the corresponding dimension.

input_size = size(Iin);
input_size = input_size(1:2);
box_size = box_size(:)';
if any(input_size < box_size)
    error('At least one entry of box_size must be smaller than the corresponding input size!');
end

% Computing the displacement of the image:
center_input = ceil(input_size/2);
center_output = ceil(box_size/2);

% This keeps the center consistently at ceil(box_size/2):
row_trim = (1:box_size(1))-center_output(1)+center_input(1);
col_trim = (1:box_size(2))-center_output(1)+center_input(1);
Iout = Iin(row_trim,col_trim,:);