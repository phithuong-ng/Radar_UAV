function [d,file]=training_generate(c,out)
% Native statistical radar detections, NOT waveform detections or the old Python generator.
training_validate(c);assert(c.frames==160,'Legacy run_mixed requires exactly 160 scans.');
if ~isfolder(out),mkdir(out);end
file=fullfile(out,'training_native.mat');assert(~isfile(file),'Use a new output directory.');
rngState=rng;restore=onCleanup(@()rng(rngState)); %#ok<NASGU>
rng(c.seed,'twister');[P,V,A,~,~,times]=training_trajectory(c);
% Radar scenario uses NED; project uses ENU. B maps ENU column vectors to NED.
B=[0 1 0;1 0 0;0 0 -1];n=numel(c.uavs);r=c.radar;
scene=radarScenario('UpdateRate',1/c.dt,'StopTime',times(end));
for j=1:n
 platform(scene,'ClassID',1,'Signatures',{rcsSignature('Pattern',10*log10(c.uavs(j).rcs_m2)*ones(2,2))});
end
sensor=radarDataGenerator(1,'No scanning','UpdateRate',1/c.dt, ...
 'MountingLocation',(B*r.position_enu_m(:))','MountingAngles',[90 0 0], ...
 'DetectionCoordinates','Sensor spherical','HasElevation',true,'HasRangeRate',false, ...
 'HasNoise',true,'HasFalseAlarms',r.false_alarms,'HasOcclusion',false, ...
 'TargetReportFormat','Detections','FieldOfView',r.field_of_view_deg(:), ...
 'RangeLimits',r.range_limits_m,'ReferenceRange',r.reference_range_m, ...
 'ReferenceRCS',10*log10(r.reference_rcs_m2),'DetectionProbability',r.detection_probability, ...
 'FalseAlarmRate',r.false_alarm_probability,'CenterFrequency',r.frequency_hz, ...
 'RangeResolution',r.range_resolution_m,'AzimuthResolution',r.azimuth_resolution_deg, ...
 'ElevationResolution',r.elevation_resolution_deg,'Profiles',platformProfiles(scene));
% Sensor yaw +90 in NED points east. Local x=E, y=-N, z=-U.
% Thus sensor az/el -> ENU az/el by negating both; range unchanged.
truth=zeros(0,14);rows=zeros(0,20);labels=zeros(0,3);scan_stats=zeros(c.frames,6);
for k=1:c.frames
 poses=struct('PlatformID',{},'Position',{},'Velocity',{});active=0;visible=0;
 for j=1:n
  u=c.uavs(j);if k<u.birth_scan||k>u.death_scan,continue;end
  p=P(k,:,j);v=V(k,:,j);[ground,los]=training_terrain(c,p);
  assert(p(3)>ground,'UAV trajectory crosses terrain.');active=active+1;visible=visible+los;
  truth(end+1,:)=[k times(k) j p v p(3)-ground los NaN 0 norm(A(k,:,j))]; %#ok<AGROW>
  if c.environment.terrain_los&&~los,continue;end
  poses(end+1)=struct('PlatformID',j,'Position',(B*p')','Velocity',(B*v')'); %#ok<AGROW>
 end
 [detections,count]=sensor(poses,times(k));
 nt=0;nf=0;
 for q=1:count
  det=detections{q};z=det.Measurement(:);C=det.MeasurementNoise;
  S=diag([-1 -1 1]);z=S*z;C=S*C*S';
  rows(end+1,:)=training_row(k,times(k),z,C,r.position_enu_m); %#ok<AGROW>
  id=NaN;attrs=det.ObjectAttributes;
  if iscell(attrs)&&~isempty(attrs),attrs=attrs{1};end
  if isstruct(attrs)&&isfield(attrs,'TargetIndex'),id=double(attrs(1).TargetIndex);end
  isTarget=double(id>=0);if isnan(id),isTarget=-1;end
  labelID=0;if isfinite(id)&&id>0,labelID=id;end
  labels(end+1,:)=[labelID isTarget 0]; %#ok<AGROW>
  nt=nt+(isTarget==1);nf=nf+(isTarget==0);
 end
 scan_stats(k,:)=[k active visible nt nf count-nt-nf];
end
volume=prod(diff(c.bounds_enu_m,1,2)); %#ok<NASGU>
d=struct('truth',truth,'detections',rows,'labels',labels,'times',times,'dt',c.dt, ...
 'n_targets',n,'lambda_clutter',mean(scan_stats(:,5)),'pd_nominal',r.detection_probability, ...
 'bounds',c.bounds_enu_m,'sensor_position',r.position_enu_m,'scenario','training_native', ...
 'seed',c.seed,'reference_range_m',r.reference_range_m,'reference_elevation_deg',5, ...
 'scan_stats',scan_stats,'config_json',jsonencode(c),'generator','radarDataGenerator R2025a', ...
 'truth_columns','scan,time,id,x,y,z,vx,vy,vz,agl,los,pd_unknown,disturbed,acceleration', ...
 'scan_stats_columns','scan,active,visible,target_reports,false_reports,unknown_reports');
save(file,'-struct','d');
fprintf('Exported %d reports, %d truth rows to %s\n',size(rows,1),size(truth,1),file);
end
