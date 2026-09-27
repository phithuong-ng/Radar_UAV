# Nội Bài Radar v8.4 FULL — MATLAB R2025a

Bản đầy đủ có **80 dataset đã sinh sẵn: 8 kịch bản × 10 seed**, nằm trong `data/datasets`.
File mặc định để chạy nhanh: `fast_uav_mixed_9100.mat`. Không cần Python để dùng MAT có sẵn.
Không chứa dataset cũ, kết quả tracking cũ hoặc GLMB/MI-GLMB. DEM Copernicus và bản đồ OSM đã ghép được giữ lại.

## Chạy ngay

Giải nén vào một thư mục mới. Trong MATLAB, chọn thư mục chứa `START_HERE.m` làm Current Folder.
Không chép đè vào bản cũ vì MATLAB có thể tìm nhầm hàm cũ trên path.

```matlab
START_HERE
run_tests
run_mixed('smoke','extended')  % 12 scan, kiểm tra 17 tổ hợp
run_mixed('tune','light')      % tìm tham số cho 3 GNN trước, chạy đủ 160 scan sau khi chọn
```

Chạy đủ 17 tổ hợp trên đúng một file mixed:

```matlab
run_mixed('tune','extended')
```

Mỗi tổ hợp: thử 6 bộ tham số ở scan 1–100; chọn 2 ứng viên tốt nhất;
so sánh ở scan 101–130; khóa tham số; chạy đủ 160 scan và báo cáo riêng scan 131–160.
Các lần chạy selection và final đều bắt đầu từ scan 1, duy trì lịch sử bám nhân quả.
Đây là kiểm tra trên một phần thời gian chưa dùng để chọn tham số, không phải một dataset độc lập.

```matlab
run_mixed('baseline','light')  % cấu hình ban đầu; chưa tìm tham số
run_mixed('deep','extended')   % 12 ứng viên/tổ hợp, tìm rộng hơn và lâu hơn
run_mixed('tune','GNN_IMM_EKF_SPH') % chỉ một tổ hợp cụ thể
view_dataset                 % xem toàn bộ raw plots, truth, bản đồ
view_best_result('results/tune_light')
```

`run_mixed` không đối số tương đương `run_mixed('tune','extended')`.
Không dùng `smoke` để kết luận chất lượng vì phần này chỉ có 12 scan đầu.
Chạy lại đúng lệnh tự sử dụng các lượt đã hoàn thành. Nếu đổi code/config/dataset,
chọn thư mục kết quả mới, ví dụ `run_mixed('tune','light','results/try_02')`.

## Cấu hình của file mixed mặc định

- 7 UAV, tốc độ liên tục từ 0 đến 150 m/s, tăng/giảm tốc trơn, có dừng thật tại một vị trí.
- Hai hoặc nhiều khoảng đứng yên cho mỗi UAV; khoảng đứng yên dài nhất của từng UAV khoảng 6,40–8,32 s tính giữa các mẫu.
- Một UAV xuất hiện muộn và một UAV kết thúc sớm để thử quản lý track.
- RCS riêng từng UAV: 0,004–0,020 m². RCS/cự ly ảnh hưởng SNR, Pd và sai số đo.
- 125 clutter/scan theo kỳ vọng Poisson ở 5 vùng; không giảm clutter để làm đẹp kết quả.
- Giữ đoạn scan 45–75 có độ lệch chuẩn nhiễu nhân 4. Covariance báo cho tracker nay phản ánh đúng độ bất định của từng plot.
- Nhiễu đo danh định còn phụ thuộc SNR. Vì vậy không được mô tả toàn bộ file bằng một bộ sigma cố định.
- Điều chỉnh bất định vận tốc khởi tạo, Q của CV/CA/CT, ngân hàng IMM, mật độ clutter và quản lý track.
- GNN mặc định dùng Score logic. JPDA mặc định dùng Integrated logic (JIPDA), vẫn là `trackerJPDA` native.
  Candidate 7 của chế độ deep có lựa chọn History để đối chiếu. Tên tổ hợp giữ tên họ liên kết điểm đo; logic thực nằm trong selected_parameters.json.
