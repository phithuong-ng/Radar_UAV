function summary=run_mixed(mode,suite,out,datasetFile,lockedParameters)
% RUN_MIXED('tune','extended'): tune 17 native methods on the single mixed file.
% modes: smoke (12 scans), baseline (160 scans), tune (6 candidates), deep (12).
% suites: light (3 GNN), standard (10), extended (17), or an exact method name.
% Soft run/scan budgets are checked AFTER each native call; not hard timeouts.
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'));
if nargin<1 || isempty(mode),mode='tune';end
if nargin<2 || isempty(suite),suite='extended';end
mode=char(mode);suite=char(suite);
assert(ismember(string(mode),["smoke","baseline","tune","deep"]),'Unknown mode');
if nargin<3 || isempty(out),out=fullfile(root,'results',[mode '_' suite]);end
if nargin<4 || isempty(datasetFile),datasetFile=fullfile(root,'data','datasets','fast_uav_mixed_9100.mat');end
if nargin<5,lockedParameters='';end
frozen=struct;
if ~isempty(lockedParameters)
 assert(ismember(string(mode),["baseline","smoke"]),'Locked parameters cannot be re-tuned.');
 locked=load(lockedParameters,'selected');frozen=locked.selected;
end
verify_installation(suite);
assert(isfile(datasetFile),'Missing dataset: %s',datasetFile);
if ~isfolder(out),mkdir(out);end
c=jsondecode(fileread(fullfile(root,'config','tracker_config.json')));
d=load(datasetFile);assert(numel(d.times)==160,'This split requires 160 scans.');
assert(all(diff(d.times)>0),'Non-increasing timestamps');
reg=method_registry(suite);budget=c.tuning.search_candidates;if strcmp(mode,'deep'),budget=12;end
code=dir(fullfile(root,'*.m'));code=[code;dir(fullfile(root,'src','*.m'))];
codeSignature=cell(numel(code),2);
for j=1:numel(code),codeSignature(j,:)={code(j).name,file_sha256(fullfile(code(j).folder,code(j).name))};end
signature=struct('dataset_sha256',file_sha256(datasetFile),'config',c,'code',{codeSignature}, ...
 'release',version('-release'),'mode',mode,'suite',suite,'budget',budget,'locked_parameters',frozen);
signatureFile=fullfile(out,'run_signature.mat');
if isfile(signatureFile)
 old=load(signatureFile);assert(isequaln(signature,old.signature), ...
  'Results belong to different code/data/settings. Choose a NEW output folder.');
else,save(signatureFile,'signature');end
logCleanup=onCleanup(@()diary('off')); %#ok<NASGU>
diary(fullfile(out,'console.txt'));
fprintf('\n%s | %d native methods | %s | %.2f s simulated\n',upper(mode),numel(reg),char(d.scenario),d.times(end));
fprintf('Output: %s\nTuning 1:100 | selection 101:130 | untouched holdout 131:160\n',out);
prepClock=tic;cache=prepare_cache(d,c,any([reg.frame]=="spherical"),any([reg.frame]=="cartesian"));
preparationSeconds=toc(prepClock);
% Audit retention with labels here only, after preprocessing. Never feed labels to trackers.
retained=vertcat(cache.indices{:});targetMask=d.labels(:,2)==1;
retention=struct('raw_reports',size(d.detections,1),'kept_reports',numel(retained), ...
 'target_reports',sum(targetMask),'kept_target_reports',sum(targetMask(retained)), ...
 'preparation_seconds',preparationSeconds,'temporal_support_enabled',c.temporal_support.enabled, ...
 'scenario',char(d.scenario),'seed',double(d.seed),'locked_parameters',~isempty(lockedParameters));
