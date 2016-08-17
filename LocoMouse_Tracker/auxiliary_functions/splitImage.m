function [I_top, I_bottom] = splitImage(I, split_line)
% SPLITIMAGE    Splits the image into upper and lower half according to the
% level set by split_line.
%
% Input:
% 
% I: the NxM image.
% split_line: an integer between 0 and N. 0 returns I in I_bottom, N
% returns I in I_top.

N = size(I,1);

if split_line < 0 || split_line > N
    error('split_line must be between 0 and N');
end

split_line = round(split_line);

I_top = I(1:split_line,:);
I_bottom = I(split_line+1:end,:);