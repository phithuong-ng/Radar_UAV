function cache=prepare_cache(d,c,needSph,needCart)
[cache.rows,cache.indices,cache.counts]=temporal_support(double(d.detections),double(d.times),c.temporal_support);
K=numel(d.times);cache.spherical=cell(K,1);cache.cartesian=cell(K,1);
for k=1:K
 if needSph,cache.spherical{k}=make_detections(cache.rows{k},'spherical',d.sensor_position,c.measurement_variance_scale);end
 if needCart,cache.cartesian{k}=make_detections(cache.rows{k},'cartesian',d.sensor_position,c.measurement_variance_scale);end
 if mod(k,40)==0,fprintf('  Prepare detections %d/%d\n',k,K);drawnow;end
end
% Effective scalar density estimated only from development reports, not labels.
% Native scalar density remains an approximation after the temporal front-end.
last=min(100,K);ratio=sum(cache.counts(2:last,2))/max(1,sum(cache.counts(2:last,1)));
cache.sensor=struct('dt',double(d.dt),'bounds',double(d.bounds),'lambda_effective',max(1,double(d.lambda_clutter)*ratio), ...
 'reference_range_m',double(d.reference_range_m),'reference_elevation_deg',double(d.reference_elevation_deg));
cache.times=double(d.times(:));
fprintf('Reports kept %d/%d | effective lambda estimate %.2f per scan (development only)\n', ...
 sum(cache.counts(:,2)),sum(cache.counts(:,1)),cache.sensor.lambda_effective);
end
