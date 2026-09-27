function tests=test_training
tests=functiontests(localfunctions);
end
function testJsonRoundTrip(t)
c=training_config;d=training_normalize(jsondecode(jsonencode(c)));training_validate(d);
verifyEqual(t,c,d);
end
function testRejectInvalidPhysicalConfiguration(t)
c=training_config;c.dt=0;verifyFails(t,@()training_validate(c));
c=training_config;c.uavs(1).arrival_s(2)=0;verifyFails(t,@()training_validate(c));
c=training_config;c.signal.bandwidth_hz=c.signal.sample_rate_hz;verifyFails(t,@()training_validate(c));
c=training_config;c.radar.reference_rcs_m2=-1;verifyFails(t,@()training_validate(c));
end
function testCoordinateAndCovarianceContract(t)
p=[500 -100 90];s=[0 -500 12];delta=p-s;
z=[atan2d(delta(2),delta(1));atan2d(delta(3),hypot(delta(1),delta(2)));norm(delta)];
R=diag([.15 .2 3].^2);row=training_row(2,.64,z,R,s);
verifyEqual(t,size(row),[1 20]);verifyEqual(t,row(3:5),p,'AbsTol',1e-9);
C=reshape(row(6:14),3,3);verifyGreaterThan(t,min(eig(C)),0);
verifyEqual(t,row(18:20),[3 deg2rad(.15) deg2rad(.2)],'AbsTol',1e-12);
verifyEqual(t,training_polar_to_enu([deg2rad(z(1:2));z(3)],s'),p','AbsTol',1e-9);
end
function testNativeMeasurementOrientation(t)
assumeTrue(t,~isempty(which('radarDataGenerator')),'Radar Toolbox unavailable');
% Deterministic close target checks NED/yaw/spherical -> ENU transform.
B=[0 1 0;1 0 0;0 0 -1];s=[0 -500 12];p=[600 -400 100];
sensor=radarDataGenerator(1,'No scanning','UpdateRate',1,'MountingLocation',(B*s')', ...
 'MountingAngles',[90 0 0],'DetectionCoordinates','Sensor spherical', ...
 'HasElevation',true,'HasRangeRate',false,'HasNoise',false,'HasFalseAlarms',false, ...
 'FieldOfView',[120;60],'ReferenceRange',100000,'DetectionProbability',.999999);
target=struct('PlatformID',1,'Position',(B*p')','Velocity',[0 0 0]);
[d,n]=sensor(target,0);verifyEqual(t,n,1);assert(n==1);
z=diag([-1 -1 1])*d{1}.Measurement;
actual=training_polar_to_enu([deg2rad(z(1:2));z(3)],s');verifyEqual(t,actual,p','AbsTol',1e-6);
end
function testNativeTrajectoryAndDEM(t)
assumeTrue(t,~isempty(which('waypointTrajectory')),'Trajectory API unavailable');
c=training_config;[P,V,~,~,tr,ts]=training_trajectory(c);
verifyEqual(t,size(P),[160 3 2]);verifyEqual(t,ts(end),101.76,'AbsTol',1e-10);
for j=1:2
 p=lookupPose(tr{j},c.uavs(j).arrival_s);verifyEqual(t,p,c.uavs(j).waypoints_enu_m,'AbsTol',1e-5);
 [ground,los]=training_terrain(c,P(:,:,j));verifyGreaterThan(t,min(P(:,3,j)-ground),0);
 verifySize(t,los,[160 1]);verifyLessThanOrEqual(t,max(vecnorm(V(:,:,j),2,2)),150);
end
end
function testExportAndLegacyBridge(t)
assumeTrue(t,~isempty(which('radarDataGenerator'))&&~isempty(which('waypointTrajectory')),'Radar APIs unavailable');
c=training_config;base=fullfile(training_root,'results','training_tests');if ~isfolder(base),mkdir(base);end
out=tempname(base);mkdir(out);[d,file]=training_generate(c,out);
verifyTrue(t,isfile(file));verifyNotEmpty(t,d.detections);
verifyEqual(t,size(d.detections,2),20);verifyEqual(t,numel(d.times),160);
verifyEqual(t,size(d.labels,1),size(d.detections,1));
verifyTrue(t,all(isfinite(d.detections),'all'));
verifyEqual(t,d.lambda_clutter,0);verifyTrue(t,all(d.labels(:,2)==1));
row=d.detections(1,:);a=make_detections(row,'spherical',d.sensor_position);
filter=initcvekf(a{1});verifyEqual(t,filter.State([1 3 5])',row(3:5),'AbsTol',1e-5);
verifyEmpty(t,a{1}.ObjectAttributes); % truth labels must not enter tracker
end
function verifyFails(t,fn)
failed=false;try,fn();catch,failed=true;end
verifyTrue(t,failed,'Invalid configuration was accepted.');
end
