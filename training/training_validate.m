function training_validate(c)
% Fail before simulation; all project-facing positions are ENU meters.
validateattributes(c.seed,{'numeric'},{'scalar','integer','nonnegative','finite'});
validateattributes(c.frames,{'numeric'},{'scalar','integer','>=',2});
validateattributes(c.dt,{'numeric'},{'scalar','real','finite','positive'});
assert(c.schema_version==1,'Unsupported training config schema.');
validateattributes(c.origin_lla,{'numeric'},{'size',[1 3],'finite','real'});
assert(abs(c.origin_lla(1))<=90 && abs(c.origin_lla(2))<=180,'Invalid origin.');
validateattributes(c.bounds_enu_m,{'numeric'},{'size',[3 2],'finite','real'});
assert(all(diff(c.bounds_enu_m,1,2)>0),'Bounds must increase.');
r=c.radar;s=c.signal;e=c.environment;
validateattributes(r.position_enu_m,{'numeric'},{'size',[1 3],'finite','real'});
positive=[r.frequency_hz r.reference_range_m r.reference_rcs_m2 r.range_resolution_m ...
 r.azimuth_resolution_deg r.elevation_resolution_deg s.sample_rate_hz s.bandwidth_hz s.pulse_width_s s.prf_hz s.target_range_m];
assert(all(isfinite(positive)&positive>0),'Physical parameters must be positive and finite.');
assert(r.detection_probability>0 && r.detection_probability<1,'Pd must be in (0,1).');
assert(r.false_alarm_probability>0 && r.false_alarm_probability<1,'Pfa must be in (0,1).');
validateattributes(r.field_of_view_deg,{'numeric'},{'size',[1 2],'finite','positive'});
assert(r.field_of_view_deg(1)<=180 && r.field_of_view_deg(2)<=180,'No-scanning FOV must be <=180 deg.');
validateattributes(r.range_limits_m,{'numeric'},{'size',[1 2],'finite','nonnegative'});
assert(diff(r.range_limits_m)>0,'Invalid radar range limits.');
assert(s.bandwidth_hz<s.sample_rate_hz,'Waveform bandwidth must be below sample rate.');
assert(s.pulse_width_s*s.prf_hz<1,'Pulse width must be smaller than PRI.');
assert(abs(s.sample_rate_hz/s.prf_hz-round(s.sample_rate_hz/s.prf_hz))<1e-7,'Fs/PRF must be integer.');
assert(2*s.target_range_m/299792458+s.pulse_width_s<1/s.prf_hz,'Echo must fit inside PRI.');
assert(abs(s.target_radial_velocity_mps)<299792458/r.frequency_hz*s.prf_hz/4,'Doppler is aliased: reduce velocity or increase PRF.');
validateattributes(s.pulses,{'numeric'},{'scalar','integer','>=',4,'<=',512});
validateattributes(s.array_elements,{'numeric'},{'scalar','integer','>=',2,'<=',256});
assert(s.sample_rate_hz/s.prf_hz*s.pulses<=2e7,'Signal cube exceeds training memory limit.');
validateattributes(s.snr_db,{'numeric'},{'scalar','finite','real'});
validateattributes(s.steer_deg,{'numeric'},{'scalar','finite','>=',-80,'<=',80});
validateattributes(e.wind_enu_mps,{'numeric'},{'size',[1 3],'finite','real'});
validateattributes(e.ray_samples,{'numeric'},{'scalar','integer','>=',4,'<=',4096});
validateattributes(e.clearance_m,{'numeric'},{'scalar','finite','nonnegative'});
assert(islogical(e.terrain_los)&&isscalar(e.terrain_los),'terrain_los must be JSON true/false.');
assert(islogical(r.false_alarms)&&isscalar(r.false_alarms),'false_alarms must be JSON true/false.');
assert(~isempty(c.uavs),'At least one UAV is required.');
assert(numel(unique(string({c.uavs.name})))==numel(c.uavs),'UAV names must be unique.');
for j=1:numel(c.uavs)
 u=c.uavs(j);p=u.waypoints_enu_m;t=u.arrival_s(:);
 validateattributes(p,{'numeric'},{'2d','ncols',3,'finite','real'});
 assert(size(p,1)>=2&&numel(t)==size(p,1)&&all(isfinite(t))&&all(diff(t)>0),'Invalid waypoints/times.');
 assert(t(1)==0&&t(end)>=(c.frames-1)*c.dt-1e-9,'Waypoints must cover entire simulation.');
 assert(all(p>=c.bounds_enu_m(:,1)'&p<=c.bounds_enu_m(:,2)','all'),'Waypoint outside bounds.');
 validateattributes(u.rcs_m2,{'numeric'},{'scalar','positive','finite'});
 validateattributes(u.speed_limit_mps,{'numeric'},{'scalar','positive','finite'});
 validateattributes([u.birth_scan u.death_scan],{'numeric'},{'integer','>=',1,'<=',c.frames});
 assert(u.birth_scan<=u.death_scan,'Invalid UAV life interval.');
end
validateattributes(c.monte_carlo.trials,{'numeric'},{'scalar','integer','>=',2,'<=',10000});
validateattributes(c.monte_carlo.sigma_m,{'numeric'},{'scalar','positive','finite'});
assert(islogical(c.monte_carlo.use_parallel)&&isscalar(c.monte_carlo.use_parallel),'use_parallel must be logical.');
validateattributes(c.optimization.sigma_bounds_m,{'numeric'},{'size',[1 2],'positive','finite'});
assert(diff(c.optimization.sigma_bounds_m)>0,'Invalid optimization bounds.');
validateattributes(c.optimization.sigma_assumed_m,{'numeric'},{'scalar','positive','finite'});
validateattributes([c.navigation.horizontal_accuracy_m c.navigation.vertical_accuracy_m c.navigation.velocity_accuracy_mps],{'numeric'},{'positive','finite'});
validateattributes([c.simulink.time_constant_s c.simulink.stop_time_s],{'numeric'},{'positive','finite'});
validateattributes(c.simulink.command_altitude_m,{'numeric'},{'scalar','finite'});
end
