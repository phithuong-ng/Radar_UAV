function results=NATIVE_LAB_TESTS(mode)
if nargin<1,mode='core';end
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'),fullfile(root,'native_lab'));
out=fullfile(root,'results','native_tests');if ~isfolder(out),mkdir(out);end
diary(fullfile(out,'console.txt'));cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
suite=testsuite(fullfile(root,'native_lab','tests'));
names=string({suite.Name});
if strcmp(mode,'core'),suite=suite(contains(names,'test_native_lab/')&~contains(names,'NativeIQExecution'));
elseif strcmp(mode,'workflow'),suite=suite(contains(names,'test_native_workflow/'));
elseif strcmp(mode,'tracking'),suite=suite(contains(names,'test_native_tracking/'));
elseif strcmp(mode,'rx'),suite=suite(contains(names,'test_native_rx/'));
elseif strcmp(mode,'fixes')
 names=string({suite.Name});suite=suite(contains(names,'NativeCartesianFrame')|contains(names,'ColdStartAndSteady')|contains(names,'InactiveProperties'));
else,assert(strcmp(mode,'all'),'Choose core, fixes, workflow, tracking, rx or all.');end
results=run(suite);disp(results);
save(fullfile(out,'results.mat'),'results');
assert(~any([results.Failed])&&~any([results.Incomplete]),'Native lab tests failed or were incomplete. Read results/native_tests/console.txt.');
end
