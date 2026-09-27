function result=nl_track(log,c,progress)
% Reuse the ORIGINAL project's native factory and tuned filter initializers.
% All new detections are Cartesian ENU, retaining the full 3x3 covariance.
if nargin<3,progress=@(~,~,~)true;end
nl_validate(c);
assert(strcmp(log.signature,nl_signature(c)),'Scenario/sensor configuration differs from saved observations.');
if isfield(log,'dem_sha256')
 path=char(c.mapping.dem_file);if ~isfile(path),path=fullfile(nl_root,path);end
 assert(strcmp(file_sha256(path),log.dem_sha256),'DEM file changed since observations were generated.');
end
m=nl_registry(c.method);m.frame="cartesian";
cfg=nl_tracking_defaults(c.tracking);
previousRng=rng;restoreRng=onCleanup(@()rng(previousRng)); %#ok<NASGU>
rng(cfg.filter_seed,'twister');
if ~isfield(cfg,'max_initialization_seconds'),cfg.max_initialization_seconds=120;end
device=nl_device(c);faces=nl_faces(c);
sensor=struct('sensor_ids',[faces.id],'num_sensors',max([faces.id]),'dt',c.dt*c.radar.update_every_steps,'bounds',c.bounds_enu_m, ...
 'lambda_effective',max(1e-12,cfg.clutter_expected_per_update),'reference_range_m',c.radar.reference_range_m, ...
 'reference_elevation_deg',5);
totalClock=tic;constructionClock=tic;
tracker=nl_make_tracker(m,sensor,cfg);
scanAware=strcmp(device.profile,'RX-R417C')&&device.scan_aware_tracking&&any(m.tracker==["GNN","JPDA"])&&isfield(log,'face_look_angle');
if scanAware,tracker.HasDetectableTrackIDsInput=true;end
constructionSeconds=toc(constructionClock);
distance=@(a,b)norm(a.Position-b.Position);
ospa=trackOSPAMetric('Distance','custom','DistanceFcn',distance,'Order',2,'CutoffDistance',cfg.metric_cutoff_m);
gospa=trackGOSPAMetric('Distance','custom','DistanceFcn',distance,'Order',2, ...
 'CutoffDistance',cfg.metric_cutoff_m,'Alpha',2,'SwitchingPenalty',0);
K=numel(log.times);
result=struct('method',c.method,'config',cfg,'estimates',{cell(K,1)},'ids',{cell(K,1)}, ...
 'native_tracks',{cell(K,1)},'ospa',nan(K,1),'gospa',nan(K,1),'timing',nan(K,1), ...
 'status','RUNNING','note','Cartesian ENU; native association diagnostics and track lifecycle saved.');
result.construction_seconds=constructionSeconds;result.initialization_seconds=NaN;
result.label=nl_run_label(c.method,cfg);
result.tentative_tracks=cell(K,1);result.all_tracks=cell(K,1);result.association=cell(K,1);
initialized=false;steadySeconds=0;
for k=1:K
 stepClock=tic;firstCall=false;tracks=[];xyz=zeros(0,3);ids=zeros(0,1);
 if log.valid_update(k)
  ds=log.detections{k};dets=cell(size(ds));
  for j=1:numel(ds)
   d=ds{j};dets{j}=objectDetection(d.Time,d.Measurement,'SensorIndex',d.SensorIndex, ...
    'MeasurementNoise',d.MeasurementNoise*cfg.measurement_variance_scale, ...
    'MeasurementParameters',struct('Frame','Rectangular','HasVelocity',false));
  end
  if initialized||~isempty(dets)
   firstCall=~initialized;
   if scanAware
    detectable=zeros(0,1);
    if initialized
     predicted=predictTracksToTime(tracker,'all',log.times(k));
     [positions,trackIDs]=nl_positions(predicted,m,cfg);
     inside=nl_in_beam(c,positions,log.face_look_angle(k,:,:),log.face_valid_update(k,:));
     detectable=trackIDs(inside);
    end
    [tracks,tentative,allTracks,analysisInfo]=tracker(dets,log.times(k),detectable);
   else
    [tracks,tentative,allTracks,analysisInfo]=tracker(dets,log.times(k));
   end
   initialized=true;
   result.tentative_tracks{k}=tentative;result.all_tracks{k}=allTracks;result.association{k}=analysisInfo;
   [xyz,ids]=nl_positions(tracks,m,cfg);
  end
  if ~strcmp(log.source,'real_csv')
   points=struct('TrackID',{},'Position',{});
   for j=1:numel(ids),points(end+1)=struct('TrackID',ids(j),'Position',xyz(j,:));end %#ok<AGROW>
   result.ospa(k)=ospa(points,log.truth{k});result.gospa(k)=gospa(points,log.truth{k});
  end
 end
 result.estimates{k}=xyz;result.ids{k}=ids;result.native_tracks{k}=tracks;result.timing(k)=toc(stepClock);
 if firstCall,result.initialization_seconds=result.timing(k);
 else,steadySeconds=steadySeconds+result.timing(k);end
 nl_timing_guard(c.method,k,result.timing(k),steadySeconds,firstCall,cfg);
 if ~progress(k,K,result),error('NativeLab:Cancelled','Tracking cancelled.');end
end
result.status='COMPLETE';result.wall_seconds=toc(totalClock);result.steady_seconds=steadySeconds;
end
