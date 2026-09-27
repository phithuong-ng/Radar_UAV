function c=nl_rebase(c,newOrigin)
% Re-express all point coordinates while preserving their geodetic location.
old=c.origin_lla;ell=wgs84Ellipsoid('meter');
c.radar.position_enu_m=convert(c.radar.position_enu_m);
for j=1:numel(c.uavs),c.uavs(j).waypoints_enu_m=convert(c.uavs(j).waypoints_enu_m);end
% Scatterers are specified by horizontal EN and AGL: preserve the ground location.
terrain=nl_terrain(c);s=c.clutter.scatterers;
if ~isempty(s)
 p=[s(:,1:2) zeros(size(s,1),1)];[g,~,~]=nl_ground(c,terrain,p);p(:,3)=g;
 p=convert(p);s(:,1:2)=p(:,1:2);c.clutter.scatterers=s;
end
[x,y,z]=ndgrid(c.bounds_enu_m(1,:),c.bounds_enu_m(2,:),c.bounds_enu_m(3,:));
p=convert([x(:) y(:) z(:)]);c.bounds_enu_m=[min(p,[],1)' max(p,[],1)'];
% Preserve the complete sensor orientation, including roll, under frame change.
axesNew=convert([0 0 0;eye(3)]);T=(axesNew(2:4,:)-axesNew(1,:))';
[left,~,right]=svd(T);T=left*right';B=[0 1 0;1 0 0;0 0 -1];
y=90-c.radar.heading_enu_deg;p=c.radar.tilt_deg;r=c.radar.roll_deg;
M=[cosd(y) -sind(y) 0;sind(y) cosd(y) 0;0 0 1]* ...
 [cosd(p) 0 sind(p);0 1 0;-sind(p) 0 cosd(p)]*[1 0 0;0 cosd(r) -sind(r);0 sind(r) cosd(r)];
M=B*T*B*M;horizontal=hypot(M(1,1),M(2,1));
if horizontal>1e-10,y=atan2d(M(2,1),M(1,1));r=atan2d(M(3,2),M(3,3));
else,y=atan2d(-M(1,2),M(2,2));r=0;end
c.radar.heading_enu_deg=90-y;c.radar.tilt_deg=atan2d(-M(3,1),horizontal);c.radar.roll_deg=r;
c.origin_lla=reshape(newOrigin,1,3);
nl_validate(c);
 function p=convert(p)
  [lat,lon,h]=enu2geodetic(p(:,1),p(:,2),p(:,3),old(1),old(2),old(3),ell);
  [e,n,u]=geodetic2enu(lat,lon,h,newOrigin(1),newOrigin(2),newOrigin(3),ell);p=[e n u];
 end
end
