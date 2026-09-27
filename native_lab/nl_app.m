function app=nl_app(visible)
% Native MATLAB UI: configuration, route editing, simulation, replay and lessons.
if nargin<1,visible=true;end
c=nl_rx_preset;terrain=[];preview=[];log=[];results={};selectedUAV=1;selectedWaypoint=1;
scan=1;busy=false;cancelled=false;playing=false;dirty=true;trackDirty=true;dragBefore=[];datasetID='';lastFolder='';queue={};
fig=uifigure('Name','Nội Bài Radar | Native Interactive Lab RC5.2 | RX-R417C','Position',[40 45 1530 940], ...
 'Visible',matlab.lang.OnOffSwitchState(visible),'Tag','NativeLab','CloseRequestFcn',@closeApp);
app=fig;
main=uigridlayout(fig,[4 1]);main.RowHeight={78,'1x',40,75};main.Padding=[8 8 8 8];
top=uigridlayout(main,[2 7]);top.Padding=[0 0 0 0];top.RowHeight={32,32};top.ColumnWidth={190,'1x','1x','1x','1x','1x','1x'};
presets={'01 Cơ bản: hai UAV','02 Góc nhìn hẹp','03 Báo giả và vật phản xạ','04 Radar quét sector','05 UAV cơ động: IMM','06 Mất phép đo: radar chậm','07 RX-R417C: bốn mặt điện tử','08 RX-R417C: vùng tập trung'};
preset=uidropdown(top,'Items',presets,'Value',presets{7},'ValueChangedFcn',@presetChanged,'Tooltip','Chọn kịch bản sẽ thay toàn bộ cấu hình hiện tại.');
uibutton(top,'Text','Mở phiên','ButtonPushedFcn',@loadSession);
uibutton(top,'Text','Lưu cấu hình','ButtonPushedFcn',@saveConfig);
uibutton(top,'Text','Xem lệnh','ButtonPushedFcn',@showCommands);
uibutton(top,'Text','Mô phỏng + bám','ButtonPushedFcn',@runAll,'Tag','RunNative');
uibutton(top,'Text','Chạy cấu hình tracker','ButtonPushedFcn',@runTracker);
uibutton(top,'Text','Chạy hàng đợi','ButtonPushedFcn',@compareTrackers);
uibutton(top,'Text','Lưu kết quả','ButtonPushedFcn',@exportRun);
uibutton(top,'Text','Hướng dẫn đầy đủ','ButtonPushedFcn',@(~,~)web(fullfile(nl_root,'native_lab','docs','WORKFLOW_RC5.html'),'-browser'));
uibutton(top,'Text','Tạo dataset','ButtonPushedFcn',@generateDataset);
uibutton(top,'Text','Lưu dataset hiện tại','ButtonPushedFcn',@saveDataset);
uibutton(top,'Text','Thư viện dataset / run','ButtonPushedFcn',@openLibrary);
uibutton(top,'Text','Chọn nơi lưu','ButtonPushedFcn',@chooseStorage);
uibutton(top,'Text','Mở kết quả đã lưu','ButtonPushedFcn',@openOutput);
body=uigridlayout(main,[1 2]);body.Padding=[0 0 0 0];body.ColumnWidth={505,'1x'};
tabs=uitabgroup(body);
tables=struct;
radarTab=uitab(tabs,'Title','Radar');rg=uigridlayout(radarTab,[6 1]);rg.RowHeight={22,210,76,22,'1x',36};
uilabel(rg,'Text','Thiết bị & nhiệm vụ','FontWeight','bold');
createProperties(rg,'device');
deviceInfo=uitextarea(rg,'Editable','off','Tag','DeviceSummary','FontSize',10);
uilabel(rg,'Text','Thông số đo & vùng quét','FontWeight','bold');
createProperties(rg,'radar');radarButtons=uigridlayout(rg,[1 2]);radarButtons.Padding=[0 0 0 0];
uibutton(radarButtons,'Text','Đặt chiều cao anten AGL (m)','ButtonPushedFcn',@setRadarAGL);
uibutton(radarButtons,'Text','Hướng dẫn cấu hình radar','ButtonPushedFcn',@(~,~)web(fullfile(nl_root,'native_lab','docs','WORKFLOW_RC5.html'),'-browser'));
uavTab=uitab(tabs,'Title','UAV');ug=uigridlayout(uavTab,[6 1]);ug.RowHeight={32,110,'1x',32,120,45};
pick=uigridlayout(ug,[1 3]);pick.Padding=[0 0 0 0];pick.ColumnWidth={'1x',85,85};
uavSelect=uidropdown(pick,'Items',{c.uavs.name},'ValueChangedFcn',@chooseUAV);
uibutton(pick,'Text','Thêm UAV','ButtonPushedFcn',@addUAV);uibutton(pick,'Text','Xóa UAV','ButtonPushedFcn',@deleteUAV);
uavProps=uitable(ug,'ColumnName',{'Thuộc tính','Giá trị'},'ColumnEditable',[false true], ...
 'ColumnWidth',{220,'auto'},'CellEditCallback',@uavEdit,'Tag','UAVProperties');
wp=uitable(ug,'ColumnName',{'East m','North m','Up m','Đến lúc s','AGL m'},'ColumnEditable',true(1,5), ...
 'ColumnWidth',{86,86,86,86,86},'CellEditCallback',@waypointEdit,'CellSelectionCallback',@waypointSelected,'Tag','Waypoints');
row=uigridlayout(ug,[1 3]);row.Padding=[0 0 0 0];
uibutton(row,'Text','Chèn waypoint','ButtonPushedFcn',@addWaypoint);
uibutton(row,'Text','Xóa waypoint','ButtonPushedFcn',@deleteWaypoint);
uibutton(row,'Text','Nhập waypoint LLA','ButtonPushedFcn',@enterLLA);
llaTable=uitable(ug,'ColumnName',{'Vĩ độ deg','Kinh độ deg','h ellipsoid m','AGL m'},'ColumnEditable',false);
uilabel(ug,'Text',{'Chọn 2D rồi kéo vòng tròn waypoint trên hình.';'Up là tọa độ ENU; AGL/h ellipsoid ở bảng dưới. Không đồng nhất ba số này.'},'WordWrap','on');
mapTab=uitab(tabs,'Title','Địa hình');mg=uigridlayout(mapTab,[3 1]);mg.RowHeight={'1x',36,64};
createProperties(mg,'mapping');mr=uigridlayout(mg,[1 3]);mr.Padding=[0 0 0 0];
uibutton(mr,'Text','Chọn DEM','ButtonPushedFcn',@chooseDEM);uibutton(mr,'Text','Đổi mốc ENU','ButtonPushedFcn',@rebase);
uibutton(mr,'Text','Tính viewshed','ButtonPushedFcn',@viewVisibility);
originLabel=uilabel(mg,'Text','','WordWrap','on');
clutterTab=uitab(tabs,'Title','Clutter');cg=uigridlayout(clutterTab,[4 1]);cg.RowHeight={145,'1x',32,100};
createProperties(cg,'clutter');scatterTable=uitable(cg,'ColumnName',{'East m','North m','AGL m','RCS m²'}, ...
 'ColumnEditable',true(1,4),'CellEditCallback',@scatterEdit,'Tag','Scatterers');
sr=uigridlayout(cg,[1 2]);sr.Padding=[0 0 0 0];
uibutton(sr,'Text','Thêm điểm tĩnh','ButtonPushedFcn',@addScatterer);uibutton(sr,'Text','Xóa điểm cuối','ButtonPushedFcn',@deleteScatterer);
uilabel(cg,'Text',{'Pfa: báo động giả ngẫu nhiên từ radarDataGenerator.'; ...
 'Điểm tĩnh: vật phản xạ RCS riêng lẻ, không phải mặt đất phân bố.'; ...
 'Clutter bề mặt: xem tab IQ; mô hình riêng, không tự chèn vào tracking.'},'WordWrap','on');
