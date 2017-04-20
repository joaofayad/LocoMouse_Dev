function [] = exportLocoMouseModelToOpenCV(file_name, model)
% Writes the paw snout and tail models into a yaml file for loading on
% OpenCV.

fid = fopen(file_name,'w');
if fid < 0
    error('Error opening file for writing!');
end

try
    fprintf(fid,'%%YAML:1.0\n');
    
    feature_types = fieldnames(model);
    N_types = length(feature_types);
    
    for i_type = 1:N_types
        type = (feature_types{i_type});
        feature_names = fieldnames(model.(type));
        N_features = length(feature_names);
        
        for i_f = 1:N_features
            
            w = model.(type).(feature_names{i_f}).w;
            rho = model.(type).(feature_names{i_f}).rho;
            fname = [upper(feature_names{i_f}(1)) feature_names{i_f}(2:end)];
            
            for i_v = 1:2
                w{i_v} = w{i_v}(end:-1:1,end:-1:1)'; % Row/Column major change.
                if i_v == 1
                    split = 'bottom';
                else
                    split = 'top';
                end
                
                fprintf(fid,'model%s_%s: !!opencv-matrix\n',fname,split);
                fprintf(fid,'   rows: %d\n',size(w{i_v},2)); % We have transposed it...
                fprintf(fid,'   cols: %d\n',size(w{i_v},1)); % We have transposed it...
                fprintf(fid,'   dt: d\n');
                fprintf(fid,'   data: [%f',w{i_v}(1));
                fprintf(fid,',%f',w{i_v}(2:end));
                fprintf(fid,']\n');
                fprintf(fid,'bias%s_%s: %f\n',fname,split,rho{i_v});
                
            end
            
        end
    end
catch err
    fclose(fid);
    delete(file_name);
    rethrow(err);
end
