function tests=test_native_lab
tests=functiontests(localfunctions);
end
function testConfigAndSafeParsing(t)
c=nl_defaults;nl_validate(c);
verifyEqual(t,nl_value('[1,2,3]',zeros(1,3)),[1 2 3]);
verifyEqual(t,nl_value('true',false),true);
mustFail(t,@()nl_value('system("anything")',0));
c.dt=0;mustFail(t,@()nl_validate(c));
c=nl_defaults;c.uavs(1).arrival_s(2)=0;mustFail(t,@()nl_validate(c));
c=nl_defaults;c.clutter.scatterers(1,4)=-1;mustFail(t,@()nl_validate(c));
end
function testDEMCoordinateAndAGL(t)
c=nl_defaults;terrain=nl_terrain(c);p=c.uavs(1).waypoints_enu_m;
[~,~,lla]=nl_ground(c,terrain,p);o=c.origin_lla;
[e,n,u]=geodetic2enu(lla(:,1),lla(:,2),lla(:,3),o(1),o(2),o(3),terrain.ellipsoid);
verifyEqual(t,[e n u],p,'AbsTol',1e-6);
q=nl_set_agl(c,terrain,p,70);[~,agl]=nl_ground(c,terrain,q);
verifyEqual(t,agl,70*ones(size(agl)),'AbsTol',1e-6);
end
function testRebasePreservesPhysicalWaypoints(t)
c=nl_defaults;terrain=nl_terrain(c);[~,~,before]=nl_ground(c,terrain,c.uavs(1).waypoints_enu_m);
c2=nl_rebase(c,c.origin_lla+[.0002 .0002 2]);terrain2=nl_terrain(c2);
[~,~,after]=nl_ground(c2,terrain2,c2.uavs(1).waypoints_enu_m);
verifyEqual(t,after,before,'AbsTol',1e-6);
end
function testTrajectoryWaypointPassageAndSpeed(t)
c=nl_defaults;preview=nl_preview(c);
for j=1:numel(c.uavs)
 p=lookupPose(preview.trajectories{j},c.uavs(j).arrival_s);
 verifyEqual(t,p,c.uavs(j).waypoints_enu_m,'AbsTol',1e-5);
 verifyLessThanOrEqual(t,max(vecnorm(preview.V(:,:,j),2,2)),c.uavs(j).speed_limit_mps);
