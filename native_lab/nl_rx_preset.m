function c=nl_rx_preset(operation)
% Datasheet-inspired, controllable measurement-level experiment.
if nargin<1,operation='Search';end
c=nl_defaults;c.device=nl_device(c);c.device.profile='RX-R417C';c.device.operation=operation;
duration=(c.frames-1)*c.dt;c.dt=.2;c.frames=401;
for j=1:numel(c.uavs)
 c.uavs(j).arrival_s=c.uavs(j).arrival_s/duration*((c.frames-1)*c.dt);
 c.uavs(j).death_scan=c.frames;c.uavs(j).speed_limit_mps=100;
end
c.radar.mode='Raster';c.radar.scan_technology='Electronic';
c.radar.electronic_azimuth_limits_deg=[-45 45];c.radar.electronic_elevation_limits_deg=[0 60];
c.radar.field_of_view_deg=[30 20]; % EXPERIMENT ASSUMPTION, not vendor beamwidth.
c.radar.range_limits_m=[200 10000];c.radar.reference_range_m=10000;
c.radar.reference_rcs_m2=.01;c.radar.detection_probability=.9; % Pd at 10 km is assumed.
c.radar.range_resolution_m=15;c.radar.azimuth_resolution_deg=6;c.radar.elevation_resolution_deg=4;
c.tracking.max_tracks=500;
% GNN/JPDA use predicted track observability for missed-detection accounting.
c.tracking.confirmation_history=[2 3];c.tracking.deletion_history=[3 5];
nl_validate(c);
end
