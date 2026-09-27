function d=nl_device(c)
% Public experiment settings, not a hardware driver or a vendor scan scheduler.
d=struct('profile','Generic','operation','Search','face_offsets_deg',[0 90 180 270], ...
 'faces_enabled',true(1,4),'focus_face',1,'focus_azimuth_deg',[-15 15], ...
 'focus_elevation_deg',[0 20],'scan_aware_tracking',true);
if isfield(c,'device')
 names=fieldnames(c.device);for j=1:numel(names),d.(names{j})=c.device.(names{j});end
end
end