trackerTab=uitab(tabs,'Title','Tracking');tg=uigridlayout(trackerTab,[4 1]);tg.RowHeight={138,'1x',36,45};
selectors=uigridlayout(tg,[4 2]);selectors.ColumnWidth={145,'1x'};selectors.RowHeight={26,26,26,26};
uilabel(selectors,'Text','Data association');
family=uidropdown(selectors,'Items',{'GNN','JPDA','TOMHT','PHD'},'ValueChangedFcn',@familyChanged);
uilabel(selectors,'Text','State estimation');
method=uidropdown(selectors,'Items',{'GNN_CV_EKF_SPH'},'Value',c.method,'ValueChangedFcn',@methodChanged,'Tag','TrackerMethod');
uilabel(selectors,'Text','Bộ giải gán GNN');
assignment=uidropdown(selectors,'Items',{'Jonker-Volgenant','Munkres','Auction','MatchPairs','Custom'},'ValueChangedFcn',@assignmentChanged);
uilabel(selectors,'Text','Track management');
management=uidropdown(selectors,'Items',{'History','Score'},'ValueChangedFcn',@managementChanged);
createProperties(tg,'tracking');
tr=uigridlayout(tg,[1 4]);tr.Padding=[0 0 0 0];
uibutton(tr,'Text','Thêm vào hàng đợi','ButtonPushedFcn',@queueCurrent);
uibutton(tr,'Text','Xem hàng đợi','ButtonPushedFcn',@viewQueue);
uibutton(tr,'Text','Tra API đang dùng','ButtonPushedFcn',@trackerHelp);
uibutton(tr,'Text','Chi tiết bám','ButtonPushedFcn',@inspectTracking);
uilabel(tg,'Text','Chọn từng lớp → chỉnh tham số → chạy trên cùng dataset. CUSTOM nhận bộ khởi tạo MATLAB riêng.','WordWrap','on');
sessionTab=uitab(tabs,'Title','Phiên');sg=uigridlayout(sessionTab,[3 1]);sg.RowHeight={'1x',36,75};
createProperties(sg,'session');sib=uigridlayout(sg,[1 2]);sib.Padding=[0 0 0 0];
uibutton(sib,'Text','Nhập CSV radar ENU','ButtonPushedFcn',@importCSV);
uibutton(sib,'Text','Kiểm tra toolbox','ButtonPushedFcn',@checkTools);
uilabel(sg,'Text',{'CSV cần đúng schema trong hướng dẫn; chưa phải bộ đọc mọi radar thương mại.'; ...
 'Mỗi thí nghiệm có config, detections, tracks, metrics và script phát lại.'},'WordWrap','on');
iqTab=uitab(tabs,'Title','IQ');ig=uigridlayout(iqTab,[3 1]);ig.RowHeight={'1x',36,85};
createProperties(ig,'iq');uibutton(ig,'Text','Chạy LFM + clutter + matched filter + CFAR + ULA','ButtonPushedFcn',@runIQ);
uilabel(ig,'Text',{'Cần Radar Toolbox + Phased Array System Toolbox.'; ...
 'Mặt đất phẳng đồng nhất, không DEM; không có echo UAV hay nhiễu máy thu trong bài IQ.'; ...
 'Kết quả riêng, không phải nguồn detections của cảnh bên phải.'},'WordWrap','on');
learnTab=uitab(tabs,'Title','Bài học');lg=uigridlayout(learnTab,[3 1]);lg.RowHeight={32,'1x',36};
lessons=nl_lessons;lessonSelect=uidropdown(lg,'Items',{lessons.title},'ValueChangedFcn',@lessonChanged);
lessonText=uitextarea(lg,'Editable','off','Value',splitlines(string(lessons(1).text)));
buttons=uigridlayout(lg,[1 2]);buttons.Padding=[0 0 0 0];
uibutton(buttons,'Text','UAV Scenario Designer','ButtonPushedFcn',@(~,~)openDesigner('uavScenarioDesigner'));
uibutton(buttons,'Text','Radar Designer','ButtonPushedFcn',@(~,~)openDesigner('radarDesigner'));
right=uigridlayout(body,[5 1]);right.RowHeight={32,30,'4x','1x',78};right.Padding=[0 0 0 0];
viewControls=uigridlayout(right,[1 5]);viewControls.Padding=[0 0 0 0];viewControls.ColumnWidth={75,120,130,130,'1x'};
viewMode=uidropdown(viewControls,'Items',{'2D','3D'},'Value','3D','ValueChangedFcn',@(~,~)redraw);
showTruth=uicheckbox(viewControls,'Text','Đường thật','Value',true,'ValueChangedFcn',@(~,~)redraw);
showDets=uicheckbox(viewControls,'Text','Điểm đo','Value',true,'ValueChangedFcn',@(~,~)redraw);
showTracks=uicheckbox(viewControls,'Text','Đường bám','Value',true,'ValueChangedFcn',@(~,~)redraw);
resultSelect=uidropdown(viewControls,'Items',{'Chưa có kết quả'},'ValueChangedFcn',@(~,~)redraw);
mapControls=uigridlayout(right,[1 6]);mapControls.Padding=[0 0 0 0];mapControls.ColumnWidth={60,100,60,'1x',100,120};
showOSM=uicheckbox(mapControls,'Text','OSM','Value',true,'ValueChangedFcn',@(~,~)redraw,'Tag','ShowOSM');
uilabel(mapControls,'Text','Tỷ lệ cao độ');
verticalScale=uidropdown(mapControls,'Items',{'Auto','1','3','6','12','20'},'Value','Auto','ValueChangedFcn',@(~,~)redraw,'Tag','VerticalScale', ...
 'Tooltip','Auto: cân đối chiều cao khung nhìn. Các số là hệ số phóng đại chiều đứng; 1 giữ cùng tỷ lệ vật lý. Chỉ thay hiển thị.');
