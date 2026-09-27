function visible=nl_los(c,terrain,p)
[~,~,target]=nl_ground(c,terrain,p);[~,~,radar]=nl_ground(c,terrain,c.radar.position_enu_m);
n=size(p,1);N=c.mapping.geoid_offset_m;R=6371000;
visible=los2(terrain.Z,terrain.R,repmat(radar(1),n,1),repmat(radar(2),n,1), ...
 target(:,1),target(:,2),radar(3)-N,target(:,3)-N,'MSL','MSL',R,R*c.mapping.effective_earth_factor);
visible=logical(visible(:));
end
