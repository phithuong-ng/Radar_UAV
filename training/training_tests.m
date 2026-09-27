function results=training_tests()
root=training_root;addpath(root,fullfile(root,'src'),fullfile(root,'training'));
results=runtests(fullfile(root,'training','tests'));disp(results);
assert(~any([results.Failed]),'Training tests failed. Incomplete means untested/missing API.');
end