uilabel(mapControls,'Text','© OpenStreetMap contributors · Copernicus GLO-30','FontSize',9);
showCoverage=uicheckbox(mapControls,'Text','Vùng quét','Value',true,'ValueChangedFcn',@(~,~)redraw);
fullRadar=uicheckbox(mapControls,'Text','Toàn tầm radar','Value',false,'ValueChangedFcn',@(~,~)redraw);
scenePanel=uipanel(right,'BorderType','none','Tag','ScenePanel');
sceneLayout=tiledlayout(scenePanel,1,1,'TileSpacing','compact','Padding','compact');
ax=uiaxes(sceneLayout,'Tag','SceneAxes');ax.Layout.Tile=1;ax.Toolbar.Visible='off';
metricAx=uiaxes(right,'Tag','MetricAxes');
info=uitextarea(right,'Editable','off','Value',{'Đang khởi tạo...'});
controls=uigridlayout(main,[1 7]);controls.Padding=[0 0 0 0];controls.ColumnWidth={80,85,85,70,'1x',155,100};
uibutton(controls,'Text','Phát / Dừng','ButtonPushedFcn',@togglePlay);
uibutton(controls,'Text','Từng bước','ButtonPushedFcn',@step);
uibutton(controls,'Text','Về đầu','ButtonPushedFcn',@resetTime);
uilabel(controls,'Text','Thời gian');
slider=uislider(controls,'Limits',[1 c.frames],'Value',1,'MajorTicks',[],'ValueChangedFcn',@seek);
timeLabel=uilabel(controls,'Text','');
uibutton(controls,'Text','Hủy tính','ButtonPushedFcn',@(~,~)cancel);
status=uitextarea(main,'Editable','off','Value',{'Đang đọc DEM và quỹ đạo native...'},'Tag','NativeStatus');
timerObj=timer('ExecutionMode','fixedSpacing','Period',.15,'BusyMode','drop','TimerFcn',@tick);
try,refresh(true);catch ME,report(ME);end

 function createProperties(parent,group)
  if isa(parent,'matlab.ui.container.Tab'),g=uigridlayout(parent,[1 1]);else,g=parent;end
  t=uitable(g,'ColumnName',{'Thông số','Giá trị','Đơn vị','API / ý nghĩa'}, ...
   'ColumnEditable',[false true false false],'ColumnWidth',{165,115,55,300}, ...
   'CellEditCallback',@(src,event)propertyEdit(src,event,group),'Tag',['Properties_' group]);
  tables.(group)=t;
 end
 function refresh(rebuildTerrain)
  if nargin<1,rebuildTerrain=false;end
  if rebuildTerrain||isempty(terrain),terrain=nl_terrain(c);end
  preview=nl_preview(c,terrain);
  updateTables;scan=min(max(scan,1),c.frames);slider.Limits=[1 c.frames];slider.Value=scan;redraw;
  if dirty,setStatus('Cấu hình hợp lệ. Hình là xem trước; nhấn “1. Mô phỏng + bám” để tạo kết quả mới.');end
 end
 function updateTables
  groups=fieldnames(tables);
  for j=1:numel(groups)
   group=groups{j};rows=nl_fields(c,group);tables.(group).UserData=rows;tables.(group).Data=rows(:,2:5);
  end
  device=nl_device(c);
  if strcmp(device.profile,'RX-R417C')
   f=nl_faces(c);cycle=preview.scan.cycle_s;
   deviceInfo.Value={sprintf('%s | %s | %d mặt bật',device.profile,device.operation,numel(f)); ...
    sprintf('Một bước chùm: %.3f s | %d hướng/mặt | vòng quét: %.3f s',c.dt*c.radar.update_every_steps,f(1).looks_per_cycle,cycle); ...
    sprintf('Chùm thực dùng: %.2f × %.2f deg (giả định)',f(1).radar.field_of_view_deg); ...
    'Bốn mặt chạy song song; Focus chỉ giữ một mặt, không xen kẽ tìm kiếm.'; ...
    'GNN/JPDA xét vùng chùm; TOMHT/PHD cần tự chỉnh quản lý track cho lượt quét thưa.'; ...
    'Mô hình thử nghiệm theo datasheet; chưa kết nối hoặc hiệu chuẩn thiết bị.'};
  else,deviceInfo.Value={'Radar tổng quát. Chọn preset 07/08 để dùng mô hình bốn mặt RX-R417C.'};end
  selectedUAV=min(selectedUAV,numel(c.uavs));u=c.uavs(selectedUAV);
  uavSelect.Items={c.uavs.name};uavSelect.Value=u.name;syncTrackerControls;
  uavProps.Data={'Tên',u.name;'RCS m²',jsonencode(u.rcs_m2);'Bắt đầu ở bước',jsonencode(u.birth_scan); ...
   'Kết thúc ở bước',jsonencode(u.death_scan);'Giới hạn tốc độ m/s',jsonencode(u.speed_limit_mps)};
  scatterTable.Data=c.clutter.scatterers;
  [~,agl,lla]=nl_ground(c,terrain,u.waypoints_enu_m);llaTable.Data=[lla agl];
  wp.Data=[u.waypoints_enu_m u.arrival_s(:) agl];
  originLabel.Text=sprintf('Mốc ENU: lat %.7f, lon %.7f, h ellipsoid %.3f m.\n%s',c.origin_lla,c.mapping.datum_note);
 end
 function markDirty
  dirty=true;trackDirty=true;playing=false;stop(timerObj);
 end
 function propertyEdit(src,event,group)
  if busy,updateTables;return;end
  old=c;
  try
   rows=src.UserData;key=rows{event.Indices(1),1};
   if strcmp(group,'device'),c.device=nl_device(c);end
   if strcmp(group,'session'),v=c.(key);c.(key)=nl_value(event.NewData,v);
   elseif strcmp(group,'tracking')&&strcmp(key,'jpda_max_events')
    if strcmp(strtrim(char(string(event.NewData))),'all'),c.tracking.jpda_max_events='all';
    else,c.tracking.jpda_max_events=nl_value(event.NewData,1);end
   else,v=c.(group).(key);c.(group).(key)=nl_value(event.NewData,v);end
   if strcmp(group,'session')&&any(strcmp(key,{'dt','frames'}))
    duration=(c.frames-1)*c.dt;
    for q=1:numel(c.uavs)
     c.uavs(q).arrival_s=c.uavs(q).arrival_s*duration/((old.frames-1)*old.dt);
     c.uavs(q).death_scan=min(c.frames,max(1,round((old.uavs(q).death_scan-1)/(old.frames-1)*(c.frames-1))+1));
     c.uavs(q).birth_scan=min(c.uavs(q).death_scan,max(1,round((old.uavs(q).birth_scan-1)/(old.frames-1)*(c.frames-1))+1));
    end
   end
   if strcmp(group,'device')&&strcmp(c.device.profile,'RX-R417C'),c.radar.mode='Raster';c.radar.scan_technology='Electronic';end
   nl_validate(c);
   if strcmp(group,'tracking'),trackDirty=true;updateTables;redraw;setStatus('Đã đổi tracker. Điểm đo giữ nguyên; nhấn “2. Chạy lại tracker”.');
   elseif strcmp(group,'iq'),updateTables;setStatus('Đã đổi cấu hình bài IQ riêng. Nhấn nút Chạy ở tab IQ.');
   else,markDirty;refresh(strcmp(group,'mapping'));end
  catch ME,c=old;refresh(strcmp(group,'mapping'));report(ME);end
 end
 function uavEdit(~,event)
  if busy,updateTables;return;end
  old=c;keys={'name','rcs_m2','birth_scan','death_scan','speed_limit_mps'};
  try,key=keys{event.Indices(1)};c.uavs(selectedUAV).(key)=nl_value(event.NewData,c.uavs(selectedUAV).(key));markDirty;refresh;
  catch ME,c=old;refresh;report(ME);end
 end
 function waypointEdit(~,event)
  if busy,updateTables;return;end
  old=c;
  try
   if event.Indices(2)==5
    row=event.Indices(1);c.uavs(selectedUAV).waypoints_enu_m(row,:)= ...
     nl_set_agl(c,terrain,c.uavs(selectedUAV).waypoints_enu_m(row,:),event.NewData);
   else
    c.uavs(selectedUAV).waypoints_enu_m=wp.Data(:,1:3);c.uavs(selectedUAV).arrival_s=wp.Data(:,4);
   end
   markDirty;refresh;
  catch ME,c=old;refresh;report(ME);end
 end
 function waypointSelected(~,event)
  if ~isempty(event.Indices),selectedWaypoint=event.Indices(1,1);end
 end
 function chooseUAV(~,~)
  if busy,return;end
  selectedUAV=find(strcmp({c.uavs.name},uavSelect.Value),1);selectedWaypoint=1;updateTables;redraw;
 end
 function addUAV(~,~)
  if busy,return;end
  old=c;
  try
   u=c.uavs(selectedUAV);i=numel(c.uavs)+1;
   while any(strcmp({c.uavs.name},sprintf('UAV_%d',i))),i=i+1;end
   u.name=sprintf('UAV_%d',i);u.waypoints_enu_m(:,3)=u.waypoints_enu_m(:,3)+20;
   c.uavs(end+1)=u;selectedUAV=numel(c.uavs);markDirty;refresh;
  catch ME,c=old;selectedUAV=1;refresh;report(ME);end
 end
 function deleteUAV(~,~)
  if busy||numel(c.uavs)==1,return;end
  c.uavs(selectedUAV)=[];selectedUAV=1;markDirty;refresh;
 end
 function addWaypoint(~,~)
  if busy,return;end
  old=c;
  try
   u=c.uavs(selectedUAV);i=min(selectedWaypoint,size(u.waypoints_enu_m,1)-1);
   u.waypoints_enu_m=[u.waypoints_enu_m(1:i,:);mean(u.waypoints_enu_m(i:i+1,:),1);u.waypoints_enu_m(i+1:end,:)];
   u.arrival_s=[u.arrival_s(1:i);mean(u.arrival_s(i:i+1));u.arrival_s(i+1:end)];c.uavs(selectedUAV)=u;
   markDirty;refresh;
  catch ME,c=old;refresh;report(ME);end
 end
 function deleteWaypoint(~,~)
  if busy,return;end
  old=c;
  try
   u=c.uavs(selectedUAV);assert(size(u.waypoints_enu_m,1)>2,'Keep at least two waypoints.');
   i=min(selectedWaypoint,size(u.waypoints_enu_m,1));u.waypoints_enu_m(i,:)=[];u.arrival_s(i)=[];
   u.arrival_s=(u.arrival_s-u.arrival_s(1));u.arrival_s=u.arrival_s/u.arrival_s(end)*(c.frames-1)*c.dt;
   c.uavs(selectedUAV)=u;selectedWaypoint=1;markDirty;refresh;
  catch ME,c=old;refresh;report(ME);end
 end
 function enterLLA(~,~)
  if busy,return;end
  i=min(selectedWaypoint,size(wp.Data,1));v=llaTable.Data(i,1:3);
  answer=inputdlg({'Vĩ độ (deg)','Kinh độ (deg)','h ellipsoid (m)'},'Thay tọa độ waypoint',1,cellstr(string(v)));
  if isempty(answer),return;end
  old=c;
  try
   a=str2double(answer);assert(all(isfinite(a)),'Use finite numbers.');o=c.origin_lla;
   [e,n,u]=geodetic2enu(a(1),a(2),a(3),o(1),o(2),o(3),terrain.ellipsoid);
   c.uavs(selectedUAV).waypoints_enu_m(i,:)=[e n u];markDirty;refresh;
  catch ME,c=old;refresh;report(ME);end
 end
 function dragStart(~,~,j,k)
  if busy||~strcmp(viewMode.Value,'2D'),return;end
  playing=false;stop(timerObj);selectedUAV=j;selectedWaypoint=k;dragBefore=c;
  fig.WindowButtonMotionFcn=@dragMove;fig.WindowButtonUpFcn=@dragEnd;
 end
 function dragMove(~,~)
  p=ax.CurrentPoint;
  if isempty(dragBefore)||any(~isfinite(p(1,1:2))),return;end
  c.uavs(selectedUAV).waypoints_enu_m(selectedWaypoint,1:2)=p(1,1:2);
  % Geometry-only preview while dragging. Native interpolation is recomputed on release.
  h=findobj(ax,'Tag','SelectedWaypoints');u=c.uavs(selectedUAV);
  if ~isempty(h),set(h,'XData',u.waypoints_enu_m(:,1),'YData',u.waypoints_enu_m(:,2));end
  data=wp.Data;data(:,1:3)=u.waypoints_enu_m;wp.Data=data;
 end
 function dragEnd(~,~)
  fig.WindowButtonMotionFcn=[];fig.WindowButtonUpFcn=[];old=dragBefore;dragBefore=[];
  try,markDirty;refresh;catch ME,c=old;refresh;report(ME);end
 end
 function scatterEdit(~,~)
  if busy,updateTables;return;end
  old=c;try,c.clutter.scatterers=scatterTable.Data;markDirty;refresh;catch ME,c=old;refresh;report(ME);end
 end
 function addScatterer(~,~)
  if busy,return;end
  c.clutter.scatterers(end+1,:)=[1500 -500 20 .02];markDirty;refresh;
 end
 function deleteScatterer(~,~)
  if busy||isempty(c.clutter.scatterers),return;end
  c.clutter.scatterers(end,:)=[];markDirty;refresh;
 end
 function syncTrackerControls
  c.tracking=nl_tracking_defaults(c.tracking);m=nl_registry(c.method);reg=nl_registry;
  family.Value=char(m.tracker);reg=reg([reg.tracker]==m.tracker);
  method.Items=cellfun(@nl_method_label,cellstr([reg.name]),'UniformOutput',false);method.ItemsData=cellstr([reg.name]);method.Value=c.method;
  assignment.Value=c.tracking.gnn_assignment;assignment.Enable=matlab.lang.OnOffSwitchState(m.tracker=="GNN");
  if m.tracker=="GNN",management.Items={'History','Score'};management.Value=c.tracking.gnn_logic;
  elseif m.tracker=="JPDA",management.Items={'History','Integrated'};management.Value=c.tracking.jpda_logic;
  elseif m.tracker=="TOMHT",management.Items={'Branch score'};
  else,management.Items={'PHD weight'};end
  management.Enable=matlab.lang.OnOffSwitchState(any(m.tracker==["GNN","JPDA"]));
 end
 function familyChanged(~,~)
  if busy,syncTrackerControls;return;end
  reg=nl_registry;reg=reg([reg.tracker]==string(family.Value));c.method=char(reg(1).name);
  c.tracking.tracker_properties_json='{}';c.tracking.filter_properties_json='{}';
  trackDirty=true;updateTables;redraw;
  setStatus('Đã đổi họ tracker. Overrides API được đặt lại để tránh dùng thuộc tính của họ cũ.');
 end
 function methodChanged(~,~)
  if busy,syncTrackerControls;return;end
  old=c;candidate=method.Value;
  try
   if contains(candidate,'CUSTOM')&&isempty(c.tracking.custom_initializer)
    a=inputdlg({'Tên hàm MATLAB: filter = name(detection)','Chỉ số [E,N,U] trong state, ví dụ [1,3,5]'},'Custom initializer',1,{'initcvckf','[1,3,5]'});
    if isempty(a),syncTrackerControls;return;end
    c.tracking.custom_initializer=a{1};c.tracking.custom_position_indices=jsondecode(a{2})';
   end
   c.method=candidate;c.tracking.filter_properties_json='{}';nl_validate(c);
   trackDirty=true;updateTables;redraw;setStatus('Đã đổi bộ lọc. Phép đo giữ nguyên; cấu hình mới chưa chạy.');
  catch ME,c=old;updateTables;report(ME);end
 end
 function assignmentChanged(~,~)
  if busy,syncTrackerControls;return;end
  old=c;
  try
   if strcmp(assignment.Value,'Custom')
    a=inputdlg({'Tên hàm gán theo giao diện trackerGNN.CustomAssignmentFcn'},'Custom assignment',1,{c.tracking.custom_assignment_fcn});
    if isempty(a),syncTrackerControls;return;end
    c.tracking.custom_assignment_fcn=a{1};
   end
   c.tracking.gnn_assignment=assignment.Value;nl_validate(c);trackDirty=true;updateTables;redraw;
  catch ME,c=old;updateTables;report(ME);end
 end
 function managementChanged(~,~)
  if busy,syncTrackerControls;return;end
  if strcmp(family.Value,'GNN'),c.tracking.gnn_logic=management.Value;else,c.tracking.jpda_logic=management.Value;end
  c.tracking.tracker_properties_json='{}';trackDirty=true;updateTables;redraw;
 end
 function queueCurrent(~,~)
  if busy,return;end
  try,nl_validate(c);queue{end+1}=c;setStatus(sprintf('Đã thêm cấu hình %d: %s. Nhấn Chạy hàng đợi khi dataset đã sẵn sàng.',numel(queue),nl_method_label(c.method)));
  catch ME,report(ME);end
 end
 function viewQueue(~,~)
  if isempty(queue),setStatus('Hàng đợi trống. Chỉnh tracker và nhấn Thêm vào hàng đợi.');return;end
  items=cellfun(@(x)sprintf('%s | gate %g | R x%g',nl_run_label(x.method,x.tracking),x.tracking.assignment_threshold,x.tracking.measurement_variance_scale),queue,'UniformOutput',false);
  [ix,ok]=listdlg('ListString',items,'SelectionMode','multiple','PromptString','Chọn các cấu hình muốn XÓA khỏi hàng đợi; Hủy để giữ.','ListSize',[550 300]);
  if ok&&~busy,queue(ix)=[];end
 end
 function trackerHelp(~,~)
  m=nl_registry(c.method);doc(['tracker' char(m.tracker)]);
 end
 function inspectTracking(~,~)
  if isempty(results)||dirty,setStatus('Chạy tracker hoặc mở một run trước khi xem chi tiết.');return;end
  ix=find(strcmp(resultSelect.Items,resultSelect.Value),1);r=results{ix};k=min(scan,numel(r.ids));
  f=uifigure('Name',sprintf('Tracking — bước %d',k),'Position',[150 100 950 700]);g=uigridlayout(f,[2 1]);g.RowHeight={220,'1x'};
  tracks=r.native_tracks{k};if isfield(r,'all_tracks'),tracks=r.all_tracks{k};end
  rows=cell(numel(tracks),4);
  for j=1:numel(tracks),rows(j,:)={tracks(j).TrackID,tracks(j).IsConfirmed,tracks(j).Age,mat2str(tracks(j).State',5)};end
  uitable(g,'Data',rows,'ColumnName',{'Track ID','Confirmed','Age','State'},'ColumnWidth',{80,90,70,650});
  detail='Phiên cũ chưa lưu association diagnostics.';
  if isfield(r,'association'),detail=jsonencode(r.association{k},'PrettyPrint',true);end
  uitextarea(g,'Editable','off','FontName','Consolas','Value',splitlines(string(detail)));
 end
 function presetChanged(~,~)
  if busy,return;end
  old=c;
  try,c=nl_preset(preset.Value);selectedUAV=1;scan=1;markDirty;refresh(true);
  catch ME,c=old;refresh(true);report(ME);end
 end
 function chooseDEM(~,~)
  if busy,return;end
  [f,p]=uigetfile({'*.tif;*.tiff','Geographic WGS84 elevation GeoTIFF'});if isequal(f,0),return;end
  a=inputdlg({'Vĩ độ mốc ENU trong DEM mới','Kinh độ mốc ENU trong DEM mới','h ellipsoid mốc (m)', ...
   'N geoid: h = H DEM + N (m)'},'Nhập DEM; đặt lại vị trí địa lý của cảnh theo mốc này',1, ...
   cellstr(string([c.origin_lla c.mapping.geoid_offset_m])));
  if isempty(a),return;end
  old=c;
  try
   values=str2double(a);assert(all(isfinite(values)),'Use finite numbers for origin/datum.');
   c.mapping.dem_file=fullfile(p,f);c.origin_lla=reshape(values(1:3),1,3);c.mapping.geoid_offset_m=values(4);
   c.mapping.datum_note='User supplied DEM and constant geoid offset; verify survey datum';
   markDirty;refresh(true);
  catch ME,c=old;refresh(true);report(ME);end
 end
 function setRadarAGL(~,~)
  if busy,return;end
  a=inputdlg({'Chiều cao anten trên DEM (m)'},'Đặt AGL radar',1,{num2str(preview.radarAGL)});
  if isempty(a),return;end
  old=c;
  try,c.radar.position_enu_m=nl_set_agl(c,terrain,c.radar.position_enu_m,str2double(a{1}));markDirty;refresh;
  catch ME,c=old;refresh;report(ME);end
 end
 function rebase(~,~)
  if busy,return;end
  a=inputdlg({'Vĩ độ mốc mới','Kinh độ mốc mới','h ellipsoid mốc mới (m)'}, ...
   'Đổi cách biểu diễn ENU; giữ vị trí địa lý',1,cellstr(string(c.origin_lla)));
  if isempty(a),return;end
  old=c;try,n=str2double(a);assert(all(isfinite(n)),'Invalid origin.');c=nl_rebase(c,n);markDirty;refresh(true);
  catch ME,c=old;refresh(true);report(ME);end
 end
 function viewVisibility(~,~)
  if busy,return;end
  busy=true;playing=false;stop(timerObj);setStatus('Đang tính Mapping viewshed; phép tính này có thể cần thời gian.');drawnow;
  try
   [V,t]=nl_viewshed(c);f=figure('Name','Mapping viewshed — visibility only');a=axes(f);
   surf(a,t.E,t.N,t.U,double(V),'EdgeColor','none');view(a,2);axis(a,'equal');colorbar(a);
   xlabel(a,'East m');ylabel(a,'North m');title(a,sprintf('Target AGL %.1f m; LOS only, not probability of detection',c.mapping.viewshed_target_agl_m));
   setStatus('Đã tính viewshed. Vùng nhìn thấy chưa đồng nghĩa radar chắc chắn phát hiện.');
  catch ME,report(ME);end
  busy=false;
 end
 function name=askName(title,default)
  a=inputdlg({'Tên thí nghiệm'},title,1,{default});name='';if ~isempty(a),name=strtrim(a{1});end
 end
 function persistDataset(name)
  [lastFolder,meta]=nl_archive('datasets',name,c,log,{},nl_storage);
  datasetID=meta.id;
 end
 function generateDataset(~,~)
  if busy,return;end
  name=askName('Tạo dataset','Radar_UAV');if isempty(name),return;end
  busy=true;cancelled=false;playing=false;stop(timerObj);
  try
   log=nl_simulate(c,@generationProgress);results={};datasetID='';dirty=false;trackDirty=true;scan=1;
   persistDataset(name);updateResults;redraw;setStatus(['Dataset đã lưu: ' lastFolder]);
  catch ME,report(ME);end
  busy=false;
 end
 function saveDataset(~,~)
  if busy,return;end
  name=askName('Lưu dataset hiện tại','Radar_UAV');if isempty(name),return;end
  try,persistDataset(name);setStatus(['Đã lưu nguyên tập phép đo: ' lastFolder]);catch ME,report(ME);end
 end
 function runAll(~,~)
  if busy,return;end
  name=askName('Mô phỏng + bám','Radar_UAV');if isempty(name),return;end
  busy=true;cancelled=false;playing=false;stop(timerObj);
  try
   log=nl_simulate(c,@generationProgress);results={};datasetID='';dirty=false;trackDirty=true;scan=1;
   persistDataset(name);updateResults;redraw;
   r=nl_track(log,c,@trackingProgress);results={r};trackDirty=false;updateResults;redraw;
   lastFolder=nl_archive('runs',name,c,log,results,nl_storage,datasetID);saveScene;
   setStatus(['Đã lưu dataset và kết quả: ' lastFolder]);
  catch ME,report(ME);end
  busy=false;
 end
 function runTracker(~,~)
  if busy,return;end
  name=askName('Chạy cấu hình tracker',nl_method_label(c.method));if isempty(name),return;end
  busy=true;cancelled=false;playing=false;stop(timerObj);
  try
   assert(~isempty(log)&&strcmp(log.signature,nl_signature(c)),'Generate or open a matching dataset first.');
   if isempty(datasetID),persistDataset([name ' dataset']);end
   r=nl_track(log,c,@trackingProgress);results{end+1}=r;trackDirty=false;dirty=false;updateResults;redraw;
   lastFolder=nl_archive('runs',name,c,log,results,nl_storage,datasetID);saveScene;
   setStatus(['Đã chạy trên cùng dataset và lưu: ' lastFolder]);
  catch ME,report(ME);end
  busy=false;
 end
 function compareTrackers(~,~)
  if busy,return;end
  if isempty(queue),setStatus('Chỉnh tracker → Thêm vào hàng đợi. Có thể thêm nhiều cấu hình của cùng một thuật toán.');return;end
  name=askName('Chạy hàng đợi trên cùng dataset','So_sanh_tracker');if isempty(name),return;end
  busy=true;cancelled=false;playing=false;stop(timerObj);
  try
   assert(~isempty(log)&&strcmp(log.signature,nl_signature(c)),'Open or generate a matching dataset first.');
   if isempty(datasetID),persistDataset([name ' dataset']);end
   configs=queue;
   for j=1:numel(configs)
    cc=c;cc.method=configs{j}.method;cc.tracking=configs{j}.tracking;configs{j}=cc;
   end
   [new,attempts]=nl_batch(log,configs,@trackingProgress);
   results=new;trackDirty=true;updateResults;redraw;
   lastFolder=nl_archive('runs',name,c,log,new,nl_storage,datasetID,attempts);saveScene;
   f=uifigure('Name','Kết quả hàng đợi');g=uigridlayout(f,[1 1]);uitable(g,'Data',struct2table(rmfield(attempts,'config')));
   setStatus(['Đã lưu báo cáo hàng đợi (gồm lỗi/hủy nếu có): ' lastFolder]);
  catch ME,report(ME);end
  busy=false;
 end
 function saveScene
  % Optional pictures must not invalidate an already saved numerical result.
  try,exportgraphics(ax,fullfile(lastFolder,'scene.png'));exportgraphics(metricAx,fullfile(lastFolder,'metrics.png'));
  catch ME,fprintf(2,'Preview export: %s\n',ME.message);end
 end
 function chooseStorage(~,~)
  if busy,return;end
  folder=uigetdir(nl_root,'Chọn thư mục chứa datasets và runs');if isequal(folder,0),return;end
  try,nl_storage(folder);setStatus(['Nơi lưu: ' folder]);catch ME,report(ME);end
 end
 function openOutput(~,~)
  if isempty(lastFolder),lastFolder=nl_storage;end
  if isfolder(lastFolder),winopen(lastFolder);else,setStatus('Chưa có dữ liệu đã lưu.');end
 end
 function openLibrary(~,~)
  if busy,return;end
  try
   T=nl_library;assert(~isempty(T),'Library is empty. Create a dataset first or choose another storage folder.');
   labels=cellstr(T.Type+" | "+T.Name+" | "+T.CreatedUTC+" | "+T.Status);
   [ix,ok]=listdlg('ListString',labels,'SelectionMode','single','PromptString','Mở dataset hoặc kết quả đã lưu','ListSize',[800 400]);
   if ~ok,return;end
   [cc,ll,rr,meta]=nl_open_archive(char(T.Folder(ix)));
   newTerrain=nl_terrain(cc);newPreview=nl_preview(cc,newTerrain);
   c=cc;terrain=newTerrain;preview=newPreview;log=ll;results=rr;dirty=false;trackDirty=false;scan=1;
   if strcmp(meta.kind,'datasets'),datasetID=meta.id;else,datasetID=meta.source_dataset_id;end
   lastFolder=char(T.Folder(ix));refresh;updateResults;redraw;setStatus(['Đã mở và kiểm tra toàn vẹn: ' meta.name]);
  catch ME,report(ME);end
 end
 function ok=generationProgress(k,K,partial)
  if mod(k,5)==0||k==1||k==K
   status.Value={sprintf('Sinh phép đo %d/%d — %d báo cáo ở bước này. Bấm Hủy tính để dừng.',k,K,partial.counts(k))};
   scan=k;drawScene(partial,{});drawnow limitrate;
  end
  ok=~cancelled&&isvalid(fig);
 end
 function ok=trackingProgress(k,K,~)
  if mod(k,5)==0||k==K,status.Value={sprintf('Tracking %d/%d; đang dùng thuật toán toolbox.',k,K)};drawnow limitrate;end
  ok=~cancelled&&isvalid(fig);
 end
 function cancel
  cancelled=true;playing=false;stop(timerObj);
 end
 function updateResults
  if isempty(results),resultSelect.Items={'Chưa có kết quả'};return;end
  items=cell(1,numel(results));for q=1:numel(results),items{q}=sprintf('%02d %s',q,nl_run_label(results{q}.method,results{q}.config));end
  resultSelect.Items=items;resultSelect.Value=items{end};
 end
 function redraw
  if isempty(preview),return;end
  if dirty,drawScene([],{});else,drawScene(log,results);end
  cla(metricAx);hold(metricAx,'on');grid(metricAx,'on');
  if ~dirty&&~isempty(results)
   for q=1:numel(results),plot(metricAx,log.times,results{q}.gospa,'DisplayName',sprintf('%d %s',q,nl_run_label(results{q}.method,results{q}.config)));end
   ylabel(metricAx,'GOSPA m');legend(metricAx,'show','Interpreter','none','Location','best');
   title(metricAx,'So sánh trên cùng phép đo; chỗ trống = không có lượt đo / không có truth');
  else
   plot(metricAx,preview.times,vecnorm(preview.V(:,:,selectedUAV),2,2));ylabel(metricAx,'Speed m/s');
   title(metricAx,'Tốc độ UAV đang chọn (native waypointTrajectory)');
  end
  xlabel(metricAx,'Time s');
  scan=min(scan,c.frames);slider.Value=scan;timeLabel.Text=sprintf('%.2f s | %d/%d',(scan-1)*c.dt,scan,c.frames);
  label='XEM TRƯỚC — kết quả mô phỏng chưa cập nhật';
  if ~dirty,label='KẾT QUẢ từ tập phép đo đã lưu';end
  if ~dirty&&trackDirty,label=[label ' | CẤU HÌNH TRACKER MỚI CHƯA CHẠY'];end
  u=c.uavs(selectedUAV);p=preview.P(scan,:,selectedUAV);
  info.Value={label;sprintf('%s: ENU [%.1f %.1f %.1f] m | AGL %.1f m | tốc độ %.2f m/s',u.name,p,preview.AGL(scan,selectedUAV),norm(preview.V(scan,:,selectedUAV))); ...
   sprintf('Anten AGL %.2f m | gốc [%.6f %.6f %.3f] | N geoid %.3f m',preview.radarAGL,c.origin_lla,c.mapping.geoid_offset_m); ...
   'Chùm quan sát biểu diễn hình học; xác suất phát hiện và che khuất được tính riêng.'};
  if ~dirty&&~isempty(log)&&strcmp(log.source,'real_csv')
   info.Value={label;'Đang phát dữ liệu radar CSV. Không có truth UAV; không dùng đường bay cấu hình làm dữ liệu thật.'; ...
    sprintf('Thời gian %.3f s, %d phép đo. ENU theo mốc cấu hình.',log.times(scan),log.counts(scan)); ...
    'Số điểm bằng 0 tại một lượt đo hợp lệ khác với thời điểm radar không cập nhật.'};
  end
 end
 function drawScene(activeLog,activeResults)
  cla(ax);hold(ax,'on');grid(ax,'on');
  nl_plot_map(ax,c,terrain,showOSM.Value);
  colors=lines(numel(c.uavs));
  if showTruth.Value&&~(~isempty(activeLog)&&strcmp(activeLog.source,'real_csv'))
   for j=1:numel(c.uavs)
    p=preview.P(:,:,j);plot3(ax,p(:,1),p(:,2),p(:,3),'-','Color',colors(j,:),'LineWidth',1.6,'HitTest','off');
    if scan>=c.uavs(j).birth_scan&&scan<=c.uavs(j).death_scan
     plot3(ax,p(scan,1),p(scan,2),p(scan,3),'^','MarkerFaceColor',colors(j,:),'Color',colors(j,:),'MarkerSize',9,'HitTest','off');
    end
   end
  end
  if isempty(activeLog)||~strcmp(activeLog.source,'real_csv')
  u=c.uavs(selectedUAV);p=u.waypoints_enu_m;
  plot3(ax,p(:,1),p(:,2),p(:,3),'--','Color',colors(selectedUAV,:),'Tag','SelectedWaypoints','HitTest','off');
  for k=1:size(p,1)
   plot3(ax,p(k,1),p(k,2),p(k,3),'o','Color',colors(selectedUAV,:),'MarkerFaceColor','w','MarkerSize',9, ...
    'ButtonDownFcn',@(src,event)dragStart(src,event,selectedUAV,k),'PickableParts','all');
  end
  end
  r=c.radar.position_enu_m;plot3(ax,r(1),r(2),r(3),'ks','MarkerFaceColor','k','MarkerSize',10,'HitTest','off');
  look=[0 0];if ~isempty(activeLog)&&isfield(activeLog,'look_angle'),look=activeLog.look_angle(min(scan,size(activeLog.look_angle,1)),:);end
  faces=nl_faces(c);
  for face=1:numel(faces)
   if ~isempty(activeLog)&&isfield(activeLog,'face_look_angle')
    angle=activeLog.face_look_angle(scan,:,face);
   elseif ~isempty(preview.scan)
    angle=preview.scan.look(scan,:,face);
   else,angle=look;end
   if showCoverage.Value&&~isempty(faces(face).coverage)
    edges=faces(face).coverage;drawSector(faces(face).radar,edges,[.65 .67 .68],':');
   end
   drawCoverage(angle,faces(face).radar);
  end
  if c.clutter.scatterers_enabled&&~isempty(c.clutter.scatterers)
   s=c.clutter.scatterers;p=[s(:,1:2) zeros(size(s,1),1)];[g,~,~]=nl_ground(c,terrain,p);p(:,3)=g+s(:,3);
   plot3(ax,p(:,1),p(:,2),p(:,3),'x','Color',[.4 .4 .4],'MarkerSize',9,'LineWidth',2,'HitTest','off');
  end
  if ~isempty(activeLog)&&showDets.Value&&scan<=numel(activeLog.detections)
   ds=activeLog.detections{scan};for j=1:numel(ds),p=ds{j}.Measurement;plot3(ax,p(1),p(2),p(3),'r.','MarkerSize',15,'HitTest','off');end
  end
  if ~isempty(activeResults)&&showTracks.Value
   chosen=find(strcmp(resultSelect.Items,resultSelect.Value),1);chosen=min(chosen,numel(activeResults));res=activeResults{chosen};
   ids=unique(vertcat(res.ids{1:scan}));
   for j=1:numel(ids)
    p=nan(scan,3);
    for k=1:scan,ix=find(res.ids{k}==ids(j),1);if ~isempty(ix),p(k,:)=res.estimates{k}(ix,:);end,end
    valid=all(isfinite(p),2);pv=p(valid,:);
    plot3(ax,pv(:,1),pv(:,2),pv(:,3),'o-.','Color',[.42 .12 .6],'MarkerSize',4,'LineWidth',2.2,'HitTest','off');
    last=find(all(isfinite(p),2),1,'last');if ~isempty(last),text(ax,p(last,1),p(last,2),p(last,3),sprintf(' T%d',ids(j)),'HitTest','off');end
   end
  end
  xlabel(ax,'Đông (m)');ylabel(ax,'Bắc (m)');zlabel(ax,'Cao độ ENU (m)');axis(ax,'equal');
  xlim(ax,c.bounds_enu_m(1,:));ylim(ax,c.bounds_enu_m(2,:));zlim(ax,[min(-30,min(terrain.U(:),[],'omitnan')) c.bounds_enu_m(3,2)]);
  if fullRadar.Value
   radius=c.radar.range_limits_m(2);xlim(ax,c.radar.position_enu_m(1)+[-radius radius]);
   ylim(ax,c.radar.position_enu_m(2)+[-radius radius]);
  end
  ax.XTick=niceTicks(ax.XLim,4);ax.YTick=niceTicks(ax.YLim,3);ax.ZTick=niceTicks(ax.ZLim,3);
  ax.XAxis.Exponent=0;ax.YAxis.Exponent=0;ax.ZAxis.Exponent=0;
  ax.FontSize=9;ax.LabelFontSizeMultiplier=1.1;ax.TitleFontSizeMultiplier=1.15;
  ax.TickDir='out';ax.TickLength=[.008 .008];ax.GridAlpha=.14;
  ax.Color=[.99 .995 .99];ax.Projection='orthographic';
  if strcmp(viewMode.Value,'2D')
   radius=c.radar.range_limits_m(2);zlim(ax,c.radar.position_enu_m(3)+[-radius radius]);
   view(ax,2);daspect(ax,[1 1 1]);
  else
   if strcmp(verticalScale.Value,'Auto')
    gain=.34*max(diff(ax.XLim),diff(ax.YLim))/diff(ax.ZLim);
   else,gain=str2double(verticalScale.Value);end
   view(ax,[-38 26]);daspect(ax,[1 1 1/gain]);
  end
  nl_legend(ax,c,showTruth.Value,showDets.Value,showTracks.Value,~isempty(activeLog)&&strcmp(activeLog.source,'real_csv'),selectedUAV);
  device=nl_device(c);
  title(ax,sprintf('%.2f s | %s | %s',(scan-1)*c.dt,device.profile,device.operation),'Interpreter','none','FontWeight','normal');
 end
 function ticks=niceTicks(limits,intervals)
  raw=diff(limits)/intervals;power=10^floor(log10(raw));choices=[1 2 5 10]*power;
  step=choices(find(choices>=raw,1));
  ticks=(ceil(limits(1)/step):floor(limits(2)/step))*step;
 end
 function drawCoverage(look,r)
  % Reproduce documented mounting/look-angle rotations for a visual beam boundary.
  B=[0 1 0;1 0 0;0 0 -1];
  M=rot(90-r.heading_enu_deg,r.tilt_deg,r.roll_deg)*rot(look(1),-look(2),0);
  az=linspace(-r.field_of_view_deg(1)/2,r.field_of_view_deg(1)/2,32);el=r.field_of_view_deg(2)/2;
  for elev=[-el el]
   dir=[cosd(elev)*cosd(az);cosd(elev)*sind(az);-sind(elev)*ones(size(az))];
   p=(B*M*dir*r.range_limits_m(2))'+r.position_enu_m;
   plot3(ax,p(:,1),p(:,2),p(:,3),'Color',[.3 .65 .8],'HitTest','off');
   for k=[1 size(p,1)],v=[r.position_enu_m;p(k,:)];plot3(ax,v(:,1),v(:,2),v(:,3),'Color',[.3 .65 .8],'HitTest','off');end
  end
 end
 function drawSector(r,edges,color,style)
  B=[0 1 0;1 0 0;0 0 -1];M=nl_rotation(90-r.heading_enu_deg,r.tilt_deg,r.roll_deg);
  az=linspace(edges(1,1),edges(1,2),45);
  for el=edges(2,:)
   dir=[cosd(el)*cosd(az);cosd(el)*sind(az);-sind(el)*ones(size(az))];
   p=(B*M*dir*r.range_limits_m(2))'+r.position_enu_m;
   plot3(ax,p(:,1),p(:,2),p(:,3),style,'Color',color,'HitTest','off');
   for ix=[1 size(p,1)],q=[r.position_enu_m;p(ix,:)];plot3(ax,q(:,1),q(:,2),q(:,3),style,'Color',color,'HitTest','off');end
  end
 end
 function M=rot(y,p,r)
  M=[cosd(y) -sind(y) 0;sind(y) cosd(y) 0;0 0 1]* ...
   [cosd(p) 0 sind(p);0 1 0;-sind(p) 0 cosd(p)]* ...
   [1 0 0;0 cosd(r) -sind(r);0 sind(r) cosd(r)];
 end
 function togglePlay(~,~)
  if busy,return;end
  playing=~playing;if playing,start(timerObj);else,stop(timerObj);end
 end
 function tick(~,~)
  if ~isvalid(fig)||busy||~playing,return;end
  scan=scan+1;if scan>c.frames,scan=c.frames;playing=false;stop(timerObj);end
  redraw;
 end
 function step(~,~)
  if busy,return;end
  playing=false;stop(timerObj);scan=min(scan+1,c.frames);redraw;
 end
 function resetTime(~,~)
  if busy,return;end
  playing=false;stop(timerObj);scan=1;redraw;
 end
 function seek(~,event)
  if busy,return;end
  scan=round(event.Value);redraw;
 end
 function saveConfig(~,~)
  if busy,return;end
  [f,p]=uiputfile('*.json','Lưu cấu hình','native_session.json');if isequal(f,0),return;end
  try,writeText(fullfile(p,f),jsonencode(c,'PrettyPrint',true));setStatus(['Đã lưu cấu hình: ' fullfile(p,f)]);catch ME,report(ME);end
 end
 function loadSession(~,~)
  if busy,return;end
  [f,p]=uigetfile({'*.json;*.mat','Session JSON / native_session.mat'});if isequal(f,0),return;end
  old=c;
  try
   if isfile(fullfile(p,'archive.json'))&&any(strcmp(f,{'archive.json','native_session.mat','session.json'}))
    [cc,ll,rr,meta]=nl_open_archive(p);newTerrain=nl_terrain(cc);newPreview=nl_preview(cc,newTerrain);
    c=cc;terrain=newTerrain;preview=newPreview;log=ll;results=rr;dirty=false;trackDirty=false;scan=1;
    lastFolder=p;refresh;updateResults;redraw;
   elseif endsWith(f,'.json','IgnoreCase',true)
    cc=jsondecode(fileread(fullfile(p,f)));cc=normalize(cc);nl_validate(cc);c=cc;markDirty;refresh(true);
   else
    s=load(fullfile(p,f));assert(isfield(s,'c')&&isfield(s,'log')&&isfield(s,'results'),'Not a native lab session MAT.');
    c=normalize(s.c);nl_validate(c);markDirty;refresh(true);log=s.log;results=s.results;
    dirty=isempty(log)||~strcmp(log.signature,nl_signature(c));trackDirty=false;updateResults;redraw;
   end
   datasetID='';setStatus(['Đã mở ' fullfile(p,f)]);
  catch ME,c=old;refresh(true);report(ME);end
 end
 function cc=normalize(cc)
  cc.tracking=nl_tracking_defaults(cc.tracking);
  cc.origin_lla=reshape(cc.origin_lla,1,3);cc.radar.position_enu_m=reshape(cc.radar.position_enu_m,1,3);
  cc.radar.field_of_view_deg=reshape(cc.radar.field_of_view_deg,1,2);cc.radar.range_limits_m=reshape(cc.radar.range_limits_m,1,2);
  cc.radar.azimuth_scan_limits_deg=reshape(cc.radar.azimuth_scan_limits_deg,1,2);cc.radar.elevation_scan_limits_deg=reshape(cc.radar.elevation_scan_limits_deg,1,2);
  cc.radar.electronic_azimuth_limits_deg=reshape(cc.radar.electronic_azimuth_limits_deg,1,2);cc.radar.electronic_elevation_limits_deg=reshape(cc.radar.electronic_elevation_limits_deg,1,2);
  cc.tracking.confirmation_history=reshape(cc.tracking.confirmation_history,1,2);cc.tracking.deletion_history=reshape(cc.tracking.deletion_history,1,2);
  cc.uavs=reshape(cc.uavs,[],1);for j=1:numel(cc.uavs),cc.uavs(j).arrival_s=cc.uavs(j).arrival_s(:);end
  if isempty(cc.clutter.scatterers),cc.clutter.scatterers=zeros(0,4);elseif isvector(cc.clutter.scatterers),cc.clutter.scatterers=reshape(cc.clutter.scatterers,1,4);end
 end
 function exportRun(~,~)
  if busy,return;end
  name=askName('Lưu các kết quả đang mở','Ket_qua');if isempty(name),return;end
  try
   assert(~dirty&&~isempty(log)&&~isempty(results),'Open or run a dataset with tracking results first.');
   lastFolder=nl_archive('runs',name,c,log,results,nl_storage,datasetID);saveScene;
   setStatus(['Đã lưu kết quả; mỗi lần chạy giữ cấu hình riêng trong MAT: ' lastFolder]);
  catch ME,report(ME);end
 end
 function showCommands(~,~)
  f=uifigure('Name','Cấu hình MATLAB có thể chạy lại','Position',[120 100 1000 740]);
  g=uigridlayout(f,[2 1]);g.RowHeight={'1x',38};
  uitextarea(g,'Value',splitlines(string(nl_commands(c))),'Editable','off','FontName','Consolas');
  row=uigridlayout(g,[1 3]);row.Padding=[0 0 0 0];
  uibutton(row,'Text','Mở mã radar native','ButtonPushedFcn',@(~,~)edit(fullfile(nl_root,'native_lab','nl_radar.m')));
  uibutton(row,'Text','Mở mã UAV + mô phỏng','ButtonPushedFcn',@(~,~)edit(fullfile(nl_root,'native_lab','nl_simulate.m')));
  uibutton(row,'Text','Mở factory tracker gốc','ButtonPushedFcn',@(~,~)edit(fullfile(nl_root,'src','make_tracker.m')));
 end
 function importCSV(~,~)
  if busy,return;end
  [f,p]=uigetfile('*.csv','Chọn detections_enu.csv');if isequal(f,0),return;end
  try
   updates=fullfile(p,'updates.csv');if ~isfile(updates),updates='';end
   imported=nl_import_csv(fullfile(p,f),c,updates);log=imported;results={};datasetID='';dirty=false;trackDirty=true;
   updateResults;redraw;setStatus('Đã nhập detections ENU. Không có truth nên không tính OSPA/GOSPA. Nhấn Chạy lại tracker.');
  catch ME,report(ME);end
 end
 function runIQ(~,~)
  if busy,return;end
  busy=true;playing=false;stop(timerObj);setStatus('Đang tính clutter IQ native; không thay tập điểm đo của cảnh...');drawnow;
  try
   iq=nl_iq(c,true);base=fullfile(nl_root,'results','native_iq');if ~isfolder(base),mkdir(base);end
   folder=tempname(base);mkdir(folder);save(fullfile(folder,'clutter_iq.mat'),'iq','c','-v7.3');
   setStatus(['Đã lưu bài IQ riêng: ' folder]);
  catch ME,report(ME);end
  busy=false;
 end
 function checkTools(~,~)
  try,T=NATIVE_LAB_CHECK;f=uifigure('Name','API presence — not execution test');g=uigridlayout(f,[1 1]);uitable(g,'Data',T);catch ME,report(ME);end
 end
 function lessonChanged(~,~)
  i=find(strcmp({lessons.title},lessonSelect.Value),1);lessonText.Value=splitlines(string(lessons(i).text));
 end
 function openDesigner(name)
  try,feval(name);catch ME,report(ME);end
 end
 function setStatus(message)
  if isvalid(fig),status.Value=splitlines(string(message));end
 end
 function report(ME)
  message=getReport(ME,'extended','hyperlinks','off');fprintf(2,'%s\n',message);
  setStatus(['Không hoàn tất: ' ME.message]);
  base=fullfile(nl_root,'results','native_errors');if ~isfolder(base),mkdir(base);end
  writeText([tempname(base) '.txt'],message);
  if isvalid(fig)&&visible,uialert(fig,ME.message,'Kiểm tra cấu hình / API');end
 end
 function closeApp(~,~)
  if busy,cancelled=true;setStatus('Đã yêu cầu hủy. Đợi phép tính hiện tại trả về rồi đóng cửa sổ.');return;end
  stop(timerObj);delete(timerObj);delete(fig);
 end
end
function writeText(path,text)
f=fopen(path,'w','n','UTF-8');assert(f>=0,'Cannot write file.');cl=onCleanup(@()fclose(f));fprintf(f,'%s',text); %#ok<NASGU>
end
