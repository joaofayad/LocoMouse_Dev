function I = backgroundSubtractionT(I,Bkg,t)
% BACKGROUNDSUBTRACTIONT Subtracts Bkg from I only on pixels where the
% difference between I and Bkg is less or equal to t.
%
% This is to avoid subtraction of the background when an object with a
% clearly different colour is moving in front of it. Results will vary
% greatly with t.
%
% t should be defined from 0 to 1. It can be defined from 0 to 255 but must
% be provided as uint8.

if t < 0
    error('t must be defined between 0 and 1 or 0 and 255, according to the class of I.');
end

if (t > 0 && t < 1 && isinteger(I))
    t = min(t,1);
    t = uint8(t*255);
end

if strcmpi(class(I),class(t))
    error('I and t must have compatible classes.');
end

Mask = Bkg - t < I;
I(Mask) = I(Mask) - Bkg(Mask);