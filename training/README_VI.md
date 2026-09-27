# Nội Bài • Toolbox Mastery

Nhánh thực hành bổ sung cho **NoiBai_Radar_v8_4_FULL_R2025a**, hướng tới MATLAB R2025a. Giữ nguyên toàn bộ project gốc, 80 dataset, DEM và OSM. Điểm vào mới: **START_TRAINING**. Có 16 bài học phủ 19 sản phẩm trong ảnh của bạn, từ bài nền tảng đến bài mở rộng.

Đây là bộ thực hành để học cách dùng công cụ và đọc kết quả. Không đồng nghĩa đã mô phỏng đầy đủ mọi chức năng của 19 toolbox, hay đã có mô hình radar/UAV thực được hiệu chuẩn. Trạng thái kiểm thử thực tế nằm trong `training/VALIDATION.md`.

## 1. Chạy lần đầu

1. Giải nén ZIP vào một thư mục mới, tránh trộn với các bản project cũ.
2. Trong MATLAB, đặt Current Folder vào thư mục có `START_TRAINING.m`.
3. Nhập các lệnh bên dưới. Không cần cài Python để chạy nhánh mới.

```matlab
START_TRAINING
training_check
training_tests
```

Trong cửa sổ mở ra, chọn **01_trajectory**, bấm **Chạy bài**. Cấu hình JSON bên trái chính là cấu hình được dùng. Sau khi chạy, bấm **Mở kết quả**. Mỗi lần chạy tạo thư mục mới trong `results/training`, có bản chụp `config.json`, nhật ký `console.txt` và `status.json`.

`training_check` chỉ kiểm tra tìm thấy API trên path; không chứng minh license có thể sử dụng hoặc mô phỏng chạy thành công. `training_tests` có kiểm tra hình học, covariance, góc radar và dữ liệu xuất. Test Incomplete là chưa kiểm thử xong, không được tính PASS.

Khi muốn chạy không mở giao diện:

```matlab
addpath(pwd,fullfile(pwd,'src'),fullfile(pwd,'training'))
r = training_run('01_trajectory');
r = training_run('03_radar');
dataset = fullfile(r.output,'training_native.mat');
view_dataset(dataset)
training_benchmark(dataset,'baseline','light')
```

Chạy thử cả 7 bài cốt lõi: `training_smoke`. Bài 04 chạy 160 scan với một GNN; thời gian tùy máy. Bài này có thể báo FAILED nếu mã tracker gốc hoặc license có lỗi; xem nhật ký thay vì hiểu FAILED là kết quả chất lượng thấp.

Để chạy project cũ: `START_HERE`, `run_tests`, `run_mixed('smoke','light')`. Các lệnh cũ và cấu hình cũ được giữ nguyên.

## 2. Project gốc đang sử dụng gì?

Kết luận dưới đây dựa trên việc đọc các tệp `.m` và công cụ sinh dữ liệu `.py`, không phải thống kê runtime.

