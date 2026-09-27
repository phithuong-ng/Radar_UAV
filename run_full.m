function summary=run_full(mode,suite,out,scenario)
% RUN_FULL('tune','extended'): 8 scenarios x 10 seeds, 17 native methods.
% Per scenario: tune on seed 9100; freeze parameters for all other seeds.
% Seed 9101-9102 = validation; 9103-9109 = evaluation. No evaluation tuning.
% Optional fourth argument selects one scenario. Batch may take a long time.
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'));
if nargin<1 || isempty(mode),mode='tune';end
if nargin<2 || isempty(suite),suite='extended';end
if nargin<3 || isempty(out),out=fullfile(root,'results',['full_' char(mode) '_' char(suite)]);end
if nargin<4,scenario='';end
assert(ismember(string(mode),["baseline","tune","deep"]),'Use baseline, tune or deep');
verify_installation(suite);
entries=jsondecode(fileread(fullfile(root,'data','datasets','manifest.json')));
if ~isempty(scenario),entries=entries(strcmp({entries.scenario},scenario));end
assert(~isempty(entries),'Unknown scenario');
if ~isfolder(out),mkdir(out);end
summary=table;names=unique(string({entries.scenario}),'stable');completed=0;
for ni=1:numel(names)
 group=entries(strcmp({entries.scenario},names(ni)));locked='';
 if ismember(string(mode),["tune","deep"])
  ti=find(strcmp({group.split},'tuning'));assert(numel(ti)==1,'Expected exactly one tuning seed');
  group=group([ti setdiff(1:numel(group),ti,'stable')]);
 end
 for j=1:numel(group)
  e=group(j);[~,stem]=fileparts(e.file);dest=fullfile(out,stem);
  fprintf('\nFULL DATASET %d/%d | %s | %s\n',completed+1,numel(entries),e.file,e.split);drawnow;
  isTuning=ismember(string(mode),["tune","deep"]) && strcmp(e.split,'tuning');
  if isTuning
   s=run_mixed(mode,suite,dest,fullfile(root,'data','datasets',e.file));
   locked=fullfile(dest,'selected_parameters.mat');
  elseif strcmp(mode,'baseline')
   s=run_mixed('baseline',suite,dest,fullfile(root,'data','datasets',e.file));
  elseif isfile(locked)
   s=run_mixed('baseline',suite,dest,fullfile(root,'data','datasets',e.file),locked);
  else
   % Do not silently fall back to untuned defaults if calibration failed.
   s=runMissing(suite);
  end
  s.Dataset=repmat(string(e.file),height(s),1);s.Scenario=repmat(string(e.scenario),height(s),1);
  s.Seed=repmat(e.seed,height(s),1);s.Split=repmat(string(e.split),height(s),1);
  if isempty(summary),summary=s;else,summary=[summary;s];end %#ok<AGROW>
  completed=completed+1;writetable(summary,fullfile(out,'ALL_RESULTS.csv'));
  writeSummary(summary,out);fprintf('BATCH %d/%d files complete\n',completed,numel(entries));drawnow;
 end
end
writeSummary(summary,out);disp(summary);
fprintf('Full-suite summary: %s\n',fullfile(out,'SUMMARY.html'));
end
function s=runMissing(suite)
reg=method_registry(suite);rows=cell(numel(reg),15);
for i=1:numel(reg),rows(i,:)={char(reg(i).name),'NO_LOCKED_PARAMETERS',NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN};end
s=cell2table(rows,'VariableNames',{'Method','Status','Candidate','Fit_OSPA_m','Selection_OSPA_m','Full_OSPA_m','Holdout_OSPA_m','Full_GOSPA_m','Matched_RMSE_m','MeanMissed','MeanFalseTracks','Tracking_ms','PeakTracking_ms','Holdout_RMSE_m','FinalWall_s'});
end
function writeSummary(s,out)
% Per-seed metrics are authoritative. Failed runs stay visible and are not scored.
rows=cell(0,9);scenarios=unique(s.Scenario,'stable');methods=unique(string(s.Method),'stable');
for sc=scenarios'
 for m=methods'
  ix=s.Scenario==sc & string(s.Method)==m & s.Split=="evaluation";
  if ~any(ix),continue;end
  ok=ix & string(s.Status)=="PASS";
  rows(end+1,:)={char(sc),char(m),sum(ix),sum(ok),mean(s.Full_OSPA_m(ok)),mean(s.Full_GOSPA_m(ok)),mean(s.Matched_RMSE_m(ok)),mean(s.MeanFalseTracks(ok)),mean(s.Tracking_ms(ok))}; %#ok<AGROW>
 end
end
a=cell2table(rows,'VariableNames',{'Scenario','Method','EvaluationFiles','PassedFiles','Mean_OSPA_m','Mean_GOSPA_m','Mean_File_RMSE_m','Mean_FalseTracks','Mean_Tracking_ms'});
writetable(a,fullfile(out,'EVALUATION_SUMMARY.csv'));
fid=fopen(fullfile(out,'SUMMARY.html'),'w','n','UTF-8');guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'<!doctype html><meta charset="utf-8"><title>Full suite</title><style>body{font:15px Arial;margin:35px}table{border-collapse:collapse}td,th{border:1px solid #aaa;padding:7px}th{background:#eef4fc}</style><h1>Full-suite evaluation</h1>');
fprintf(fid,'<p>Seed 9100: tuning. Seeds 9101–9102: validation. Seeds 9103–9109: evaluation with locked parameters.</p><p>Means cover PASS files only. Check PassedFiles / EvaluationFiles; incomplete rows cannot establish superiority. Mean_File_RMSE is a mean of per-file RMSE, not pooled RMSE.</p><p><a href="ALL_RESULTS.csv">All per-file results</a> | <a href="EVALUATION_SUMMARY.csv">Evaluation summary</a></p><table><tr>');
for n=a.Properties.VariableNames,fprintf(fid,'<th>%s</th>',n{1});end
fprintf(fid,'</tr>');
for i=1:height(a)
 fprintf(fid,'<tr>');
 for j=1:width(a)
  v=a{i,j};if iscell(v),v=v{1};end
  if isnumeric(v),fprintf(fid,'<td>%.3f</td>',v);else,fprintf(fid,'<td>%s</td>',char(v));end
 end
 fprintf(fid,'</tr>');
end
fprintf(fid,'</table>');
end
