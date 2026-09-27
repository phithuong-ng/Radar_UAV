SYNTHETIC_SCHEMA_EXAMPLE — KHÔNG PHẢI PHÉP ĐO RADAR THẬT

Dùng baseline nl_defaults của RC4, giữ mốc ENU mặc định. Đặt dt=1 rồi frames=121, radar update_every_steps=1. Nhập detections_enu.csv từ tab Phiên; updates.csv đặt cùng thư mục.

Tọa độ và covariance được tạo minh họa định dạng: vị trí ENU m, covariance m²; 121 frame, 110 dòng detection, không có detection ở t=40..50 s nhưng lượt đo vẫn hợp lệ. Các tọa độ nằm trên một đường thẳng, không giả làm mẫu nhiễu đã hiệu chuẩn. Không có truth được import; OSPA/GOSPA trống.

Xem B24 trong WORKFLOW_RC4.html. Mã ứng dụng không thay đổi trong bản cập nhật tài liệu v2.
