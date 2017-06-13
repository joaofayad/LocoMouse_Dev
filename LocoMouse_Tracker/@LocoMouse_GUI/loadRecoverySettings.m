function loadRecoverySettings(gui)
% Loading last used settings.
recovery_settings = ...
    fullfile(gui.settings_path, 'GUI_Recovery_Settings_v2.mat');

if exist(recovery_settings,'file')
   gui.loadSettings(recovery_settings);
end
end