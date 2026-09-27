function folder=nl_storage(newFolder)
% Persist only the workspace location; observations/configs belong to archives.
pref=fullfile(nl_root,'results','native_workspace_location.mat');
folder=fullfile(nl_root,'results','native_workspace');
if nargin>0
 assert(isfolder(newFolder),'Select an existing storage folder.');folder=char(newFolder);
 parent=fileparts(pref);if ~isfolder(parent),mkdir(parent);end
 save(pref,'folder');
elseif isfile(pref)
 s=load(pref,'folder');if isfield(s,'folder')&&isfolder(s.folder),folder=s.folder;end
end
end
