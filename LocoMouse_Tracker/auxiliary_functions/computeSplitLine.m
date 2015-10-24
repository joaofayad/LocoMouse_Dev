function mirror_line = computeSplitLine(vid,Bkg,N)
% COMPUTESPLITLINE Computes a horizontal line that splits the top and
% bottom side of an image/video of the LocoMouse setup.
%
% INPUT:
% vid: A video structure from MATLAB
% Bkg: A background image (optional);
% N: How many images to use in the estimation (optional). Default value is
% min(100,vid.NumberOfFrames). Images will be spaced by
% N/vid.NumberOfFrames;
%
% OUPUT:
% mirror_line: A scalar representing the pixel index where the images
% should be split such that Itop = I(1:mirror_line,:); Ibottom =
% I(mirror_line+1:end,:);
%
% The idea behind this function is to sample the whole video and determine
% where in the image the mouse walks. The whole movie is collapsed into
% the mean pixel value of that

if ~exist('N','var')
N = min(100,vid.NumberOfFrames);
end

% The likelihood of being located in the middle is higher. We thus exclude
% the top and bottom third of the image.
ithird = round(vid.Height/3);
Bkg = Bkg(ithird:end-ithird,:);
if vid.NumberOfFrames == N
    Iset = read(vid,[1 N]);
    if size(Iset,3) > 1
        % Not exactly the same as using rgb2gray, but our videos are not 
        % supposed to have colour, that happens because of bugs in the 
        % capture code.
        Iset = squeeze(Iset(:,:,1,:)); 
    end
    Iset = bsxfun(@minus,Iset(ithird:end-ithird,:,:),Bkg);
else
    Iset = uint8(zeros(length(ithird:vid.Height-ithird),vid.Width,N));
    for i_images = 1:round(vid.NumberOfFrames/(N-1)):vid.NumberOfFrames
        temp = read(vid,i_images);
        if size(temp,3) > 1
            temp = temp(:,:,1);
        end
        Iset(:,:,i_images) = temp(ithird:end-ithird,:)-Bkg;
    end   
end

% We take the line with the minimum sum accross the other two dimensions:
[~,mirror_line] = min(sum(sum(double(Iset),3),2));
mirror_line = mirror_line + ithird -1;
