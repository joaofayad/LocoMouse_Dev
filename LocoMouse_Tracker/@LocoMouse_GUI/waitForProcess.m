function [] = waitForProcess(gui,state)
% state     'on' or 'off'
% Function that disables/enables a GUI during/after execution.
% values should have the

switch state
    case 'on'
        set(gui.Window,'Pointer','arrow');
        if ~isempty(gui.handles_to_enable)
            set(gui.handles_to_enable,'Enable','on');
            gui.handles_to_enable = [];
        end
        drawnow;
        
    case 'off'
        gui.handles_to_enable = findall(gui.Window,'Enable','on');
        gui.old_pointer = get(gui.Window,'Pointer');
        set(gui.Window,'Pointer','watch');
        set(gui.handles_to_enable,'Enable','off');
        drawnow;
        
    otherwise
        error('Unknown option!');
end

end