| Công cụ | Vai trò trong bản gốc | Thực hành trong nhánh mới |
|---|---|---|
| MATLAB | Chạy mã, dữ liệu MAT, đồ thị, kiểm thử, báo cáo | Tất cả các bài, GUI, cấu hình, lưu kết quả |
| Radar Toolbox | Chưa có lời gọi trực tiếp sinh radar native trong mã MATLAB gốc | 03: radarDataGenerator, radarScenario, rcsSignature |
| Phased Array System Toolbox | Chưa thấy chuỗi waveform/array native trong mã gốc | 05: LFM, matched filter, CFAR; 06: ULA, steering |
| Signal Processing Toolbox | Chưa thấy chuỗi xử lý tín hiệu riêng trong mã gốc | 05: hann và phổ Doppler; FFT là MATLAB |
| DSP System Toolbox | Chưa thấy bộ DSP System object trong mã gốc | 05: dsp.FIRFilter làm mượt công suất |
| Sensor Fusion and Tracking Toolbox | Thành phần chính: GNN, JPDA, TOMHT, PHD, EKF/UKF/IMM | 04 và training_benchmark: dùng lại 17 tổ hợp |
| Mapping Toolbox | Bản gốc đọc MAT đã chuẩn bị; không cần readgeoraster để xem map | 02: GeoTIFF, WGS84 và đổi ENU sang địa lý |
| UAV Toolbox | Quỹ đạo cũ sinh bằng Python; chưa có uavScenario | 07: uavScenario, uavPlatform; 01: API quỹ đạo dùng chung |
| Antenna Toolbox | Chưa thấy lời gọi trực tiếp | 08: thiết kế dipole, tính pattern |
| Communications Toolbox | Chưa thấy channel System object | 05: comm.AWGNChannel |
| Parallel Computing Toolbox | Các vòng benchmark gốc chạy tuần tự | 11: serial/parfor cùng seed mỗi lượt |
| Aerospace Toolbox | Chưa thấy mô hình khí quyển native | 10: atmosisa, mật độ, Mach, vận tốc tương đối gió |
| Aerospace Blockset | Chưa có mô hình SLX được nối vào pipeline | 14: tạo khung 6DOF để tự cấu hình |
| Navigation Toolbox | Chưa có sensor GPS/IMU trong pipeline | 09: GPS và IMU; một số API chia sẻ giữa các toolbox |
| Simulink | Project gốc chạy bằng script/function | 13: tạo và chạy mô hình đáp ứng cao độ bậc nhất |
| Simulink 3D Animation | Bản đồ gốc dùng đồ thị MATLAB | 16: tạo world/actor; mở renderer bằng bước riêng |
| Statistics and Machine Learning Toolbox | Mã cũ có matchpairs; cần kiểm tra gói cung cấp/license trên máy | 11: normfit, histogram kết quả Monte Carlo |
| Optimization Toolbox | Tuning gốc là thử danh sách ứng viên, không gọi optimizer liên tục | 12: fmincon khớp sigma đo trên dữ liệu hiệu chuẩn giả lập |
| MATLAB Coder | Chưa thấy bước sinh C/MEX | 15: sinh C cho hàm đổi tọa độ; chưa biên dịch MEX |

Không cần ép tất cả toolbox vào một lần chạy. Chẳng hạn Coder phục vụ triển khai, còn Mapping phục vụ địa lý; chúng không tự nâng chất lượng tracking chỉ vì đã cài.

## 3. Ba luồng cần phân biệt

**Luồng điểm đo mới:** cấu hình → waypointTrajectory → vị trí/vận tốc UAV → kiểm tra DEM/LOS → radarDataGenerator → dữ liệu MAT 20 cột → bộ bám gốc → OSPA/GOSPA/RMSE.

**Luồng tín hiệu:** LFM → trễ cự ly + Doppler giả lập một mục tiêu → AWGN → matched filter → FFT Doppler + CFAR. Đây là lab tín hiệu độc lập, chưa biến thành detection đầu vào của bộ bám. Chưa có link budget công suất phát/thu, clutter mặt đất, MTI, waveform propagation đầy đủ hoặc ghost đa đường trong lab này.

**Luồng UAV/hệ thống:** UAV platform, GPS/IMU, khí quyển, Simulink, 6DOF và 3D là các bài riêng để hiểu từng lớp. Mô hình Simulink bậc nhất và khung 6DOF chưa điều khiển quỹ đạo đầu vào của radar. Antenna pattern cũng chưa tự thay gain của radarDataGenerator.

Vì vậy, đổi bandwidth ở bài 05 không tự đổi RangeResolution ở bài 03. Muốn đối chiếu, bạn chủ động chọn phân giải cự ly xấp xỉ c/(2B) và ghi giả định đó vào sổ thực nghiệm.

## 4. Tạo quỹ đạo và cấu hình UAV

Mở `training/config/default.json` hoặc dùng trình sửa JSON trong GUI. Mỗi phần tử `uavs` là một UAV. Mỗi hàng `waypoints_enu_m` gồm **[Đông, Bắc, Cao]**, đơn vị mét. `arrival_s` là thời gian đến từng điểm, bắt đầu từ 0 và phủ hết thời gian mô phỏng.

