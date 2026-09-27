function terrain=nl_terrain(c)
% Read the actual GeoTIFF. The legacy terrain.mat is not substituted silently.
path=char(c.mapping.dem_file);if ~isfile(path),path=fullfile(nl_root,path);end
assert(isfile(path),'DEM not found: %s',path);
info=georasterinfo(path);[Z,R]=readgeoraster(path,'OutputType','double');
assert(isa(R,'map.rasterref.GeographicCellsReference')||isa(R,'map.rasterref.GeographicPostingsReference'), ...
 'This importer requires a geographic WGS84 raster in degrees; reproject projected DEMs first.');
assert(ismatrix(Z),'Use a single-band elevation raster in metres.');
% Reject geographic CRSs whose ellipsoid is not WGS84 instead of mislabelling them.
if ~isempty(info.CoordinateReferenceSystem)
 crs=info.CoordinateReferenceSystem;
 assert(isa(crs,'geocrs')&&any(contains(upper(string(crs.Name)),["WGS 84","WGS84"])),'DEM CRS must be WGS84.');
end
missing=info.MissingDataIndicator;
for k=1:numel(missing),Z(Z==missing(k))=NaN;end
[lat,lon]=geographicGrid(R);ell=wgs84Ellipsoid('meter');o=c.origin_lla;
[E,N,U]=geodetic2enu(lat,lon,Z+c.mapping.geoid_offset_m,o(1),o(2),o(3),ell);
terrain=struct('Z',Z,'R',R,'E',E,'N',N,'U',U,'path',path,'ellipsoid',ell);
assert(isfinite(geointerp(Z,R,o(1),o(2))),'Coordinate origin lies outside valid DEM.');
end
