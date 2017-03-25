% readMouseImage: 
% Reads a LocoMouse setup image from a MATLAB vid sturcture
% containing a LocoMouse video file.
%
% NECESSARY INPUT:
% vid: The Matlab video structure.
% frame_number: The scalar representing the frame number.
% Bkg: The background image.
% flip: A boolean that is true if the image must be flipped vertically.
% scale: A scale in case the image needs to be rescaled.
% ind_warp_mapping: A vid.Height*vid.Width vector with the pixel to pixel
% mapping to warp the raw images into the "undistorted" format (i.e.
% vertical lines should match between views).
% expected_im_size: The expected size for the images in vid. If the images
% are smaller they will be padded with zeros. If they are larger, an error
% will occur.
%
% OPTIONAL INPUTS:
% use a string for the property name, followed by the value.
%
% Properties:
% 'h_flip'     : flips the bottom image horizontally (needs split_line)
% 'split_line' : sets the split_line
%
% Example: 
% readMouseImage(...,'h_flip',true);
%
% OUTPUT:
% Img: A grayscale image read from vid. If vid is a colour video, the image
% will be converted to grayscale as colour is not supported.


function [Img,ImgAux] = readMouseImage(varargin)

% Assign necessary inputs:
[vid,frame_number,Bkg,flip,scale,ind_warp_mapping,expected_im_size] = varargin{1:7};

% Assign optional inputs
setVars = {};
if size(varargin,2) > 7
    for tvar = 8:2:size(varargin,2)
        try
            if ~ischar(varargin{tvar+1})
                varargin{tvar+1} = num2str(varargin{tvar+1});
            end
            eval([varargin{tvar},' = varargin{tvar+1};'])
            setVars = [setVars {varargin{tvar}}];
        catch tError
            disp(tError.message)
        end
    end
end

for tSV = 1:size(setVars,2)
    tVar = setVars{tSV};
    switch tVar
        case 'h_flip'
            if ~any([h_flip == true h_flip == false])
                if ~ischar(h_flip)
                    if h_flip == 1
                        h_flip = true;            
                    elseif h_flip == 0
                        h_flip = false; 
                    else
                        warning('readMouseImage: h_flip must be 1 or 0. Set to false.')
                    end
                    if ~exist('split_line','var')
                        warning('readMouseImage: h_flip needs split_line.')
                        h_flip = false;
                    end
                    
                else
                 warning('readMouseImage: h_flip must be 1 or 0. Set to false.')
                end
            else
                h_flip = false;
            end
            
        case 'split_line'
            if ischar(split_line)
                split_line = -1;
                warning('readMouseImage: split_line must be a number.')
                
            elseif any([split_line >= size(Bkg,1) split_line <= 1])
                split_line = -1;
                warning('readMouseImage: split_line outside image boundaries.')
            end
            if ~exist('h_flip','var')
                warning('readMouseImage: split_line is only used with h_flip.')
                split_line = -1;
            end
            
        case 'contrast_template'
            if ischar(contrast_template)
                if ~isempty(fileparts(contrast_template))
                    [~,~,tcte] = fileparts(contrast_template);
                    if strcmp(tcte,'.mat')
                        if exist(contrast_template,'file')==2
                            try
                                load([contrast_template],'TEMPLATE')
                            catch tError
                                warning('readMouseImage: contrast_template does not contain TEMPLATE.')
                            end
                            if exist('TEMPLATE','var')
                                if length(Bkg(:)) == length(TEMPLATE)
                                    UseTemplate = true;
                                else
                                    warning('readMouseImage: TEMPLATE had the wrong size.')
                                end
                            end
                        else
                            warning('readMouseImage: contrast_template does not exist.')
                        end
                    else
                        warning('readMouseImage: contrast_template must be a .mat file.')
                    end
                else
                    warning('readMouseImage: contrast_template must be a path.')
                end
            else
                warning('readMouseImage: contrast_template must be a string.')
            end
            
        case 'SmoothIt'
            if ischar(SmoothIt)
                SmoothIt = str2num(SmoothIt);
            end
            if ~isempty(SmoothIt)

                if mod(SmoothIt,2)==0
                    SmoothIt = SmoothIt+1;
                end
                if SmoothIt <= 0
                    SmoothIt = 3;
                end
            else
                warning('Wrong Value for SmoothIt')
                clear SmoothIt
            end
                
        otherwise
            warning(['readMouseImage: Unknown property "',tVar,'".'])
    end
