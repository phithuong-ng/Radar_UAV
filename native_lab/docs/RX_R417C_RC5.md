# RX‑R417C · Phòng thử nghiệm RC5

## Mục đích

Cấu hình mô phỏng bốn mặt anten quét điện tử, quan sát chùm quét và UAV trên nền OSM có sẵn, tạo dataset rồi so sánh thuật toán. Đây là mô hình ở mức phép đo chạy bằng radarDataGenerator, uavScenario và Mapping Toolbox. Không cần Python để sử dụng project. Chưa gửi lệnh tới radar thật.

## Bắt đầu trong MATLAB R2025a

1. Giải nén FULL_RC5 vào một thư mục mới. Không chép lên thư mục đang chứa kết quả thí nghiệm.
2. Trong MATLAB, mở thư mục có START_NATIVE_LAB.m làm Current Folder.
3. Chạy `NATIVE_LAB_CHECK` để kiểm tra sự hiện diện API. Kết quả này không xác nhận license hay chạy mô phỏng thành công.
4. Chạy `NATIVE_LAB_TESTS('rx')`. Bộ mới kiểm tra hướng bốn mặt, phép đo native, lịch chùm, số hiệu mặt, lưu/nhập CSV, bám và OSM/3D.
5. Chạy `START_NATIVE_LAB`. Mặc định mở preset **07 RX-R417C: bốn mặt điện tử**, nền OSM bật, góc nhìn 3D và tỷ lệ cao độ Auto.
6. Trước khi tính, dùng **Phát / Dừng**, **Từng bước** hoặc thanh thời gian để xem chùm quét native cùng đường bay cấu hình. Chỉ khi nhấn **Tạo dataset** hoặc **Mô phỏng + bám** mới sinh dữ liệu mục tiêu.

MATLAB tại môi trường đóng gói lỗi khởi động `File system inconsistency` trước khi chạy mã. Phân tích tĩnh và kiểm tra gói được ghi riêng; không coi các bài kiểm thử MATLAB hoặc hình giao diện mới là đã chạy đạt.

## Cách đọc giao diện

- **Radar → Thiết bị & nhiệm vụ:** hồ sơ, nhiệm vụ Search/Focus, hướng tương đối và bật/tắt bốn mặt, vùng tập trung. Hộp tóm tắt cho biết thời gian mỗi bước chùm, số hướng và chu kỳ tính theo lưới quét.
- **Radar → Thông số đo & vùng quét:** vị trí, hướng đế, độ nghiêng, biên vùng Search, bề rộng chùm thử nghiệm, cự ly, RCS, Pd, nhiễu và độ phân giải. Khi dùng RX, Raster/Electronic được áp dụng cố định; các trường quét cơ khí không được hiển thị.
- **UAV:** từng waypoint (điểm phải đi qua) gồm E/N/U theo mét và thời gian đến theo giây. AGL là độ cao so với mặt đất, khác Up ENU. Các thao tác chỉnh đường bay, nhập LLA vẫn giữ nguyên.
- **Địa hình, Clutter, Tracking, Phiên, IQ:** giữ các chức năng RC4. IQ là bài riêng, không phải tín hiệu thu RX-R417C, không tự sinh điểm đo cho cảnh này.
- **OSM:** bật/tắt đường bộ, đường băng, đường lăn, sân đỗ và viền công trình trên nền xanh. Dùng dữ liệu offline trong project, không tải bản đồ mạng.
- **Tỷ lệ cao độ:** chọn Auto, 1, 3, 6, 12 hoặc 20. ×12 nghĩa chiều cao được vẽ phóng đại 12 lần so với chiều ngang. Nhãn trục vẫn là số mét thật. Không thay quỹ đạo, dữ liệu, DEM hoặc đường bám. Chọn ×1 để xem cùng tỷ lệ vật lý.
- **Vùng quét:** bật/tắt đường chấm biểu diễn biên vùng có thể quét. Đường liền xanh biểu diễn chùm đang quan sát. Các hình này chỉ là hình học, không biểu diễn xác suất phát hiện.
- **Toàn tầm radar:** mở rộng khung hình theo tầm xa đang cấu hình. Chỉ đổi góc nhìn, không đổi miền thí nghiệm hay tự mở rộng DEM. Ngoài vùng bản đồ đã có sẽ không có đường OSM/địa hình để hiển thị.

Chú giải dùng đúng các dấu vẽ trong cảnh: tam giác cho UAV, chấm cho phép đo, hình vuông cho radar và đường có dấu tròn cho track. Màu của hai UAV chỉ phân biệt hai mục tiêu.