- PHD dùng initializer công khai của MathWorks; bỏ các lời gọi `fusion.internal` và bộ nhớ 10.000 thành phần ghi cứng.
- Giới hạn số sự kiện JPDA, giả thuyết/nhánh TOMHT, thành phần PHD; tính trước và dùng lại detection.
- OSPA giữ cutoff 300 m, p=1; GOSPA p=2, alpha=2; RMSE là tọa độ 3D trên cặp đã ghép.

## Tuning và kết quả

Cấu hình mặc định trong `config/tracker_config.json` là điểm bắt đầu có xét môi trường.
**Chưa có MATLAB trong môi trường đóng gói nên chưa có kết quả benchmark native hoặc bộ tham số thắng đã đo sẵn.**
Lệnh `run_mixed('tune',...)` thực thi việc chọn tham số bằng MATLAB trên máy của bạn; không phải script chỉ chạy một cấu hình cố định.
Không có cam kết tối ưu toàn cục, thời gian chạy cụ thể hoặc OSPA luôn dưới một ngưỡng nào đó.

Thư mục `results/tune_light` hoặc `results/tune_extended` sau khi chạy chứa:

| Tệp | Ý nghĩa |
|---|---|
| `SUMMARY.html`, `summary.csv` | Kết quả đầy đủ và đoạn holdout; OSPA/GOSPA, RMSE 3D, thiếu/thừa track, thời gian |
| `ranked_selection.csv` | Xếp thứ tự theo đoạn selection, không dùng holdout để chọn |
| `best_method.json` | Tổ hợp tốt nhất theo selection trong các lượt final chạy thành công |
| `selected_parameters.mat` | Bộ tham số đã chọn cho từng tổ hợp |
| `METHOD/selected_parameters.json` | Tham số và điểm chọn của tổ hợp đó |
| `METHOD/tuning_candidates.csv` | Mọi ứng viên, lỗi và thời gian; không giấu lượt thất bại |
| `METHOD/frames.csv`, `METHOD/tracks.mat`, `METHOD/tracking.png` | Kết quả từng scan và hình |
| `input_audit.json` | Số raw/retained plots; giữ được bao nhiêu detection UAV, chỉ kiểm tra sau xử lý |
| `console.txt` | Tiến độ và lỗi |

Mọi trạng thái `FAILED`, `TIME_LIMIT`, `NO_VALID_CANDIDATE` phải xem là chưa thành công.
Không đưa điểm của lượt chạy dở vào xếp hạng. Nếu muốn thử lại sau lỗi môi trường,
xóa đúng tệp cache `fit_XX.mat`/`selection_XX.mat`/`final.mat` bị lỗi hoặc chọn thư mục output mới.
Giới hạn thời gian là **soft limit**, kiểm tra giữa các lệnh tracker; không thể ngắt giữa một lời gọi toolbox đang chạy.
Thời gian `tracking_ms` bao gồm gọi tracker và lấy vị trí, có thể gồm JIT ở các scan đầu.
Thời gian tạo detection và đánh giá metrics được tách khỏi `tracking_ms`; tổng `run_mixed` vẫn bao gồm các phần đó.

## Các tổ hợp

| Họ tracker | Bộ lọc |
|---|---|
| GNN | CV-EKF, CV-UKF, IMM-EKF, CA-UKF, CT-UKF |
| JPDA / JIPDA tùy logic | CV-EKF, CV-UKF, IMM-EKF, CA-UKF, CT-UKF |
| TOMHT | CV-EKF, CV-UKF, IMM-EKF, CA-UKF, CT-UKF |
| GM-PHD | CV, CA |

`light`: 3 GNN (CV-EKF, CV-UKF, IMM). `standard`: 10 tổ hợp như danh sách trong `method_registry.m`.
`extended`: đủ 17. Tất cả nhận cùng tập điểm đo sau bước tiền xử lý chung.

## Bước lọc hỗ trợ thời gian

