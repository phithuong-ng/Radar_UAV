function folder=nl_export(c,log,results,folder)
% Full native MAT plus portable CSV, configuration and reproducible entry script.
if ~isempty(log)
 assert(strcmp(log.status,'COMPLETE')&&strcmp(log.signature,nl_signature(c)),'Only a complete matching observation log can be exported.');
end
for q=1:numel(results),assert(strcmp(results{q}.status,'COMPLETE'),'Cannot export an incomplete tracking run.');end
if nargin<4||isempty(folder)
 base=fullfile(nl_root,'results','native_lab');if ~isfolder(base),mkdir(base);end
 folder=tempname(base);
end
assert(~isfolder(folder),'Choose a NEW output folder to protect previous runs.');mkdir(folder);
writeText(fullfile(folder,'session.json'),jsonencode(c,'PrettyPrint',true));
writeText(fullfile(folder,'configure_session.m'),nl_commands(c));
save(fullfile(folder,'native_session.mat'),'c','log','results','-v7.3');
D=zeros(0,11);T=zeros(0,8);
if ~isempty(log)&&isfield(log,'face_look_angle')
 S=zeros(0,7);
 for j=1:numel(log.face_ids)
  S=[S;log.times repmat(log.face_ids(j),numel(log.times),1) log.face_look_angle(:,:,j) ...
   double(log.face_valid_update(:,j)) double(log.face_scan_done(:,j)) log.face_counts(:,j)]; %#ok<AGROW>
 end
 writetable(array2table(S,'VariableNames',{'time_s','face_id','look_az_deg','look_el_deg','valid_update','scan_done','detection_count'}),fullfile(folder,'scan_state.csv'));
end
if ~isempty(log)
 for k=1:numel(log.times)
  for j=1:numel(log.detections{k})
   d=log.detections{k}{j};R=d.MeasurementNoise;
   D(end+1,:)=[log.times(k) d.SensorIndex d.Measurement(:)' R(1,1) R(2,2) R(3,3) R(1,2) R(1,3) R(2,3)]; %#ok<AGROW>
  end
  for j=1:numel(log.truth{k})
   t=log.truth{k}(j);T(end+1,:)=[log.times(k) t.PlatformID t.Position t.Velocity]; %#ok<AGROW>
  end
 end
 writetable(array2table(D,'VariableNames',{'time_s','sensor_id','east_m','north_m','up_m', ...
  'r_ee','r_nn','r_uu','r_en','r_eu','r_nu'}),fullfile(folder,'detections_enu.csv'));
 writetable(array2table(T,'VariableNames',{'time_s','target_id','east_m','north_m','up_m','ve_mps','vn_mps','vu_mps'}),fullfile(folder,'truth_enu.csv'));
 writetable(table(log.times,log.valid_update,log.counts,'VariableNames',{'time_s','valid_update','detection_count'}),fullfile(folder,'updates.csv'));
end
for q=1:numel(results)
 r=results{q};E=zeros(0,5);
 for k=1:numel(r.estimates)
  p=r.estimates{k};E=[E;repmat(log.times(k),size(p,1),1) r.ids{k} p]; %#ok<AGROW>
 end
 tag=sprintf('%02d_%s',q,r.method);
 writetable(array2table(E,'VariableNames',{'time_s','track_id','east_m','north_m','up_m'}),fullfile(folder,[tag '_tracks.csv']));
 writetable(table(log.times,r.ospa,r.gospa,r.timing,'VariableNames',{'time_s','ospa_m','gospa_m','seconds'}),fullfile(folder,[tag '_metrics.csv']));
end
writeText(fullfile(folder,'replay.m'),sprintf(['%% First run START_NATIVE_LAB once to add project paths.\n' ...
 'here=fileparts(mfilename(''fullpath''));\n' ...
 'saved=load(fullfile(here,''native_session.mat''));\n' ...
 'c=saved.c; log=saved.log;\n' ...
 '%% Replay exact stored observations, including imported real measurements.\n' ...
 'result=nl_track(log,c);\n' ...
 '%% Regenerate a simulation only when saved.log.source is native_simulation:\n' ...
 '%% regenerated=nl_simulate(c);\n']));
writeText(fullfile(folder,'README.txt'),sprintf(['Frames: ENU metres relative to session origin_lla (ellipsoid height).\n' ...
 'DEM orthometric height H, configured constant geoid N: h=H+N. Default N=0 is demo only.\n' ...
 'Raw source labels exist only in native MAT raw_detections; trackers receive no labels.\n' ...
 'Clutter prior is configured, not estimated from truth. No IQ surface clutter is injected into this run.\n' ...
 'Blank metric cells at non-update frames are intentional. OSPA/GOSPA use p=2; GOSPA alpha=2.\n' ...
 'The original _SPH registry names identify filter combinations; this branch supplies Cartesian ENU.\n']));
fprintf('Saved complete experiment: %s\n',folder);
end
function writeText(path,text)
f=fopen(path,'w','n','UTF-8');assert(f>=0,'Cannot write output file.');cl=onCleanup(@()fclose(f));fprintf(f,'%s',text); %#ok<NASGU>
end
