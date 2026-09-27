function tests=test_native_workflow
tests=functiontests(localfunctions);
end
function testArchiveRoundTripAndRelocation(t)
[c,log]=fixture;base=tempname;mkdir(base);
[a,meta]=nl_archive('datasets','Trùng tên',c,log,{},base);
b=nl_archive('datasets','Trùng tên',c,log,{},base);verifyNotEqual(t,a,b);
copy=fullfile(base,'relocated');copyfile(a,copy);
[cc,ll,rr,mm]=nl_open_archive(copy);
verifyEqual(t,meta.id,mm.id);verifyEmpty(t,rr);
verifyEqual(t,ll.signature,nl_signature(cc));verifyEqual(t,ll.detections{1}{1}.Measurement,log.detections{1}{1}.Measurement);
verifyEqual(t,ll.detections{1}{1}.MeasurementNoise,log.detections{1}{1}.MeasurementNoise);
verifyTrue(t,startsWith(cc.mapping.dem_file,copy));
T=nl_library(base);verifyEqual(t,height(T),2);
mkdir(fullfile(base,'datasets','interrupted'));verifyEqual(t,height(nl_library(base)),2);
f=fopen(fullfile(copy,'assets','terrain.tif'),'a');fwrite(f,uint8(42));fclose(f);
mustFail(t,@()nl_open_archive(copy));
end
function testArchiveRefusesChangedSensor(t)
[c,log]=fixture;c.radar.heading_enu_deg=1;mustFail(t,@()nl_archive('datasets','Bad',c,log,{}));
end
function testBatchKeepsFailuresAndSuccessfulResults(t)
[c,log]=fixture;bad=c;bad.method='NO_SUCH_METHOD';
[results,a]=nl_batch(log,{bad,c});verifyEqual(t,{a.status},{'FAILED','COMPLETE'});verifyEqual(t,numel(results),1);
base=tempname;mkdir(base);folder=nl_archive('runs','Partial',c,log,results,base,'fixture',a);
[~,~,r,m]=nl_open_archive(folder);verifyEqual(t,m.status,'PARTIAL');verifyEqual(t,numel(r),1);
verifyTrue(t,isfile(fullfile(folder,'attempts.json')));verifyTrue(t,isfile(fullfile(folder,'summary.csv')));
end
function testBatchCancellationMarksRemainingNotRun(t)
[c,log]=fixture;[r,a]=nl_batch(log,{c,c},@(~,~,~)false);
verifyEmpty(t,r);verifyEqual(t,{a.status},{'CANCELLED','NOT_RUN'});
end
function testLegendHasActualMarkers(t)
c=nl_defaults;f=figure('Visible','off');cleanup=onCleanup(@()close(f)); %#ok<NASGU>
a=axes(f);l=nl_legend(a,c,true,true,true,false,2);
verifyTrue(t,any(strcmp(l.String,c.uavs(1).name)));
verifyNotEmpty(t,findobj(a,'Marker','^'));verifyNotEmpty(t,findobj(a,'Marker','s'));
verifyNotEmpty(t,findobj(a,'Marker','o'));
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
