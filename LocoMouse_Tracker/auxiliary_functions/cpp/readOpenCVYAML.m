function S = readOpenCVYAML(file_name)
% Basic reading of opencv yaml tested on my own files only.
% Very inneficient!

fid = fopen(file_name,'r');
if fid < 0
    error('Could not read file!')
end
fid_safe = onCleanup(@()(fclose(fid)));
S = [];
loop = true;
while (loop)
    
    line = fgetl(fid);
    
    if line == -1
        %EOF
        loop = false;
        continue;
    end
    
    %Count identation:
    identation = countIdentation(line);    
    line = line(identation+1:end);
    %Check field type:
    if line(1) == '%'
        % Comment, ignore.
    elseif strcmpi(line,'---')
        % OpenCV 3.2 has this separating now, so skip as well
    else
        % Processing the value (Basically, const or Mat);
        field = strsplit(line,': ');
        if field{2}(1) == '!'
            
            % Structure. For now Assuming opencv matrix:
            matrix_name = field{1};
           
            row_line = strsplit(fgetl(fid),': ');
            N_rows = str2double(row_line{2});
            
            col_line = strsplit(fgetl(fid),': ');
            N_cols = str2double(col_line{2});
            
            data_line = strsplit(fgetl(fid),': ');
            data_type = data_line{2}; 
                        
            %Data lines:
            M = zeros(N_cols,N_rows); % C++ is row major!
            
            if strcmpi(data_type, 'u')
                M = uint8(M);
            end
            
            counter = 1;
            mat_loop = true;
            
            while (mat_loop)
                values = fgetl(fid);
                
                if counter == 1
                    % first line, split on the bracket;
                    values = strsplit(values,': [');
                    values = values{2};
                end
                values = strrep(values,' ','');
                
                switch data_type
                    case 'u'
                        pattern = '%d';
                    case 'i'
                        pattern = '%d';
                    case 'd'
                        pattern = '%f';
                    case 'f'
                        pattern = '%f';
                    otherwise
                        error('Unknown data type!');
                end
                
                numeric_values = textscan(values,pattern,'Delimiter',',');
                Lnm = length(numeric_values{1});
                M(counter:counter+Lnm-1) = numeric_values{1};
                counter = counter+Lnm;
                
                if counter > N_cols*N_rows
                    mat_loop = false;
                end
            end
            
            S.(matrix_name) = M';
            
        else
            S.(field{1}) = str2double(field{2});
        end
        
    end
    
end


function counter = countIdentation(line)
% Counts blocks of 4 spaces:

loop = true;
counter = 0;
while (loop)
    if line(counter+1) == ' '
        counter = counter+1;
    else
        loop = false;
    end
end




    


