% --- Function that loads a model file and performs a few basic checks:
function handles = loadModel(full_file_path, handles)
    model = load(full_file_path);
    % Since there is no model file type we must check we have all the right
    % fields:
    if isfield(model,'model')
        model =model.model;
    end
    ModelFieldNames      = fieldnames(model);
    ExpectedModel        = [{'line'}  {'tail'} ; ...
                            {'point'} {'paw'} ; ...
                            {'point'} {'snout'}];
                        
    failed = false;
    if ~any(ismember(ModelFieldNames,'line')) || ~any(ismember(ModelFieldNames,'point'))    
        for emt = 1:size(ExpectedModel,1)
             if any(ismember(ModelFieldNames,ExpectedModel(emt,2)))
                if any(ismember(fieldnames(eval(['model.' char(ExpectedModel(emt,2))])),'w')) && any(ismember(fieldnames(eval(['model.' char(ExpectedModel(emt,2))])),'rho'))
                     eval(['model.',char(ExpectedModel(emt,1)),'.',char(ExpectedModel(emt,2)),' = model.',char(ExpectedModel(emt,2)),';']);
                else
                     failed = true;
                end
             else
                 failed = true;
             end

        end
    end
    if failed
        error('LocoMouse_Tracker() / loadModel() :: Model file useless.')
    else
        if ~isfield(model.point.paw,'N_points')
            model.point.paw.N_points =4;
        end
        if ~isfield(model.point.snout,'N_points')
            model.point.snout.N_points =1;
        end
        handles.model =model;
    end
end