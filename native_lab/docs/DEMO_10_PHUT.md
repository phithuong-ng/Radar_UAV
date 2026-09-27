# Demo 10 phút — thao tác trên nhánh native

Chuẩn bị trước buổi demo: chạy NATIVE_LAB_TESTS, chạy preset cơ bản và mở lại native_session.mat; không dành buổi trình bày để cài toolbox. Chỉ demo những bước đã chạy thành công trên máy trình bày.

1. Phút 0–1: giải thích truth, detection, track; bật/tắt từng lớp.
2. Phút 1–2: tab UAV, kéo waypoint số 3 trong 2D, thả và chỉ biểu đồ tốc độ. Cho thấy kết quả cũ bị đánh dấu chưa cập nhật.
3. Phút 2–3: sửa AGL của waypoint, chỉ Up và h ellipsoid thay đổi. Tab Radar, đặt AGL anten.
4. Phút 3–4: xoay hướng radar và giảm FOV; chỉ hình chùm trước khi chạy lại.
5. Phút 4–6: bật báo giả hoặc các điểm RCS tĩnh; chạy lại. Thời gian tính phụ thuộc máy, nên chuẩn bị thêm phiên MAT đã chạy chính xác cấu hình này để trình bày nếu cần.
6. Phút 6–8: đổi GNN sang JPDA hoặc IMM và Chạy lại tracker; giải thích phép đo không đổi và nhìn GOSPA/đường bám.
7. Phút 8–9: mở Xem lệnh, chỉ nl_radar và make_tracker gốc để chứng minh thuật toán toolbox thực sự được gọi.
8. Phút 9–10: Xuất thí nghiệm, chỉ config, detections, updates, tracks, metrics và script replay.

IQ clutter/viewshed là phần trình bày thêm nếu đã chạy trước; không gọi bài IQ clutter-only là phát hiện UAV.
