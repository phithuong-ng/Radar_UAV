function [P,V,A,Q,trajectories,t]=training_trajectory(c)
training_validate(c);t=(0:c.frames-1)'*c.dt;n=numel(c.uavs);
P=zeros(c.frames,3,n);V=P;A=P;Q=cell(n,1);trajectories=cell(n,1);
for j=1:n
 u=c.uavs(j);
 tr=waypointTrajectory('Waypoints',u.waypoints_enu_m,'TimeOfArrival',u.arrival_s(:), ...
 'SampleRate',1/c.dt,'ReferenceFrame','ENU');
 [p,q,v,a]=lookupPose(tr,t);
 % Wind is an explicit constant kinematic drift, not a flight controller model.
 p=p+t*c.environment.wind_enu_mps;v=v+c.environment.wind_enu_mps;
 assert(all(p>=c.bounds_enu_m(:,1)'&p<=c.bounds_enu_m(:,2)','all'),'Interpolated path/wind drift outside bounds.');
 assert(max(vecnorm(v,2,2))<=u.speed_limit_mps+1e-7,'Interpolated UAV speed exceeds limit. Increase arrival times.');
 P(:,:,j)=p;V(:,:,j)=v;A(:,:,j)=a;Q{j}=q;trajectories{j}=tr;
end
end
