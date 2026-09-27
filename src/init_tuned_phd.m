function f=init_tuned_phd(name,c,varargin)
% Only public initializers/properties. Native tracker owns mixture capacity.
f=feval(char(name),varargin{:});
if contains(string(name),'cagmphd')
 vel=[2 5 8];acc=[3 6 9];
 f.ProcessNoise=diag([c.jerk_std_mps3 c.jerk_std_mps3 .5*c.jerk_std_mps3].^2);
else
 vel=[2 4 6];acc=[];
 f.ProcessNoise=diag([c.acceleration_std_mps2 c.acceleration_std_mps2 .5*c.acceleration_std_mps2].^2);
end
P=f.StateCovariances;
for j=1:size(P,3)
 P(vel,vel,j)=diag([c.velocity_std_mps c.velocity_std_mps c.vertical_velocity_std_mps].^2);
 if ~isempty(acc),P(acc,acc,j)=eye(3)*c.initial_accel_std_mps2^2;end
end
f.StateCovariances=P;f.HasExtent=false;
end
