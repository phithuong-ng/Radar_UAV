function T=nl_library(storage)
if nargin<1,storage=nl_storage;end
rows=cell(0,8);
for kind={'datasets','runs'}
 base=fullfile(storage,kind{1});if ~isfolder(base),continue;end
 entries=dir(base);
 for j=1:numel(entries)
  if ~entries(j).isdir||startsWith(entries(j).name,'.'),continue;end
  folder=fullfile(base,entries(j).name);file=fullfile(folder,'archive.json');
  if ~isfile(file),continue;end % Interrupted writes are not published archives.
  try
   m=jsondecode(fileread(file));
   rows(end+1,:)={string(m.kind),string(m.name),string(m.created_utc),double(m.frames), ...
    double(m.reports),string(m.status),string(m.id),string(folder)}; %#ok<AGROW>
  catch
   rows(end+1,:)={string(kind{1}),string(entries(j).name),"",NaN,NaN,"INVALID",string(entries(j).name),string(folder)}; %#ok<AGROW>
  end
 end
end
T=cell2table(rows,'VariableNames',{'Type','Name','CreatedUTC','Frames','Reports','Status','ID','Folder'});
if ~isempty(T),T=sortrows(T,'CreatedUTC','descend');end
end
