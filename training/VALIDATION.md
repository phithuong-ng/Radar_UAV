# Trạng thái kiểm chứng — 25/09/2026

## Đã kiểm chứng trong phiên đóng gói

- SHA-256 đối chiếu với ZIP đầu vào: giữ nguyên **150/150 tệp gốc**; không thay đổi mã/config/dữ liệu cũ.
- Có đủ **80 file dataset MAT**, mỗi file có 160 thời điểm, detections 20 cột, truth 14 cột.
- Đã đọc định dạng MAT-v5 bằng trình kiểm tra độc lập để xác minh kích thước/biến, không chạy mô phỏng bằng Python thay MATLAB.
- Sáu cấu hình JSON đọc hợp lệ; waypoint được kiểm tra trong vùng DEM và trên bề mặt tại điểm lưới gần nhất. Kiểm tra này chưa kiểm tra toàn bộ đường nội suy; mã MATLAB có kiểm tra thêm khi chạy.
- Dùng **Code Analyzer (mlint.exe) đi kèm MATLAB R2025a** kiểm tra 19 tệp MATLAB mới. Không báo lỗi cú pháp. Nhật ký giữ nguyên cả cảnh báo style/unused trong `validation/static_analyzer.txt`.
- Kiểm tra độc lập đại số biến đổi ENU↔NED và yaw +90° của radar bằng một điểm thử. Kiểm thử API native cho phép đổi này nằm trong `tests/test_training.m`, chưa được thực thi.
- Đối chiếu tên block 6DOF Euler Angles với thư viện SLX R2025a đã cài. Đọc help/source API R2025a tại máy và tài liệu MathWorks liên quan.
- ZIP cuối được kiểm tra CRC và SHA-256 từng tệp nội dung; xem manifest và file checksum bàn giao.

## Chưa kiểm chứng bằng thực thi MATLAB

Hai lần gọi MATLAB R2025a tự động đều kết thúc trước khi script chạy:

```
Fatal Startup Error:
Dynamic exception type: class std::runtime_error
std::exception::what: System Error: File system inconsistency
ERROR: MATLAB error Exit Status: 0x00000001
```

Lần thứ hai đã dùng thư mục preference và temp riêng trong workspace, lỗi vẫn lặp lại. Vì vậy **không có kết quả PASS native, ảnh chụp GUI đang chạy, điểm benchmark mới, SLX đã mô phỏng hay C đã sinh sẵn** được tuyên bố trong gói này. Lỗi cụ thể chưa được quy kết cho license hay source code vì script chưa được chạy.

19 tệp được static-check không có nghĩa tất cả API, license, đồ họa, System object hay cấu hình Simulink sẽ hoạt động ở runtime. Bản này là mã thực hành hoàn chỉnh kèm dữ liệu và bài kiểm tra, cần xác nhận runtime trên MATLAB của bạn.

## Chạy xác nhận trên máy

```
START_TRAINING
training_check
training_tests
training_smoke
```

- `training_tests`: test cấu hình/JSON, hình học và covariance, đổi góc native radar, quỹ đạo/DEM, xuất MAT và cầu nối objectDetection. Thiếu API tạo Incomplete, không được tính PASS.
- `training_smoke`: 7 bài cốt lõi; ghi PASS / FAILED / SKIPPED_MISSING_API riêng từng bài. Nhánh cũ cũng có `run_tests`; chạy thêm trước khi làm benchmark nghiêm túc.
- Bài 08–13 chạy riêng bằng `training_run('08_antenna')`, tương tự cho các ID còn lại.
- 14/16 có trạng thái BUILT_NOT_SIMULATED theo thiết kế; 15 có GENERATED_NOT_COMPILED. Đó không phải xác nhận chạy vật lý, renderer hoặc binary.
- Không có benchmark hiệu năng hay khẳng định “tối ưu” nào được suy từ static check.

## Phạm vi mô hình

Luồng 03/04 dùng radar thống kê native, kiểm tra che khuất DSM lấy mẫu; luồng 05 dùng waveform LFM và echo một mục tiêu giản lược. Chưa ghép waveform → detections, antenna pattern → gain native, GPS/IMU → fusion, hoặc 6DOF → trajectory radar. Các bước này được nêu rõ trong lộ trình học.

Giữ nguyên giấy phép MIT của code và ghi công dữ liệu Copernicus/OSM. Không sao chép mã MathWorks hoặc toolbox vào gói.
