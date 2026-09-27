function f=configure_filter(f,model,c)
% Native non-additive noise inputs: CV acceleration, CA jerk, CT acceleration/turn acceleration.
model=string(model);
if contains(model,'ca')
 vel=[2 5 8];acc=[3 6 9];
 f.ProcessNoise=diag([c.jerk_std_mps3 c.jerk_std_mps3 .5*c.jerk_std_mps3].^2);
 P=f.StateCovariance;P(acc,acc)=eye(3)*c.initial_accel_std_mps2^2;
elseif contains(model,'ct')
 vel=[2 4 7];
 % constturn noise order: ax, ay, angular acceleration (deg/s^2), az.
 f.ProcessNoise=diag([c.acceleration_std_mps2 c.acceleration_std_mps2 c.turn_accel_std_degps2 .5*c.acceleration_std_mps2].^2);
 P=f.StateCovariance;P(5,5)=c.initial_turn_std_degps^2;
else
 vel=[2 4 6];
 f.ProcessNoise=diag([c.acceleration_std_mps2 c.acceleration_std_mps2 .5*c.acceleration_std_mps2].^2);
 P=f.StateCovariance;
end
P(vel,vel)=diag([c.velocity_std_mps c.velocity_std_mps c.vertical_velocity_std_mps].^2);
f.StateCovariance=(P+P')/2;
end