```matlab
c = training_config;
c.uavs(1).waypoints_enu_m = [600 -600 100; 1000 -300 160; 1600 -500 140];
c.uavs(1).arrival_s = [0; 50; 101.76];
c.uavs(1).rcs_m2 = 0.02;
c.uavs(1).birth_scan = 1;
c.uavs(1).death_scan = 140;
training_validate(c)
fid = fopen('training/config/my_route.json','w','n','UTF-8');
fprintf(fid,'%s',jsonencode(c,'PrettyPrint',true)); fclose(fid);
training_run('01_trajectory','training/config/my_route.json')
training_run('03_radar','training/config/my_route.json')
```

`rcs_m2` là diện tích phản xạ giả định, không phải khối lượng UAV. Bên trong radar, giá trị được đổi thành dBsm bằng 10*log10(rcs_m2). `speed_limit_mps` chỉ đặt giới hạn kiểm tra, không tự ép tốc độ: muốn bay chậm, tăng thời gian giữa các waypoint. Bộ nội suy có thể vượt tốc độ ước lượng từ đoạn thẳng; mã kiểm tra tốc độ tại các mẫu mô phỏng. Nó không chứng minh giới hạn liên tục giữa mọi mẫu.

`birth_scan/death_scan` lọc thời gian UAV tồn tại khi sinh điểm đo. Quỹ đạo vẫn được xác định trên toàn khoảng thời gian. Bài 01 và trình xem UAV ở bài 07 hiển thị đường đầy đủ để học hình học.

Để tập hover, chọn `training/config/hover.json`. Để thêm UAV, nhân bản một phần tử trong mảng `uavs`, đổi tên, RCS, waypoint và thời gian. Các tên phải khác nhau. Bài 01 xuất bảng tốc độ/gia tốc để kiểm tra đường bay trước khi sinh điểm đo.

## 5. Cấu hình radar

| Tham số | Ý nghĩa / đơn vị | Thử nghiệm nên làm |
|---|---|---|
| position_enu_m | Vị trí anten [E,N,U], mét | Tăng độ cao radar, xem LOS đổi ra sao |
| frequency_hz | Tần số Hz, mặc định 9.4 GHz | Ở lab 05/06, quan sát thay đổi bước sóng và Doppler |
| reference_range_m | Cự ly mục tiêu tham chiếu, mét | Giữ RCS/Pd cố định, so số detection khi thay cự ly tham chiếu |
| reference_rcs_m2 | RCS tham chiếu m² | Phân biệt với RCS từng UAV |
| detection_probability | Pd tại điều kiện tham chiếu | Thử 0.7 và 0.9; không xem đây là Pd cố định ở mọi cự ly |
| false_alarms | Bật/tắt false alarms thống kê native | Mặc định false để học hình học trước |
| false_alarm_probability | Pfa trên resolution cell | Không đồng nghĩa số clutter/scan của generator Python cũ |
| field_of_view_deg | [góc phương vị, góc tà] tổng, độ | Thu hẹp FOV, kiểm tra UAV nào ra khỏi chùm |
| range_limits_m | [cự ly gần, cự ly xa] mét | Chặn mục tiêu ngoài phạm vi |
| range_resolution_m | Phân giải cự ly mét | So độ phân tách mục tiêu và bất định native |
| azimuth_resolution_deg / elevation_resolution_deg | Phân giải góc độ | Thử tăng gấp đôi và so sai số vị trí xa radar |

Bài 03 dùng radar **No scanning**, hướng nhìn chính về phía Đông. Không phải radar quay 360°. Để nghiên cứu Rotator/Raster, mở `doc radarDataGenerator`, tạo cấu hình riêng và kiểm tra tốc độ cập nhật theo scan; không chỉ đổi một chữ rồi giữ nguyên giả định 0.64 s/scan của benchmark.

Một radar thống kê dùng điểm tham chiếu Pd/RCS/cự ly không tương đương mô hình RF đầy đủ. Tần số chỉ được thay đổi không có nghĩa cự ly phát hiện sẽ thay theo một radar thật đã đo.

