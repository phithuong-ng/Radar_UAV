function c=nl_defaults()
% Reuse the project waypoints, radar parameters, DEM and tracker configuration.
old=jsondecode(fileread(fullfile(nl_root,'training','config','default.json')));
t=load(fullfile(nl_root,'data','dem','terrain.mat'),'origin_height_msl');
c=struct('schema_version',2,'seed',old.seed,'dt',old.dt,'frames',old.frames, ...
 'origin_lla',[old.origin_lla(1:2)' t.origin_height_msl], ...
 'bounds_enu_m',old.bounds_enu_m);
c.origin_lla=reshape(c.origin_lla,1,3);
c.mapping=struct('dem_file','data/dem/noibai_copernicus_glo30.tif', ...
 'geoid_offset_m',0,'datum_note','DEMO: constant geoid offset N=0, not surveyed', ...
 'terrain_los',true,'effective_earth_factor',4/3,'minimum_agl_m',1,'viewshed_target_agl_m',100);
c.radar=old.radar;
c.radar.position_enu_m=reshape(c.radar.position_enu_m,1,3);
c.radar.field_of_view_deg=reshape(c.radar.field_of_view_deg,1,2);
c.radar.range_limits_m=reshape(c.radar.range_limits_m,1,2);
c.radar.heading_enu_deg=0;c.radar.tilt_deg=0;c.radar.roll_deg=0;
c.radar.mode='No scanning';c.radar.update_every_steps=1;c.radar.scan_rate_deg_s=30;
c.radar.scan_technology='Mechanical';c.radar.elevation_scan_rate_deg_s=10;
c.radar.electronic_azimuth_limits_deg=[-45 45];c.radar.electronic_elevation_limits_deg=[-10 20];
c.radar.azimuth_scan_limits_deg=[-60 60];c.radar.elevation_scan_limits_deg=[-10 20];
c.radar.noise=true;c.radar.range_bias_fraction=0;c.radar.azimuth_bias_fraction=0;
c.radar.elevation_bias_fraction=0;
c.clutter=struct('false_alarms',false,'pfa',1e-6,'scatterers_enabled',false, ...
 'scatterers',[1200 -650 20 .02;1700 -350 25 .05]);
c.radar=rmfield(c.radar,{'false_alarms','false_alarm_probability'});
c.uavs=old.uavs;
for j=1:numel(c.uavs)
 c.uavs(j).arrival_s=reshape(c.uavs(j).arrival_s,[],1);
end
c.method='GNN_CV_EKF_SPH';
c.tracking=jsondecode(fileread(fullfile(nl_root,'config','tracker_config.json')));
c.tracking.gnn_logic='History';c.tracking.jpda_logic='History';
c.tracking.confirmation_history=[2 3];c.tracking.deletion_history=[3 5];
c.tracking.temporal_support.enabled=false;
c.tracking.clutter_expected_per_update=2;
c.tracking.max_initialization_seconds=120;
c.iq=struct('sample_rate_hz',2e6,'prf_hz',1000,'pulse_width_s',20e-6, ...
 'bandwidth_hz',1e6,'pulses',16,'array_elements',4,'gamma_db',-20, ...
 'height_m',30,'speed_mps',0,'depression_deg',5,'max_range_m',5000, ...
 'azimuth_span_deg',60,'patch_azimuth_deg',5,'transmit_erp_w',1000, ...
 'cfar_pfa',1e-4,'steer_deg',0);
c.tracking=nl_tracking_defaults(c.tracking);
c.device=nl_device(c);
nl_validate(c);
end
