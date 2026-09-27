function dets=make_detections(rows,frame,sensor,varianceScale)
if nargin<4,varianceScale=1;end
rows=double(rows);sensor=double(sensor(:));assert(numel(sensor)==3 && all(isfinite(sensor)));
dets=cell(size(rows,1),1);
for j=1:size(rows,1)
 if string(frame)=="spherical"
  z=rows(j,[16 17 15])';
  R=diag([rad2deg(rows(j,19)),rad2deg(rows(j,20)),rows(j,18)].^2);
  params=struct('Frame','Spherical','HasAzimuth',true,'HasElevation',true, ...
   'HasRange',true,'HasVelocity',false,'OriginPosition',sensor,'OriginVelocity',zeros(3,1), ...
   'Orientation',eye(3),'IsParentToChild',false);
 else
  z=rows(j,3:5)';R=reshape(rows(j,6:14),3,3);
  params=struct('Frame','Rectangular','HasVelocity',false);
 end
 R=varianceScale*(R+R')/2;
 dets{j}=objectDetection(rows(j,2),z,'SensorIndex',1,'MeasurementNoise',R,'MeasurementParameters',params);
end
end
