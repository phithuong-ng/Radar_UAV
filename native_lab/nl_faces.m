function faces=nl_faces(c)
% Coverage settings are EDGES; native electronic limits are beam CENTRES.
d=nl_device(c);faces=struct('id',1,'radar',c.radar,'coverage',[],'looks_per_cycle',NaN);
if strcmp(d.profile,'Generic'),return;end
faces=repmat(faces,0,1);base=c.radar;
mount=nl_rotation(90-base.heading_enu_deg,base.tilt_deg,base.roll_deg);
for j=1:4
 if ~d.faces_enabled(j)||(strcmp(d.operation,'Focus')&&j~=d.focus_face),continue;end
 r=base;r.mode='Raster';r.scan_technology='Electronic';
 if strcmp(d.operation,'Focus')
  edges=[reshape(d.focus_azimuth_deg,1,2);reshape(d.focus_elevation_deg,1,2)];
 else
  edges=[reshape(base.electronic_azimuth_limits_deg,1,2);reshape(base.electronic_elevation_limits_deg,1,2)];
 end
 % Tile the requested sector without gaps. The nominal FOV is an upper bound.
 n=max(1,ceil(diff(edges,1,2)./base.field_of_view_deg(:)-1e-10));
 r.field_of_view_deg=(diff(edges,1,2)./n)';
 centers=edges+[r.field_of_view_deg(:)/2 -r.field_of_view_deg(:)/2];
 % Native scanner needs non-zero limits to steer a one-cell sector off boresight.
 for axisID=1:2
  if n(axisID)==1,centers(axisID,:)=mean(edges(axisID,:))+[-1e-4 1e-4];end
 end
 r.electronic_azimuth_limits_deg=centers(1,:);r.electronic_elevation_limits_deg=centers(2,:);
 M=mount*nl_rotation(-d.face_offsets_deg(j),0,0);
 r.heading_enu_deg=90-atan2d(M(2,1),M(1,1));
 r.tilt_deg=atan2d(-M(3,1),hypot(M(1,1),M(2,1)));r.roll_deg=atan2d(M(3,2),M(3,3));
 faces(end+1)=struct('id',j,'radar',r,'coverage',edges,'looks_per_cycle',prod(n)); %#ok<AGROW>
end
end
