function [Cout, C_inv_out] = LocoMouse_ResizeCalibration(C, C_inv, mode, params)
    % LocoMouse_ResizeCalibration   Resizes calibration matrices to match new
    % image sizes.
    %
    %   The LocoMouse tracker might need videos to be rescaled if the original
    %   videos are at a substantially different scale from the original
    %   training data. The best approach to generate new calibration matrices
    %   is to rescale the calibratio video. When that is not possible this
    %   function rescales a calibration performed at the original resolution.
    %
    %   Usage:
    %
    %   LocoMouse_ResizeCalibration(C, C_inv, 'rescale', scale): Resizes the
    %   calibration matrix C and C_inv to work on images that were rescaled
    %   using imresize(I, scale) (or equivalent operation).
    %
    %   LocoMouse_ResizeCalibration(C, C_inv, 'pad', [i_pre, i_post, j_pre,
    %   j_post]): Resizes the calibration matrix to work on images that were
    %   padded using padarray (or equivalent).
    %
    %   One can also specify the padding values as a 2-vector [i_pad, j_pad]
    %   where in such case it is assumed that pre and post have the same value
    %   for x and y.
    %
    %   Algorithm:
    %
    %   ** Padding**:
    %       The mapping fom original to calibrated is kept untouched. The
    %       indexes of the mapping are simply shifted to account for the
    %       new rows and columns.
    %
    %       The mapping from calibrated to original must fill in the
    %       originally padded images. This is done by copying the values of
    %       the nearest existing rows and columns, similar to the
    %       'replicate' option in padarray. There is a bias towards rows
    %       in the copying process (i.e. the ambiguous pixels at the corner
    %       of the image are filled with row values).
    
    
    switch lower(mode)
        case 'rescale'
            error('Not supported yet!');
            %         [Cout, C_inv_out] = resizeRescale(C, C_inv, params);
        case 'pad'
            
%             if length(params) == 2
%                 params = params([1 1 2 2]);
%             end
            
            [Cout, C_inv_out] = resizePad(C, C_inv, params);
        otherwise
            error('Parameter ''mode'' must be either ''rescale'' or ''pad''.');
    end
    
end

function [Cout, C_inv_out] = resizePad(C, C_inv, pad_params)
    % Resizing based on pad:
    size_in = size(C_inv);
    
    [I_forward,J_forward] = ind2sub(size_in, C(:));
    
    % Adding effect of padding:
    new_size_in = size_in + [sum(pad_params(1:2)) sum(pad_params(3:4))];
    
    I_forward = I_forward + pad_params(1);
    J_forward = J_forward + pad_params(3);
    
    Cout = sub2ind(new_size_in, I_forward, J_forward);
    
    Cout = reshape(Cout,size(C));
    
    %%% FIXME: There is for sure a more efficient way to do this...
    %%% [joaofayad]
    
    % Invert padding
    C_inv_out = zeros(new_size_in);
    
    sub_roi = [[1 size_in(1)] + pad_params(1) ,...
               [1 size_in(2)] + pad_params(3)];
        
    % Copying existing transformation:
    C_inv_out(sub_roi(1):sub_roi(2), sub_roi(3):sub_roi(4)) = C_inv;
    
    % Padding rows:
    C_inv_out(1:pad_params(1), sub_roi(3):sub_roi(4)) = ...
        repmat(C_inv(1,:),pad_params(1),1);
    C_inv_out(end-pad_params(2)+1:end, sub_roi(3):sub_roi(4)) = ...
        repmat(C_inv(end,:),pad_params(2),1);
    
    % Padding columns:
    C_inv_out(sub_roi(1):sub_roi(2),1:pad_params(3)) = ...
        repmat(C_inv(:,1), 1, pad_params(3));
    C_inv_out(sub_roi(1):sub_roi(2),end-pad_params(4)+1:end) = ...
        repmat(C_inv(:,end), 1, pad_params(4));
    
    % Padding diagonals:
    C_inv_out(1:pad_params(1), 1:pad_params(3)) = C_inv(1,1);
    C_inv_out(1:pad_params(1), end-pad_params(4):end) = C_inv(1,end);
    C_inv_out(end-pad_params(2):end, 1:pad_params(3)) = C_inv(end,1);
    C_inv_out(end-pad_params(2):end, ...
        end-pad_params(4):end) = C_inv(end, end);
end

function [Cout, C_inv_out] = resizeRescale(C, C_inv, scale)
    % Resizing based on scale:
end