`temporal_support.enabled=true` mặc định: một plot từ scan thứ hai cần có ít nhất một plot thô
ở 1–3 scan trước mà nó có thể đi tới với tốc độ tối đa 150 m/s, cộng dung sai từ covariance đo.
Scan đầu giữ toàn bộ plots. Không dùng truth, nhãn UAV/clutter, lịch dừng hoặc báo cáo tương lai.
Không đặt vận tốc tối thiểu nên không loại mục tiêu chỉ vì đứng yên.
Bước này có thể bỏ sót plot đầu của mục tiêu mới hoặc sau mất đo lâu; số giữ/bỏ được báo cáo rõ.

Trong file `fast_uav_mixed_9100.mat`, bước này giữ 1.053/1.054 target detections và loại khoảng 14,75% clutter.
Mức giảm có giới hạn do vùng có độ bất định đo lớn; không tuyên bố giảm tải hàng chục lần.
Muốn so với raw plots: đặt `temporal_support.enabled=false` trong config, chạy vào output mới.
Mật độ clutter đưa cho native tracker là xấp xỉ vô hướng, ước lượng tỷ lệ giữ từ reports ở 100 scan đầu;
đổi sang đơn vị spherical ở cự ly tham chiếu 2.500 m. Chưa mô hình hóa chính xác mật độ biến thiên theo mọi vị trí.

## RCS, Pd, sai số đo và đa đường

RCS là giả định mô phỏng được khai báo, không phải số đo thật của UAV cụ thể.
SNR tương đối tỷ lệ `RCS / range^4`, hiệu chuẩn theo điểm tham chiếu giả định:
RCS 0,01 m² tại 5 km có Pd=0,5; Pfa tham chiếu 1e-6; Pd giới hạn trên 0,98.
Đây là mô hình hiệu dụng single-look Swerling-I, chưa hiệu chuẩn tích lũy xung của RX-R417C.
Pfa tham chiếu dùng trong mô hình Pd; số clutter Poisson cấu hình riêng, không suy trực tiếp từ Pfa này.

Sai số đo tại điểm tham chiếu 2 km / 0,01 m²: sigma range 5 m, az 0,3°, el 0,5°.
Sigma thay đổi theo 1/sqrt(SNR), có sàn/trần theo config; sau đó nhân 4 ở đoạn nhiễu tăng.
`reported_covariance='matched'` giả định radar cung cấp đúng chất lượng plot.
Đây không phải một bộ ước lượng R thích nghi đã được chứng minh trên radar thực.
Có thể đổi thành `'nominal'` để thử mismatch: tracker không được biết hệ số tăng nhiễu.
Truth, nhãn, sigma oracle và RCS thật chỉ phục vụ sinh dữ liệu/đánh giá, không vào thuật toán tracking.
Không có mô phỏng bộ lọc Doppler/MTI loại mục tiêu đứng yên; khả năng radar thực giữ plot của UAV đứng yên cần xác nhận riêng.

Đa đường mặc định **tắt** để làm mốc. Có mô hình suy hao/tăng cường SNR hai tia trên mặt phẳng cục bộ,
trung bình theo băng tần và sai số cao, có giới hạn hệ số. Nó không sinh ghost plots hoặc bias góc tà;
không phải mô hình đầy đủ phản xạ mọi tòa nhà, bề mặt sân bay.
Sinh một bản thử riêng khi cần (Python chỉ cần cho việc tái sinh, không cần khi chạy MAT có sẵn):

```bash
python -m pip install -r requirements.txt
python tools/build_dataset.py --multipath --output data/mixed_multipath
```

```matlab
run_mixed('tune','light','results/mp_light', ...
    'data/mixed_multipath/fast_uav_mixed_9100.mat');
view_dataset('data/mixed_multipath/fast_uav_mixed_9100.mat');
```

Không cộng thêm nhiễu đa đường sau khi đã tạo file `.mat` mà vẫn ghi đó là dữ liệu cũ.
Muốn thay RCS/tốc độ/clutter: sửa `config/dataset_config.json` và sinh vào thư mục mới.
Mảng `speed_times_s`/`speed_values_mps` định nghĩa lịch tốc độ; `max_speed_mps` là thông tin mô tả.
Trình sinh dùng tích phân tốc độ và tham số độ dài cung để đảm bảo tốc độ không vượt 150 m/s.

## Toàn bộ dataset và các bảng