## 6. Cấu hình môi trường

`terrain_los=true` bỏ mục tiêu bị DSM che trước khi gọi radar. `ray_samples=128` lấy mẫu dọc đường nhìn; `clearance_m=1` thêm biên cao độ. Đây là kiểm tra tia có lấy mẫu, có thể bỏ qua vật cản nhỏ giữa các mẫu. Không ray trace mặt đứng các tòa nhà OSM và không sinh đa đường.

`wind_enu_mps=[3,0,0]` ở bài 01/03 cộng trôi động học về Đông: p = p_waypoint + wind*t, v = v_waypoint + wind. Nó chưa mô phỏng lực khí động, bộ điều khiển giữ vị trí hoặc gió giật. Bài 07 yêu cầu gió bằng 0 vì đang dùng chuyển động waypoint native trực tiếp. Bài 10 tính khí quyển ISA và vận tốc tương đối gió.

DEM đi kèm là Copernicus DSM, có thể gồm cây/công trình. Cao độ MAT là cao độ tương đối so với mốc gốc, không phải trực tiếp AGL, MSL hay ellipsoid. `AGL = z - terrain(E,N)`. Gốc MSL trong provenance là khoảng 13.108 m. Không cộng thêm độ cao công trình lên DSM khi chưa kiểm tra có tính hai lần hay không.

`origin_lla(3)=0` mặc định là **giả định cao độ ellipsoid** chỉ cho bài đổi tọa độ/GPS. DEM gốc dùng EGM2008 orthometric, còn WGS84 dùng ellipsoid: cần geoid separation và dữ liệu mốc thật nếu muốn tọa độ cao độ ngoài thực địa. Phép chiếu ngang MAT gốc cũng là xấp xỉ theo bán kính cong địa phương, không phải exact ECEF/ENU. Không tự đổi lat/lon của origin vì DEM gói này cố định vùng Nội Bài; chương trình sẽ báo lỗi khi mốc không khớp.

## 7. Mười sáu bài thực hành

Mỗi bài: chạy mốc → đổi một nhóm tham số → chạy vào thư mục mới → so sánh file/đồ thị → ghi kết luận và giới hạn. Các kết quả mong đợi dưới đây là mục tiêu quan sát, chưa phải kết quả đã đo từ máy này.

| Bài | Cách thao tác | Đầu ra / tiêu chí hiểu bài |
|---|---|---|
| 01_trajectory | Đổi waypoint, arrival_s, RCS riêng từng UAV; RCS chỉ tác động từ bài 03 | trajectory.png, uav_01.csv; giải thích tốc độ/gia tốc và cao độ |
| 02_environment | Đổi cao radar, cao UAV, ray_samples; mở GeoTIFF và provenance | terrain_los.png, environment_01.csv; phân biệt ENU, AGL, datum |
| 03_radar | Đổi Pd, FOV, RCS, false_alarms | training_native.mat; quan sát số detection/scan và vùng mất đo |
| 04_tracking | Chạy một GNN; dùng training_benchmark để đổi họ tracker | tracking/summary.csv, frames.csv, tracking.png; đọc thiếu/thừa track và OSPA |
| 05_signal | Thay bandwidth, PRF, pulses, snr_db, target_radial_velocity_mps | range_doppler.png, signal.mat; hiểu phân giải, aliasing, matched-filter delay |
| 06_array | Đổi array_elements từ 8 lên 16, steer_deg từ 0 lên 30 | beam.png; so bề rộng búp chính, sidelobe và góc cực đại |
| 07_uav | Chạy waypoint qua uavScenario; xem trainingUAVScenario trong workspace | uav_initial.png, uav_final.png; phân biệt platform và đường bay |
| 08_antenna | Đổi tần số và xem code tạo dipole; thử sửa hướng cắt pattern | antenna.png; phân biệt directivity/gain và array factor |
| 09_navigation | Đổi horizontal_accuracy_m, vertical_accuracy_m, velocity_accuracy_mps | gps.csv, navigation.mat; phân biệt truth với phép đo |
| 10_atmosphere | Đổi cao độ và gió | atmosphere.csv; đọc nhiệt độ, áp suất, mật độ, Mach |
| 11_montecarlo | Đổi trials, sigma_m; chạy thêm parallel.json | trials.csv, montecarlo.mat; phân biệt một seed và phân bố nhiều seed |
| 12_optimization | Đổi sigma_assumed_m, sigma_bounds_m | fit.mat; hiểu objective, bounds, exitflag, train và holdout |
| 13_simulink | Đổi time_constant_s và command_altitude_m | SLX tạo khi chạy, simulation.mat, altitude.png; hiểu solver và đáp ứng bậc nhất |
| 14_aerospace_blocks | Tạo SLX 6DOF, mở mask, nhập khối lượng/quán tính/lực/moment | Khung mô hình chưa chạy; tự nối gravity/lực khí động và Scope để luyện |
| 15_coder | Đọc training_polar_to_enu, chạy codegen rồi xem C/report | codegen/; mã nguồn C được sinh, chưa biên dịch/thử MEX |
| 16_3d | Tạo training3DWorld, rồi chạy viewer bằng lệnh dưới | World/actor trong workspace; chưa phát lại quỹ đạo hoặc nhập DEM/OSM |

