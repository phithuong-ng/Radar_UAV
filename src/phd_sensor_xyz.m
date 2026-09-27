function xyz=phd_sensor_xyz(states,params)
% Explicit Cartesian sensor transform avoids spherical SensorLimits defaults.
xyz=states(params.position_indices,:);
end