end
end
function testNativeCartesianFrameIncludingMountTranslation(t)
c=nl_defaults;c.radar.noise=false;c.mapping.terrain_los=false;c.radar.reference_range_m=1e6;
c.radar.detection_probability=1-1e-9;c.radar.range_bias_fraction=0;
[sensor,~]=nl_radar(c,0);B=[0 1 0;1 0 0;0 0 -1];p=[700 -300 110];
pose=struct('PlatformID',1,'Position',(B*p')','Velocity',[0 0 0]);
[d,n]=sensor(pose,0);verifyEqual(t,n,1);assert(n==1);
% Noise-free is not refraction-free: test coordinates against an independent
% native spherical report of the SAME physical model, not unperturbed truth.
[reference,~]=nl_radar(c,0);reference.DetectionCoordinates='Sensor spherical';
[spherical,count]=reference(pose,0);verifyEqual(t,count,1);assert(count==1);
z=spherical{1}.Measurement;
local=[z(3)*cosd(z(2))*cosd(z(1));-z(3)*cosd(z(2))*sind(z(1));-z(3)*sind(z(2))];
expected=c.radar.position_enu_m(:)+local;
verifyEqual(t,B*d{1}.Measurement,expected,'AbsTol',1e-5);
verifyLessThan(t,norm(expected-p'),1); % Physical sanity bound for this fixed 734 m fixture.
end
function testHeadingCanExcludeTarget(t)
c=nl_defaults;c.radar.heading_enu_deg=180;c.radar.field_of_view_deg=[15 20];c.radar.noise=false;
c.radar.reference_range_m=1e6;c.radar.detection_probability=1-1e-9;
[sensor,~]=nl_radar(c,0);B=[0 1 0;1 0 0;0 0 -1];p=[700 -500 100];
pose=struct('PlatformID',1,'Position',(B*p')','Velocity',[0 0 0]);[~,n]=sensor(pose,0);verifyEqual(t,n,0);
end
function testRadarScanConfigurations(t)
c=nl_defaults;
for mode={'No scanning','Rotator','Sector','Raster'}
 c.radar.mode=mode{1};[r,~]=nl_radar(c,0);
 verifyEqual(t,r.UpdateRate,1/(c.dt*c.radar.update_every_steps),'AbsTol',1e-12);
end
c.radar.mode='Raster';c.radar.scan_technology='Electronic';[r,~]=nl_radar(c,0);
verifyEqual(t,r.ScanMode,'Electronic');
end
function testNativeSimulationReproducibilityAndLabelIsolation(t)
c=shortConfig;c.mapping.terrain_los=false;
a=nl_simulate(c);b=nl_simulate(c);
verifyEqual(t,a.counts,b.counts);verifyEqual(t,a.valid_update,b.valid_update);
verifyEqual(t,a.status,'COMPLETE');
for k=1:numel(a.times)
 for j=1:numel(a.detections{k})
  x=a.detections{k}{j};y=b.detections{k}{j};
  verifyEqual(t,x.Measurement,y.Measurement);verifyEqual(t,x.MeasurementNoise,y.MeasurementNoise);
  verifyEmpty(t,x.ObjectAttributes);verifyGreaterThanOrEqual(t,min(eig(x.MeasurementNoise)),-1e-10);
 end
end
end
function testSensorUpdateSchedule(t)
c=shortConfig;c.mapping.terrain_los=false;c.radar.update_every_steps=2;
log=nl_simulate(c);verifyEqual(t,log.valid_update,mod((0:c.frames-1)',2)==0);
verifyEqual(t,log.counts(~log.valid_update),zeros(sum(~log.valid_update),1));
end
function testStationaryScattererUsesNativeRadarButIsNotTruth(t)
c=shortConfig;c.mapping.terrain_los=false;c.clutter.scatterers_enabled=true;
c.radar.reference_range_m=1e6;c.radar.detection_probability=1-1e-9;c.radar.noise=false;
log=nl_simulate(c);
for k=1:c.frames,verifyEqual(t,numel(log.truth{k}),numel(c.uavs));end
verifyGreaterThan(t,sum(log.counts),0);
end
function testAllSeventeenOriginalNativeTrackerCombinations(t)
c=shortConfig;c.frames=24;c.dt=5;
for q=1:numel(c.uavs),c.uavs(q).arrival_s=c.uavs(q).arrival_s/105*115;c.uavs(q).death_scan=c.frames;end
log=syntheticLog(c);reg=method_registry('extended');
verifyEqual(t,numel(reg),17);
% Correctness suite, not a benchmark: allow native cold-start overhead.
c.tracking.max_initialization_seconds=300;c.tracking.max_scan_seconds=120;c.tracking.max_run_seconds=600;
records=cell(numel(reg),4);
for j=1:numel(reg)
 c.method=char(reg(j).name);fprintf('\nNative tracker %d/17: %s\n',j,c.method);clock=tic;
 try
  result=nl_track(log,c);
  verifyEqual(t,result.status,'COMPLETE');verifyTrue(t,all(isfinite(result.gospa)));
  verifyGreaterThanOrEqual(t,min(result.gospa),0);
  records(j,:)={c.method,'COMPLETED',toc(clock),''};
 catch ME
  records(j,:)={c.method,'ERROR',toc(clock),ME.message};
  verifyFail(t,sprintf('%s: %s',c.method,ME.message));
 end
end
out=fullfile(nl_root,'results','native_tests');if ~isfolder(out),mkdir(out);end
writetable(cell2table(records,'VariableNames',{'Method','Execution','Seconds','Message'}),fullfile(out,'tracker_methods.csv'));
end
function testColdStartAndSteadyTimeLimitsRemainEnforced(t)
c=nl_defaults;cfg=c.tracking;
nl_timing_guard('fixture',1,100,0,true,cfg);
verifyError(t,@()nl_timing_guard('fixture',1,121,0,true,cfg),'NativeLab:TimeLimit');
verifyError(t,@()nl_timing_guard('fixture',2,21,21,false,cfg),'NativeLab:TimeLimit');
verifyError(t,@()nl_timing_guard('fixture',3,1,181,false,cfg),'NativeLab:TimeLimit');
end
function testInactivePropertiesDoNotWarn(t)
c=nl_defaults;
for mode={'No scanning','Rotator','Sector','Raster'}
 c.radar.mode=mode{1};verifyWarningFree(t,@()nl_radar(c,0));
end
c.radar.mode='Raster';c.radar.scan_technology='Electronic';verifyWarningFree(t,@()nl_radar(c,0));
% RC1/RC2 saved sessions may contain this legacy field. It must not cause
% an inactive property assignment; Custom scanning is not implemented here.
c.radar.scan_loss=true;verifyWarningFree(t,@()nl_radar(c,0));
c.radar.scan_loss=false;verifyWarningFree(t,@()nl_radar(c,0));
rows=nl_fields(c,'radar');verifyFalse(t,any(strcmp(rows(:,1),'scan_loss')));
m=method_registry(c.method);m.frame="cartesian";
d=struct('dt',c.dt,'bounds',c.bounds_enu_m,'lambda_effective',2,'reference_range_m',3000,'reference_elevation_deg',5);
verifyWarningFree(t,@()nl_make_tracker(m,d,c.tracking));
end
function testNativeMetricsKnownGeometry(t)
distance=@(a,b)norm(a.Position-b.Position);
o=trackOSPAMetric('Distance','custom','DistanceFcn',distance,'Order',2,'CutoffDistance',300);
g=trackGOSPAMetric('Distance','custom','DistanceFcn',distance,'Order',2,'CutoffDistance',300,'Alpha',2,'SwitchingPenalty',0);
a=struct('TrackID',1,'Position',[0 0 0]);b=struct('PlatformID',1,'Position',[3 4 0]);
verifyEqual(t,o(a,b),5,'AbsTol',1e-10);verifyEqual(t,g(a,b),5,'AbsTol',1e-10);
end
function testTrackerReplayDoesNotMutateStoredMeasurements(t)
c=nl_defaults;log=syntheticLog(c);before=log.detections{1}{1}.MeasurementNoise;
c.tracking.measurement_variance_scale=4;nl_track(log,c);
verifyEqual(t,log.detections{1}{1}.MeasurementNoise,before);
end
function testExportImportPreservesCovarianceAndEmptyUpdates(t)
c=nl_defaults;log=syntheticLog(c);log.detections{3}={};log.counts(3)=0;
log.signature=nl_signature(c);folder=nl_export(c,log,{});
other=nl_import_csv(fullfile(folder,'detections_enu.csv'),c,fullfile(folder,'updates.csv'));
verifyEqual(t,other.counts,log.counts);verifyEqual(t,other.valid_update,log.valid_update);
verifyEmpty(t,other.detections{3});
verifyEqual(t,other.detections{1}{1}.MeasurementNoise,log.detections{1}{1}.MeasurementNoise,'AbsTol',1e-12);
verifyTrue(t,isfile(fullfile(folder,'configure_session.m')));
end
function testChangedSensorConfigInvalidatesReplay(t)
c=nl_defaults;before=nl_signature(c);c.tracking.assignment_threshold=30;verifyEqual(t,nl_signature(c),before);
c.radar.heading_enu_deg=15;verifyNotEqual(t,nl_signature(c),before);
end
function testGeneratedConfigurationHandlesSingleUAV(t)
c=nl_defaults;c.uavs=c.uavs(1);text=nl_commands(c);
verifyTrue(t,contains(text,'c.uavs=c.uavs(1);'));
verifyTrue(t,contains(text,'c.uavs(1).name='));
end
function testNativeIQExecution(t)
assert(~isempty(which('constantGammaClutter'))&&~isempty(which('phased.ULA')), ...
 'Optional IQ module requires Radar and Phased Array toolboxes.');
c=nl_defaults;c.iq.pulses=4;c.iq.array_elements=2;result=nl_iq(c,false);
verifyEqual(t,size(result.cube),[2000 2 4]);verifyTrue(t,all(isfinite(result.cube),'all'));
end
function testUIConstructsRequiredEditors(t)
f=nl_app(false);cleanup=onCleanup(@()close(f)); %#ok<NASGU>
for tag={'Waypoints','Properties_radar','Scatterers','TrackerMethod','SceneAxes'}
 verifyNotEmpty(t,findall(f,'Tag',tag{1}));
end
status=findall(f,'Tag','NativeStatus');verifyNotEmpty(t,status);
verifyFalse(t,contains(strjoin(string(status.Value)),"Không hoàn tất"));
end
function c=shortConfig
c=nl_defaults;oldEnd=(c.frames-1)*c.dt;c.frames=8;c.dt=15;
for j=1:numel(c.uavs),c.uavs(j).arrival_s=c.uavs(j).arrival_s*((c.frames-1)*c.dt)/oldEnd;c.uavs(j).death_scan=c.frames;end
end
function log=syntheticLog(c)
K=c.frames;times=(0:K-1)'*c.dt;
log=struct('source','native_simulation','times',times,'detections',{cell(K,1)}, ...
 'truth',{cell(K,1)},'valid_update',true(K,1),'counts',ones(K,1),'status','COMPLETE', ...
 'signature',nl_signature(c));
R=[25 2 1;2 36 3;1 3 49];
for k=1:K
 p=[300+10*times(k) -200 100];
 log.detections{k}={objectDetection(times(k),p','MeasurementNoise',R, ...
  'MeasurementParameters',struct('Frame','Rectangular','HasVelocity',false))};
 log.truth{k}=struct('PlatformID',1,'Position',p,'Velocity',[10 0 0]);
end
end
function mustFail(t,fn)
failed=false;try,fn();catch,failed=true;end
verifyTrue(t,failed);
end
