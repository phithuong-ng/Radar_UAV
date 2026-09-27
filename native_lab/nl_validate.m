function nl_validate(c)
% Validate before creating System objects. Never eval text from the editor.
assert(c.schema_version==2,'Unsupported session schema.');
validateattributes(c.seed,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1});
validateattributes(c.dt,{'numeric'},{'scalar','finite','positive'});
validateattributes(c.frames,{'numeric'},{'scalar','integer','>=',2,'<=',20000});
validateattributes(c.origin_lla,{'numeric'},{'numel',3,'finite'});
assert(abs(c.origin_lla(1))<90&&abs(c.origin_lla(2))<=180,'Invalid latitude/longitude.');
validateattributes(c.bounds_enu_m,{'numeric'},{'size',[3 2],'finite'});
assert(all(diff(c.bounds_enu_m,1,2)>0),'Bounds must increase.');
assert(isfinite(c.mapping.geoid_offset_m),'Geoid offset must be finite.');
assert(c.mapping.effective_earth_factor>0&&isfinite(c.mapping.effective_earth_factor),'Invalid effective Earth factor.');
assert(c.mapping.minimum_agl_m>=0,'Minimum AGL cannot be negative.');
r=c.radar;validateattributes(r.position_enu_m,{'numeric'},{'numel',3,'finite'});
validateattributes(r.field_of_view_deg,{'numeric'},{'numel',2,'finite','positive','<=',180});
assert(numel(r.range_limits_m)==2&&r.range_limits_m(1)>=0&&diff(r.range_limits_m)>0,'Invalid radar range limits.');
assert(r.reference_range_m>0&&r.reference_rcs_m2>0&&r.frequency_hz>0,'Radar reference quantities must be positive.');
assert(r.detection_probability>0&&r.detection_probability<1,'Pd must be between 0 and 1, exclusive.');
assert(c.clutter.pfa>0&&c.clutter.pfa<1,'Pfa must be between 0 and 1, exclusive.');
assert(all([r.range_resolution_m r.azimuth_resolution_deg r.elevation_resolution_deg]>0),'Resolution must be positive.');
assert(all(isfinite([r.heading_enu_deg r.tilt_deg r.roll_deg]))&&abs(r.tilt_deg)<=90,'Invalid mounting angles.');
assert(any(strcmp(r.mode,{'No scanning','Rotator','Sector','Raster'})),'Unsupported scan mode.');
assert(any(strcmp(r.scan_technology,{'Mechanical','Electronic','Mechanical and electronic'})),'Invalid ScanMode technology.');
assert(r.elevation_scan_rate_deg_s>0,'Elevation scan rate must be positive.');
assert(numel(r.electronic_azimuth_limits_deg)==2&&diff(r.electronic_azimuth_limits_deg)>0&&all(abs(r.electronic_azimuth_limits_deg)<=90),'Invalid electronic azimuth limits.');
assert(numel(r.electronic_elevation_limits_deg)==2&&diff(r.electronic_elevation_limits_deg)>0&&all(abs(r.electronic_elevation_limits_deg)<=90),'Invalid electronic elevation limits.');
validateattributes(r.update_every_steps,{'numeric'},{'scalar','integer','>=',1});
assert(r.scan_rate_deg_s>0,'Scan rate must be positive.');
assert(numel(r.azimuth_scan_limits_deg)==2&&diff(r.azimuth_scan_limits_deg)>0,'Invalid azimuth scan limits.');
assert(numel(r.elevation_scan_limits_deg)==2&&diff(r.elevation_scan_limits_deg)>0,'Invalid elevation scan limits.');
assert(all(isfinite([r.range_bias_fraction r.azimuth_bias_fraction r.elevation_bias_fraction])),'Bias must be finite.');
s=c.clutter.scatterers;
assert(isempty(s)||(size(s,2)==4&&all(isfinite(s),'all')&&all(s(:,3)>0)&&all(s(:,4)>0)), ...
 'Scatterers use [East North AGL RCS_m2]; AGL and RCS must be positive.');
