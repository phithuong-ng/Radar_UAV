function row=training_row(k,time,z,R,sensor)
% z=[azimuth ENU deg;elevation ENU deg;range m]. R uses deg,deg,m.
z=double(z(:));R=double(R);assert(numel(z)==3&&isequal(size(R),[3 3]));
R=(R+R')/2;assert(all(isfinite(R),'all')&&min(eig(R))>=-1e-8,'Invalid covariance.');
a=deg2rad(z(1));e=deg2rad(z(2));r=z(3);assert(isfinite(r)&&r>0,'Nonpositive range.');
p=double(sensor(:))'+r*[cos(e)*cos(a) cos(e)*sin(a) sin(e)];
% Native simulator angular covariance is diagonal in this configuration.
assert(norm(R-diag(diag(R)),'fro')<1e-8*max(1,norm(R,'fro')), ...
 'Legacy spherical schema cannot preserve correlated spherical covariance.');
sigma=[sqrt(max(R(3,3),0)) deg2rad(sqrt(max(R(1,1),0))) deg2rad(sqrt(max(R(2,2),0)))];
J=[cos(e)*cos(a) -r*cos(e)*sin(a) -r*sin(e)*cos(a); ...
 cos(e)*sin(a) r*cos(e)*cos(a) -r*sin(e)*sin(a);sin(e) 0 r*cos(e)];
C=J*diag(sigma.^2)*J'+eye(3)*1e-8;
row=[k time p C(:)' r z(1) z(2) sigma];
end