| Kịch bản | UAV | File | Scan/file | Clutter kỳ vọng/scan |
|---|---:|---:|---:|---:|
| control_cv | 6 | 10 | 160 | 25 |
| motion_only | 6 | 10 | 160 | 25 |
| measurement_only | 6 | 10 | 160 | 25 |
| joint_mismatch | 6 | 10 | 160 | 25 |
| regional_clutter | 6 | 10 | 160 | 125 |
| dense_12 | 12 | 10 | 160 | 125 |
| paper_style_3 | 3 | 10 | 160 | 25 |
| fast_uav_mixed | 7 | 10 | 160 | 125 |

Tổng 12.800 scan; 75.820 truth samples; 71.103 target detections; 799.359 clutter reports;
870.462 reports; Pd quan sát 0,9378. Tất cả đều được đếm lại từ MAT mới.
Mọi file dùng 160 scan (kể cả paper_style_3), thời lượng 101,76 s.
Tên paper_style_3 được giữ để nhận diện nhóm 3 UAV khác RCS; đã đổi quỹ đạo/tốc độ,
không phải bản tái lập MI-GLMB. Tên joint_mismatch giữ tương thích, nhưng mặc định R báo
đúng noise thực; không cố tình giấu hệ số nhiễu tăng.

Các nhóm cơ động có 0–150 m/s và dừng thật; paper_style_3 có 0–90 m/s.
control_cv và measurement_only giữ vận tốc không đổi từng UAV, dải 14,42–150 m/s,
để làm đối chứng CV. Tất cả quỹ đạo ở trong vùng giám sát khi UAV tồn tại.
Seed chỉ thay phần ngẫu nhiên của detection, nhiễu, clutter và xáo trộn reports.
Quỹ đạo không đổi giữa 10 seed của cùng một kịch bản. Các cặp đối chứng dùng common random numbers.
Đánh giá seed độc lập kiểm tra độ nhạy nhiễu, chưa chứng minh tổng quát hóa sang quỹ đạo mới.

- `docs/BANG_DATASET.html`: hai bảng theo bố cục ảnh mẫu, kèm thống kê từng kịch bản và từng UAV.
- `docs/BANG_01_TONG_QUAN.png`, `docs/BANG_02_DIEU_KIEN.png`: ảnh 1920×1080 để đưa vào slide.
- Bản `.svg` tương ứng: chữ và đường bảng dạng vector.
- `docs/all_uav_parameters.csv`: RCS/dBsm, AGL, cự ly, tốc độ, thời gian đứng yên và birth/death của mọi UAV.

## Chạy cả 80 file với tham số khóa

```matlab
run_full('tune','light')      % 3 GNN, 80 file; lâu hơn rất nhiều so với một mixed
run_full('tune','extended')   % 17 tổ hợp, 80 file
```

Mỗi kịch bản tune riêng trên seed 9100, dùng 6 ứng viên/tổ hợp và tách fit/selection như run_mixed.
Tham số đã chọn được khóa rồi áp dụng sang seed 9101–9109:
9101–9102 là validation, 9103–9109 là evaluation. Không tune lại trên evaluation.
Mật độ clutter hiệu dụng vẫn được tính từ metadata và tỷ lệ giữ raw reports của từng file;
đây là hiệu chỉnh môi trường ngoại tuyến từ 100 scan đầu, không dùng nhãn hay truth.
Nếu không tìm được tham số, các lượt liên quan báo NO_LOCKED_PARAMETERS thay vì tự chạy mặc định.
Baseline là một chế độ riêng, rõ ràng chưa tune.

```matlab
run_full('baseline','light')  % cấu hình khởi đầu, toàn bộ 80 file
run_full('tune','light','results/mixed_10seeds','fast_uav_mixed') % chỉ 10 seed mixed
run_mixed('tune','light','results/motion_9100','data/datasets/motion_only_9100.mat')
view_dataset('dense_12_9100.mat')
```

