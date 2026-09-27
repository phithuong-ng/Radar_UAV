function tests=test_native_rx
tests=functiontests(localfunctions);
end
function testProfileAndFaceMounts(t)
c=nl_rx_preset;f=nl_faces(c);verifyEqual(t,[f.id],1:4);
verifyEqual(t,[f.looks_per_cycle],9*ones(1,4));
verifyEqual(t,f(1).coverage,[-45 45;0 60]);
verifyEqual(t,f(1).radar.electronic_azimuth_limits_deg,[-30 30]);
verifyEqual(t,f(1).radar.electronic_elevation_limits_deg,[10 50]);
for j=1:4
 M=nl_rotation(90-f(j).radar.heading_enu_deg,f(j).radar.tilt_deg,f(j).radar.roll_deg);
 B=[0 1 0;1 0 0;0 0 -1];v=B*M*[1;0;0];
 verifyEqual(t,v,[cosd((j-1)*90);sind((j-1)*90);0],'AbsTol',1e-12);
end
c.device.faces_enabled=[false true false false];c.device.operation='Focus';c.device.focus_face=2;
nl_validate(c);f=nl_faces(c);verifyEqual(t,f.id,2);verifyEqual(t,f.looks_per_cycle,1);
c.device.focus_face=1;mustFail(t,@()nl_validate(c));
end
function testLogicalFaceEditor(t)
verifyEqual(t,nl_value('[true,false,true,false]',true(1,4)),[true false true false]);
mustFail(t,@()nl_value('true',true(1,4)));
end
function testFourFacesNativeDetectionAndPreviewAgreement(t)
c=shortConfig;c.radar.noise=false;c.radar.reference_range_m=1e6;
c.radar.detection_probability=1-1e-9;c.mapping.terrain_los=false;
[sensors,scenes,faces]=nl_sensor_bank(c,0); %#ok<ASGLU>
preview=nl_scan_preview(c);B=[0 1 0;1 0 0;0 0 -1];hits=zeros(1,4);
for k=1:c.frames
 for j=1:4
  a=preview.look(k,:,j);r=faces(j).radar;
  M=nl_rotation(90-r.heading_enu_deg,r.tilt_deg,r.roll_deg)*nl_rotation(a(1),-a(2),0);
  p=(B*M*[1000;0;0])'+r.position_enu_m;
  pose=struct('PlatformID',1,'Position',(B*p')','Velocity',[0 0 0]);
  [reports,count,cfg]=sensors{j}(pose,(k-1)*c.dt);
  verifyEqual(t,reshape(sensors{j}.LookAngle,1,2),a,'AbsTol',1e-10);
  verifyTrue(t,cfg.IsValidTime);hits(j)=hits(j)+count;
  if count>0
   verifyEqual(t,reports{1}.SensorIndex,j);
   verifyLessThan(t,norm(B*reports{1}.Measurement-p'),2);
  end
 end
end
verifyGreaterThan(t,hits,zeros(1,4));
end
function testPredictedVisibilityDoesNotCountUnilluminatedTracks(t)
c=nl_rx_preset('Focus');c.device.focus_face=1;
look=reshape([0 10],1,2,1);p=c.radar.position_enu_m;
xyz=[p+[1000 0 180];p+[-1000 0 180];p+[20 0 3];p+[12000 0 2100]];
verifyEqual(t,nl_in_beam(c,xyz,look,true),[true;false;false;false]);
verifyEqual(t,nl_in_beam(c,xyz,look,false),false(4,1));
end
function testSimulationPreservesFaceIDsAndArchiveScanState(t)
c=shortConfig;c.mapping.terrain_los=false;c.radar.reference_range_m=1e6;c.radar.noise=false;
log=nl_simulate(c);verifySize(t,log.face_look_angle,[c.frames 2 4]);
verifyEqual(t,sum(log.face_counts,2),log.counts);
verifyEqual(t,log.face_look_angle,nl_scan_preview(c).look,'AbsTol',1e-10);
for k=1:c.frames
 for j=1:numel(log.detections{k})
  verifyEqual(t,log.detections{k}{j}.SensorIndex,log.raw_detections{k}{j}.SensorIndex);
  verifyEmpty(t,log.detections{k}{j}.ObjectAttributes);
 end
end
folder=nl_export(c,log,{});verifyTrue(t,isfile(fullfile(folder,'scan_state.csv')));
other=nl_import_csv(fullfile(folder,'detections_enu.csv'),c,fullfile(folder,'updates.csv'));
verifyEqual(t,other.counts,log.counts);
for k=1:c.frames
 for j=1:numel(log.detections{k}),verifyEqual(t,other.detections{k}{j}.SensorIndex,log.detections{k}{j}.SensorIndex);end
end
end
function testRXTrackersExecute(t)
c=shortConfig;c.mapping.terrain_los=false;c.radar.reference_range_m=1e6;
c.radar.noise=false;log=nl_simulate(c);
verifyGreaterThan(t,sum(log.counts),0);
c.tracking.max_initialization_seconds=300;c.tracking.max_scan_seconds=120;c.tracking.max_run_seconds=600;
for method={'GNN_CV_EKF_SPH','JPDA_CV_EKF_SPH','TOMHT_CV_EKF_SPH','GM_PHD_CV_CART'}
 c.method=method{1};r=nl_track(log,c);verifyEqual(t,r.status,'COMPLETE');
 verifyTrue(t,all(isfinite(r.gospa(log.valid_update))));
end
end
function testOSMOverlayRebasesAndViewHasHeight(t)
c=nl_defaults;terrain=nl_terrain(c);map=nl_osm(c,terrain);
verifyTrue(t,any(all(isfinite(map.runway),2)));
p=map.runway(find(all(isfinite(map.runway),2),1),:);
[lat,lon]=enu2geodetic(p(1),p(2),p(3)-1.5,c.origin_lla(1),c.origin_lla(2),c.origin_lla(3),terrain.ellipsoid);
c2=nl_rebase(c,c.origin_lla+[.0001 -.0001 1]);terrain2=nl_terrain(c2);map2=nl_osm(c2,terrain2);
q=map2.runway(find(all(isfinite(map2.runway),2),1),:);
[lat2,lon2]=enu2geodetic(q(1),q(2),q(3)-1.5,c2.origin_lla(1),c2.origin_lla(2),c2.origin_lla(3),terrain2.ellipsoid);
verifyEqual(t,[lat2 lon2],[lat lon],'AbsTol',1e-8);
f=nl_app(false);cleanup=onCleanup(@()close(f)); %#ok<NASGU>
ax=findall(f,'Tag','SceneAxes');verifyNotEmpty(t,findall(ax,'Tag','OSM_runway'));
verifyEqual(t,findall(f,'Tag','VerticalScale').Value,'Auto');
verifyEqual(t,ax.ZLabel.String,'Cao độ ENU (m)');
verifyEqual(t,ax.ZTick,[0 200 400]);
verifyEqual(t,ax.FontSize,9);
surface=findall(ax,'Tag','TerrainSurface');verifyEqual(t,surface.FaceColor,[.67 .77 .59]);
verifyNotEmpty(t,findall(f,'Tag','Properties_device'));
deviceEditor=findall(f,'Tag','Properties_device');parentTab=ancestor(deviceEditor,'uitab');
verifyEqual(t,parentTab.Title,'Radar');
tabs=findall(f,'Type','uitab');verifyFalse(t,any(strcmp({tabs.Title},'RX-R417C')));
end
function c=shortConfig
c=nl_rx_preset;c.frames=28;c.dt=4;
for j=1:numel(c.uavs),c.uavs(j).arrival_s=c.uavs(j).arrival_s/80*108;c.uavs(j).death_scan=28;end
end
function mustFail(t,f)
failed=false;try,f();catch,failed=true;end
verifyTrue(t,failed,'Invalid input must fail explicitly.');
end
