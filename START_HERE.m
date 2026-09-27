function START_HERE()
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'));
verify_installation('extended');
manifest=jsondecode(fileread(fullfile(root,'data','datasets','manifest.json')));
files=dir(fullfile(root,'data','datasets','*.mat'));
assert(numel(files)==80 && numel(manifest)==80,'Expected full suite: 8 scenarios x 10 seeds.');
assert(isequal(sort(string({files.name})),sort(string({manifest.file}))), 'Dataset filenames do not match manifest');
d=load(fullfile(root,'data','datasets','fast_uav_mixed_9100.mat'));speed=vecnorm(d.truth(:,7:9),2,2);
fprintf('\nNoiBai v8.4 FULL | %d files | 8 scenarios x 10 seeds | %d total scans\n',numel(files),sum([manifest.frames]));
fprintf('Default quick file: fast_uav_mixed_9100.mat | speed %.2f..%.2f m/s\n',min(speed),max(speed));
fprintf(['\nrun_tests\nrun_mixed(''smoke'',''light'')\n' ...
 'run_mixed(''baseline'',''light'') %% 160 scans, no search\n' ...
 'run_mixed(''tune'',''extended'') %% 17 methods on ONE mixed file\n' ...
 'run_full(''tune'',''extended'')  %% full suite; long batch\nview_dataset\n']);
fprintf('No native scores shipped. Open HUONG_DAN.html and docs/BANG_DATASET.html.\n');
end
