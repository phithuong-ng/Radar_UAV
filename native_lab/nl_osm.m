function map=nl_osm(c,terrain)
% Reuse offline OSM geometry. Source XY is the legacy local map projection.
% Recover geographic XY with the original MAT/GeoTIFF grid pair, then drape onto
% the CURRENT DEM and transform using Mapping Toolbox; never shift OSM by UAV.
persistent key cached
next=jsonencode(struct('origin',c.origin_lla,'geoid',c.mapping.geoid_offset_m,'dem',terrain.path));
if isequal(key,next),map=cached;return;end
source=load(fullfile(nl_root,'data','osm_v5_on_dem_v8.mat'));
ell=terrain.ellipsoid;
legacy=load(fullfile(nl_root,'data','dem','terrain.mat'),'east','north','origin_lat','origin_lon');
assert(norm(source.origin_lat_lon-[legacy.origin_lat legacy.origin_lon])<1e-8,'OSM and legacy terrain origins differ.');
[~,R]=readgeoraster(fullfile(nl_root,'data','dem','noibai_copernicus_glo30.tif'));
[latGrid,lonGrid]=geographicGrid(R);latAxis=sort(latGrid(:,1));lonAxis=sort(lonGrid(1,:));
assert(numel(legacy.east)==numel(lonAxis)&&numel(legacy.north)==numel(latAxis),'Legacy map grid does not match its geographic raster.');
names={'road','apron','taxiway','runway','building_outlines'};map=struct;
for j=1:numel(names)
 q=source.(names{j});
 lat=interp1(legacy.north,latAxis,q(:,2),'linear','extrap');
 lon=interp1(legacy.east,lonAxis,q(:,1),'linear','extrap');
 H=nan(size(lat));valid=isfinite(lat)&isfinite(lon);
 H(valid)=geointerp(terrain.Z,terrain.R,lat(valid),lon(valid));
 [E,N,U]=geodetic2enu(lat,lon,H+c.mapping.geoid_offset_m,c.origin_lla(1),c.origin_lla(2),c.origin_lla(3),ell);
 map.(names{j})=[E N U+1.5]; % Tiny DISPLAY offset prevents surface z-fighting.
end
key=next;cached=map;
end
