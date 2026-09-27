function c=training_normalize(c)
% JSON vectors can decode as columns; enforce explicit row-vector contracts.
c.origin_lla=c.origin_lla(:)';
c.radar.position_enu_m=c.radar.position_enu_m(:)';
c.radar.field_of_view_deg=c.radar.field_of_view_deg(:)';
c.radar.range_limits_m=c.radar.range_limits_m(:)';
c.environment.wind_enu_mps=c.environment.wind_enu_mps(:)';
c.optimization.sigma_bounds_m=c.optimization.sigma_bounds_m(:)';
for j=1:numel(c.uavs),c.uavs(j).arrival_s=c.uavs(j).arrival_s(:);end
end
