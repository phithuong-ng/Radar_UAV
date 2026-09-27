function log=nl_import_csv(file,c,updatesFile)
% Explicit interchange schema, NOT a claim to support an unknown radar format.
T=readtable(file,'VariableNamingRule','preserve');
names={'time_s','sensor_id','east_m','north_m','up_m','r_ee','r_nn','r_uu','r_en','r_eu','r_nu'};
assert(all(ismember(names,T.Properties.VariableNames)),'CSV does not match documented ENU schema.');
X=T{:,names};assert(isnumeric(X)&&all(isfinite(X),'all'),'CSV values must be finite numeric data.');
faces=nl_faces(c);assert(all(ismember(X(:,2),[faces.id])),'sensor_id must match an active configured face.');
times=(0:c.frames-1)'*c.dt;
assert(all(X(:,1)>=0&X(:,1)<=times(end)+1e-7),'CSV time outside current session. Set dt/frames first.');
idx=round(X(:,1)/c.dt)+1;assert(all(abs(times(idx)-X(:,1))<1e-7),'Times must align with session dt.');
K=c.frames;log=struct('schema_version',2,'source','real_csv','config',c,'signature',nl_signature(c), ...
 'times',times,'detections',{cell(K,1)},'raw_detections',{cell(K,1)},'truth',{cell(K,1)}, ...
 'valid_update',mod((0:K-1)',c.radar.update_every_steps)==0,'counts',zeros(K,1), ...
 'look_angle',zeros(K,2),'status','COMPLETE','release',version('-release'));
if nargin>=3&&~isempty(updatesFile)
 U=readtable(updatesFile);assert(height(U)==K&&max(abs(U.time_s-times))<1e-7,'Update schedule differs from session.');
 assert(all(ismember(U.valid_update,[0 1])),'valid_update must be 0 or 1.');
 log.valid_update=logical(U.valid_update);
end
assert(all(log.valid_update(idx)),'Measurements fall outside valid radar update times.');
for k=1:K
 rows=find(idx==k);d=cell(numel(rows),1);
 for j=1:numel(rows)
  z=X(rows(j),:);R=[z(6) z(9) z(10);z(9) z(7) z(11);z(10) z(11) z(8)];
  [~,flag]=chol(R);assert(flag==0,'Measurement covariance must be positive definite.');
  d{j}=objectDetection(times(k),z(3:5)','SensorIndex',z(2),'MeasurementNoise',R, ...
   'MeasurementParameters',struct('Frame','Rectangular','HasVelocity',false));
 end
 log.detections{k}=d;log.counts(k)=numel(d);
 log.truth{k}=struct('PlatformID',{},'Position',{},'Velocity',{},'Visible',{});
end
end