## Những gì lấy từ datasheet và những gì đang giả định

Nguồn: RX-R417C X-band Long-range four-face radar Technical Specification, Bảng 1 trang in 3–5; chức năng phần mềm trang in 3. Không coi các chỉ tiêu có dấu ≤/≥ là giá trị đo chính xác.

| Nội dung | Giá trị RC5 | Ý nghĩa |
|---|---|---|
| Kiến trúc | 4 mặt; hướng tương đối 0/90/180/270° | Mô hình bốn mặt. Cùng tâm pha, chạy đồng thời là giả định thí nghiệm; chưa biết lịch chia tài nguyên của hãng. |
| Vùng Search | Mỗi mặt −45..45° ngang; 0..60° đứng | Đế cân bằng tạo vùng phủ danh định 360°. Khi nghiêng đế, vùng phủ cũng nghiêng. |
| Cự ly | 200..10000 m | Chọn giới hạn bảo thủ từ vùng mù ≤200 m và tầm phát hiện ≥10 km. Không chứng minh radar mù chính xác 200 m hoặc bị chặn ở 10 km. |
| RCS tham chiếu | 0,01 m² | Diện tích phản xạ radar tương đương, không phải diện tích hình học UAV. |
| Pd tại 10 km | 0,9 | Giả định kiểm soát được. PDF không cho Pd/Pfa và điều kiện kiểm định tại 10 km. |
| Tần số | 9,4 GHz | Giá trị thử nghiệm thuộc băng X; PDF chưa nêu tần số cụ thể. |
| Độ phân giải | 15 m / 6° / 4° | Dùng các ngưỡng công bố để thử. Không đồng nhất với độ chính xác RMS. |
| Chùm thử nghiệm | Tối đa 30° × 20° | Chưa có số hãng. Là FOV thống kê trong mô hình Electronic, không phải mô hình phần tử anten/beamforming đã hiệu chuẩn. |
| Nhịp bước chùm | 0,2 s | Do dt × N quyết định. Khác chu kỳ quay lại cùng hướng/mục tiêu. |
| Search | 9 hướng/mặt; lưới danh định 1,8 s | Bốn mặt song song. Chuỗi góc thực lấy trực tiếp từ sensor native. Đây không phải firmware TWS. |
| Focus | Một mặt; mặc định một hướng, 0,2 s | Thử vùng ưu tiên nhỏ. Không phải TAS bám 24 mục tiêu; không tự hướng chùm theo truth hoặc kết quả bám, không xen kẽ tìm kiếm. |
| Track capacity | 500 | Giới hạn bộ bám trong phần mềm. Không cam kết tốc độ xử lý 500 mục tiêu trên máy của bạn. |

**Các chỗ chưa mô phỏng:** sai số RMS đã hiệu chuẩn theo từng chế độ; suy hao quét đặc thù anten; micro-Doppler và AI phân loại của hãng; giới hạn phát hiện theo vận tốc 1–100 m/s; vận tốc Doppler trong dữ liệu bám; thời gian xử lý/giao thức thiết bị. Giới hạn tốc độ UAV 100 m/s chỉ kiểm tra đường bay, không phải mô hình lọc Doppler của radar.

## Bài 1 · Hiểu bốn mặt và quét điện tử

1. Chọn preset **07 RX-R417C: bốn mặt điện tử** ở góc trên trái.
2. Chọn **2D**, bật **Vùng quét** và **Toàn tầm radar**.
3. Bấm **Từng bước** vài lần. Quan sát chùm đổi hướng trong khi vị trí đế radar không quay. Bốn mặt được điều khiển bởi bốn radarDataGenerator ở chế độ Electronic.
4. Trong tab **Radar → Thiết bị & nhiệm vụ**, nhấp đôi ô giá trị **Bật các mặt 1/2/3/4**, nhập `[true,false,false,false]`, nhấn Enter.
5. Quan sát còn một mặt. Nhập lại `[true,true,true,true]` để bật đủ bốn mặt.
6. Trong tab **Radar**, đổi **Hướng: 0 Đông, 90 Bắc** từ `0` thành `45`. Cả cụm bốn mặt đổi hướng cùng đế; OSM giữ nguyên vị trí địa lý.

Mỗi mặt có số hiệu 1–4, lưu trong SensorIndex của phép đo. Không trộn thành một sensor_id giả. Nhiều mặt có thể quan sát cùng mục tiêu ở vùng giao; dữ liệu đó được giao cho tracker native theo đúng số hiệu mặt.