```matlab
training_run('16_3d')
run(training3DWorld,0.05,5)
```

Với 3D, cần renderer/driver và các thành phần cài đặt phù hợp của MATLAB. Không có scene sân bay Unreal tùy chỉnh được đóng kèm. Box mặc định chỉ là actor khởi đầu để học coordinate, transform và render; không đại diện UAV có động lực học.

Bài 09 giữ cố định tư thế thân để tách tác động trọng lực/gia tốc khỏi bài toán attitude. Nó chưa phải bộ lọc INS/GNSS fusion. GPS và IMU đang độc lập, chưa đưa vào tracker radar. Khi đã hiểu, tiếp tục với `doc insfilterErrorState` hoặc ví dụ INS/GNSS chính thức và kiểm tra license cung cấp API.

Bài 11 hiện đánh giá RMSE của nhiễu vị trí Gaussian, không chạy 100 benchmark radar. `parfor` dùng stream riêng theo seed để so chế độ serial/parallel. Chưa benchmark GPU. Bài 12 là hiệu chuẩn sigma Gaussian trên dữ liệu giả lập: 100 mẫu để fit, 60 mẫu giữ lại; chưa tự tìm Q/R cho tracker thật. Tuning Q/R của project có sẵn trong `run_mixed('tune',...)`.

CFAR bài 05 dùng profile công suất tích lũy; dữ liệu sau matched filter có tương quan và tích lũy làm đổi phân bố. Pfa danh định trong lab không được báo cáo thành Pfa thực nghiệm đã hiệu chuẩn. Muốn đánh giá detector phải chạy nhiều dữ liệu noise-only và đếm false alarms.

## 8. Nối về benchmark gốc và luyện tuning

```matlab
r = training_run('03_radar','training/config/false_alarms.json');
dataset = fullfile(r.output,'training_native.mat');
training_benchmark(dataset,'baseline','light')
training_benchmark(dataset,'tune','light')
% Chỉ sau khi bản light hoạt động tốt:
training_benchmark(dataset,'tune','extended')
```

`light` gồm 3 GNN; `extended` gồm 17 tổ hợp. Bộ bám nhận cùng định dạng điểm đo như project cũ, không nhận nhãn truth. Adapter đổi tọa độ NED của radar và hướng anten sang ENU của project; giữ covariance và chuyển độ/radian theo hợp đồng 20 cột.

Benchmark cũ bắt buộc **160 scan**, chia fit 1–100, selection 101–130, holdout 131–160. `training_generate` từ chối số scan khác để tránh đánh giá sai. Dữ liệu xuất dùng generator native mới, không thể coi là cùng phân bố với 80 file Python cũ. False alarm count native cũng khác clutter vùng 125/scan trong file mixed cũ. Không so hai điểm OSPA rồi quy nguyên nhân hoàn toàn cho thuật toán.

