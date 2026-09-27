function [c,log,results,meta]=nl_open_archive(path)
if isfile(path),path=fileparts(path);end
manifest=fullfile(path,'archive.json');assert(isfile(manifest),'Not a published dataset/run archive.');
meta=jsondecode(fileread(manifest));assert(meta.schema_version==1,'Unsupported archive schema.');
assert(any(strcmp(meta.status,{'COMPLETE','PARTIAL'})),'Archive is incomplete.');
file=fullfile(path,'native_session.mat');dem=fullfile(path,'assets','terrain.tif');
assert(isfile(file)&&strcmp(file_sha256(file),meta.mat_sha256),'Dataset MAT integrity check failed.');
assert(isfile(dem)&&strcmp(file_sha256(dem),meta.dem_sha256),'DEM integrity check failed.');
s=load(file,'c','log','results');c=s.c;log=s.log;results=s.results;
assert(strcmp(log.status,'COMPLETE')&&strcmp(log.signature,nl_signature(c)),'Stored configuration/observations are inconsistent.');
c.mapping.dem_file=dem;log.config=c;log.signature=nl_signature(c);nl_validate(c);
end
