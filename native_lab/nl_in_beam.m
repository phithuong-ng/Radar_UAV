function inside=nl_in_beam(c,positions,look,valid)
% Predicted ENU positions only: no truth identity, labels or true target pose.
% This is a geometric opportunity mask, NOT a calibrated probability model.
faces=nl_faces(c);inside=false(size(positions,1),1);B=[0 1 0;1 0 0;0 0 -1];
for j=1:numel(faces)
 if ~valid(j),continue;end
 r=faces(j).radar;a=reshape(look(1,:,j),1,2);
 M=nl_rotation(90-r.heading_enu_deg,r.tilt_deg,r.roll_deg)*nl_rotation(a(1),-a(2),0);
 p=M'*B*(positions-r.position_enu_m)';
 range=sqrt(sum(p.^2,1));az=atan2d(p(2,:),p(1,:));el=atan2d(-p(3,:),hypot(p(1,:),p(2,:)));
 visible=abs(az)<=r.field_of_view_deg(1)/2+1e-8&abs(el)<=r.field_of_view_deg(2)/2+1e-8& ...
  range>=r.range_limits_m(1)&range<=r.range_limits_m(2);
 inside=inside|visible';
end
end
