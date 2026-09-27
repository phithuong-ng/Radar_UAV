function lg=nl_legend(ax,c,truthVisible,detectionsVisible,tracksVisible,realData,selectedUAV)
% Actual MATLAB plot markers, identical to scene glyphs (no emoji/font dependency).
h=gobjects(0);names={};colors=lines(numel(c.uavs));hold(ax,'on');
if truthVisible&&~realData
 for j=1:numel(c.uavs)
  h(end+1)=plot3(ax,NaN,NaN,NaN,'-^','Color',colors(j,:),'MarkerFaceColor',colors(j,:),'LineWidth',1.6); %#ok<AGROW>
  names{end+1}=c.uavs(j).name; %#ok<AGROW>
 end
end
h(end+1)=plot3(ax,NaN,NaN,NaN,'ks','MarkerFaceColor','k');names{end+1}='Radar';
h(end+1)=plot3(ax,NaN,NaN,NaN,'-','Color',[.3 .65 .8]);names{end+1}='Chùm quét';
d=nl_device(c);if strcmp(d.profile,'RX-R417C'),h(end+1)=plot3(ax,NaN,NaN,NaN,':','Color',[.65 .67 .68]);names{end+1}='Vùng quét';end
if ~realData
 h(end+1)=plot3(ax,NaN,NaN,NaN,'o','Color',colors(selectedUAV,:),'MarkerFaceColor','w');names{end+1}='Waypoint';
end
if c.clutter.scatterers_enabled
 h(end+1)=plot3(ax,NaN,NaN,NaN,'x','Color',[.4 .4 .4],'LineWidth',2);names{end+1}='Phản xạ tĩnh';
end
if detectionsVisible,h(end+1)=plot3(ax,NaN,NaN,NaN,'r.','MarkerSize',15);names{end+1}='Điểm đo';end
if tracksVisible
 h(end+1)=plot3(ax,NaN,NaN,NaN,'o-.','Color',[.42 .12 .6],'MarkerSize',4,'LineWidth',2);names{end+1}='Đường bám';
end
set(h,'HitTest','off','Tag','LegendProxy');
lg=legend(ax,h,names,'Location','eastoutside','Orientation','vertical','Interpreter','none','NumColumns',1,'FontSize',9);
% Reserve a separate tile so labels cannot overlap the lower metric axes.
if isa(ax.Parent,'matlab.graphics.layout.TiledChartLayout'),lg.Layout.Tile='east';end
lg.Title.String='Chú giải';lg.Title.FontWeight='normal';
lg.ItemTokenSize=[22 12];
lg.AutoUpdate='off';lg.Box='off';lg.Tag='SceneLegend';
end
