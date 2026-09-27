function preview=nl_preview(c,terrain)
nl_validate(c);if nargin<2,terrain=nl_terrain(c);end
times=(0:c.frames-1)'*c.dt;n=numel(c.uavs);
P=zeros(c.frames,3,n);V=P;A=P;agl=zeros(c.frames,n);traj=cell(n,1);
[~,radarAGL]=nl_ground(c,terrain,c.radar.position_enu_m);
assert(radarAGL>0,'Radar antenna is underground; increase its Up coordinate.');
for j=1:n
 u=c.uavs(j);
 traj{j}=waypointTrajectory('Waypoints',u.waypoints_enu_m,'TimeOfArrival',u.arrival_s(:), ...
  'ReferenceFrame','ENU','SampleRate',1/c.dt);
 [p,~,v,a]=lookupPose(traj{j},times);
 assert(max(vecnorm(v,2,2))<=u.speed_limit_mps+1e-7,'UAV %s exceeds speed limit. Increase duration or shorten route.',u.name);
 assert(all(p>=c.bounds_enu_m(:,1)'&p<=c.bounds_enu_m(:,2)','all'),'UAV %s leaves configured ENU bounds.',u.name);
 [~,agl(:,j)]=nl_ground(c,terrain,p);
 active=u.birth_scan:u.death_scan;
 assert(all(agl(active,j)>=c.mapping.minimum_agl_m),'UAV %s crosses terrain/minimum AGL.',u.name);
 P(:,:,j)=p;V(:,:,j)=v;A(:,:,j)=a;
end
scanPreview=nl_scan_preview(c);
preview=struct('scan',scanPreview,'P',P,'V',V,'A',A,'AGL',agl,'times',times,'trajectories',{traj},'radarAGL',radarAGL);
end
