function bounding_box = Call_computeMouseBox(Iaux, split_line,cmd_string)
% This function is necessary to use eval() in a parfor loop

    eval(cmd_string);   
    
end