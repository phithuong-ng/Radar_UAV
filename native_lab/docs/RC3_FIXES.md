# RC3 — sửa đúng điều kiện HasScanLoss trong MATLAB R2025a

Log người dùng của RC2: 18 Passed, 1 Failed, 0 Incomplete. Bài kiểm tra 17 tracker đã hoàn tất và đạt; bài duy nhất lỗi là testInactivePropertiesDoNotWarn.

Đối chiếu radarDataGenerator.m trong R2025a: phần help của HasScanLoss ghi thuộc tính chỉ áp dụng ScanMode='Custom'; isInactivePropertyImpl cũng vô hiệu hóa thuộc tính với mọi mode khác. RC2 đã suy sai rằng Electronic là điều kiện đủ.

RC3 bỏ gán HasScanLoss trong nl_radar và bỏ ô scan_loss khỏi giao diện/cấu hình mặc định. Nhánh hiện tại không triển khai Custom scanning, nên không đưa một tham số không có tác dụng vào phần tùy chỉnh. Các cấu hình RC1/RC2 đã lưu vẫn có thể chứa scan_loss; trường cũ được giữ như dữ liệu tương thích nhưng không được áp dụng. Bài kiểm tra cảnh báo vẫn giữ nguyên, bổ sung cả trường hợp đọc trường cũ true/false. Không tắt cảnh báo, không bỏ qua assert.

Các phép tính radar, thuật toán tracking và ngân sách thời gian còn lại giữ như RC2. Toàn bộ 150 tệp gốc/80 dataset vẫn nguyên byte. Code Analyzer R2025a đã kiểm tra mã mới. RC3 chưa có runtime PASS tại môi trường xây gói do lỗi khởi động MATLAB đã nêu ở các bản trước; không dùng 18 bài PASS của RC2 để tuyên bố đã chạy RC3.

## Cài bản vá nhỏ lên RC2

1. Đóng cửa sổ Native Lab đang mở.
2. Giải nén NoiBai_Radar_RC2_TO_RC3_PATCH.zip. Bên trong có thư mục NoiBai_Radar_v8_4_FULL_R2025a.
3. Mở thư mục đó, chép các mục bên trong vào thư mục project RC2 đang dùng (nơi có START_NATIVE_LAB.m). Chọn thay thế các tệp trùng tên. Không tạo thêm một cấp thư mục lồng bên trong. Bản vá không chứa results hoặc dữ liệu người dùng.
4. Trong MATLAB, đặt Current Folder đúng thư mục vừa vá. Chạy riêng: clear functions; sau đó NATIVE_LAB_TESTS('fixes').
5. Nếu ba bài kiểm tra đạt, chạy riêng START_NATIVE_LAB. Không cần chạy lại 17 tracker chỉ để kiểm tra phép sửa property này. Có thể chạy NATIVE_LAB_TESTS sau đó để kiểm tra toàn bộ core khi cần.

Nếu không muốn chép đè tệp mã, dùng ZIP FULL_RC3 và giải nén vào thư mục mới. Nếu vẫn thấy cảnh báo ở dòng sensor.HasScanLoss, chạy which nl_radar -all để xác định MATLAB có đang dùng một bản cũ trên path hay không.
