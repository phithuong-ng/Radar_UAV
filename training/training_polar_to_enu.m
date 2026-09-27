function p=training_polar_to_enu(z,sensor)
%#codegen
% z = [azimuth rad; elevation rad; range m], fixed size 3x1 double.
p=sensor+z(3)*[cos(z(2))*cos(z(1));cos(z(2))*sin(z(1));sin(z(2))];
end