Mở `config/tracker_config.json` để xem `measurement_variance_scale`, bất định vận tốc, process noise, gating, quản lý track và `temporal_support`. Nhánh thực hành không tự ghi đè file này. Muốn thử tham số, lưu bản sao trước, đổi một yếu tố, chạy vào output mới, giữ nguyên seed/dataset và ghi nhận cấu hình. Dùng bản Git baseline nếu cần đối chiếu. Không giảm clutter hoặc dùng truth lọc detections rồi kết luận tracker tốt hơn.

Các nhãn TargetIndex từ radar chỉ dùng audit. `make_detections` tạo lại objectDetection với ObjectAttributes rỗng trước khi tracking. Giá trị Pd từng truth chưa được lấy từ native generator nên cột này để NaN, không bịa một giá trị chắc chắn.

## 9. Lộ trình để thành thạo

**Giai đoạn A – hình học và dữ liệu:** làm 01, 02, 03, 07. Tự tạo 3 đường bay, một hover, một mục tiêu xuất hiện muộn. Chứng minh đơn vị và hệ tọa độ bằng một điểm tính tay.

**Giai đoạn B – radar tín hiệu:** làm 05, 06, 08. Tự dự đoán deltaR≈c/(2B), R_unamb≈c/(2PRF), |v|_unamb≈lambda*PRF/4, deltaV≈lambda*PRF/(2*Npulses). Đối chiếu đồ thị. Thêm một mục tiêu thứ hai là bài mở rộng tự triển khai, chưa nằm trong mô hình một mục tiêu mặc định.

**Giai đoạn C – tracking:** làm 04 và benchmark light. Thử noise mismatch, gating và temporal_support. Dùng dữ liệu seed mới để đánh giá thay vì chỉ chọn cấu hình tốt nhất trên một file.

**Giai đoạn D – độ tin cậy và hiệu năng:** làm 11, 12. Chạy nhiều seed, báo trung bình/độ phân tán và thất bại. Đưa chính tracker vào vòng Monte Carlo là bước mở rộng tiếp theo; không lấy bài nhiễu Gaussian thay cho phép thử tracker.

**Giai đoạn E – hệ thống:** làm 09, 10, 13 rồi mới tới 14–16. Trước khi ghép, viết hợp đồng dữ liệu: thời gian, ENU/NED/body, rad/deg, mét, chiều vector, covariance và độ trễ. Tiếp theo mới nối 6DOF→UAV→radar, IMU/GPS fusion, waveform→CFAR→detections và tối ưu hiệu năng C/MEX.

Để tự đánh giá “đã hiểu”: bạn phải giải thích được tại sao kết quả thay đổi, biết khi nào mô hình không còn đúng, tái lập được kết quả từ config+seed và có một bài kiểm tra độc lập. Chạy hết 16 lệnh là khởi đầu, chưa phải thành thạo toàn bộ toolbox.

## 10. Đọc kết quả và xử lý lỗi

| Trạng thái | Ý nghĩa |
|---|---|
| PASS | Bài đã chạy xong trong lần thực thi đó; không phải chứng nhận độ chính xác vật lý |
| FAILED | Có exception; xem status.json và console.txt; không đưa kết quả này vào so sánh thành công |
| SKIPPED_MISSING_API | Smoke không tìm được API; chưa chạy bài |
| BUILT_NOT_SIMULATED | Bài 14/16 chỉ dựng đối tượng hoặc mô hình, chưa chạy phần vật lý/renderer |
| GENERATED_NOT_COMPILED | Bài 15 mới sinh C, chưa kiểm tra binary/MEX |

**Missing API:** dùng `which radarDataGenerator -all`, `ver`, `doc radarDataGenerator`. Cài đặt đủ sản phẩm không đảm bảo license cho mọi API. Không có cơ chế im lặng thay toolbox bằng mock.

