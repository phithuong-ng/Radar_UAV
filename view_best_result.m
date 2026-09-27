function view_best_result(out)
root=fileparts(mfilename('fullpath'));
if nargin<1,out=fullfile(root,'results','tune_extended');end
file=fullfile(out,'best_method.json');assert(isfile(file),'Run tuning successfully before viewing the selected result.');
b=jsondecode(fileread(file));
view_dataset(fullfile(root,'data','datasets','fast_uav_mixed_9100.mat'),fullfile(out,b.tracks_file));
end
