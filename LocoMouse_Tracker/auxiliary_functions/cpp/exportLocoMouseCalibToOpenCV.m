function [] = exportLocoMouseCalibToOpenCV(file_name, calibration_struct)
% Writes the paw snout and tail models into a yaml file for loading on
% OpenCV.
%
% VERY IMPORTANT: Due to the row/column major property of C/C++ the
% indexing must be made row-wise. This means that the linear indices from
% MATLAB (which are column-wise) need to be converted first.

try
    name_fields = {'ind_warp_mapping','inv_ind_warp_mapping','mirror_line','split_line'};
    N_fields = size(name_fields,2);
    
    tfields = fieldnames(calibration_struct);
    tfoundfield = false(1,N_fields);
    
    for i_f = 1:N_fields
        tfoundfield(i_f) = ismember(name_fields(i_f),tfields);
    end
    
    allfields = all(tfoundfield([1,2])) && any(tfoundfield([3 4]));
    
    if ~allfields
        fprintf('ERROR: Incomplete model file.')
    else

        if tfoundfield(3)
            warning('Calibration file is outdated. Update mirror_line field to split_line');
            calibration_struct.split_line = calibration_struct.mirror_line;
        end
        
        fid = fopen(file_name,'w');
        if fid < 0
            error('Error opening file for writing!');
        end
        
        fid_safe = onCleanup(@()(fclose(fid)));
        
        fprintf(fid,'%%YAML:1.0\n');
        
        for i_f = 1:length(tfields)
            switch tfields{i_f}
                case 'ind_warp_mapping'
                    % ind_warp_mapping:
                    row_ind = convert_ColToRowMajor(calibration_struct.ind_warp_mapping,size(calibration_struct.inv_ind_warp_mapping));
                    writeMatrix(fid,'ind_warp_mapping',row_ind-1); %-1 because these are indices and must be converted to C/C++ style starting from 0.
                    
                case 'inv_ind_warp_mapping'
                    % inv_ind_warp_mapping:
                    row_ind = convert_ColToRowMajor(calibration_struct.inv_ind_warp_mapping,size(calibration_struct.ind_warp_mapping));
                    writeMatrix(fid,'inv_ind_warp_mapping',row_ind-1);
                    
                case 'split_line'
                    % Write integer:
                    view_boxes = [0 0 size(calibration_struct.ind_warp_mapping,2) calibration_struct.split_line;
                        0 calibration_struct.split_line size(calibration_struct.ind_warp_mapping,2) size(calibration_struct.ind_warp_mapping,1)-calibration_struct.split_line];
                    writeMatrix(fid,'view_boxes',view_boxes); % view_boxes already defined in C++ style...
                otherwise
                    warning('Unknown field name in calibration file: %s. Field not written',tfields{i_f});
            end
        end
        
        % Adding the scale:
        if isfield(calibration_struct,'scale')
            scale = calibration_struct.scale;
        else
            scale = 1;
        end
        fprintf(fid,'scale: %d\n',scale);
    end
catch load_error
    report = getReport(load_error,'extended');
    disp(report);
    beep;
end


function row_ind = convert_ColToRowMajor(col_ind,mat_size)
template = reshape(1:prod(mat_size),mat_size([2 1]))';
row_ind = template(col_ind);

function writeMatrix(fid, matrix_name, M)
M = M';
%M = (M-1)'; % Row/Col major.
fprintf(fid,'%s: !!opencv-matrix\n',matrix_name);
fprintf(fid,'   rows: %d\n',size(M,2)); % We have transposed it...
fprintf(fid,'   cols: %d\n',size(M,1)); % We have transposed it...
fprintf(fid,'   dt: i\n');

if numel(M) > 3
% Using %d but setting the data type to double. This can only be done
% becacuse we are passing indices.
fprintf(fid,'   data: [%d, %d, %d, \n',M(1:3));
fprintf(fid,'      %d, %d, %d, %d, \n',M(4:end-1));
fprintf(fid,'      %d]\n',M(end));

else
    error('Matrix seems to small for a calibration file! If correct, implement such code...');
end



