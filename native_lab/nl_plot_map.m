function nl_plot_map(ax,c,terrain,showOSM)
stride=max(1,ceil(max(size(terrain.Z))/180));i=1:stride:size(terrain.Z,1);j=1:stride:size(terrain.Z,2);
surf(ax,terrain.E(i,j),terrain.N(i,j),terrain.U(i,j),'EdgeColor','none', ...
 'FaceColor',[.67 .77 .59],'FaceAlpha',1,'HitTest','off','Tag','TerrainSurface');
if ~showOSM,return;end
map=nl_osm(c,terrain);names={'road','apron','taxiway','runway','building_outlines'};
colors=[.46 .48 .46;.52 .54 .54;.36 .38 .39;.20 .23 .25;.45 .42 .40];width=[.5 1 1.2 3.2 .6];
for j=1:numel(names)
 p=map.(names{j});plot3(ax,p(:,1),p(:,2),p(:,3),'Color',colors(j,:), ...
  'LineWidth',width(j),'HitTest','off','Tag',['OSM_' names{j}]);
end
end
