function [results,attempts]=nl_batch(log,configs,progress)
% Every entry runs on the same immutable observations. Failed runs stay failed.
if nargin<3,progress=@(~,~,~)true;end
results={};attempts=struct('method',{},'status',{},'message',{},'config',{});
cancelled=false;
for j=1:numel(configs)
 c=configs{j};status='NOT_RUN';message='Cancelled before this configuration started.';
 if ~cancelled
  try
   r=nl_track(log,c,progress);results{end+1}=r;status='COMPLETE';message=''; %#ok<AGROW>
  catch ME
   status='FAILED';message=getReport(ME,'extended','hyperlinks','off');
   if strcmp(ME.identifier,'NativeLab:Cancelled'),status='CANCELLED';cancelled=true;end
  end
 end
 attempts(end+1)=struct('method',char(c.method),'status',status,'message',message,'config',c.tracking); %#ok<AGROW>
end
end
