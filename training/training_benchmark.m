function summary=training_benchmark(dataset,mode,suite)
% Run any original tracker family against a generated training dataset.
if nargin<2,mode='baseline';end
if nargin<3,suite='light';end
root=training_root;addpath(root,fullfile(root,'src'));
base=fullfile(root,'results','training');if ~isfolder(base),mkdir(base);end
[~,tag]=fileparts(tempname(base));out=fullfile(base,['benchmark_' tag]);
summary=run_mixed(mode,suite,out,dataset);
end