**Invalid trajectory:** kiểm tra thời gian tăng, số hàng waypoint khớp, đường nằm trong bounds/DEM, speed_limit. Kéo dài arrival_s hoặc giảm độ dài đường bay. Không chỉ tăng speed_limit để bỏ qua một cấu hình thiếu thực tế.

**Radar/UAV below terrain:** cao độ dùng z tương đối, không phải AGL; tăng z theo ground ở vị trí đó. Kiểm tra origin trước.

**No reports:** kiểm tra radar nhìn Đông, FOV, range limits, LOS, RCS và Pd. Đây có thể là kết quả hợp lệ. Nếu báo lỗi hợp đồng dữ liệu thì xem log; không thêm truth làm detections để làm đẹp hình.

**Results belong to different settings:** output benchmark cũ có chữ ký dữ liệu/config/code. Dùng thư mục mới; wrapper training_benchmark đã tự làm việc này.

**MATLAB tự động không khởi động:** môi trường đóng gói gặp `System Error: File system inconsistency` trước khi MATLAB chạy script. Đây là lý do chưa có PASS native kèm sẵn. Mở MATLAB bình thường trên máy, chạy `training_tests` và `training_smoke` để xác nhận; giữ lại log nếu lỗi tiếp diễn.

## 11. Cấu trúc và nhánh Git

```text
START_HERE.m                   Điểm vào gốc, không đổi
START_TRAINING.m               Điểm vào GUI thực hành
training/config/*.json         Mốc và 5 biến thể cấu hình
training/training_run.m        Bộ chạy 16 bài
training/training_generate.m   Native radar → MAT hợp đồng cũ
training/training_benchmark.m  Nối sang run_mixed
training/tests/                Kiểm thử cần chạy trong MATLAB
training/VALIDATION.md          Những gì đã/chưa kiểm chứng
training/README_VI.html         Hướng dẫn này, đọc offline
data/                          Đủ 80 dataset + DEM + OSM gốc
results/training/              Sinh khi bạn chạy bài
```

ZIP kèm kho Git cục bộ: `baseline-v8.4` là mã gốc, nhánh hiện tại `training/toolbox-mastery` thêm nhánh học. Thư mục `data/` được đóng đủ trong ZIP nhưng bỏ qua trong lịch sử Git để không nhân đôi dữ liệu lớn. `git diff baseline-v8.4..training/toolbox-mastery --stat` cho biết phần bổ sung. Không cần dùng Git để chạy project. Không có thay đổi nào được đẩy lên GitHub.

File `FILE_MANIFEST.json` gốc được giữ nguyên để mô tả gói cũ. `TRAINING_MANIFEST.json` mới kiểm tra toàn bộ tệp nội dung bản mở rộng, không gồm thư mục `.git` và chính manifest. Bảo toàn ghi công Copernicus và OpenStreetMap trong `data/`.

## 12. Tài liệu MathWorks dùng để đối chiếu

Tài liệu cài tại máy R2025a là điểm đối chiếu chính; trang web trực tuyến có thể hiển thị bản MATLAB mới hơn. Dùng `doc tenAPI` trên R2025a để kiểm tra thuộc tính đúng phiên bản.

- [Radar Toolbox R2025a Reference](https://www.mathworks.com/help/releases/r2025a/pdf_doc/radar/radar_ref.pdf)
- [radarDataGenerator](https://www.mathworks.com/help/radar/ref/radardatagenerator-system-object.html)
- [uavScenario](https://www.mathworks.com/help/uav/ref/uavscenario.html)
- [uavPlatform và ReferenceFrame](https://www.mathworks.com/help/uav/ref/uavplatform.html)
- [UAV show3D](https://www.mathworks.com/help/uav/ref/uavscenario.show3d.html)
- [LFM matched-filter coefficients](https://www.mathworks.com/help/phased/ref/phased.linearfmwaveform.getmatchedfilter.html)
- [6DOF Euler Angles](https://www.mathworks.com/help/aeroblks/6dofeulerangles.html)
- [Simulink 3D Animation R2025a](https://www.mathworks.com/help/releases/r2025a/pdf_doc/sl3d/sl3d_ug.pdf)