## Bài 2 · Đổi vùng quét và nhịp quan sát

1. Trở lại preset 07. Tab **Radar**, đổi **Biên vùng Search đứng** từ `[0,60]` thành `[0,20]`.
2. Hộp tóm tắt trong tab Radar → Thiết bị & nhiệm vụ giảm từ 9 xuống 3 hướng mỗi mặt. Vùng cao trên 20° không còn thuộc vùng Search cấu hình khi đế cân bằng.
3. Đổi **Chùm thử nghiệm [ngang,đứng]** từ `[30,20]` thành `[15,10]`. Lưới tăng lên 12 hướng mỗi mặt; một vòng danh định 2,4 s với nhịp 0,2 s.
4. Đổi **Đo mỗi N bước** từ `1` thành `2`. Chùm đổi hướng mỗi 0,4 s; một vòng danh định 4,8 s. Quan sát thanh thời gian: các bước xen giữa không có lượt đo mới.
5. Bấm **Tạo dataset**, đặt tên `search_15x10_N2`. Dataset lưu đúng cấu hình này; tên chỉ để gợi nhớ.

Giảm bề rộng chùm khi giữ nguyên nhịp lấy mẫu làm tăng số hướng cần quét. Không nhập 0,5 s vào một ô rồi mặc định mọi mục tiêu đều được cập nhật mỗi 0,5 s. Khi vùng không chia hết cho chùm tối đa, chương trình chia đều thành các ô nhỏ hơn để không chừa khoảng trống; đọc bề rộng thực dùng ở phần tóm tắt.

## Bài 3 · Tập trung vào một vùng

1. Chọn preset **08 RX-R417C: vùng tập trung**. Mặc định mặt 1 nhìn hướng Đông của đế; chỉ mặt này hoạt động.
2. Ở tab Radar → Thiết bị & nhiệm vụ, đặt **Mặt dùng trong Focus** thành `2`: vùng hoạt động chuyển sang mặt thứ hai.
3. Đặt lại mặt `1`. Đổi **Vùng Focus: phương vị** từ `[-15,15]` thành `[10,40]`. Vùng quan sát đổi hướng trong hệ tọa độ mặt, không cần quay đế.
4. Đổi **Vùng Focus: góc ngẩng** thành `[0,40]`: cần nhiều bước chùm hơn để phủ vùng đứng rộng hơn.
5. Đổi **Nhiệm vụ quét** thành `Search`: các mặt đã bật lại dùng vùng Search trong tab Radar.

Focus là một bài thử vùng ưu tiên do bạn chỉ định. Nó không tìm tọa độ thật UAV để bí mật chĩa theo mục tiêu và không tái hiện bộ lập lịch TAS của nhà sản xuất.

## Bài 4 · Chỉnh UAV và xem ngay trên OSM

1. Tắt **Toàn tầm radar** để trở lại miền UAV; chọn **2D**.
2. Tab **UAV**, chọn UAV_1. Kéo vòng tròn waypoint trên hình, hoặc nhập East/North trong bảng. Sau khi thả chuột, quỹ đạo được dựng lại bằng waypointTrajectory.
3. Đổi AGL một điểm từ giá trị hiện tại lên `180` m. AGL là khoảng cách thẳng đứng so với DEM tại vị trí đó.
4. Chuyển sang **3D**, đổi **Tỷ lệ cao độ** lần lượt `1`, `6`, `12`. Các tọa độ trong bảng không đổi. Chọn `Auto` để tự cân đối khung 3D. Nhãn trục dùng Đông (m), Bắc (m), Cao độ ENU (m), không ghi hệ số phóng đại.
5. Bỏ chọn **OSM**, rồi bật lại: chỉ các đường bản đồ thay đổi, dữ liệu đo và địa hình tính toán không đổi.

OSM là lớp ngữ cảnh trực quan, không tự tạo clutter hoặc vật cản trong LOS. Chương trình lấy XY từ bản đồ gốc, khôi phục tọa độ địa lý bằng cặp lưới MAT/GeoTIFF gốc, phủ lại lên DEM hiện hành và đổi sang ENU theo mốc phiên. Các đường được nâng 1,5 m chỉ để tránh chìm vào mặt vẽ; không đưa phần nâng này vào mô phỏng. Không dựng các nhà giả định thành vật cản thật.

## Bài 5 · Tạo dataset và so sánh thuật toán