write_json(fullfile(out,'input_audit.json'),retention);
fprintf('Input audit: retained target plots %d/%d (audit only)\n',retention.kept_target_reports,retention.target_reports);
summaryRows=cell(0,15);selected=struct;overall=tic;
for mi=1:numel(reg)
 m=reg(mi);name=char(m.name);methodFolder=fullfile(out,name);if ~isfolder(methodFolder),mkdir(methodFolder);end
 fprintf('\nMETHOD %d/%d: %s | elapsed %.1fs\n',mi,numel(reg),name,toc(overall));drawnow;
 chosen=c;chosenIndex=0;selectionOSPA=NaN;fitOSPA=NaN;
 if ~isempty(lockedParameters)
  if ~isfield(frozen,name)
   summaryRows(end+1,:)={name,'NO_LOCKED_PARAMETERS',NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}; %#ok<AGROW>
   continue
  end
  chosen=frozen.(name).parameters;chosenIndex=frozen.(name).candidate;
 end
 if ismember(string(mode),["tune","deep"])
  [configs,names]=tuning_candidates(c,m,budget);fitScores=inf(1,budget);selectionScores=inf(1,budget);rows=cell(budget,10);
  for ci=1:budget
   r=cachedPass(m,configs(ci),100,fullfile(methodFolder,sprintf('fit_%02d.mat',ci)),sprintf('%s fit %d/%d',name,ci,budget));
   [st,~]=evaluate_pass(r,d.truth,configs(ci).metric_cutoff_m,1,100);fitScores(ci)=st.ospa;
   rows(ci,:)={char(names(ci)),r.status,st.ospa,NaN,st.missed,st.false_tracks,st.rmse,st.tracking_ms,r.wall_seconds,r.message};
   fprintf('  Fit %d/%d: %s | OSPA %.2f | missed %.2f | false %.2f | %.1fms/scan\n', ...
    ci,budget,r.status,st.ospa,st.missed,st.false_tracks,st.tracking_ms);
   writetable(candidateTable(rows(1:ci,:)),fullfile(methodFolder,'tuning_candidates.csv'));drawnow;
  end
  [~,order]=sort(fitScores);order=order(isfinite(fitScores(order)));order=order(1:min(c.tuning.finalists,numel(order)));
  for ci=order
   r=cachedPass(m,configs(ci),130,fullfile(methodFolder,sprintf('selection_%02d.mat',ci)),sprintf('%s selection %d',name,ci));
   [st,~]=evaluate_pass(r,d.truth,configs(ci).metric_cutoff_m,101,130);
   selectionScores(ci)=st.ospa;rows{ci,4}=st.ospa;
   rows{ci,2}=[rows{ci,2} '/selection:' r.status];
   if ~strcmp(r.status,'PASS'),rows{ci,10}=[rows{ci,10} newline r.message];end
  end
  writetable(candidateTable(rows),fullfile(methodFolder,'tuning_candidates.csv'));
  [selectionOSPA,chosenIndex]=min(selectionScores);
  if ~isfinite(selectionOSPA)
   summaryRows(end+1,:)={name,'NO_VALID_CANDIDATE',NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN}; %#ok<AGROW>
   summary=summaryTable(summaryRows);writetable(summary,fullfile(out,'summary.csv'));continue
  end
  chosen=configs(chosenIndex);fitOSPA=fitScores(chosenIndex);
  selected.(name)=struct('parameters',chosen,'candidate',chosenIndex,'fit_ospa',fitOSPA,'selection_ospa',selectionOSPA, ...
   'dataset_sha256',signature.dataset_sha256,'status','SELECTED_BY_NATIVE_MATLAB','selection_scope','Best validation OSPA among finalists; not global optimum');
  write_json(fullfile(methodFolder,'selected_parameters.json'),selected.(name));
  save(fullfile(out,'selected_parameters.mat'),'selected','signature');
  fprintf('  Selected candidate %d | fit %.2f m | selection %.2f m\n',chosenIndex,fitOSPA,selectionOSPA);
 end
 K=160;if strcmp(mode,'smoke'),K=12;end
 r=cachedPass(m,chosen,K,fullfile(methodFolder,'final.mat'),[name ' final']);
 [allStats,frames]=evaluate_pass(r,d.truth,c.metric_cutoff_m,1,K);
 if K==160,[holdStats,~]=evaluate_pass(r,d.truth,c.metric_cutoff_m,131,160);else,holdStats=emptyStats();end
 estimates=r.estimates;ids=r.ids;parameters=chosen;status=r.status; %#ok<NASGU>
 save(fullfile(methodFolder,'tracks.mat'),'estimates','ids','parameters','status','m','signature');
 if ~isempty(frames)
  ft=array2table(frames,'VariableNames',{'scan','OSPA_m','GOSPA_m','matched','missed','false_tracks','cardinality_bias','matched_RMSE_m','tracking_ms'});
  writetable(ft,fullfile(methodFolder,'frames.csv'));
 end
 summaryRows(end+1,:)={name,r.status,chosenIndex,fitOSPA,selectionOSPA,allStats.ospa,holdStats.ospa, ...
  allStats.gospa,allStats.rmse,allStats.missed,allStats.false_tracks,allStats.tracking_ms, ...
  allStats.peak_tracking_ms,holdStats.rmse,r.wall_seconds}; %#ok<AGROW>
 summary=summaryTable(summaryRows);writetable(summary,fullfile(out,'summary.csv'));
 if strcmp(r.status,'PASS'),save_result_plot(d,r,m,methodFolder,c.metric_cutoff_m);end
 write_run_report(summary,out,mode,retention);
 fprintf('  COMPLETE %d/%d | %s | OSPA %.2f | holdout %.2f | elapsed %.1fs\n', ...
  mi,numel(reg),r.status,allStats.ospa,holdStats.ospa,toc(overall));disp(summary);drawnow;
