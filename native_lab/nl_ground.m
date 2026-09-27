function [up,agl,lla]=nl_ground(c,terrain,p)
o=c.origin_lla;
[lat,lon,h]=enu2geodetic(p(:,1),p(:,2),p(:,3),o(1),o(2),o(3),terrain.ellipsoid);
msl=geointerp(terrain.Z,terrain.R,lat,lon);
assert(all(isfinite(msl)),'Point is outside the DEM or over NoData.');
[~,~,up]=geodetic2enu(lat,lon,msl+c.mapping.geoid_offset_m,o(1),o(2),o(3),terrain.ellipsoid);
agl=h-(msl+c.mapping.geoid_offset_m);lla=[lat lon h];
end
