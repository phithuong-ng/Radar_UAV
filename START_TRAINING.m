function START_TRAINING()
% Open the independent toolbox training branch. Original START_HERE remains unchanged.
root=fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'src'),fullfile(root,'training'));
fprintf('Noi Bai Toolbox Mastery | MATLAB R2025a\n');
fprintf('Read training/README_VI.html. Start with training_check, then training_app.\n');
training_app;
end