end

if ~exist('UseTemplate','var')
    UseTemplate = false;
end

if ~exist('h_flip','var')
    h_flip = false;
end

if ischar(vid)
    vid = VideoReader(vid);
end

if ischar(Bkg) && ~isempty(Bkg)
    Bkg = imread(Bkg);
end

if ~exist('expected_im_size','var')
    expected_im_size = size(ind_warp_mapping);
end
Img = read(vid,frame_number);

% Checking for colour: sometimes the LocoMouse system wrongly outputs
% colour video even though the camera is grayscale. This is potentially
% using too much disk space since the videos are in raw format...
if size(Img,3) > 2
    Img = rgb2gray(Img);
end

% Removing background and spreading brightness values:
if ~isempty(Bkg)
    Img = Img-Bkg; 
end
Img = Img-min(Img(:));
m = max(Img(:));
Img = uint8((double(Img)/double(m))*255);

% Apply contrast template.
if UseTemplate
    [~,b] = sort(Img(:));
    [I,J] = ind2sub(size(Img),b);
    n_Img = uint8(zeros(size(Bkg)));
    for tpx = 1:length(b)
        n_Img(I(tpx),J(tpx))=TEMPLATE(tpx);
    end
    Img = uint8((double(n_Img)/double(m))*255);
end

% Smooth Image
if exist('SmoothIt','var')
    
        for X = 1:SmoothIt
            for Y = 1:SmoothIt
                t_Pos(X,Y)=sqrt(sum(abs([X Y]-[ceil(SmoothIt/2)  ceil(SmoothIt/2)]).^2));
            end
        end
        Y = 1-normpdf(1-(t_Pos/max(t_Pos(:))));
        Img = conv2(double(Img),double(Y));
        Img = uint8(Img/max(Img(:))*255);
        
        margin = (size(Img,1)-size(Bkg,1))/2;
        Img = Img(margin+1:end-margin,margin+1:end-margin);    
        Img = Img-min(Img(:));
        m = max(Img(:));
        Img = uint8((double(Img)/double(m))*255);
end

% If requested, unwarp the image:
if ~exist('ind_warp_mapping','var')
    ImgAux = [];
else
    if ~isempty(ind_warp_mapping)
        Img_size = size(Img);
        if all(Img_size <= expected_im_size)
            if ~all(Img_size == expected_im_size)
                % If the map is larger than the image, the image is padded with
                % zeros.
                padd_amount = floor((expected_im_size-Img_size)/2);
                Img = padarray(Img, padd_amount, 0,'both');
                Img = padarray(Img, expected_im_size-Img_size-2*padd_amount,0,'post');
            end
        else
            % If the map is smaller than the image, the image is cropped to
            % the size of the map.
            error('Image is larger than expected!');
        end
        
        ImgAux = gpuArray(uint8(zeros(size(ind_warp_mapping))));ImgAux(:) = Img(ind_warp_mapping(:));
    else
        ImgAux = [];
    end
end

% Resizing it:
if scale ~= 1
    Img = imresize(Img,scale);
    if ~isempty(ImgAux)
        ImgAux = imresize(ImgAux,scale);
    end
end

% vertical flip
if flip
    Img = Img(:,end:-1:1);
    if ~isempty(ImgAux)
        ImgAux = ImgAux(:,end:-1:1);
    end
end

% horizontal flip of the bottom image
if h_flip && split_line > -1
    [I_side, I_bottom] = splitImage(Img, split_line);
    Img = [I_side; I_bottom(end:-1:1,:)];
     if ~isempty(ImgAux)
        [I_side, I_bottom] = splitImage(ImgAux, split_line);
        ImgAux = [I_side; I_bottom(end:-1:1,:)];
     end

end
Img =uint8(gather(Img));
ImgAux = uint8(gather(ImgAux));