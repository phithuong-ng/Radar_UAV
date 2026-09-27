function tests=test_core
tests=functiontests(localfunctions);
end
function testMetricContracts(t)
s=set_metrics(zeros(0,3),zeros(0,3),300);verifyEqual(t,s(1:6),zeros(1,6));
s=set_metrics([0 0 0],zeros(0,3),300);verifyEqual(t,s([1 4]),[300 1]);
s=set_metrics([0 0 0],[3 4 0],300);verifyEqual(t,s([1 2 7]),[5 5 5],'AbsTol',1e-10);
s=set_metrics([0 0 0],[0 0 0;1000 0 0],300);verifyEqual(t,s(1),150);verifyEqual(t,s(5),1);
X=[0 0 0;50 20 0;100 0 0];Y=[99 0 0;1 0 0;50 21 0];
a=set_metrics(X,Y,300);b=set_metrics(X([3 1 2],:),Y([2 3 1],:),300);verifyEqual(t,a,b,'AbsTol',1e-10);
end
function testDatasetSpeedAndNoise(t)
[root,c]=configuration(); %#ok<ASGLU>
d=load(fullfile(root,'data','datasets','fast_uav_mixed_9100.mat'));
v=vecnorm(d.truth(:,7:9),2,2);verifyEqual(t,min(v),0);verifyEqual(t,max(v),150,'AbsTol',1e-8);
verifyLessThanOrEqual(t,max(v),150+1e-8);verifyGreaterThan(t,sum(v==0),100);
mask=d.labels(:,2)==1;verifyEqual(t,d.detections(mask,18:20),d.oracle_noise_sigma_bias(mask,1:3),'AbsTol',1e-12);
verifyEqual(t,numel(dir(fullfile(root,'data','datasets','*.mat'))),80);
end
function testSensorConversionAndCovariance(t)
[~,c]=configuration();p=[500 -100 90];row=makeRow(1,p,[0 -500 12]);
a=make_detections(row,'spherical',int64([0 -500 12]));f=init_tuned_filter(a{1},'initcvekf',c);
verifyEqual(t,f.State([1 3 5])',p,'AbsTol',1e-7);
verifyEqual(t,diag(f.StateCovariance([2 4 6],[2 4 6])),[90;90;10].^2,'AbsTol',1e-7);
verifyEqual(t,a{1}.ObjectClassID,0);verifyTrue(t,isempty(a{1}.ObjectAttributes));
b=make_detections(row,'cartesian',[0 -500 12]);verifyEqual(t,b{1}.Measurement,p');
verifyEqual(t,diag(a{1}.MeasurementNoise),[.15 .2 3]'.^2,'AbsTol',1e-10);
end
function testStateDefinitions(t)
[~,c]=configuration();p=[100 200 80];a=make_detections(makeRow(1,p,[0 -500 12]),'spherical',[0 -500 12]);
for name=["initcvekf","initcvukf","initekfimm","initcaukf","initctukf"]
 f=init_tuned_filter(a{1},name,c);tr=struct('State',f.State,'TrackID',1);xyz=track_positions(tr,name);
 verifyEqual(t,xyz,p,'AbsTol',1e-6);
 if name=="initekfimm",verifyEqual(t,numel(f.TrackingFilters),3);end
end
for name=["initcvgmphd","initcagmphd"]
 f=init_tuned_phd(name,c);verifyFalse(t,f.HasExtent);
 b=make_detections(makeRow(1,p,[0 -500 12]),'cartesian',[0 -500 12]);
 f=init_tuned_phd(name,c,b);verifyFalse(t,f.HasExtent);
end
end
function testTemporalSupportIsCausalAndKeepsHover(t)
[~,c]=configuration();rows=zeros(0,20);
for k=1:8
 rows(end+1,:)=makeRow(k,[100 -100 80],[0 -500 12]); %#ok<AGROW>
 rows(end+1,:)=makeRow(k,[1000*k 2000 80],[0 -500 12]); %#ok<AGROW>
end
[~,indices]=temporal_support(rows,(0:7)'*.64,c.temporal_support);ix=vertcat(indices{:});
verifyTrue(t,all(ismember(1:2:size(rows,1),ix)));
[~,prefix]=temporal_support(rows(rows(:,1)<=4,:),(0:3)'*.64,c.temporal_support);
verifyEqual(t,vertcat(prefix{:}),ix(rows(ix,1)<=4));
end
function testNativeGNN(t)
checkFamily(t,'GNN');
end
function testNativeJPDA(t)
checkFamily(t,'JPDA');
end
function testNativeTOMHT(t)
checkFamily(t,'TOMHT');
end
function testNativePHD(t)
checkFamily(t,'PHD');
end
function checkFamily(t,family)
[~,c]=configuration();reg=method_registry('extended');reg=reg([reg.tracker]==string(family));
sensor=struct('dt',.64,'bounds',[-3000 5000;-4000 2000;20 400], ...
 'lambda_effective',10,'reference_range_m',2500,'reference_elevation_deg',5);
for m=reg
 tracker=make_tracker(m,sensor,c);seen=false;lastXYZ=zeros(0,3);
 for k=1:24
  p=[100+80*.64*min(k-1,12),-100,100];row=makeRow(k,p,[0 -500 12]);ds=make_detections(row,m.frame,[0 -500 12]);
  tracks=tracker(ds,(k-1)*.64);[xyz,ids]=track_positions(tracks,m.init);
  verifyTrue(t,all(isfinite(xyz(:))),char(m.name));verifyEqual(t,numel(unique(ids)),numel(ids));
  seen=seen || ~isempty(xyz);if k==24,lastXYZ=xyz;end
 end
 verifyTrue(t,seen,['Never confirmed: ' char(m.name)]);
 verifyNotEmpty(t,lastXYZ,['Lost stationary target: ' char(m.name)]);
 if ~isempty(lastXYZ),verifyLessThan(t,min(vecnorm(lastXYZ-p,2,2)),100,char(m.name));end
 tracks=tracker(cell(0,1),24*.64);xyz=track_positions(tracks,m.init);verifyTrue(t,all(isfinite(xyz(:))));
end
end
function testIncompleteRunsCannotWin(t)
r=struct('status','TIME_LIMIT','completed_scans',1,'estimates',{{zeros(0,3)}},'timing',.1);
[stats,~]=evaluate_pass(r,[1 0 1 0 0 50],300,1,160);verifyEqual(t,stats.ospa,Inf);
end
function [root,c]=configuration()
root=fileparts(fileparts(mfilename('fullpath')));c=jsondecode(fileread(fullfile(root,'config','tracker_config.json')));
end
function row=makeRow(k,p,sensor)
rvec=p-sensor;r=norm(rvec);az=atan2d(rvec(2),rvec(1));el=atan2d(rvec(3),hypot(rvec(1),rvec(2)));
a=deg2rad(az);e=deg2rad(el);sig=[3 deg2rad(.15) deg2rad(.2)];
J=[cos(e)*cos(a) -r*cos(e)*sin(a) -r*sin(e)*cos(a); ...
 cos(e)*sin(a) r*cos(e)*cos(a) -r*sin(e)*sin(a);sin(e) 0 r*cos(e)];
R=J*diag(sig.^2)*J'+eye(3)*1e-8;row=[k (k-1)*.64 p R(:)' r az el sig];
end
