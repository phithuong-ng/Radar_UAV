function verify_installation(suite)
if nargin<1,suite='extended';end
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'));
if ~strcmp(version('-release'),'2025a'),warning('Target release is R2025a; current is %s.',version('-release'));end
reg=method_registry(suite);required=["objectDetection","matchpairs",unique([reg.init])];
if any([reg.init]=="initekfimm"),required=[required "trackingIMM" "initcaekf" "initctekf" "switchimm"];end
for name=unique([reg.tracker])
 switch name
  case "GNN",required(end+1)="trackerGNN";
  case "JPDA",required(end+1)="trackerJPDA";
  case "TOMHT",required(end+1)="trackerTOMHT";
  case "PHD",required=[required "trackerPHD" "trackingSensorConfiguration"];
 end
end
missing=strings(0);
for name=unique(required),if isempty(which(char(name))),missing(end+1)=name;end;end %#ok<AGROW>
assert(isempty(missing),'Missing MATLAB/Sensor Fusion APIs: %s',strjoin(missing,', '));
assert(usejava('jvm'),'This package uses the MATLAB JVM for SHA-256 result identity.');
fprintf('APIs found for %d methods. This check is not an execution test.\n',numel(reg));
end