assert(~isempty(c.uavs),'At least one UAV is required.');names=string({c.uavs.name});
assert(numel(unique(names))==numel(names)&&all(strlength(names)>0),'UAV names must be unique.');
for j=1:numel(c.uavs)
 u=c.uavs(j);assert(isvarname(char(u.name)),'UAV name must be a MATLAB identifier.');
 p=u.waypoints_enu_m;t=u.arrival_s(:);
 assert(size(p,2)==3&&size(p,1)>=2&&size(p,1)==numel(t)&&all(isfinite(p),'all'),'Invalid waypoints.');
 assert(all(isfinite(t))&&t(1)==0&&all(diff(t)>0),'Arrival times must start at 0 and increase.');
 assert(abs(t(end)-(c.frames-1)*c.dt)<1e-7,'Last waypoint time must equal (frames-1)*dt.');
 assert(u.rcs_m2>0&&u.speed_limit_mps>0,'RCS and speed limit must be positive.');
 assert(u.birth_scan>=1&&u.death_scan<=c.frames&&u.birth_scan<=u.death_scan&& ...
  mod(u.birth_scan,1)==0&&mod(u.death_scan,1)==0,'Invalid birth/death scan.');
end
d=nl_device(c);
assert(any(strcmp(d.profile,{'Generic','RX-R417C'})),'Choose device profile Generic or RX-R417C.');
assert(any(strcmp(d.operation,{'Search','Focus'})),'Choose operation Search or Focus.');
validateattributes(d.face_offsets_deg,{'numeric'},{'numel',4,'finite'});
assert(numel(d.faces_enabled)==4&&all(ismember(d.faces_enabled,[0 1]))&&any(d.faces_enabled),'Enable at least one of four faces.');
validateattributes(d.focus_face,{'numeric'},{'scalar','integer','>=',1,'<=',4});
for limits={d.focus_azimuth_deg,d.focus_elevation_deg}
 v=limits{1};assert(numel(v)==2&&all(isfinite(v))&&diff(v)>0&&all(abs(v)<=89.9),'Invalid focus sector.');
end
assert(isscalar(d.scan_aware_tracking)&&ismember(d.scan_aware_tracking,[0 1]),'Scan-aware tracking must be true/false.');
if strcmp(d.profile,'RX-R417C')
 assert(strcmp(r.mode,'Raster')&&strcmp(r.scan_technology,'Electronic'),'RX profile requires Raster + Electronic. Use Generic for other scan types.');
 if strcmp(d.operation,'Focus'),assert(d.faces_enabled(d.focus_face),'Enable the selected focus face.');end
 assert(all(abs(r.electronic_azimuth_limits_deg)<89.9)&&all(abs(r.electronic_elevation_limits_deg)<89.9),'Keep RX sector edges inside +/-89.9 degrees.');
 faces=nl_faces(c);assert(max([faces.looks_per_cycle])<=2000,'Over 2000 looks per cycle: enlarge the beam or narrow the sector.');
end
reg=nl_registry('extended');assert(any([reg.name]==string(c.method)),'Unknown tracker method.');
t=nl_tracking_defaults(c.tracking);
nl_validate_tracking(t,c.method);
assert(t.measurement_variance_scale>0&&t.assignment_threshold>0&&t.coarse_gate_multiplier>=1,'Invalid tracker R/gate.');
assert(t.pd_assumed>0&&t.pd_assumed<1&&t.clutter_expected_per_update>=0,'Invalid tracker Pd/clutter prior.');
for x={t.confirmation_history,t.deletion_history}
 v=x{1};assert(numel(v)==2&&all(v>=1)&&all(mod(v,1)==0)&&v(1)<=v(2),'History thresholds use [M N], 1 <= M <= N.');
end
assert(t.metric_cutoff_m>0&&t.max_run_seconds>0&&t.max_scan_seconds>0,'Invalid metric/time limits.');
if isfield(t,'max_initialization_seconds')
 validateattributes(t.max_initialization_seconds,{'numeric'},{'scalar','finite','positive'});
end
end
