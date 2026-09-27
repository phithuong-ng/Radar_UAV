function log=nl_simulate(c,progress)
% Single simulation clock: uavScenario drives poses, radar samples that clock.
if nargin<2,progress=@(~,~,~)true;end
nl_validate(c);terrain=nl_terrain(c);preview=nl_preview(c,terrain);
state=rng;cleanup=onCleanup(@()rng(state));rng(c.seed,'twister'); %#ok<NASGU>
scene=uavScenario('UpdateRate',1/c.dt,'StopTime',preview.times(end),'ReferenceLocation',c.origin_lla);
n=numel(c.uavs);u=cell(n,1);
for j=1:n
 u{j}=uavPlatform(c.uavs(j).name,scene,'Trajectory',preview.trajectories{j},'ReferenceFrame','ENU');
end
setup(scene);
s=zeros(0,4);
if c.clutter.scatterers_enabled,s=c.clutter.scatterers;end
sp=zeros(size(s,1),3);
if ~isempty(s)
 sp=[s(:,1:2) zeros(size(s,1),1)];[g,~,~]=nl_ground(c,terrain,sp);sp(:,3)=g+s(:,3);
end
[sensors,profileScenes,faces]=nl_sensor_bank(c,size(s,1)); %#ok<ASGLU>
B=[0 1 0;1 0 0;0 0 -1];K=c.frames;
log=struct('schema_version',2,'source','native_simulation','config',c,'signature',nl_signature(c), ...
 'dem_sha256',file_sha256(terrain.path), ...
 'times',preview.times,'detections',{cell(K,1)},'raw_detections',{cell(K,1)}, ...
 'truth',{cell(K,1)},'sensor_config',{cell(K,1)},'valid_update',false(K,1), ...
 'look_angle',zeros(K,2),'counts',zeros(K,1),'P',preview.P,'V',preview.V, ...
 'AGL',preview.AGL,'release',version('-release'),'status','RUNNING');
F=numel(sensors);log.face_ids=[faces.id];log.face_definitions=faces;
log.face_look_angle=zeros(K,2,F);log.face_counts=zeros(K,F);
log.face_valid_update=false(K,F);log.face_scan_done=false(K,F);
for k=1:K
 assert(abs(scene.CurrentTime-log.times(k))<1e-7,'UAV/radar clocks diverged.');
 poses=struct('PlatformID',{},'Position',{},'Velocity',{});
 truth=struct('PlatformID',{},'Position',{},'Velocity',{},'Visible',{});
 for j=1:n
  motion=read(u{j});p=motion(1:3);v=motion(4:6);
  assert(norm(p-preview.P(k,:,j))<1e-5,'Preview differs from native UAV pose.');
  if k<c.uavs(j).birth_scan||k>c.uavs(j).death_scan,continue;end
  visible=true;if c.mapping.terrain_los,visible=nl_los(c,terrain,p);end
  truth(end+1)=struct('PlatformID',j,'Position',p,'Velocity',v,'Visible',visible); %#ok<AGROW>
  if visible,poses(end+1)=pose(j,p,v);end %#ok<AGROW>
 end
 for j=1:size(sp,1)
  if ~c.mapping.terrain_los||nl_los(c,terrain,sp(j,:)),poses(end+1)=pose(n+j,sp(j,:),[0 0 0]);end %#ok<AGROW>
 end
 raw=cell(0,1);configs=cell(F,1);
 for face=1:F
  [reports,num,config]=sensors{face}(poses,log.times(k));
  raw=[raw;reports(1:num)]; %#ok<AGROW>
  configs{face}=config;log.face_counts(k,face)=num;
  log.face_valid_update(k,face)=config.IsValidTime;log.face_scan_done(k,face)=config.IsScanDone;
  log.face_look_angle(k,:,face)=reshape(sensors{face}.LookAngle,1,2);
 end
 count=numel(raw);dets=cell(count,1);
 for q=1:count
  z=B*raw{q}.Measurement(1:3);R=B*raw{q}.MeasurementNoise(1:3,1:3)*B';
  % Raw source metadata kept separately; tracker must never receive truth IDs.
  dets{q}=objectDetection(log.times(k),z,'MeasurementNoise',(R+R')/2, ...
   'SensorIndex',raw{q}.SensorIndex,'MeasurementParameters',struct('Frame','Rectangular','HasVelocity',false));
 end
 log.raw_detections{k}=raw(1:count);log.detections{k}=dets;log.truth{k}=truth;
 if F==1,log.sensor_config{k}=configs{1};else,log.sensor_config{k}=configs;end
 log.valid_update(k)=any(log.face_valid_update(k,:));
 log.look_angle(k,:)=log.face_look_angle(k,:,1);log.counts(k)=count;
 if ~progress(k,K,log),error('NativeLab:Cancelled','Simulation cancelled. No complete run saved.');end
 if k<K,assert(advance(scene),'UAV scenario stopped early.');end
end
log.status='COMPLETE';
 function out=pose(id,p,v)
  out=struct('PlatformID',id,'Position',(B*p(:))','Velocity',(B*v(:))');
 end
end
