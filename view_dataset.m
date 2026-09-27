function view_dataset(filename,resultFile)
% Offline OSM v5 draped on original v8 DSM. Optional benchmark track overlay.
root=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(filename),filename='fast_uav_mixed_9100.mat';end
if isfile(filename), datafile=filename; else, datafile=fullfile(root,'data','datasets',filename); end
d=load(datafile); terrain=load(fullfile(root,'data','dem','terrain.mat'));
o=load(fullfile(root,'data','osm_v5_on_dem_v8.mat')); result=[];
if nargin>=2 && ~isempty(resultFile), result=load(resultFile); end
f=figure('Name','Noi Bai | OSM v5 + Copernicus DSM v8','Color','w','Position',[70 70 1250 760]);
ax=axes('Parent',f,'Position',[.07 .18 .66 .76]); hold(ax,'on');
% Full ~30 m mesh remains modest (157k vertices); no 3x decimation over tiny ROI.
surf(ax,terrain.east,terrain.north,terrain.terrain,'EdgeColor','none','FaceColor',[.67 .77 .59]);
colors=[.46 .48 .46;.52 .54 .54;.36 .38 .39;.20 .23 .25];
names=["road","apron","taxiway","runway"]; widths=[.5 1 1.5 5];
for j=1:numel(names)
 q=o.(names(j));plot3(ax,q(:,1),q(:,2),q(:,3),'Color',colors(j,:),'LineWidth',widths(j));
end
q=o.building_outlines;plot3(ax,q(:,1),q(:,2),q(:,3),'Color',[.45 .42 .40],'LineWidth',.6);
hwalls=patch(ax,'Vertices',o.vertices,'Faces',o.faces,'FaceColor',[.70 .72 .75],'EdgeColor','none','Visible','off');
hroofs=patch(ax,'Vertices',o.vertices,'Faces',o.roofs,'FaceColor',[.58 .62 .67],'EdgeColor','none','Visible','off');
for id=unique(d.truth(:,3))'
 tr=d.truth(d.truth(:,3)==id,:);plot3(ax,tr(:,4),tr(:,5),tr(:,6),'Color',[.15 .4 .7],'LineWidth',.7);
end
ht=scatter3(ax,NaN,NaN,NaN,36,[0 .35 .85],'filled');
hd=scatter3(ax,NaN,NaN,NaN,10,[.8 .2 .15],'.');
he=scatter3(ax,NaN,NaN,NaN,65,[.8 0 .8],'s','LineWidth',1.5);
hr=plot3(ax,d.sensor_position(1),d.sensor_position(2),d.sensor_position(3),'kp','MarkerFaceColor','y','MarkerSize',13);
xlabel(ax,'East (m)');ylabel(ax,'North (m)');zlabel(ax,'Height relative to origin DSM (m)');
view(ax,35,35);grid(ax,'on');daspect(ax,[1 1 1]);
legend(ax,[hr ht hd he],{'Radar','UAV truth','All reports (unclassified)','Confirmed native tracks'},'Location','northwest','AutoUpdate','off');
% Airport context stays visible even when the main view is zoomed to the dataset.
ctx=axes('Parent',f,'Position',[.77 .59 .21 .32]);hold(ctx,'on');
for j=1:numel(names),q=o.(names(j));plot(ctx,q(:,1),q(:,2),'Color',colors(j,:));end
plot(ctx,d.sensor_position(1),d.sensor_position(2),'rp','MarkerFaceColor','r');
b=d.bounds; rectangle(ctx,'Position',[b(1,1) b(2,1) diff(b(1,:)) diff(b(2,:))],'EdgeColor',[0 .4 .9],'LineWidth',1.4);
axis(ctx,'equal');grid(ctx,'on');title(ctx,'Airport context / blue: dataset');xlabel(ctx,'East (m)');ylabel(ctx,'North (m)');
uicontrol(f,'Style','checkbox','String','Whole airport','Units','normalized','Position',[.77 .48 .20 .04],'Value',0,'Callback',@(h,~)setExtent(h.Value));
uicontrol(f,'Style','checkbox','String','Illustrative 3D buildings','Units','normalized','Position',[.77 .43 .22 .04],'Value',0,'Callback',@(h,~)showBuildings(h.Value));
uicontrol(f,'Style','text','Units','normalized','Position',[.77 .20 .21 .20],'BackgroundColor','w','HorizontalAlignment','left', ...
 'String',{'Blue: synthetic UAV positions';'Red: mixed target/clutter reports';'Magenta: loaded tracker output';'Building heights mostly assumed.';'DSM can already contain buildings.';'OSM/DSM do not generate clutter.'});
uicontrol(f,'Style','slider','Units','normalized','Position',[.15 .09 .57 .035], ...
 'Min',1,'Max',numel(d.times),'Value',1,'SliderStep',[1 min(10,numel(d.times)-1)]/(numel(d.times)-1),'Callback',@(h,~)drawFrame(round(h.Value)));
annotation(f,'textbox',[.07 .015 .90 .05],'String','Map: OpenStreetMap contributors (ODbL), v5 snapshot | Terrain: Copernicus GLO-30 DSM, v8 | Synthetic radar/UAV/plots','EdgeColor','none','FontSize',9);
setExtent(false);drawFrame(1);
 function showBuildings(on)
  if on, v='on'; else, v='off'; end
  set([hwalls hroofs],'Visible',v);
 end
 function setExtent(wide)
  if wide
   lim=o.map_bounds;axis(ax,[lim(1,:) lim(2,:) -20 450]);
  else
   sp=d.sensor_position;axis(ax,[min(b(1,1),sp(1))-60 max(b(1,2),sp(1))+60 min(b(2,1),sp(2))-60 max(b(2,2),sp(2))+60 -15 b(3,2)+40]);
  end
 end
 function drawFrame(k)
  tr=d.truth(d.truth(:,1)==k,:);z=d.detections(d.detections(:,1)==k,:);
  set(ht,'XData',tr(:,4),'YData',tr(:,5),'ZData',tr(:,6));set(hd,'XData',z(:,3),'YData',z(:,4),'ZData',z(:,5));
  xyz=zeros(0,3);
  if ~isempty(result) && k<=numel(result.estimates),xyz=result.estimates{k};end
  set(he,'XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3));
  [~,nm]=fileparts(datafile);title(ax,sprintf('%s | %.2f s | %d UAV (%d hover) | %d reports',nm,d.times(k),size(tr,1),sum(vecnorm(tr(:,7:9),2,2)<1e-8),size(z,1)),'Interpreter','none');
 end
end
