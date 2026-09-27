function summary=tune_native_tracker(datasetName,trackerType)
% Compatibility wrapper; now performs a real bounded native parameter search.
if nargin<1,datasetName='fast_uav_mixed_9100.mat';end
if nargin<2,trackerType='GNN';end
root=fileparts(mfilename('fullpath'));
method=char(string(trackerType)+"_CV_EKF_SPH");
summary=run_mixed('tune',method,[],fullfile(root,'data','datasets',datasetName));
end
