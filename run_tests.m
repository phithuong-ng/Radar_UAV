function result=run_tests()
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'));verify_installation('extended');
result=runtests(fullfile(root,'tests','test_core.m'));disp(result);
if ~isfolder(fullfile(root,'results')),mkdir(fullfile(root,'results'));end
save(fullfile(root,'results','native_tests.mat'),'result');
assert(all([result.Passed]),'Native test failed. Fix the reported API/behavior error before benchmarking.');
end