1. Chọn preset 07, giữ GNN mặc định rồi bấm **Mô phỏng + bám**. Nhập tên, ví dụ `RX_search_baseline`.
2. Chương trình lưu dataset trước, sau đó chạy tracker và lưu kết quả. Bấm **Mở kết quả đã lưu** để xem thư mục.
3. Trong tab **Tracking**, đổi Data association sang JPDA; chọn bộ ước lượng tương ứng rồi bấm **Chạy cấu hình tracker**. Tập phép đo được giữ nguyên.
4. Thêm các cấu hình cần so sánh vào hàng đợi, bấm **Chạy hàng đợi** để lưu báo cáo chung.
5. Trong thư mục kết quả, mở `scan_state.csv`: mỗi hàng cho biết thời gian, số mặt, góc chùm ngang/đứng, lượt đo hợp lệ, kết thúc vòng quét và số điểm.
6. `detections_enu.csv` giữ sensor_id của mặt; `native_session.mat` giữ dữ liệu native, cấu hình và kết quả. `session.json` giúp đọc lại các thông số. Dùng **Thư viện dataset / run** để mở đúng phiên đã lưu.

GNN/JPDA có tùy chọn **Bám xét chùm đang quét**: vị trí track được dự đoán bằng bộ lọc, sau đó kiểm tra hình học chùm. Một track nằm ngoài chùm không bị tính là một lần radar bỏ sót ở bước đó. Đây là xét cơ hội quan sát bằng vị trí ước lượng, không dùng truth và không thay thế mô hình xác suất phát hiện đã hiệu chuẩn. Track ra khỏi toàn vùng có thể cần quy tắc kết thúc bổ sung cho thử nghiệm dài. TOMHT/PHD vẫn dùng logic riêng với prior cố định; cần chỉnh tham số quản lý track khi chu kỳ quan sát thưa. Không coi mọi tổ hợp có chất lượng ngang nhau.

CSV nhập độc lập không chứa lịch chùm native nên không bật cơ chế xét chùm chỉ dựa vào cấu hình. Mở lại dataset MAT để phát lại đầy đủ lịch đã ghi.

## Bài 6 · Thêm clutter có kiểm soát

1. Lưu cấu hình baseline. Tab **Clutter**, bật **Báo động giả ngẫu nhiên**, giữ Pfa ban đầu nhỏ rồi tạo dataset mới.
2. So sánh số phép đo và GOSPA với baseline. Pfa là xác suất mỗi ô phân giải, không phải số chấm giả mỗi khung hình. Thay độ phân giải cũng có thể đổi số ô và số báo giả.
3. Bật **Điểm phản xạ tĩnh**, chỉnh East/North/AGL/RCS trong bảng. Chúng là các mục tiêu phản xạ đứng yên được đưa vào radar native.
4. Đổi seed ở tab **Phiên** để tạo một lần thử ngẫu nhiên khác. Giữ seed và toàn bộ cấu hình để tái lập lần cũ.

Không suy từ việc thêm vài điểm tĩnh rằng đã tái tạo thuật toán khử clutter mưa/mây của RX-R417C.

## Tệp mới và phạm vi thay đổi

- `nl_rx_preset.m`: giá trị khởi đầu Search/Focus, có chú thích giả định.
- `nl_device.m`, `nl_faces.m`, `nl_sensor_bank.m`: cấu hình thiết bị và các cảm biến native theo mặt.
- `nl_scan_preview.m`: lấy hướng quét từ API native, lưu đệm để xem trước; không tự thay thuật toán quét của toolbox.
- `nl_in_beam.m`: kiểm tra vị trí dự đoán thuộc chùm đang nhìn cho GNN/JPDA.
- `nl_osm.m`, `nl_plot_map.m`: dùng lại dữ liệu bản đồ gốc và vẽ nền xanh.
- `test_native_rx.m`: bộ kiểm thử RC5. Sổ tay RC4 vẫn dùng cho các chức năng nền, tham số tracker và hệ tọa độ.

Nguồn bản đồ: © OpenStreetMap contributors, ODbL; địa hình Copernicus GLO-30. Giữ các tệp attribution và provenance có sẵn. 150 tệp của ZIP gốc và 80 dataset gốc phải được đối chiếu nguyên vẹn khi đóng gói.

## Khi radar thật về

Giữ giao diện học này. Bổ sung adapter theo giao thức nhà sản xuất, xác nhận bản tin là điểm đo hay track, quy ước góc/cao độ/thời gian, và thu dữ liệu đối chứng. Những việc đó chưa được thực hiện trong RC5. Không nhập địa chỉ IP rồi cho rằng các cấu hình mô phỏng đã được ghi vào thiết bị.
