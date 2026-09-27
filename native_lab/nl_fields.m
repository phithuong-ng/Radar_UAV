function rows=nl_fields(c,group)
% path, Vietnamese label, editable value, unit, native API / interpretation.
switch group
 case 'device'
  c.device=nl_device(c);
  spec={
  'profile','Hồ sơ thiết bị','','Generic | RX-R417C (mô phỏng, không kết nối phần cứng)';
  'operation','Nhiệm vụ quét','','Search: quét các mặt bật | Focus: chỉ quét mặt được chọn';
  'face_offsets_deg','Hướng bốn mặt tương đối','deg','[0,90,180,270] so với hướng đế; cùng tâm pha giả định';
  'faces_enabled','Bật các mặt 1/2/3/4','','[true,true,true,true]';
  'focus_face','Mặt dùng trong Focus','1..4','Mặt phải được bật; các mặt khác nghỉ trong bài Focus';
  'focus_azimuth_deg','Vùng Focus: phương vị','deg','Hai BIÊN góc trong hệ của mặt anten; [min,max]';
  'focus_elevation_deg','Vùng Focus: góc ngẩng','deg','Hai BIÊN góc trong hệ của mặt anten; [min,max]';
  'scan_aware_tracking','Bám xét chùm đang quét','true/false','GNN/JPDA: chỉ tính miss khi vị trí dự đoán nằm trong chùm; không dùng truth'};
 case 'radar'
  spec={
  'position_enu_m','Vị trí anten [E,N,U]','m','MountingLocation; ENU đổi sang NED';
  'heading_enu_deg','Hướng: 0 Đông, 90 Bắc','deg','MountingAngles yaw = 90 - hướng ENU';
  'tilt_deg','Góc ngẩng anten','deg','MountingAngles pitch';
  'roll_deg','Góc lăn anten','deg','MountingAngles roll';
  'mode','Chế độ quét','','No scanning | Rotator | Sector | Raster';
  'scan_technology','Cách quét','','Mechanical | Electronic | Mechanical and electronic; bỏ qua khi No scanning';
  'update_every_steps','Đo mỗi N bước','bước','UpdateRate = 1/(dt*N); tracker chỉ cập nhật khi có lượt đo';
  'scan_rate_deg_s','Tốc độ quét cơ khí','deg/s','MaxAzimuthScanRate';
  'elevation_scan_rate_deg_s','Tốc độ quét đứng cơ khí','deg/s','MaxElevationScanRate';
  'electronic_azimuth_limits_deg','Giới hạn quét điện tử ngang','deg','ElectronicAzimuthLimits';
  'electronic_elevation_limits_deg','Giới hạn quét điện tử đứng','deg','ElectronicElevationLimits';
  'azimuth_scan_limits_deg','Giới hạn quét ngang','deg','MechanicalAzimuthLimits, Sector/Raster';
  'elevation_scan_limits_deg','Giới hạn quét đứng','deg','MechanicalElevationLimits, Sector/Raster';
  'field_of_view_deg','Bề rộng chùm [ngang,đứng]','deg','FieldOfView; không phải toàn bộ vùng quét';
  'range_limits_m','Khoảng cách [min,max]','m','RangeLimits';
  'frequency_hz','Tần số','Hz','CenterFrequency';
  'reference_range_m','Khoảng cách tham chiếu','m','ReferenceRange';
  'reference_rcs_m2','RCS tham chiếu','m²','ReferenceRCS = 10*log10(m²) dBsm';
  'detection_probability','Pd tại mục tiêu tham chiếu','0..1','DetectionProbability, không phải Pd cố định mọi nơi';
  'range_resolution_m','Độ phân giải cự ly','m','RangeResolution, không phải sigma trực tiếp';
  'azimuth_resolution_deg','Độ phân giải góc ngang','deg','AzimuthResolution';
  'elevation_resolution_deg','Độ phân giải góc đứng','deg','ElevationResolution';
  'noise','Thêm nhiễu đo','true/false','HasNoise';
  'range_bias_fraction','Bias cự ly theo độ phân giải','','RangeBiasFraction';
  'azimuth_bias_fraction','Bias góc ngang theo độ phân giải','','AzimuthBiasFraction';
  'elevation_bias_fraction','Bias góc đứng theo độ phân giải','','ElevationBiasFraction'};
  d=nl_device(c);
  if strcmp(d.profile,'RX-R417C')
   hide={'mode','scan_technology','scan_rate_deg_s','elevation_scan_rate_deg_s','azimuth_scan_limits_deg','elevation_scan_limits_deg'};
   spec=spec(~ismember(spec(:,1),hide),:);
   spec(strcmp(spec(:,1),'electronic_azimuth_limits_deg'),2:4)={'Biên vùng Search ngang','deg','Biên phủ mỗi mặt, không phải tâm chùm; mặc định [-45,45]'};
   spec(strcmp(spec(:,1),'electronic_elevation_limits_deg'),2:4)={'Biên vùng Search đứng','deg','Biên phủ mỗi mặt; mặc định [0,60]'};
   spec(strcmp(spec(:,1),'field_of_view_deg'),2:4)={'Chùm thử nghiệm [ngang,đứng]','deg','Giả định; chia đều vùng phủ, có thể thu nhỏ để khớp ô cuối. Không phải thông số hãng'};
  end
 case 'mapping' 
  spec={
  'dem_file','Tệp DEM/DSM GeoTIFF','','WGS84 geographic, cao độ trực giao mét';
  'geoid_offset_m','N: ellipsoid h = H + N','m','H từ DEM; N hằng chỉ phù hợp vùng nhỏ đã hiệu chuẩn';
  'datum_note','Ghi chú mốc cao độ','','N=0 mặc định là giả định demo, không phải số đo';
  'terrain_los','Che khuất bởi địa hình','true/false','Mapping los2';
  'effective_earth_factor','Hệ số bán kính hiệu dụng','','los2 apparent radius / actual radius';
  'minimum_agl_m','Khoảng hở UAV tối thiểu','m','Kiểm tra cao độ UAV so với DEM';
  'viewshed_target_agl_m','AGL mục tiêu cho viewshed','m','viewshed: độ cao mục tiêu giả định trên địa hình'};
 case 'clutter'
  spec={
  'false_alarms','Báo động giả ngẫu nhiên','true/false','radarDataGenerator.HasFalseAlarms';
  'pfa','Xác suất báo giả mỗi ô phân giải','0..1','FalseAlarmRate; không phải số điểm giả/scan';
  'scatterers_enabled','Bật điểm phản xạ tĩnh','true/false','Các platform RCS đứng yên; không phải mô hình mặt đất phân bố'};
 case 'session'
  spec={
  'seed','Seed ngẫu nhiên','','Lặp cùng cấu hình và seed để tái hiện';
  'dt','Bước thời gian','s','uavScenario.UpdateRate = 1/dt';
  'frames','Số bước mô phỏng','','Đổi dt/frames sẽ co giãn thời gian waypoint';
  'bounds_enu_m','Miền [Emin Emax;Nmin Nmax;Umin Umax]','m','Nhập JSON [[...],[...],[...]]; kiểm tra quỹ đạo và mật độ tracker'};
 case 'iq'
  spec={
  'sample_rate_hz','Tần số lấy mẫu','Hz','SampleRate';
  'prf_hz','Tần số lặp xung','Hz','PRF';
  'pulse_width_s','Độ dài xung LFM','s','phased.LinearFMWaveform.PulseWidth';
  'bandwidth_hz','Băng thông LFM','Hz','SweepBandwidth';
  'pulses','Số xung','','NumPulses / coherent processing interval';
  'array_elements','Số phần tử ULA','','phased.ULA, khoảng cách lambda/2';
  'gamma_db','Gamma địa hình','dB','constantGammaClutter.Gamma';
  'height_m','Cao radar so mặt phẳng','m','PlatformHeight; bài IQ riêng, không lấy DSM';
  'speed_mps','Tốc độ platform radar','m/s','PlatformSpeed';
  'depression_deg','Góc chúc xuống','deg','constantGammaClutter.MountingAngles';
  'max_range_m','Cự ly clutter lớn nhất','m','ClutterMaxRange';
  'azimuth_span_deg','Góc phủ clutter','deg','ClutterAzimuthSpan';
  'patch_azimuth_deg','Bề rộng patch','deg','PatchAzimuthSpan';
  'transmit_erp_w','ERP phát','W','Biên độ tín hiệu phát dùng sqrt(ERP)';
  'cfar_pfa','Pfa CFAR','0..1','phased.CFARDetector';
  'steer_deg','Hướng ULA để xem beam','deg','phased.SteeringVector; không áp vào radar thống kê'};
 case 'tracking'
  names=nl_tracking_keys(c);spec=cell(0,4);
  for j=1:numel(names)
   key=names{j};if any(strcmp(key,{'description','temporal_support','tuning'})),continue;end
   spec(end+1,:)={key,key,'','Tham số bộ tracker gốc; xem hướng dẫn tham số'}; %#ok<AGROW>
  end
  labels={
   'assignment_threshold','Ngưỡng gate (khoảng cách chuẩn hóa bình phương)';
   'measurement_variance_scale','Nhân R (ma trận phương sai), không phải nhân sigma';
   'acceleration_std_mps2','Độ lệch chuẩn gia tốc CV / CT (m/s²)';
   'jerk_std_mps3','Độ lệch chuẩn jerk CA (m/s³)';
   'confirmation_history','Xác nhận track [M,N]';
   'deletion_history','Xóa track [M,N]';
   'gnn_logic','GNN: History hoặc Score';
   'jpda_logic','JPDA: History hoặc Integrated';
   'clutter_expected_per_update','Số clutter kỳ vọng mỗi lượt đo: prior do người dùng đặt';
   'imm_stay_probability','IMM: xác suất giữ mô hình';
   'metric_cutoff_m','Khoảng cách cắt OSPA/GOSPA (m)'};
  labels(end+1,:)={'max_initialization_seconds','Giới hạn lần đầu gọi tracker native (s)'};
  labels=[labels;{
   'jpda_max_events','JPDA: số sự kiện k-best; nhập all để xét đầy đủ';
   'tracker_properties_json','Thuộc tính tracker nâng cao (JSON)';
   'filter_properties_json','Thuộc tính filter nâng cao (JSON)';
   'filter_seed','Seed bộ lọc: tái hiện Particle Filter';
   'pf_particles','Particle Filter: số hạt';
   'pf_resampling','Particle Filter: cách lấy mẫu lại';
   'imm_transition','IMM: ma trận chuyển CV/CA/CT; [] dùng xác suất giữ';
   'imm_initial_probabilities','IMM: xác suất ban đầu [CV,CA,CT]';
   'custom_initializer','Tên hàm khởi tạo filter tùy chọn';
   'custom_position_indices','Chỉ số E,N,U trong state tùy chọn'}];
  labels(end+1,:)={'max_scan_seconds','Giới hạn mỗi bước sau khởi tạo (s)'};
  labels(end+1,:)={'max_run_seconds','Giới hạn thời gian tính cộng dồn, trừ lần khởi tạo (s)'};
  for j=1:size(labels,1),k=strcmp(spec(:,1),labels{j,1});spec(k,2)=labels(j,2);end
 otherwise,error('Unknown property group.');
end
rows=cell(size(spec,1),5);
for j=1:size(spec,1)
 key=spec{j,1};if strcmp(group,'session'),v=c.(key);else,v=c.(group).(key);end
 if ischar(v)||isstring(v),value=char(v);else,value=jsonencode(v);end
 rows(j,:)={key,spec{j,2},value,spec{j,3},spec{j,4}};
end
end