Kết quả full: `ALL_RESULTS.csv` từng file, `EVALUATION_SUMMARY.csv` gộp 7 seed evaluation,
`SUMMARY.html` và thư mục riêng từng file. Phải đọc PassedFiles/EvaluationFiles khi so sánh;
mean chỉ tính file PASS, không biến lỗi/timeout thành điểm tốt.
Không chọn thuật toán thắng bằng điểm evaluation. Mean_File_RMSE là trung bình RMSE từng file,
không phải pooled RMSE. Seed 9100 có thêm holdout scan 131–160 trong báo cáo riêng.
Chạy lại cùng lệnh để dùng cache. Đổi code/config/data thì dùng thư mục output mới.

## Tái sinh toàn bộ dữ liệu

Không cần tái sinh để chạy benchmark. Bộ sinh đầy đủ đã được đóng gói:

```bash
python -m pip install -r requirements.txt
python tools/build_suite.py --force
python tools/audit_suite.py
python tools/validate_dataset.py
python tools/build_tables.py
```

`--force` chỉ ghi đè đúng 80 file được cấu hình. Nếu có MAT ngoài bộ này trong output,
script dừng và yêu cầu thư mục khác; không xóa file không thuộc bộ. Bộ ZIP đã loại dataset cũ.
Đổi cấu hình tổng quát ở `config/dataset_config.json`, nhóm/seed ở `config/suite_config.json`.
Cấu hình CV và dense bổ sung nằm trong `tools/build_suite.py::case_config`.
Mỗi MAT lưu đầy đủ config đã áp dụng trong `config_json`.

```bash
python tools/build_suite.py --scenario fast_uav_mixed --output data/mixed_10seeds
python tools/build_suite.py --multipath --output data/full_multipath
```

PNG bảng có sẵn. Nếu đổi dữ liệu, `build_tables.py` cập nhật HTML/SVG; xuất PNG bằng Inkscape:

```bash
inkscape docs/BANG_01_TONG_QUAN.svg --export-type=png
inkscape docs/BANG_02_DIEU_KIEN.svg --export-type=png
```

## Kiểm chứng và giới hạn

- `docs/full_validation.json`: 2.720 kiểm tra trên đủ 80 MAT, cộng 2 so sánh cặp đối chứng.
- `docs/python_validation.json`: kiểm tra dữ liệu thực đã chạy; tính tái lập, hover đúng vị trí, giới hạn tốc độ,
  covariance dương xác định, sigma khai báo/đã sinh khớp, RCS/đa đường có tác động và bước lọc nhân quả.
- `docs/matlab_static_analysis.txt`: kiểm tra cú pháp bằng MISS_HIT, ngữ pháp MATLAB 2022a mà công cụ hỗ trợ;
  mã không cần cú pháp mới hơn. Kiểm tra này không kiểm chứng API hoặc hành vi runtime R2025a.
- `run_tests`: kiểm thử native R2025a được đóng gói, gồm khởi tạo filter, chuyển hệ tọa độ,
  metric, stationary target, 17 tổ hợp và cập nhật khi không có detection. Chưa được chạy tại nơi đóng gói.
- `docs/dataset_summary.json`, `docs/uav_parameters.csv`: số liệu đếm/tính trực tiếp từ MAT mới.
- Không có dữ liệu tracking native cũ được gắn nhãn lại thành kết quả của bản này.
- OSPA cao có thể do thiếu/thừa track; phải đọc kèm RMSE và số track. Không hạ cutoff 300 m để che lỗi.
- Đoạn nhiễu x4 rất khó: RMSE 3D raw target plots khoảng 272,85 m, đoạn bình thường khoảng 43,16 m.
  Đây là lỗi plot trước tracking, không phải kết quả tracker hoặc mức sai số của radar thật.
- OSM/DSM dùng để hiển thị và kiểm tra LOS; clutter vẫn là mô hình Poisson tổng hợp. Tất cả đường nhìn
  ở file mixed mặc định thông thoáng; không tuyên bố đã kiểm thử UAV bị che khuất địa hình.
- Chạy MAT + trackers chỉ cần MATLAB và Sensor Fusion and Tracking Toolbox; không yêu cầu Phased Array
  System Toolbox, Mapping Toolbox hoặc Python cho bước benchmark thông thường.

Nguồn API chính: xem `docs/SOURCES.md`. Giấy phép/ghi công OSM và Copernicus nằm trong `data/`.
