function p=nl_set_agl(c,terrain,p,agl)
% Preserve latitude/longitude; set physical height above the raster surface.
assert(isscalar(agl)&&isfinite(agl)&&agl>=0,'AGL must be nonnegative metres.');
[~,~,lla]=nl_ground(c,terrain,p);H=geointerp(terrain.Z,terrain.R,lla(:,1),lla(:,2));
o=c.origin_lla;
[e,n,u]=geodetic2enu(lla(:,1),lla(:,2),H+c.mapping.geoid_offset_m+agl,o(1),o(2),o(3),terrain.ellipsoid);
p=[e n u];
end
