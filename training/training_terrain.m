function [ground,los]=training_terrain(c,p)
d=load(fullfile(training_root,'data','dem','terrain.mat'));
assert(abs(c.origin_lla(1)-d.origin_lat)<1e-8&&abs(c.origin_lla(2)-d.origin_lon)<1e-8, ...
 'Bundled DEM has a fixed origin; reproject terrain before changing origin.');
F=griddedInterpolant({double(d.north(:)),double(d.east(:))},double(d.terrain),'linear','none');
ground=F(p(:,2),p(:,1));assert(all(isfinite(ground)),'Position outside DEM.');
s=c.radar.position_enu_m;gs=F(s(2),s(1));
assert(isfinite(gs)&&s(3)>gs,'Radar must be above terrain and inside DEM.');
los=true(size(p,1),1);f=linspace(.01,.99,c.environment.ray_samples)';
for k=1:size(p,1)
 ray=s+f*(p(k,:)-s);h=F(ray(:,2),ray(:,1));
 assert(all(isfinite(h)),'Line of sight leaves DEM.');
 los(k)=all(ray(:,3)>h+c.environment.clearance_m);
end
end
