# RC2 — sửa theo log chạy RC1 trên MATLAB R2025a của người dùng

## Bằng chứng đã nhận

NATIVE_LAB_CHECK: tìm thấy đủ 23 API, kể cả các API optional. required=false không phải thiếu toolbox.
NATIVE_LAB_TESTS core trên RC1: 15 Passed, 2 Failed, 1 Incomplete; tổng 177.1716 giây. Incomplete là một trong hai bài Failed, không phải bài lỗi thứ ba.

1. Bài kiểm tra chuyển hệ tọa độ đòi Cartesian bằng truth tới 1e-5 m. Trong log, sai khác khoảng 0.23 m. Đối chiếu bản R2025a cài tại máy xây gói cho thấy radarDataGenerator có khúc xạ khí quyển mặc định, kể cả HasNoise=false; bài kiểm tra cũ đã trộn tính đúng của phép đổi hệ với hiệu ứng mô hình đo.
2. Bài kiểm tra 17 tracker ngắt ở scan 1 bởi giới hạn thời gian. Log cũ chưa in tên tracker/elapsed nên không đủ kết luận chính xác bộ nào chậm hoặc nguyên nhân chậm. Không có bằng chứng toàn bộ 17 bộ đã chạy thành công.
3. Cảnh báo property not relevant xuất hiện vì các tham số cho quét điện tử được đặt ở chế độ cơ khí/không quét, và tham số GNN Score được đưa vào chế độ History.

## Mã đã sửa

- Bài chuyển hệ đối chiếu native Body Cartesian với phép đổi tọa độ từ một báo cáo native Sensor spherical của cùng mô hình. Giữ tolerance 1e-5 m cho phép đổi tọa độ, không chỉ nới tolerance của bài cũ. Có thêm giới hạn kiểm tra vật lý cho fixture cố định.
- nl_radar chỉ gán thuộc tính cơ khí khi bật quét cơ khí, chỉ gán thuộc tính điện tử/scan loss khi bật quét điện tử. Không tắt warning toàn cục.
- nl_make_tracker là adapter mỏng cho GNN History: giữ bộ khởi tạo filter gốc nhưng không truyền tham số chỉ áp dụng cho Score. Mọi kết hợp khác vẫn gọi factory gốc. src/make_tracker.m không bị sửa.
- Tách giới hạn lần gọi native đầu tiên max_initialization_seconds (mặc định 120 s) khỏi max_scan_seconds (20 s mặc định) cho bước sau. max_run_seconds giới hạn thời gian tính cộng dồn ngoài lần khởi tạo; vẫn ghi đầy đủ construction/initialization/steady/wall time. Lỗi thời gian mới có tên method, scan, elapsed và limit.
- Bài kiểm tra 17 bộ là bài kiểm tra tính đúng, dùng ngân sách thử rộng hơn (300 s khởi tạo, 120 s/bước sau, 600 s cộng dồn), in từng tên và tiếp tục thử bộ kế tiếp nếu một bộ lỗi. Bảng tracker_methods.csv được lưu trong results/native_tests. Không coi timeout thành PASS.
- Bổ sung kiểm tra giới hạn startup/steady vẫn được thực thi và kiểm tra constructor không phát các warning không phù hợp nói trên.

## Cách chạy bản sửa

1. Đóng cửa sổ Native Lab cũ. Giải nén ZIP RC2 vào thư mục MỚI, giữ nguyên bản cũ và dữ liệu tự làm.
2. Chuyển Current Folder của MATLAB đến thư mục RC2 có START_NATIVE_LAB.m.
3. Chạy riêng từng lệnh: clear functions; rồi NATIVE_LAB_CHECK; rồi NATIVE_LAB_TESTS; cuối cùng START_NATIVE_LAB.
4. Có thể kiểm tra nhanh ba bài vừa sửa bằng NATIVE_LAB_TESTS('fixes'). Chế độ này không thay thế toàn bộ core/17 tracker. Chế độ all vẫn thêm bài IQ.
5. Nếu TESTS còn lỗi, giữ console.txt và tracker_methods.csv trong results/native_tests. Chạy START_NATIVE_LAB riêng có thể mở giao diện; việc mở được app không chứng minh các bài mô phỏng/tracking đã đạt.

## Trạng thái kiểm chứng RC2

Môi trường xây gói vẫn dừng trước khi thực thi MATLAB với lỗi startup File system inconsistency. RC2 đã kiểm tra tĩnh và toàn vẹn ZIP, nhưng chưa có runtime PASS của RC2. 15 bài PASS là bằng chứng của RC1 từ người dùng, không được chuyển thành chứng nhận cho bản mới.

150 tệp và 80 dataset gốc được giữ nguyên byte. Bản sửa không yêu cầu cài lại toolbox hoặc bỏ qua assert để coi lỗi là thành công.
