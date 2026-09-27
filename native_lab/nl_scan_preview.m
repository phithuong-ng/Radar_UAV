function scan=nl_scan_preview(c)
% Replay the PUBLIC native sensor API with no targets to get exact look angles.
% Full session cached; no assumption about the native order on later sweeps.
persistent key cached
d=nl_device(c);scan=[];if strcmp(d.profile,'Generic'),return;end
faces=nl_faces(c);next=jsonencode(struct('faces',faces,'dt',c.dt,'frames',c.frames));
if isequal(next,key),scan=cached;return;end
old=rng;cleanup=onCleanup(@()rng(old)); %#ok<NASGU>
cc=c;cc.clutter.false_alarms=false;cc.radar.noise=false;
[sensors,scenes]=nl_sensor_bank(cc,0); %#ok<ASGLU>
L=c.frames;N=numel(faces);
look=zeros(L,2,N);done=false(L,N);
emptyPoses=struct('PlatformID',{},'Position',{},'Velocity',{});
for k=1:L
 % Enabled faces share the same local scan grid; mount orientation does not
 % change that grid. Focus has one face. Use one native sensor for the preview.
 [~,~,cfg]=sensors{1}(emptyPoses,(k-1)*c.dt);
 for j=1:N,look(k,:,j)=reshape(sensors{1}.LookAngle,1,2);done(k,j)=cfg.IsScanDone&&cfg.IsValidTime;end
end
scan=struct('look',look,'scan_done',done,'faces',faces, ...
 'cycle_s',max([faces.looks_per_cycle])*c.dt*c.radar.update_every_steps);
key=next;cached=scan;
end
