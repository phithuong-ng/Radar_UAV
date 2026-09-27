function T=NATIVE_LAB_CHECK()
root=fileparts(mfilename('fullpath'));addpath(fullfile(root,'native_lab'),fullfile(root,'src'));
names=["waypointTrajectory";"uavScenario";"uavPlatform";"readgeoraster"; ...
 "geointerp";"geodetic2enu";"enu2geodetic";"los2";"viewshed"; ...
 "radarScenario";"radarDataGenerator";"rcsSignature";"trackerGNN"; ...
 "trackerJPDA";"trackerTOMHT";"trackerPHD";"trackOSPAMetric";"trackGOSPAMetric"; ...
 "constantGammaClutter";"phased.ULA";"phased.LinearFMWaveform";"phased.MatchedFilter";"phased.CFARDetector"];
found=arrayfun(@(s)~isempty(which(char(s))),names);
required=[true(18,1);false(5,1)];
reg=nl_registry;extra=unique([reg.init]);extra=extra(~ismember(extra,["custom","initekfimm"]));
names=[names;extra(:)];required=[required;false(numel(extra),1)];
found=[found;arrayfun(@(s)~isempty(which(char(s))),extra(:))];
T=table(names,required,found);disp(T);
fprintf('Release %s. Presence only, NOT execution/license verification. Run NATIVE_LAB_TESTS.\n',version('-release'));
end