end
summary=summaryTable(summaryRows);writetable(summary,fullfile(out,'summary.csv'));write_run_report(summary,out,mode,retention);
if ismember(string(mode),["tune","deep"])
 valid=find(string(summary.Status)=="PASS" & isfinite(summary.Selection_OSPA_m));
 if ~isempty(valid)
  [~,order]=sort(summary.Selection_OSPA_m(valid));ranked=summary(valid(order),:);
  writetable(ranked,fullfile(out,'ranked_selection.csv'));
  bestName=char(string(ranked.Method(1)));best=selected.(bestName);best.method=bestName;
  best.tracks_file=fullfile(bestName,'tracks.mat');best.selection_rule='Lowest selection OSPA, never holdout OSPA';
  write_json(fullfile(out,'best_method.json'),best);
  fprintf('Best method by selection segment: %s\n',bestName);
 end
end
fprintf('\nFinished in %.1fs + %.1fs preparation.\n%s\n',toc(overall),preparationSeconds,fullfile(out,'SUMMARY.html'));
disp(summary);
if any(string(summary.Status)~="PASS"),warning('Some methods did not complete. Inspect console.txt and per-method status; partial results are not ranked.');end
 function r=cachedPass(method,params,n,path,tag)
  if isfile(path)
   prior=load(path);assert(isequaln(prior.parameters,params) && prior.lastScan==n,'Cache mismatch: %s',path);
   r=prior.result;fprintf('  Resume cached %s (%s)\n',tag,r.status);return
  end
  result=tracker_pass(method,params,cache,n,tag);parameters=params;lastScan=n; %#ok<NASGU>
  tmp=[path '.partial'];save(tmp,'result','parameters','lastScan','-v7');movefile(tmp,path,'f');r=result;
 end
end
function t=candidateTable(rows)
t=cell2table(rows,'VariableNames',{'Candidate','Status','Fit_OSPA_m','Selection_OSPA_m','Missed','FalseTracks','Matched_RMSE_m','Tracking_ms','Wall_s','Error'});
end
function t=summaryTable(rows)
t=cell2table(rows,'VariableNames',{'Method','Status','Candidate','Fit_OSPA_m','Selection_OSPA_m','Full_OSPA_m','Holdout_OSPA_m', ...
 'Full_GOSPA_m','Matched_RMSE_m','MeanMissed','MeanFalseTracks','Tracking_ms','PeakTracking_ms','Holdout_RMSE_m','FinalWall_s'});
end
function s=emptyStats()
s=struct('ospa',NaN,'rmse',NaN);
end
