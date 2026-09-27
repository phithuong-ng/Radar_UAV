function [folder,meta]=nl_archive(kind,name,c,log,results,storage,sourceID,attempts)
% Create an immutable self-contained dataset or run. Publish metadata LAST.
if nargin<6||isempty(storage),storage=nl_storage;end
if nargin<7,sourceID='';end
if nargin<8,attempts=struct('method',{},'status',{},'message',{});end
assert(any(strcmp(kind,{'datasets','runs'})),'Archive type must be datasets or runs.');
name=strtrim(char(string(name)));assert(~isempty(name)&&numel(name)<=120,'Name must contain 1..120 characters.');
assert(~isempty(log)&&strcmp(log.status,'COMPLETE'),'A complete observation dataset is required.');
assert(strcmp(log.signature,nl_signature(c)),'Configuration differs from observations. Generate a new dataset.');
if strcmp(kind,'datasets'),assert(isempty(results),'Datasets contain observations; save tracking separately as a run.');end
terrainPath=char(c.mapping.dem_file);if ~isfile(terrainPath),terrainPath=fullfile(nl_root,terrainPath);end
assert(isfile(terrainPath),'DEM is missing.');demHash=file_sha256(terrainPath);
if isfield(log,'dem_sha256'),assert(strcmp(demHash,log.dem_sha256),'DEM changed after the dataset was generated.');end
parent=fullfile(storage,kind);if ~isfolder(parent),mkdir(parent);end
[~,token]=fileparts(tempname(parent));id=[char(datetime('now','Format','yyyyMMdd_HHmmss')) '_' token];
folder=fullfile(parent,id);
% Store relative asset paths. Loader restores absolute paths and recomputes
% only the location-dependent config signature; observations remain unchanged.
c.mapping.dem_file='assets/terrain.tif';log.config=c;log.signature=nl_signature(c);log.dem_sha256=demHash;
nl_export(c,log,results,folder);
mkdir(fullfile(folder,'assets'));copyfile(terrainPath,fullfile(folder,'assets','terrain.tif'));
writeText(fullfile(folder,'replay.m'),sprintf(['%% Run START_NATIVE_LAB once, or add project/native_lab and project/src.\n' ...
 'here=fileparts(mfilename(''fullpath''));\n' ...
 '[c,log,results,meta]=nl_open_archive(here);\n' ...
 'result=nl_track(log,c); %% exact stored observations, no regeneration\n']));
script=nl_commands(c);
script=strrep(script,'nl_validate(c);',sprintf('c.mapping.dem_file=fullfile(fileparts(mfilename(''fullpath'')),''assets'',''terrain.tif'');\nnl_validate(c);'));
writeText(fullfile(folder,'configure_session.m'),script);
summary=nl_summary(log,results);writetable(summary,fullfile(folder,'summary.csv'));
if ~isempty(attempts),writeText(fullfile(folder,'attempts.json'),jsonencode(attempts,'PrettyPrint',true));end
meta=struct('schema_version',1,'id',id,'kind',kind,'name',name,'created_utc', ...
 char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd HH:mm:ss')), ...
 'status','COMPLETE','source_dataset_id',sourceID,'source',log.source,'seed',c.seed, ...
 'frames',numel(log.times),'reports',sum(cellfun(@numel,log.detections)), ...
 'methods',{cellfun(@(r)r.method,results,'UniformOutput',false)},'attempts',attempts, ...
 'mat_sha256',file_sha256(fullfile(folder,'native_session.mat')),'dem_sha256',demHash, ...
 'release',version('-release'));
if ~isempty(attempts)&&any(~strcmp({attempts.status},'COMPLETE')),meta.status='PARTIAL';end
writeText(fullfile(folder,'archive.json'),jsonencode(meta,'PrettyPrint',true));
fprintf('%s: %s\n',name,folder);
end
function writeText(path,value)
f=fopen(path,'w','n','UTF-8');assert(f>=0,'Cannot create archive file.');cl=onCleanup(@()fclose(f));fprintf(f,'%s',value); %#ok<NASGU>
end
