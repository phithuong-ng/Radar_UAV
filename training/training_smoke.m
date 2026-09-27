function results=training_smoke(configFile)
% Execute core labs only. Never hide FAILED as SKIPPED.
if nargin<1,configFile='';end
catalog=training_check;ids=catalog.id(catalog.level=="core");
base=fullfile(training_root,'results','training');if ~isfolder(base),mkdir(base);end
[~,tag]=fileparts(tempname(base));out=fullfile(base,['smoke_' tag]);mkdir(out);
status=strings(numel(ids),1);message=status;
for k=1:numel(ids)
 idx=find(catalog.id==ids(k));
 if ~catalog.available(idx),status(k)="SKIPPED_MISSING_API";message(k)=catalog.missing(idx);continue;end
 try
  r=training_run(ids(k),configFile,fullfile(out,char(ids(k))));status(k)=string(r.status);
 catch ME,status(k)="FAILED";message(k)=string(ME.message);
 end
end
results=table(ids,status,message);writetable(results,fullfile(out,'smoke_summary.csv'));disp(results);
fprintf('Execution summary: %s\n',out);
if any(status=="FAILED"),warning('One or more labs FAILED. Read per-lab console.txt and status.json.');end
end
