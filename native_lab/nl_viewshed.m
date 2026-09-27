function [V,terrain]=nl_viewshed(c)
terrain=nl_terrain(c);[~,~,r]=nl_ground(c,terrain,c.radar.position_enu_m);
V=viewshed(terrain.Z,terrain.R,r(1),r(2),r(3)-c.mapping.geoid_offset_m, ...
 c.mapping.viewshed_target_agl_m,'MSL','AGL',6371000,6371000*c.mapping.effective_earth_factor);
end
