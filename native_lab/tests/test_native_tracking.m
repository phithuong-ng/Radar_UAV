function tests=test_native_tracking
tests=functiontests(localfunctions);
end
function testExpandedRegistryAndOriginalCompatibility(t)
old=method_registry('extended');reg=nl_registry;
verifyTrue(t,all(ismember([old.name],[reg.name])));verifyGreaterThan(t,numel(reg),40);
verifyFalse(t,any([reg.tracker]=="JPDA"&endsWith([reg.init],"pf")));
end
function testEveryBuiltInFilterRunsWithNativeAssociator(t)
[c,log]=fixture;reg=nl_registry;reg=reg([reg.init]~="custom");
for j=1:numel(reg)
 fprintf('Expanded tracker %d/%d: %s\n',j,numel(reg),reg(j).name);
 c.method=char(reg(j).name);c.tracking.pf_particles=250;r=nl_track(log,c);
 verifyEqual(t,r.status,'COMPLETE');verifyNotEmpty(t,r.estimates{end});
 verifyLessThan(t,norm(r.estimates{end}(1,:)-log.truth{end}.Position),500);
 verifyNotEmpty(t,r.association{end});
end
end
function testGnnAssignmentAndManagementChoices(t)
[c,log]=fixture;
for assignment={'Jonker-Volgenant','Munkres','Auction','MatchPairs'}
 for logic={'History','Score'}
  c.tracking.gnn_assignment=assignment{1};c.tracking.gnn_logic=logic{1};
  r=nl_track(log,c);verifyEqual(t,r.status,'COMPLETE');verifyNotEmpty(t,r.all_tracks{end});
 end
end
c.method='JPDA_CV_EKF_SPH';c.tracking.jpda_logic='Integrated';r=nl_track(log,c);verifyEqual(t,r.status,'COMPLETE');
c.tracking.jpda_max_events='all';r=nl_track(log,c);verifyEqual(t,r.status,'COMPLETE');
end
function testParticleSeedAndCovarianceIsolation(t)
[c,log]=fixture;c.method='GNN_CV_PF_CART';c.tracking.pf_particles=250;
before=rng;a=nl_track(log,c);after=rng;b=nl_track(log,c);
verifyEqual(t,after,before);verifyEqual(t,a.estimates,b.estimates);
verifyEqual(t,log.detections{1}{1}.MeasurementNoise,[25 2 1;2 36 3;1 3 49]);
end
function testCustomInitializerAndPropertyValidation(t)
[c,log]=fixture;c.method='GNN_CUSTOM_CART';c.tracking.custom_initializer='initcvckf';
r=nl_track(log,c);verifyEqual(t,r.status,'COMPLETE');verifyNotEmpty(t,r.estimates{end});
c.tracking.tracker_properties_json='{"NoSuchProperty":1}';mustFail(t,@()nl_track(log,c));
c.tracking.tracker_properties_json='{"HasCostMatrixInput":true}';mustFail(t,@()nl_track(log,c));
end
function testImmMatrixAndVisibleParameters(t)
c=nl_defaults;c.method='GNN_IMM_EKF_SPH';c.tracking.imm_transition=[.8 .1 .1;.1 .8 .1;.1 .1 .8];
d=objectDetection(0,[100;200;100],'MeasurementNoise',eye(3));f=nl_init_filter(d,'initekfimm',c.tracking);
verifyEqual(t,f.TransitionProbabilities,c.tracking.imm_transition,'AbsTol',1e-12);
verifyEqual(t,f.ModelProbabilities,[.4;.3;.3],'AbsTol',1e-12);
c.method='GNN_CV_EKF_SPH';keys=nl_tracking_keys(c);
verifyFalse(t,any(strcmp(keys,'jpda_max_events')));verifyFalse(t,any(strcmp(keys,'score_confirmation')));
end

function [c,log]=fixture
c=nl_defaults;last=(c.frames-1)*c.dt;c.frames=12;c.dt=10;
for j=1:numel(c.uavs),c.uavs(j).arrival_s=c.uavs(j).arrival_s*110/last;c.uavs(j).death_scan=c.frames;end
c.tracking.max_scan_seconds=120;c.tracking.max_run_seconds=600;
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
