function [] = displayErrorGui(error_type)
% displayErrorGui Mimics the MATLAB error output without halting the
% program. It prints the messages to the command line.
N_stack = length(error_type.stack);
errmsg = sprintf('Error in ');
for i_stack = 1:N_stack
    
    if ~isempty(error_type.stack(i_stack).file)
        [~,fname,~] = fileparts(error_type.stack(i_stack).file);
        errmsg = [errmsg fname '> '];
    end
    
    errmsg = [errmsg error_type.stack(i_stack).name];
    if error_type.stack(i_stack).line>0
        errmsg = [errmsg sprintf(' (line %d)',error_type.stack(i_stack).line)];
    end
    errmsg = [errmsg '\n'];
end
fprintf([errmsg '\n'])
end