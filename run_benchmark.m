function summary=run_benchmark(mode,out,datasetFolder,datasetName,suite)
% Compatibility wrapper. Use run_mixed for the new documented workflow.
root=fileparts(mfilename('fullpath'));
if nargin<1,mode='one';end
if nargin<2,out=[];end
if nargin<3 || isempty(datasetFolder),datasetFolder=fullfile(root,'data','datasets');end
if nargin<4 || isempty(datasetName),datasetName='fast_uav_mixed_9100.mat';end
if nargin<5 || isempty(suite),suite='extended';end
if strcmp(mode,'full')
 summary=run_full('baseline',suite,out);return
end
switch string(mode)
 case {"quick","smoke"},newMode='smoke';
 case "one",newMode='baseline';
 case {"tune","deep"},newMode=char(mode);
 otherwise,error('Use one, quick, smoke, tune or deep.');
end
summary=run_mixed(newMode,suite,out,fullfile(datasetFolder,datasetName));
end
