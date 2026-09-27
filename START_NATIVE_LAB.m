function app=START_NATIVE_LAB()
% Open the native interactive branch. Original entry points remain unchanged.
root=fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'src'),fullfile(root,'native_lab'));
app=nl_app;
end
