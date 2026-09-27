function training_app()
% Transparent JSON editor: the saved snapshot is exactly the configuration run.
root=training_root;c=training_config;catalog=training_catalog;
f=uifigure('Name','Noi Bai | Toolbox Mastery R2025a','Position',[80 60 1200 790]);
grid=uigridlayout(f,[5 2]);grid.RowHeight={45,40,'1x',40,65};grid.ColumnWidth={'1x','1x'};
head=uilabel(grid,'Text','NOI BAI — TOOLBOX MASTERY','FontSize',22,'FontWeight','bold');head.Layout.Column=[1 2];
pick=uidropdown(grid,'Items',cellstr(catalog.id+' | '+catalog.title),'ItemsData',cellstr(catalog.id));
pick.Layout.Row=2;pick.Layout.Column=1;
buttons=uigridlayout(grid,[1 3]);buttons.Layout.Row=2;buttons.Layout.Column=2;
uibutton(buttons,'Text','Kiểm tra toolbox','ButtonPushedFcn',@(~,~)inventory());
uibutton(buttons,'Text','Mở cấu hình','ButtonPushedFcn',@(~,~)loadConfig());
uibutton(buttons,'Text','Hướng dẫn','ButtonPushedFcn',@(~,~)web(fullfile(root,'training','README_VI.html'),'-browser'));
editor=uitextarea(grid,'Value',splitlines(string(jsonencode(c,'PrettyPrint',true))),'FontName','Consolas');
editor.Layout.Row=3;editor.Layout.Column=1;
notes=uitextarea(grid,'Editable','off','Value',{
 'BẮT ĐẦU: chọn 01_trajectory → Chạy bài.';
 'Cấu hình JSON bên trái chính là cấu hình sẽ chạy.';
 '';
 'QUỸ ĐẠO: uavs → waypoints_enu_m, arrival_s.';
 'Mỗi hàng waypoint = [Đông, Bắc, Cao], đơn vị mét.';
 'UAV: rcs_m2, birth_scan, death_scan, speed_limit_mps.';
 'RADAR: radar → vị trí, Pd, RCS tham chiếu, FOV, phân giải.';
 'MÔI TRƯỜNG: environment → terrain_los, clearance_m, wind_enu_mps.';
 'TÍN HIỆU: signal → Fs, B, PRF, pulse_width, pulses, vận tốc.';
 '';
 'GIỮ frames=160 khi xuất dữ liệu sang benchmark cũ.';
 'Nhánh tín hiệu 05 và nhánh điểm đo 03 là hai mô hình riêng.';
 'Đổi pulse_width ở 05 không tự đổi kết quả ở 03.';
 'Gió ở 01/03 là trôi động học; không phải mô hình lực bay.';
 'Altitude WGS84 trong bài 02/09 dùng origin_lla(3) giả định.';
 '';
 '13: tạo và chạy mô hình Simulink bậc nhất.';
 '14: tạo khung 6DOF, cần cấu hình vật lý trước khi mô phỏng.';
 '15: sinh mã C; không tự biên dịch MEX.';
 '16: dựng thế giới 3D trong workspace; mở viewer bằng lệnh riêng.';
 '';
 'Mỗi lần chạy tạo thư mục mới và lưu config.json + status.json.';
 'FAILED không được xem là đã chạy thành công.';
 'Thực hành bằng mô phỏng; các thông số mặc định là giả định.'});
notes.Layout.Row=3;notes.Layout.Column=2;
bar=uigridlayout(grid,[1 4]);bar.Layout.Row=4;bar.Layout.Column=[1 2];
uibutton(bar,'Text','Kiểm tra cấu hình','ButtonPushedFcn',@(~,~)check());
uibutton(bar,'Text','Lưu cấu hình','ButtonPushedFcn',@(~,~)saveConfig());
runButton=uibutton(bar,'Text','Chạy bài','ButtonPushedFcn',@(~,~)execute());
uibutton(bar,'Text','Mở kết quả','ButtonPushedFcn',@(~,~)openOutput());
status=uitextarea(grid,'Editable','off','Value',{'Sẵn sàng. Đọc hướng dẫn trước bài nâng cao.'});
status.Layout.Row=5;status.Layout.Column=[1 2];lastOut='';
 function parsed=readEditor()
  parsed=training_normalize(jsondecode(strjoin(string(editor.Value),newline)));training_validate(parsed);
 end
 function check()
  try,readEditor();status.Value={'Cấu hình hợp lệ về cấu trúc. Quỹ đạo và DEM được kiểm tra thêm khi chạy.'};
  catch ME,uialert(f,ME.message,'Cấu hình chưa hợp lệ');end
 end
 function inventory()
  T=training_check;status.Value=cellstr(T.id+": "+string(T.available)+" "+T.missing);
 end
 function loadConfig()
  [file,folder]=uigetfile('*.json','Chọn cấu hình',fullfile(root,'training','config'));
  if isequal(file,0),return;end
  try,c=training_config(fullfile(folder,file));editor.Value=splitlines(string(jsonencode(c,'PrettyPrint',true)));
  catch ME,uialert(f,ME.message,'Không mở được cấu hình');end
 end
 function saveConfig()
  try,parsed=readEditor();catch ME,uialert(f,ME.message,'Cấu hình chưa hợp lệ');return;end
  [file,folder]=uiputfile('*.json','Lưu cấu hình mới',fullfile(root,'training','config','my_experiment.json'));
  if isequal(file,0),return;end
  writeConfig(fullfile(folder,file),parsed);status.Value={['Đã lưu: ' fullfile(folder,file)]};
 end
 function execute()
  try,parsed=readEditor();catch ME,uialert(f,ME.message,'Cấu hình chưa hợp lệ');return;end
  base=fullfile(root,'results','training');if ~isfolder(base),mkdir(base);end
  inputFile=[tempname(base) '.json'];writeConfig(inputFile,parsed);
  [~,tag]=fileparts(tempname(base));lastOut=fullfile(base,[pick.Value '_' tag]);
  runButton.Enable='off';status.Value={['Đang chạy ' pick.Value];['Kết quả: ' lastOut]};drawnow;
  try,res=training_run(pick.Value,inputFile,lastOut);status.Value={res.status;res.output};
  catch ME,status.Value={'FAILED';ME.message;lastOut};uialert(f,ME.message,'Bài thực hành thất bại');end
  if isfile(inputFile),delete(inputFile);end
  runButton.Enable='on';
 end
 function openOutput()
  if isempty(lastOut)||~isfolder(lastOut),uialert(f,'Chưa có kết quả.','Kết quả');return;end
  winopen(lastOut);
 end
end
function writeConfig(path,c)
fid=fopen(path,'w','n','UTF-8');assert(fid>=0,'Cannot write configuration.');cl=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(c,'PrettyPrint',true));
end
