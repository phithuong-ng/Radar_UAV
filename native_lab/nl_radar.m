function [sensor,scene]=nl_radar(c,scattererCount,sensorIndex)
if nargin<3,sensorIndex=1;end
% Parent body frame is a stationary NED frame at scenario origin.
% Body Cartesian output therefore includes the radar mounting translation.
B=[0 1 0;1 0 0;0 0 -1];r=c.radar;
scene=radarScenario('UpdateRate',1/c.dt,'StopTime',(c.frames-1)*c.dt);
rcs=[c.uavs.rcs_m2];
if scattererCount>0,rcs=[rcs c.clutter.scatterers(:,4)'];end
for j=1:numel(rcs)
 platform(scene,'ClassID',1,'Signatures',{rcsSignature('Pattern',10*log10(rcs(j))*ones(2,2))});
end
sensor=radarDataGenerator(sensorIndex,r.mode,'UpdateRate',1/(c.dt*r.update_every_steps), ...
 'MountingLocation',(B*r.position_enu_m(:))','MountingAngles',[90-r.heading_enu_deg r.tilt_deg r.roll_deg], ...
 'DetectionCoordinates','Body','HasElevation',true,'HasRangeRate',false, ...
 'HasNoise',r.noise,'HasFalseAlarms',c.clutter.false_alarms,'HasOcclusion',false, ...
 'TargetReportFormat','Detections','FieldOfView',r.field_of_view_deg(:), ...
 'RangeLimits',reshape(r.range_limits_m,1,2),'ReferenceRange',r.reference_range_m, ...
 'ReferenceRCS',10*log10(r.reference_rcs_m2),'DetectionProbability',r.detection_probability, ...
 'FalseAlarmRate',c.clutter.pfa,'CenterFrequency',r.frequency_hz, ...
 'RangeResolution',r.range_resolution_m,'AzimuthResolution',r.azimuth_resolution_deg, ...
 'ElevationResolution',r.elevation_resolution_deg,'Profiles',platformProfiles(scene), ...
 'RangeBiasFraction',r.range_bias_fraction,'AzimuthBiasFraction',r.azimuth_bias_fraction, ...
 'ElevationBiasFraction',r.elevation_bias_fraction);
if ~strcmp(r.mode,'No scanning')
 sensor.ScanMode=r.scan_technology;
 if contains(sensor.ScanMode,'Mechanical','IgnoreCase',true)
  sensor.MaxAzimuthScanRate=r.scan_rate_deg_s;
  sensor.MaxElevationScanRate=r.elevation_scan_rate_deg_s;
  if ~strcmp(r.mode,'Rotator')
   sensor.MechanicalAzimuthLimits=reshape(r.azimuth_scan_limits_deg,1,2);
   sensor.MechanicalElevationLimits=reshape(r.elevation_scan_limits_deg,1,2);
  end
 end
 if contains(sensor.ScanMode,'Electronic','IgnoreCase',true)
  sensor.ElectronicAzimuthLimits=reshape(r.electronic_azimuth_limits_deg,1,2);
  sensor.ElectronicElevationLimits=reshape(r.electronic_elevation_limits_deg,1,2);
  % R2025a HasScanLoss is active ONLY for ScanMode='Custom', not Electronic.
  % This UI does not implement Custom scanning; do not set that property.
 end
end
end
