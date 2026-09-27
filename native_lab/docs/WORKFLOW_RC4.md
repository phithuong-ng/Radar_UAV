# Sổ tay Native Lab RC5: hiểu bản chất, cấu hình và kiểm chứng

Sổ tay hợp nhất RC5 • cập nhật giao diện RC5.2 • 27/09/2026 • Dành cho người mới • Đối chiếu mã nguồn RC5 / MATLAB R2025a

Bạn sẽ học theo một vòng lặp: **hiểu đại lượng → sửa đúng ô → quan sát đúng hình → chạy khi cần → lưu bằng chứng → giải thích kết quả**. Không cần đọc toàn bộ mã để bắt đầu. **Để tiếp tục bản RX-R417C, đọc chương 0 và làm B27–B32. B01–B26 dùng preset 01 Generic như ghi trong từng bài.** Tên trong dấu `...` là tên trường có thể tra trong cấu hình hoặc MATLAB; chữ in đậm là nhãn thao tác trên giao diện.

## 0. RC5: RX-R417C, OSM và quan sát 3D

### 0.1. Mục đích

Cấu hình mô phỏng bốn mặt anten quét điện tử, quan sát chùm quét và UAV trên nền OSM có sẵn, tạo dataset rồi so sánh thuật toán. Đây là mô hình ở mức phép đo chạy bằng radarDataGenerator, uavScenario và Mapping Toolbox. Không cần Python để sử dụng project. Chưa gửi lệnh tới radar thật.

### 0.2. Bắt đầu trong MATLAB R2025a

1. Giải nén FULL_RC5 vào một thư mục mới. Không chép lên thư mục đang chứa kết quả thí nghiệm.
2. Trong MATLAB, mở thư mục có START_NATIVE_LAB.m làm Current Folder.
3. Chạy `NATIVE_LAB_CHECK` để kiểm tra sự hiện diện API. Kết quả này không xác nhận license hay chạy mô phỏng thành công.
4. Chạy `NATIVE_LAB_TESTS('rx')`. Bộ mới kiểm tra hướng bốn mặt, phép đo native, lịch chùm, số hiệu mặt, lưu/nhập CSV, bám và OSM/3D.
5. Chạy `START_NATIVE_LAB`. Mặc định mở preset **07 RX-R417C: bốn mặt điện tử**, nền OSM bật, góc nhìn 3D và tỷ lệ cao độ Auto.
6. Trước khi tính, dùng **Phát / Dừng**, **Từng bước** hoặc thanh thời gian để xem chùm quét native cùng đường bay cấu hình. Chỉ khi nhấn **Tạo dataset** hoặc **Mô phỏng + bám** mới sinh dữ liệu mục tiêu.

MATLAB tại môi trường đóng gói lỗi khởi động `File system inconsistency` trước khi chạy mã. Phân tích tĩnh và kiểm tra gói được ghi riêng; không coi các bài kiểm thử MATLAB hoặc hình giao diện mới là đã chạy đạt.

### 0.3. Cách đọc giao diện

- **Radar → Thiết bị & nhiệm vụ:** hồ sơ, nhiệm vụ Search/Focus, hướng tương đối và bật/tắt bốn mặt, vùng tập trung. Hộp tóm tắt cho biết thời gian mỗi bước chùm, số hướng và chu kỳ tính theo lưới quét.
- **Radar → Thông số đo & vùng quét:** vị trí, hướng đế, độ nghiêng, biên vùng Search, bề rộng chùm thử nghiệm, cự ly, RCS, Pd, nhiễu và độ phân giải. Khi dùng RX, Raster/Electronic được áp dụng cố định; các trường quét cơ khí không được hiển thị.
- **UAV:** từng waypoint (điểm phải đi qua) gồm E/N/U theo mét và thời gian đến theo giây. AGL là độ cao so với mặt đất, khác Up ENU. Các thao tác chỉnh đường bay, nhập LLA vẫn giữ nguyên.
- **Địa hình, Clutter, Tracking, Phiên, IQ:** giữ các chức năng RC4. IQ là bài riêng, không phải tín hiệu thu RX-R417C, không tự sinh điểm đo cho cảnh này.
- **OSM:** bật/tắt đường bộ, đường băng, đường lăn, sân đỗ và viền công trình trên nền xanh. Dùng dữ liệu offline trong project, không tải bản đồ mạng.
- **Tỷ lệ cao độ:** Auto là chế độ mặc định; tự cân đối chiều đứng, nhãn trục không hiển thị hệ số phóng đại. chọn Auto, 1, 3, 6, 12 hoặc 20. ×12 nghĩa chiều cao được vẽ phóng đại 12 lần so với chiều ngang. Nhãn trục vẫn là số mét thật. Không thay quỹ đạo, dữ liệu, DEM hoặc đường bám. Chọn ×1 để xem cùng tỷ lệ vật lý.
- **Vùng quét:** bật/tắt đường chấm biểu diễn biên vùng có thể quét. Đường liền xanh biểu diễn chùm đang quan sát. Các hình này chỉ là hình học, không biểu diễn xác suất phát hiện.
- **Toàn tầm radar:** mở rộng khung hình theo tầm xa đang cấu hình. Chỉ đổi góc nhìn, không đổi miền thí nghiệm hay tự mở rộng DEM. Ngoài vùng bản đồ đã có sẽ không có đường OSM/địa hình để hiển thị.

Chú giải dùng đúng các dấu vẽ trong cảnh: tam giác cho UAV, chấm cho phép đo, hình vuông cho radar và đường có dấu tròn cho track. Màu của hai UAV chỉ phân biệt hai mục tiêu.

### 0.4. Những gì lấy từ datasheet và những gì đang giả định

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

### B27 — Hiểu bốn mặt và quét điện tử

1. Chọn preset **07 RX-R417C: bốn mặt điện tử** ở góc trên trái.
2. Chọn **2D**, bật **Vùng quét** và **Toàn tầm radar**.
3. Bấm **Từng bước** vài lần. Quan sát chùm đổi hướng trong khi vị trí đế radar không quay. Bốn mặt được điều khiển bởi bốn radarDataGenerator ở chế độ Electronic.
4. Trong tab **Radar → Thiết bị & nhiệm vụ**, nhấp đôi ô giá trị **Bật các mặt 1/2/3/4**, nhập `[true,false,false,false]`, nhấn Enter.
5. Quan sát còn một mặt. Nhập lại `[true,true,true,true]` để bật đủ bốn mặt.
6. Trong tab **Radar**, đổi **Hướng: 0 Đông, 90 Bắc** từ `0` thành `45`. Cả cụm bốn mặt đổi hướng cùng đế; OSM giữ nguyên vị trí địa lý.

Mỗi mặt có số hiệu 1–4, lưu trong SensorIndex của phép đo. Không trộn thành một sensor_id giả. Nhiều mặt có thể quan sát cùng mục tiêu ở vùng giao; dữ liệu đó được giao cho tracker native theo đúng số hiệu mặt.

### B28 — Đổi vùng quét và nhịp quan sát

1. Trở lại preset 07. Tab **Radar**, đổi **Biên vùng Search đứng** từ `[0,60]` thành `[0,20]`.
2. Hộp tóm tắt trong tab Radar → Thiết bị & nhiệm vụ giảm từ 9 xuống 3 hướng mỗi mặt. Vùng cao trên 20° không còn thuộc vùng Search cấu hình khi đế cân bằng.
3. Đổi **Chùm thử nghiệm [ngang,đứng]** từ `[30,20]` thành `[15,10]`. Lưới tăng lên 12 hướng mỗi mặt; một vòng danh định 2,4 s với nhịp 0,2 s.
4. Đổi **Đo mỗi N bước** từ `1` thành `2`. Chùm đổi hướng mỗi 0,4 s; một vòng danh định 4,8 s. Quan sát thanh thời gian: các bước xen giữa không có lượt đo mới.
5. Bấm **Tạo dataset**, đặt tên `search_15x10_N2`. Dataset lưu đúng cấu hình này; tên chỉ để gợi nhớ.

Giảm bề rộng chùm khi giữ nguyên nhịp lấy mẫu làm tăng số hướng cần quét. Không nhập 0,5 s vào một ô rồi mặc định mọi mục tiêu đều được cập nhật mỗi 0,5 s. Khi vùng không chia hết cho chùm tối đa, chương trình chia đều thành các ô nhỏ hơn để không chừa khoảng trống; đọc bề rộng thực dùng ở phần tóm tắt.

### B29 — Tập trung vào một vùng

1. Chọn preset **08 RX-R417C: vùng tập trung**. Mặc định mặt 1 nhìn hướng Đông của đế; chỉ mặt này hoạt động.
2. Ở tab Radar → Thiết bị & nhiệm vụ, đặt **Mặt dùng trong Focus** thành `2`: vùng hoạt động chuyển sang mặt thứ hai.
3. Đặt lại mặt `1`. Đổi **Vùng Focus: phương vị** từ `[-15,15]` thành `[10,40]`. Vùng quan sát đổi hướng trong hệ tọa độ mặt, không cần quay đế.
4. Đổi **Vùng Focus: góc ngẩng** thành `[0,40]`: cần nhiều bước chùm hơn để phủ vùng đứng rộng hơn.
5. Đổi **Nhiệm vụ quét** thành `Search`: các mặt đã bật lại dùng vùng Search trong tab Radar.

Focus là một bài thử vùng ưu tiên do bạn chỉ định. Nó không tìm tọa độ thật UAV để bí mật chĩa theo mục tiêu và không tái hiện bộ lập lịch TAS của nhà sản xuất.

### B30 — Chỉnh UAV và xem ngay trên OSM

1. Tắt **Toàn tầm radar** để trở lại miền UAV; chọn **2D**.
2. Tab **UAV**, chọn UAV_1. Kéo vòng tròn waypoint trên hình, hoặc nhập East/North trong bảng. Sau khi thả chuột, quỹ đạo được dựng lại bằng waypointTrajectory.
3. Đổi AGL một điểm từ giá trị hiện tại lên `180` m. AGL là khoảng cách thẳng đứng so với DEM tại vị trí đó.
4. Chuyển sang **3D**, đổi **Tỷ lệ cao độ** lần lượt `1`, `6`, `12`. Các tọa độ trong bảng không đổi. Chọn `Auto` để tự cân đối khung 3D. Nhãn trục dùng Đông (m), Bắc (m), Cao độ ENU (m), không ghi hệ số phóng đại.
5. Bỏ chọn **OSM**, rồi bật lại: chỉ các đường bản đồ thay đổi, dữ liệu đo và địa hình tính toán không đổi.

OSM là lớp ngữ cảnh trực quan, không tự tạo clutter hoặc vật cản trong LOS. Chương trình lấy XY từ bản đồ gốc, khôi phục tọa độ địa lý bằng cặp lưới MAT/GeoTIFF gốc, phủ lại lên DEM hiện hành và đổi sang ENU theo mốc phiên. Các đường được nâng 1,5 m chỉ để tránh chìm vào mặt vẽ; không đưa phần nâng này vào mô phỏng. Không dựng các nhà giả định thành vật cản thật.

### B31 — Tạo dataset và so sánh thuật toán

1. Chọn preset 07, giữ GNN mặc định rồi bấm **Mô phỏng + bám**. Nhập tên, ví dụ `RX_search_baseline`.
2. Chương trình lưu dataset trước, sau đó chạy tracker và lưu kết quả. Bấm **Mở kết quả đã lưu** để xem thư mục.
3. Trong tab **Tracking**, đổi Data association sang JPDA; chọn bộ ước lượng tương ứng rồi bấm **Chạy cấu hình tracker**. Tập phép đo được giữ nguyên.
4. Thêm các cấu hình cần so sánh vào hàng đợi, bấm **Chạy hàng đợi** để lưu báo cáo chung.
5. Trong thư mục kết quả, mở `scan_state.csv`: mỗi hàng cho biết thời gian, số mặt, góc chùm ngang/đứng, lượt đo hợp lệ, kết thúc vòng quét và số điểm.
6. `detections_enu.csv` giữ sensor_id của mặt; `native_session.mat` giữ dữ liệu native, cấu hình và kết quả. `session.json` giúp đọc lại các thông số. Dùng **Thư viện dataset / run** để mở đúng phiên đã lưu.

GNN/JPDA có tùy chọn **Bám xét chùm đang quét**: vị trí track được dự đoán bằng bộ lọc, sau đó kiểm tra hình học chùm. Một track nằm ngoài chùm không bị tính là một lần radar bỏ sót ở bước đó. Đây là xét cơ hội quan sát bằng vị trí ước lượng, không dùng truth và không thay thế mô hình xác suất phát hiện đã hiệu chuẩn. Track ra khỏi toàn vùng có thể cần quy tắc kết thúc bổ sung cho thử nghiệm dài. TOMHT/PHD vẫn dùng logic riêng với prior cố định; cần chỉnh tham số quản lý track khi chu kỳ quan sát thưa. Không coi mọi tổ hợp có chất lượng ngang nhau.

CSV nhập độc lập không chứa lịch chùm native nên không bật cơ chế xét chùm chỉ dựa vào cấu hình. Mở lại dataset MAT để phát lại đầy đủ lịch đã ghi.

### B32 — Thêm clutter có kiểm soát

1. Lưu cấu hình baseline. Tab **Clutter**, bật **Báo động giả ngẫu nhiên**, giữ Pfa ban đầu nhỏ rồi tạo dataset mới.
2. So sánh số phép đo và GOSPA với baseline. Pfa là xác suất mỗi ô phân giải, không phải số chấm giả mỗi khung hình. Thay độ phân giải cũng có thể đổi số ô và số báo giả.
3. Bật **Điểm phản xạ tĩnh**, chỉnh East/North/AGL/RCS trong bảng. Chúng là các mục tiêu phản xạ đứng yên được đưa vào radar native.
4. Đổi seed ở tab **Phiên** để tạo một lần thử ngẫu nhiên khác. Giữ seed và toàn bộ cấu hình để tái lập lần cũ.

Không suy từ việc thêm vài điểm tĩnh rằng đã tái tạo thuật toán khử clutter mưa/mây của RX-R417C.

### 0.5. Tệp mới và phạm vi thay đổi

- `nl_rx_preset.m`: giá trị khởi đầu Search/Focus, có chú thích giả định.
- `nl_device.m`, `nl_faces.m`, `nl_sensor_bank.m`: cấu hình thiết bị và các cảm biến native theo mặt.
- `nl_scan_preview.m`: lấy hướng quét từ API native, lưu đệm để xem trước; không tự thay thuật toán quét của toolbox.
- `nl_in_beam.m`: kiểm tra vị trí dự đoán thuộc chùm đang nhìn cho GNN/JPDA.
- `nl_osm.m`, `nl_plot_map.m`: dùng lại dữ liệu bản đồ gốc và vẽ nền xanh.
- `test_native_rx.m`: bộ kiểm thử RC5. Các chương 1–13 bên dưới là phần nền đã cập nhật cùng phiên bản.

Nguồn bản đồ: © OpenStreetMap contributors, ODbL; địa hình Copernicus GLO-30. Giữ các tệp attribution và provenance có sẵn. 150 tệp của ZIP gốc và 80 dataset gốc phải được đối chiếu nguyên vẹn khi đóng gói.

### 0.6. Khi radar thật về

Giữ giao diện học này. Bổ sung adapter theo giao thức nhà sản xuất, xác nhận bản tin là điểm đo hay track, quy ước góc/cao độ/thời gian, và thu dữ liệu đối chứng. Những việc đó chưa được thực hiện trong RC5. Không nhập địa chỉ IP rồi cho rằng các cấu hình mô phỏng đã được ghi vào thiết bị.

## 1. Project đang làm gì, và chưa làm gì?

Nhánh RC5 có hồ sơ Generic một cảm biến và hồ sơ RX-R417C gồm bốn mặt anten cố định quét điện tử. Ứng dụng mở mặc định preset 07 RX-R417C; các bài B01–B26 chủ động chọn preset 01 Generic để giữ điều kiện bài học. UAV đi theo quỹ đạo đã đặt; radar tạo các báo cáo phát hiện có thể nhiễu hoặc thiếu; bộ bám kết nối các báo cáo theo thời gian và ước lượng chuyển động. Bạn có thể lưu tập báo cáo, đổi thuật toán và chạy lại trên đúng tập đó.

**RC5 chưa tích hợp toàn bộ chức năng của các toolbox.** Cài toolbox chỉ làm API sẵn có; chức năng xuất hiện trong ứng dụng còn phụ thuộc vào mã kết nối, cấu trúc dữ liệu và cách kiểm tra. Một mô hình point-target với phép đo vị trí 3D không thể dùng nguyên xi cho mọi thuật toán xử lý ảnh radar, mục tiêu mở rộng, mạng radar hoặc dữ liệu chỉ có góc.

| Thành phần | Đang có trong RC5 | Chưa có trong giao diện này |
| --- | --- | --- |
| MATLAB | Giao diện, cấu hình, lưu MAT/JSON/CSV, phát lại, hàng đợi | Một ứng dụng điều khiển thiết bị radar hoàn chỉnh |
| Mapping Toolbox | Đọc DEM WGS84, chuyển LLA/ENU, đặt AGL, LOS/viewshed; phủ OSM offline gốc lên địa hình | Tự nhận mọi CRS/datum, tự tải bản đồ, geoid biến thiên theo không gian, dựng đủ công trình |
| UAV Toolbox | Waypoint, thời gian đến, nhiều platform, lấy tư thế theo thời gian | Autopilot, điều khiển động cơ, tránh va chạm, 6-DOF có lực và mômen, mô phỏng gió tác động lên chuyến bay |
| Radar Toolbox | Radar thống kê Generic hoặc bốn mặt RX-R417C; Electronic Search/Focus; RCS điểm, hướng anten, FOV, nhiễu/bias, báo giả | Mọi chế độ bistatic/ESM, Doppler đo đầu ra, mạng radar phân tán hoàn chỉnh, anten thật, multipath/ray tracing đầy đủ, điều khiển phần cứng |
| Sensor Fusion and Tracking Toolbox | GNN/JPDA/TOMHT/GM-PHD; filter, logic track, diagnostics, OSPA/GOSPA; giữ SensorIndex theo mặt; GNN/JPDA xét chùm bằng vị trí dự đoán | Toàn bộ Grid RFS, GGIW/extended target, track-to-track fusion, luồng nhiều cảm biến bất đồng bộ/OOSM hoàn chỉnh |
| Phased Array System Toolbox + Radar Toolbox | Bài IQ riêng: LFM, clutter mặt phẳng, matched filter, CFAR, ULA | Nối echo UAV → xử lý IQ → detections → tracking của cảnh; cấu hình mọi property qua ô riêng |
| Các toolbox cài thêm | Một số bài training cũ còn trong gói | Không phải tất cả đã được nối vào RC5; không coi Antenna, Navigation, DSP, Simulink, Coder… là đã dùng đầy đủ |

**Thứ tự nên học cho luồng này:** MATLAB cơ bản → tọa độ/Mapping → quỹ đạo/UAV → mô hình đo/Radar → bám/Fusion → IQ/Phased nếu bạn cần nghiên cứu tín hiệu. DSP hoặc Communications có thể cần cho API/bài khác, nhưng không vì đã cài mà bắt buộc phải học hết trước khi tạo dataset và chạy bám.

### 1.1. Ba cấp dữ liệu phải phân biệt

| Cấp | Nội dung thực chất | Ví dụ | RC5 dùng thế nào? |
| --- | --- | --- | --- |
| Tín hiệu I/Q | Chuỗi mẫu phức của tín hiệu thu; chưa phải vị trí mục tiêu | Một khối mẫu theo thời gian nhanh × kênh anten × xung | Tab IQ riêng, chưa đưa vào tracker của cảnh |
| Detection — báo cáo phát hiện | Một phép đo tại một thời điểm; chưa khẳng định nó thuộc UAV nào | Vị trí ENU, thời gian, covariance, sensor ID | Đầu vào chính của các tracker trong RC5 |
| Track — vệt bám | Giả thuyết về một đối tượng được duy trì qua nhiều thời điểm | Track ID, vị trí/vận tốc ước lượng, covariance, tuổi, trạng thái xác nhận | Kết quả của tracker; không phải truth |

`radarDataGenerator` đang tạo dữ liệu ở **cấp phép đo**. Nó không thực hiện toàn bộ dây chuyền phát/thu/ADC/FFT/CFAR của radar thật. Vì vậy, chỉnh tần số ở tab Radar không tự dựng lại một máy thu hay waveform. Đây là cách dùng mô hình thống kê được MathWorks mô tả, phù hợp cho nghiên cứu phát hiện và bám. [Mô hình radar cấp phép đo](https://www.mathworks.com/help/releases/r2025a/pdf_doc/radar/radar_ug.pdf)

## 2. Hiểu tọa độ trước khi sửa đường bay

### 2.1. Waypoint và trajectory khác nhau ở đâu?

**Waypoint** là một điểm mốc UAV cần đi qua. Trong RC5, mỗi waypoint đi kèm **vị trí 3 chiều** và **thời điểm đến**. Một dòng `[1000, -300, 130, 25]` nghĩa là: tại giây thứ 25 kể từ lúc bắt đầu, UAV đi qua vị trí East=1000 m, North=−300 m, Up=130 m trong hệ ENU của cảnh.

**Trajectory — quỹ đạo theo thời gian** là toàn bộ chuyển động giữa các waypoint: UAV ở đâu, đi nhanh bao nhiêu, hướng ra sao ở từng thời điểm. Toolbox nội suy chuyển động từ các mốc. Không được hiểu waypoint là “mỗi điểm radar đo được”, cũng không mặc định các đoạn nối là chuyển động thẳng đều. RC5 đưa Waypoints và TimeOfArrival cho `waypointTrajectory`; nó chưa cho nhập mọi điều kiện vận tốc/tư thế tại mốc. [API waypointTrajectory](https://www.mathworks.com/help/robotics/ref/waypointtrajectory-system-object.html)

**Ví dụ:** A ở E=600 m, B ở E=1000 m, các tọa độ còn lại giữ nguyên. Từ giây 0 đến giây 20, độ dời theo Đông là 400 m; tốc độ trung bình theo đoạn là 20 m/s. Tốc độ tức thời trên quỹ đạo nội suy có thể khác số này. Cần xem đồ thị tốc độ, không chỉ chia khoảng cách hai waypoint cho thời gian.

### 2.2. ENU: một hệ trục đặt tại mốc đã chọn

ENU viết tắt của **East–North–Up**: Đông–Bắc–Lên. Cả ba thành phần đều có đơn vị mét.

| Thành phần | Dương nghĩa là | Âm nghĩa là | Ví dụ |
| --- | --- | --- | --- |
| E / East | Về phía Đông của gốc | Về phía Tây của gốc | E=600 m |
| N / North | Về phía Bắc của gốc | Về phía Nam của gốc | N=−600 m |
| U / Up | Theo trục lên của hệ ENU tại gốc | Theo chiều ngược lại | U=100 m |

Gốc ENU có tọa độ địa lý riêng, là `origin_lla`. **Gốc tọa độ không nhất thiết là vị trí radar.** Radar mặc định có ENU `[0,-500,12]`, nên khoảng cách từ một UAV tới radar phải trừ vị trí radar trước; không lấy trực tiếp độ dài vector UAV tính từ gốc.

Với UAV `[600,-600,100]` và radar `[0,-500,12]`, vector radar → UAV là `[600,-100,88]` m. Khoảng cách thẳng xấp xỉ **614,6 m**. Đây là cự ly xiên 3D, không chỉ là khoảng cách ngang trên hình 2D.

### 2.3. LLA: ghi cùng vị trí bằng tọa độ địa lý

LLA là **Latitude–Longitude–Altitude**. Chữ Altitude tự nó chưa xác định mốc cao độ; phải đọc quy ước của dữ liệu. **Riêng hộp nhập LLA trong RC5 dùng cao ellipsoid h.**

| Ô nhập RC5 | Đại lượng | Đơn vị | Quy ước |
| --- | --- | --- | --- |
| Vĩ độ | Góc địa lý Bắc/Nam | độ thập phân, deg | Bắc dương, Nam âm |
| Kinh độ | Góc địa lý Đông/Tây | độ thập phân, deg | Đông dương, Tây âm |
| h ellipsoid | Cao so với ellipsoid tham chiếu WGS84 | m | Không phải AGL; không mặc nhiên là cao độ trên mực nước biển |

Nhập `21.2212`, không nhập chuỗi `21°13′...` vào ô số. Vĩ độ, kinh độ không có đơn vị mét. Khoảng cách tương ứng với một độ kinh độ phụ thuộc vĩ độ; không dùng một hệ số mét/độ cố định cho mọi nơi. Mapping Toolbox thực hiện chuyển đổi dựa trên ellipsoid và mốc ENU. [Quy ước geodetic2enu](https://www.mathworks.com/help/map/ref/geodetic2enu.html)

### 2.4. Up, h, H và AGL: bốn con số không thay thế nhau

| Ký hiệu | Mốc tham chiếu | Ý nghĩa thực tế |
| --- | --- | --- |
| U / Up | Mặt phẳng và trục ENU đặt tại gốc | Một thành phần tọa độ địa phương |
| h | Ellipsoid WGS84 | Cao độ hình học dùng cho LLA trong RC5 |
| H | Geoid / mốc cao độ trực chuẩn tương ứng | Cao độ địa hình theo cách mô hình của RC5 giả định cho DEM |
| N geoid | Khoảng cách geoid–ellipsoid theo quy ước | Dùng công thức h = H + N |
| AGL | Bề mặt địa hình tại vị trí đang xét | UAV/anten cao hơn bề mặt DEM bao nhiêu mét |

Ví dụ minh họa, **không phải số đo Nội Bài**: tại một vị trí, DEM có H=20 m, N=30 m, nên mặt đất có h=50 m. UAV có h=150 m thì AGL=100 m. Không thể kết luận Up=100 m vì còn phụ thuộc mốc ENU và vị trí. Tại vùng nhỏ, Up có thể gần chênh lệch cao ellipsoid so với gốc, nhưng RC5 dùng phép đổi tọa độ chứ không đồng nhất hai đại lượng. [Ellipsoid, geoid và cao độ trực chuẩn](https://www.mathworks.com/help/map/ellipsoid-geoid-and-orthometric-height.html)

Trong RC5: `AGL = h_UAV − (H_DEM tại vị trí UAV + N cấu hình)`. N đang là **một hằng số cho cả cảnh**. `N=0` mặc định là giả định demo, không phải kết quả khảo sát. DEM/DSM còn có loại cao độ khác; không gán nhãn “orthometric” cho dữ liệu chưa xác minh metadata. Nếu dùng DSM có nhà/cây, AGL ở đây là cao hơn bề mặt raster đó, không đảm bảo là cao hơn nền đất trần.

### 2.5. Đổi mốc và đổi vị trí địa lý là hai thao tác khác nhau

**Đổi mốc ENU**: thay gốc biểu diễn nhưng giữ vị trí địa lý của radar/waypoint; các số ENU đổi. **Chọn DEM rồi nhập mốc mới**: thay dữ liệu địa hình và đặt vị trí địa lý của cảnh theo mốc nhập; không tự bảo đảm các waypoint ENU cũ vẫn là cùng điểm ngoài thực địa. Luôn kiểm tra LLA/AGL sau thao tác. Mốc và toàn bộ điểm cần nằm trong vùng raster có dữ liệu hợp lệ.

## 3. Thời gian, nhiễu và bám: những khái niệm dễ nhầm

### 3.1. Một frame không nhất thiết là một lượt radar đo

`dt` là bước thời gian của cảnh, tính bằng giây. `frames` là số thời điểm lấy mẫu, gồm cả t=0. Thời gian kết thúc là `(frames−1)×dt`. Preset 01 Generic dùng 160 frame, dt=0,64 s, thời gian cuối 101,76 s. Preset 07/08 RX-R417C dùng 401 frame, dt=0,2 s, thời gian cuối 80 s. Nhịp mỗi bước chùm khác thời gian quét lại cùng hướng.

`update_every_steps=N` cho radar đo một lượt mỗi N bước; khoảng thời gian danh định giữa hai lượt đo là `N×dt`, tốc độ cập nhật là `1/(N×dt)` Hz. Với N=4 và dt=0,64 s: 2,56 s/lượt, khoảng 0,390625 Hz. **Đây không phải PRF.** PRF là số xung phát mỗi giây ở cấp tín hiệu.

Một **lượt đo hợp lệ không có detection** nghĩa là radar đã nhìn/đo nhưng không báo mục tiêu; bộ bám có thể ghi miss. Một **frame radar không cập nhật** không phải miss. RC5 chỉ gọi tracker ở lượt cập nhật hợp lệ; chưa nội suy/predict để xuất một trạng thái mới ở mọi frame không đo. Đường nối hiển thị giữa các điểm bám không chứng minh có phép đo tại mọi điểm trên đường.

Nút **Phát / Dừng** chỉ phát lại hình. Timer giao diện chạy theo nhịp hiển thị riêng, nên thời gian bạn chờ không bằng thời gian mô phỏng. Đọc đồng hồ mô phỏng và số bước trên giao diện.

### 3.2. Độ phân giải, nhiễu ngẫu nhiên và bias

**Độ phân giải** diễn tả khả năng phân biệt các đối tượng gần nhau theo đại lượng đo; **độ chính xác** diễn tả mức gần với giá trị tham chiếu; **bias** là lệch có hệ thống; **nhiễu ngẫu nhiên** làm các lần đo phân tán. `RangeResolution=15 m` không có nghĩa mọi phép đo sai đúng 15 m hoặc sigma=15 m. [Accuracy, bias và resolution](https://www.mathworks.com/help/radar/ug/measurement-accuracy-bias-and-resolution.html)

RC5 có độ phân giải cự ly tính bằng m, góc ngang/đứng tính bằng deg; bias được nhập theo tỷ lệ của độ phân giải. Ví dụ `range_bias_fraction=0.2` và `range_resolution_m=15` tương ứng tham số bias cự ly 3 m của mô hình. Tắt `noise` không loại bỏ bias hoặc mọi hiệu ứng mô hình, chẳng hạn khúc xạ của radar native.

### 3.3. RCS, Pd và Pfa không phải cùng một thứ

**RCS** là tiết diện tán xạ radar tương đương: mô tả mức tín hiệu mục tiêu tán xạ về phía radar trong điều kiện xét. Đơn vị m² không có nghĩa bằng diện tích hình học UAV. RC5 dùng RCS hằng cho mỗi UAV/điểm tĩnh; chưa mô hình RCS đầy đủ theo góc nhìn, tần số, phân cực hoặc chuyển động cánh. Đổi RCS không làm biểu tượng UAV to lên. [RCS của mục tiêu](https://www.mathworks.com/help/radar/ug/modeling-target-radar-cross-section.html)

**Pd** là xác suất phát hiện. Ô Pd trong RC5 là giá trị tại điều kiện tham chiếu: ReferenceRange và ReferenceRCS. Không có nghĩa mọi UAV ở mọi vị trí đều được phát hiện đúng 90% khi nhập 0,9. **Pfa** là xác suất báo giả theo ô/phép thử của mô hình radar, không phải tổng số điểm giả mỗi frame. Pd/Pfa là xác suất nên không có đơn vị; `0.9` tương ứng 90%, không nhập `90`. [RadarDataGenerator](https://www.mathworks.com/help/radar/ref/radardatagenerator-system-object.html)

### 3.4. State, P, Q và R

**State — trạng thái** là các đại lượng bộ lọc đang ước lượng, thường gồm vị trí và vận tốc; một số mô hình thêm gia tốc hoặc tốc độ quay. **P** là covariance mô tả độ bất định của state. **R** mô tả độ bất định phép đo. **Q** mô tả phần chuyển động mà mô hình dự báo chưa giải thích được.

Trong luồng ENU 3D, detection có ba tọa độ nên R là ma trận 3×3, các phần tử có đơn vị m². Nếu sigma_E=5 m thì R_EE=25 m². `R_EN` là covariance giữa sai số East và North, không phải độ lệch chuẩn. R cần đối xứng và xác định dương khi nhập CSV RC5. Không tự điền 0 cho mọi phương sai vì “radar đo chính xác”.

Q không có một đơn vị chung cho mọi mô hình. RC5 nhập độ lệch chuẩn của kích thích chuyển động: gia tốc m/s² cho CV, jerk m/s³ cho CA; CT còn có gia tốc góc deg/s². Adapter bình phương các độ lệch chuẩn để dựng ProcessNoise. P chứa cả m², (m/s)² và các tích đơn vị tương ứng theo thứ tự state. Tăng Q không làm UAV thật cơ động hơn; nó làm **bộ lọc tin rằng chuyển động có thể thay đổi nhiều hơn**.

### 3.5. Ba lớp của tracking

1. **Data association — gán dữ liệu:** detection này có thể thuộc track nào? GNN giải một phương án gán tổng thể; JPDA dùng nhiều khả năng gán với trọng số; TOMHT duy trì nhiều giả thuyết qua thời gian. PHD là nhánh RFS riêng, không phải một solver GNN.
2. **State estimation — ước lượng trạng thái:** từ dự báo và phép đo, cập nhật vị trí/vận tốc và độ bất định. CV/CA/CT là mô hình chuyển động; KF/EKF/UKF/CKF/PF là phương pháp ước lượng. Không nên gọi CV là một bộ giải gán.
3. **Track management — quản lý vòng đời:** khi nào tạo track tạm, xác nhận, giữ khi mất đo và xóa? History dựa vào lịch sử hit/miss; Score dựa vào điểm bằng chứng; Integrated dựa vào xác suất tồn tại trong JPDA. TOMHT/PHD có tham số quản lý riêng.

Ví dụ History `[2,3]` là ít nhất 2 hit trong 3 cập nhật gần đây, không phải “đợi 2–3 giây”. Deletion `[3,5]` là ngưỡng 3 miss trong 5 cập nhật gần đây; track tạm còn có thể bị xóa khi không còn khả năng đạt điều kiện xác nhận. Trong JPDA, quyết định hit/miss liên quan xác suất gán và ngưỡng native. [Track history logic](https://www.mathworks.com/help/fusion/ref/trackhistorylogic.html), [xóa track tạm](https://www.mathworks.com/help/fusion/ref/trackhistorylogic.checkdeletion.html)

**Gate** là điều kiện loại các cặp detection–track quá khó phù hợp trước khi gán. Giá trị 25 không có nghĩa bán kính 25 m. RC5 chuyển nó thành ngưỡng chi phí/khoảng cách chuẩn hóa của tracker native. Nhãn giao diện “khoảng cách chuẩn hóa bình phương” là cách ghi giản lược; không nên suy ra mọi filter/override đều dùng chính một công thức Mahalanobis bình phương thuần túy. Chi phí thực tế phụ thuộc filter và mô hình đo. [AssignmentThreshold](https://www.mathworks.com/help/fusion/ref/trackergnn-system-object.html)

### 3.6. Đọc chất lượng kết quả cho đúng

OSPA/GOSPA ở RC5 đánh giá tập vị trí bám so với tập vị trí truth, có tính đến chênh lệch số lượng. Đơn vị đang hiển thị là m; thấp hơn thường tốt hơn **khi giữ cùng dữ liệu, thời điểm và thiết lập metric**. Đây không chỉ là RMSE của một UAV. GOSPA hiện đặt SwitchingPenalty=0, nên không đủ để chứng minh giữ đúng danh tính qua một giao cắt. Cần xem Track ID/association hoặc bổ sung metric liên tục danh tính.

Truth là vị trí tham chiếu do mô phỏng biết. Tracker không được cấp ID thật của UAV để giải bài toán. Với CSV thực, RC5 không có truth nên không tính OSPA/GOSPA. Một đường bám trơn hoặc có ít track không tự chứng minh đo đúng.

## 4. Bản đồ giao diện: mỗi nút làm gì?

### 4.1. Cách nhập ô

Trong bảng thông số, chỉ cột **Giá trị** sửa được. Nhấp đúp ô, nhập giá trị, nhấn Enter rồi đọc thông báo dưới cùng. Dùng dấu chấm thập phân: `0.64`. Mảng ở bảng thông số dùng JSON: `[120,60]`; ma trận dùng `[[...],[...],[...]]`; công tắc dùng `true`/`false`. **Bảng waypoint là bảng số**: sửa từng ô số, không dán cả dòng JSON vào một ô. Chuỗi như `Sector` nhập đúng chữ, không kèm dấu nháy; JSON overrides thì phải có dấu nháy cho tên property.

Nếu cấu hình không hợp lệ, app báo lỗi và thường trả về cấu hình trước lần sửa. Không tiếp tục dựa vào số vừa gõ cho tới khi kiểm tra ô và thông báo. Dữ liệu trên bảng rộng có thể cần kéo thanh cuộn ngang để đọc cột API/ý nghĩa.

### 4.2. Thanh thao tác phía trên

| Thành phần / nút | Thực hiện | Có sinh phép đo mới? |
| --- | --- | --- |
| Danh sách 6 kịch bản mẫu | Đặt lại cấu hình theo mẫu, gồm cả tracker; không phải chỉ đổi góc nhìn | Chưa, tới khi chạy |
| Mở phiên | Đọc cấu hình JSON hoặc MAT phiên đã lưu; archive RC5 được nhận dạng khi đủ tệp đi kèm | Không |
| Lưu cấu hình | Lưu thiết lập hiện hành; chưa chứa bộ phép đo/kết quả mới | Không |
| Xem lệnh | Xem mã MATLAB biểu diễn cấu hình và các lời gọi chạy | Chỉ xem; chạy mã sinh mô phỏng là việc khác |
| Mô phỏng + bám | Tạo phép đo, lưu dataset rồi chạy cấu hình tracker hiện hành và lưu kết quả | Có |
| Chạy cấu hình tracker | Chạy bộ bám trên dataset đang mở/phép đo hiện có | Không |
| Chạy hàng đợi | Chạy các cấu hình tracker đã thêm trên dataset hiện tại | Không |
| Lưu kết quả | Đóng gói các result đang mở; mỗi result có cấu hình riêng đã dùng | Không |
| Hướng dẫn đầy đủ | Mở tài liệu này sau khi cập nhật gói hướng dẫn | Không |
| Tạo dataset | Sinh phép đo và lưu với tên bạn nhập; chưa chạy tracker | Có |
| Lưu dataset hiện tại | Lưu lại tập phép đo đang có, cùng cấu hình tương ứng | Không |
| Thư viện dataset / run | Liệt kê và mở dataset/run ở nơi lưu đang chọn | Không |
| Chọn nơi lưu | Chọn thư mục cha để chứa datasets và runs | Không; không di chuyển dữ liệu cũ |
| Mở kết quả đã lưu | Mở thư mục lưu gần nhất | Không |

### 4.3. Tám tab bên trái

| Tab | Bên trong | Cách quan sát |
| --- | --- | --- |
| Radar | Nhóm Thiết bị & nhiệm vụ (hồ sơ, mặt, Search/Focus) và nhóm Thông số đo & vùng quét; vị trí/hướng, FOV, cự ly, lịch đo, chế độ/công nghệ quét, thông số đo; nút đặt AGL anten | Hình radar/chùm xem trước; detections sau mô phỏng |
| UAV | Chọn/thêm/xóa UAV; tên/RCS/thời gian hoạt động/giới hạn tốc độ; bảng waypoint; chèn/xóa/nhập LLA; bảng LLA chỉ đọc | Đường thật, marker waypoint, bảng AGL và đồ thị tốc độ khi xem trước |
| Địa hình | Tệp DEM, N, ghi chú datum, LOS, bán kính hiệu dụng, AGL tối thiểu; chọn DEM/đổi gốc/viewshed | Mặt địa hình, LLA/AGL, cửa sổ viewshed |
| Clutter | Báo giả, Pfa, bật điểm tĩnh; bảng E/N/AGL/RCS; thêm/xóa điểm tĩnh | Dấu × là vị trí vật phản xạ; detection của nó chỉ có sau mô phỏng |
| Tracking | Họ tracker, filter/mô hình, solver GNN, logic; bảng tham số; hàng đợi, help API, chi tiết bám | Track, metric, trạng thái xác nhận và diagnostics sau khi chạy |
| Phiên | Seed, dt, frames, bounds; nhập CSV radar ENU, kiểm tra toolbox | Đồng hồ, giới hạn trục và lịch cập nhật |
| IQ | Các tham số tín hiệu/mảng anten/clutter; nút chạy bài riêng | Cửa sổ range–Doppler, công suất/CFAR, beam ULA |
| Bài học | Nội dung 16 bài cũ; nút mở UAV Scenario Designer và Radar Designer | Các app designer mở độc lập; RC5 chưa tự nhận thiết kế quay lại từ đó |

Trong Tracking, ô **State estimation** đang gộp tên mô hình và filter, ví dụ `GNN · CV · EKF`; không có một dropdown “motion model” riêng. Solver GNN bị khóa khi chọn JPDA/TOMHT/PHD. Management chỉ đổi trực tiếp với GNN/JPDA; TOMHT/PHD dùng bảng ngưỡng tương ứng. Đổi họ tracker xóa overrides tracker/filter; đổi filter xóa overrides filter; đổi management xóa overrides tracker. Đọc lại bảng trước khi thêm hàng đợi.

**Xem hàng đợi** có hành vi cần chú ý: hộp danh sách cho chọn cấu hình muốn **xóa**; OK sẽ xóa các mục đã chọn. Bấm Hủy nếu chỉ muốn xem. Hàng đợi chưa tự lưu khi đóng app; hãy lưu JSON từng cấu hình quan trọng hoặc giữ kết quả batch/attempts đã chạy.

Bố cục RC5.2: bản đồ ở bên trái; chú giải ký hiệu xếp dọc trong vùng riêng bên phải, dùng cho cả 2D và 3D. Biểu đồ tốc độ/GOSPA nằm bên dưới, tách khỏi chú giải.

### 4.4. Vùng xem và phát lại

| Điều khiển | Ý nghĩa |
| --- | --- |
| OSM | Bật/tắt các lớp đường bộ, đường băng, đường lăn, sân đỗ, viền công trình của bản đồ offline gốc; không thay DEM tính toán. |
| Tỷ lệ cao độ | Chọn Auto hoặc ×1/3/6/12/20, mặc định Auto. Chỉ phóng đại hình theo chiều đứng; tọa độ, đơn vị mét và kết quả giữ nguyên. |
| Vùng quét | Đường chấm là biên vùng quét, đường liền là chùm đang nhìn. Không phải heatmap Pd. |
| Toàn tầm radar | Mở rộng khung nhìn ngang theo max range; không tự mở rộng DEM hoặc miền bay. |
| 2D / 3D | 2D nhìn theo mặt phẳng East–North; 3D giúp thấy độ cao khác nhau. Đây là hình MATLAB, không phải Unreal/Simulink 3D Animation. |
| Đường thật / Điểm đo / Đường bám | Chỉ bật/tắt lớp hiển thị, không bật/tắt thành phần vật lý của mô phỏng. |
| Danh sách kết quả | Chọn result nào để xem đường bám. Các lượt có thể cùng tên thuật toán nhưng khác tham số; đọc config trong summary/MAT để phân biệt chắc chắn. |
| Phát / Dừng | Chạy/dừng hoạt ảnh kết quả hoặc xem trước; không chạy mô phỏng mới. |
| Từng bước | Tiến một frame. |
| Về đầu | Quay về frame đầu. |
| Thanh thời gian | Kéo tới frame cần xem; đọc nhãn thời gian. |
| Hủy tính | Yêu cầu dừng công việc đang tính; đợi lời gọi native hiện tại trả về. Không phải cưỡng bức cắt ngay mọi API. |

**Chú giải marker:** tam giác đặc là từng UAV theo tên/màu; vuông đặc là radar; vòng tròn rỗng là waypoint đang sửa; chấm đỏ là phép đo; dấu × xám là phản xạ tĩnh; đường tím có vòng tròn là track, ký hiệu T… là Track ID. Từng UAV có quỹ đạo riêng; hai tam giác đi ngược nhau trong mẫu cơ bản không phải “truth và estimate bị đảo”. Tại t=50 s, hai waypoint có E/N trùng nhau nhưng Up lần lượt 130 m và 180 m; đồ thị chỉ lấy mẫu mỗi dt nên thanh thời gian có thể không dừng đúng 50,00 s.

Hình chùm là đường biên hình học danh định, không phải heatmap Pd hoặc mặt nạ che khuất. Trong bản này hình chủ yếu vẽ biên ở **cự ly tối đa**; không vẽ riêng đầy đủ vùng mù cự ly tối thiểu. Thay min range có thể không đổi hình nhưng vẫn đổi detections sau khi chạy.

### 4.5. Khi nào phải chạy lại?

| Bạn vừa sửa | Xem trước có thể đổi ngay | Việc cần làm để có kết quả tương ứng |
| --- | --- | --- |
| Waypoint, LLA, AGL, mốc, DEM, hướng/FOV/max range | Có, sau xác nhận và kiểm tra | Tạo dataset mới nếu muốn đánh giá detections/tracking |
| RCS, Pd, nhiễu, độ phân giải, bias, Pfa | Không nhất thiết có thay đổi hình học | Tạo dataset mới rồi chạy tracker |
| Solver/filter/management, Q/R, gate | Đường thật và phép đo giữ nguyên | Chạy cấu hình tracker hoặc batch |
| Checkbox lớp, 2D/3D, thời điểm phát lại | Có | Không cần chạy thuật toán |
| Tham số IQ | Cảnh bên phải không đổi | Bấm nút chạy trong tab IQ |

Thông báo **XEM TRƯỚC** nghĩa là kết quả mô phỏng chưa cập nhật theo cảnh. Thông báo **CẤU HÌNH TRACKER MỚI CHƯA CHẠY** nghĩa là số trong bảng chưa tạo ra một result tương ứng. Đừng lấy hình/result cũ để kết luận về giá trị mới.

## 5. Quy trình làm bài và tiêu chí tự kiểm tra

Trước mỗi bài độc lập: chọn mẫu **01 Cơ bản: hai UAV**; nếu mẫu đó đang được chọn và việc chọn lại không phát sinh sự kiện, chọn mẫu 02 rồi chọn lại mẫu 01. Lưu cấu hình gốc bằng **Lưu cấu hình** với tên `baseline_Generic.json`. Cách quay về chuẩn ổn định nhất sau đó là **Mở phiên → baseline_Generic.json**. Đặt tên thí nghiệm theo điều thay đổi, ví dụ `B11_Pd_070`.

Mỗi bài phải ghi được: **đã sửa gì, đơn vị gì, dự đoán tác dụng gì, đã chạy bước nào, nhìn ở đâu, kết quả thực tế gì, tệp lưu ở đâu**. Mô phỏng có ngẫu nhiên; một lượt có thể chưa cho thấy xu hướng. Đừng viết “thuật toán A luôn tốt hơn B” từ một cảnh hoặc một seed.

Phần bài tập bên dưới dùng các nút hiện có và phân biệt rõ bước xem trước với bước tạo dữ liệu. Các giá trị thử là để học, không phải cấu hình hiệu chuẩn cho radar thật. Mã RC5 và các bài chạy MATLAB mới chưa được thực thi tại môi trường biên soạn do lỗi khởi động MATLAB; kết quả cần kiểm tra trên máy chạy của bạn, không có số PASS được suy diễn.


## 6. Các bài thực hành từ đầu đến cuối

Làm theo thứ tự. Bài nào nói “về baseline” thì dùng **Mở phiên → baseline_Generic.json** đã lưu ở mục 5. Mỗi lần nhập một ô phải nhấn Enter, chờ kiểm tra và đọc thông báo. Thay đổi thông số đo cần **Tạo dataset** mới; thay đổi riêng tracker dùng lại dataset đã có.

### B01 — Khởi động, nhận diện màn hình và lưu cấu hình gốc

**Mục tiêu:** phân biệt khởi tạo giao diện, kiểm tra API và chạy mô phỏng.

1. Giải nén gói project. Mở MATLAB R2025a, tìm ô **Current Folder** và chọn thư mục có `START_NATIVE_LAB.m`, không chọn thư mục cha của nó.
2. Trong Command Window, chạy riêng `clear functions`, rồi `NATIVE_LAB_CHECK`. Cột found chỉ cho biết MATLAB tìm thấy API, chưa chứng minh license hoặc thực thi thành công.
3. Chạy `START_NATIVE_LAB`. Kiểm tra tên cửa sổ có **RC5.2 | RX-R417C**. Nếu không, chạy `which START_NATIVE_LAB -all` để tìm bản đang được gọi.
4. Chọn mẫu **01 Cơ bản: hai UAV**, kiểm tra tab UAV có hai tên và hai đường bay. Chuyển 2D→3D→2D để nhận diện trục.
5. Bấm **Lưu cấu hình**, lưu tên `baseline_Generic.json` tại thư mục bạn dễ nhớ. Bấm **Chọn nơi lưu**, chọn một thư mục đang tồn tại để chứa các thí nghiệm.
6. Bấm **Xem lệnh** để thấy các giá trị tương ứng trong biến cấu hình `c`. Đóng cửa sổ xem lệnh, chưa cần chạy đoạn mã.

**Tự kiểm tra:** nói được tên tám tab, chỗ sửa giá trị, chỗ xem thời gian, nơi lưu cấu hình. Chưa có dataset là bình thường ở bước này.

### B02 — Phân biệt hai UAV, waypoint, detection và track

**Mục tiêu:** không nhầm hai tam giác là hai phiên bản của cùng một mục tiêu.

1. Về baseline. Tab UAV, chọn UAV_1, nhìn các vòng tròn waypoint; chuyển sang UAV_2, vòng tròn chuyển sang quỹ đạo của UAV_2.
2. Đọc dòng waypoint thứ ba: E=1500, N=−500; UAV_1 có Up=130 m, UAV_2 có Up=180 m, thời điểm đến 50 s.
3. Chọn 3D, dùng thanh thời gian tới gần 50 s. Hai mục tiêu có thể chồng lên nhau trên hình 2D nhưng có độ cao khác nhau; frame gần nhất không nhất thiết đúng 50,00 s.
4. Bấm **Mô phỏng + bám**, đặt tên `B02_baseline`, đợi thông báo lưu xong. Bấm **Về đầu**, rồi **Phát / Dừng**.
5. Lần lượt tắt/bật **Đường thật**, **Điểm đo**, **Đường bám**. Chỉ lớp hình biến mất/hiện lại; dataset không đổi.
6. Dừng tại một bước có track, đọc T…; mở tab Tracking → **Chi tiết bám**. So sánh Track ID với tên UAV: chúng không phải cùng một nhãn do hệ thống biết trước.

**Tự kiểm tra:** chỉ đúng marker từng lớp. Nếu có detection nhưng chưa có đường track, kiểm tra track còn tentative và ngưỡng xác nhận, không vội kết luận mô phỏng hỏng.

### B03 — Sửa đường bay bằng số và bằng kéo thả

**Mục tiêu:** hiểu waypoint thay hình học quỹ đạo như thế nào.

1. Về baseline, chọn UAV_1 trong tab UAV; ở bảng waypoint nhấp đúp ô North của dòng 2.
2. Đổi từ −300 thành `-100`, nhấn Enter. Quan sát vòng tròn dòng 2 dịch về Bắc; kiểm tra đường nối/quỹ đạo và đồ thị tốc độ xem trước.
3. Chọn 2D, nhấn giữ một vòng tròn waypoint, kéo nhẹ khoảng vài trăm mét rồi thả. Không kéo tam giác UAV hoặc chấm đỏ detection.
4. Đọc lại E/N trong bảng. Khi đang kéo, hình là xem trước hình học; khi thả, toolbox tính lại quỹ đạo và app kiểm tra tốc độ/miền/AGL.
5. Chọn dòng 2 → **Chèn waypoint**. Điểm mới được chèn giữa dòng đang chọn và dòng kế, kèm thời điểm trung gian. Sửa tọa độ điểm mới nếu cần.
6. Chọn điểm mới → **Xóa waypoint**. Việc xóa mốc có thể chuẩn hóa lại các thời điểm tới toàn thời lượng; luôn đọc lại cột **Đến lúc s**.
7. **Tạo dataset** tên `B03_route_change`, rồi **Chạy cấu hình tracker**. So sánh với dataset B02 qua thư viện; không so hai tracker nếu hai dataset khác nhau mà gọi là “cùng dữ liệu”.

**Tự kiểm tra:** vị trí thay đổi theo giá trị đã nhập; tốc độ vẫn hợp lệ. App chỉ cho giữ ít nhất hai waypoint và kiểm tra quỹ đạo không ra ngoài bounds/DEM.

### B04 — Đặt AGL và nhận ra Up không phải AGL

**Mục tiêu:** yêu cầu UAV cao hơn địa hình 150 m tại một mốc.

1. Về baseline, chọn UAV_1, chọn dòng waypoint 2. Ghi lại Up, AGL và h ellipsoid trong bảng phía dưới.
2. Nhấp đúp ô **AGL m** dòng 2, nhập `150`, Enter. Đừng sửa ô Up thành 150 để thay thế thao tác này.
3. Đọc lại AGL≈150 m và Up/h mới. E/N có thể thay đổi rất nhỏ do phép đổi geodetic giữ vị trí địa lý ngang.
4. Chọn 3D để quan sát độ cao mốc. Tiếp theo sửa AGL các mốc còn lại thành 150 nếu muốn so cách bay theo cao độ địa hình.
5. Đọc thông báo kiểm tra quỹ đạo. AGL 150 tại tất cả waypoint không bảo đảm AGL giữa các waypoint luôn đúng 150; quỹ đạo và địa hình đều thay đổi giữa mốc.
6. Chuyển tab Radar → **Đặt chiều cao anten AGL (m)**, nhập `20`. Kiểm tra thông tin Anten AGL và marker radar trên 3D.
7. Lưu cấu hình `B04_agl.json`, tạo dataset riêng nếu muốn kiểm tra khả năng phát hiện sau thay đổi.

**Tự kiểm tra:** giải thích được vì sao Up, h và AGL khác nhau nhưng cùng dùng đơn vị m. Nếu điểm bị báo ngoài DEM hoặc dưới đất, xử lý tọa độ/mốc trước khi chạy.

### B05 — Nhập vị trí bằng LLA

**Mục tiêu:** dùng đúng đơn vị và đúng điểm đang chọn.

1. Về baseline, chọn UAV_1 và dòng waypoint 2; ghi lại ba số vĩ độ, kinh độ, h từ bảng LLA chỉ đọc.
2. Bấm **Nhập waypoint LLA**. Hộp phải chứa giá trị của dòng đang chọn; nếu nhầm dòng, Hủy và chọn lại.
3. Giữ vĩ độ/h; tăng kinh độ thêm `0.001` độ. Ví dụ số đang là 105.81… thì cộng 0.001 vào chính số đó, không thay bằng một tọa độ tùy ý.
4. Bấm OK, đọc lại bảng E/N/U: điểm thường dịch chủ yếu về phía Đông. Không tự kết luận đây là đúng 100 m; phép đổi tùy vị trí địa lý.
5. Mở hộp lần nữa, giữ vĩ độ/kinh độ, tăng h thêm 10 m; nhìn AGL tăng tương ứng gần 10 m trong mô hình hiện tại.
6. Lưu `B05_lla.json`; mở lại baseline để làm bài sau. Nếu cần nhập tọa độ khảo sát, trước hết phải biết cao độ khảo sát là h hay H.

**Tự kiểm tra:** vị trí sửa bằng LLA và vị trí đọc lại ENU là cùng một điểm vật lý theo quy ước của project.

### B06 — Thay thời gian đến, tốc độ và chu kỳ đo

**Mục tiêu:** tách thời gian chuyến bay, bước mô phỏng và nhịp radar.

1. Về baseline, đọc dt=0.64 và frames=160 ở tab Phiên; tính thời gian cuối 101.76 s.
2. Tab UAV: đổi thời điểm đến dòng 2 từ 25 thành `30` s. Giữ nó nhỏ hơn thời điểm dòng 3 là 50 s.
3. Quan sát đồ thị tốc độ: chặng trước có nhiều thời gian hơn, chặng sau có ít thời gian hơn. Nội suy quyết định tốc độ tức thời, không chỉ phép chia trung bình.
4. Thử nhập thời điểm dòng 2 bằng `50`; app phải từ chối vì các thời điểm cần tăng nghiêm ngặt. Đọc giá trị sau khi lỗi để chắc đã quay về cấu hình hợp lệ.
5. Về baseline, tab Phiên đổi dt thành `1`. Các thời điểm waypoint được co giãn tới thời điểm cuối 159 s; đường bay có cùng các mốc nhưng lịch thời gian thay đổi.
6. Tab Radar đặt **Đo mỗi N bước** thành `4`. Với dt=1 s, chu kỳ cập nhật radar là 4 s, không phải PRF=4 Hz.
7. Tạo dataset `B06_update4`; mở `updates.csv` sau lưu và kiểm tra valid_update. Frame không cập nhật khác với frame cập nhật mà detection_count=0.

**Tự kiểm tra:** ngưỡng speed_limit là điều kiện kiểm tra, không phải ô đặt tốc độ bay. Muốn giảm tốc độ, tăng thời lượng hoặc rút ngắn đường đi.

### B07 — Thêm UAV, thay RCS và thời gian hoạt động

**Mục tiêu:** tách số mục tiêu thật, độ phản xạ và thời điểm xuất hiện.

1. Về baseline, chọn UAV_1 → **Thêm UAV**. UAV mới sao chép quỹ đạo đang chọn và nâng Up thêm 20 m; không phải một cấu hình máy bay mới với lực/động cơ.
2. Đổi tên UAV mới thành `UAV_demo`; chọn 3D để thấy đường bay được nâng. Tên phải hợp lệ và không trùng.
3. Đổi RCS m² từ 0.01 thành `0.02`. Hình tam giác không đổi kích thước; đây là thay đổi mức tán xạ trong mô hình đo.
4. Đổi **Bắt đầu ở bước** thành `20`, **Kết thúc ở bước** thành `120`. Với dt=0.64 s, các thời điểm tương ứng là 12.16 s và 76.16 s.
5. Tạo dataset `B07_three_UAV`, chạy tracker. Phát trước/trong/sau khoảng hoạt động và xem số lượng truth/track; track có thể xác nhận trễ hoặc còn được giữ sau khi mục tiêu mất.
6. Chọn `UAV_demo` → **Xóa UAV** để thực hành; quay về baseline trước bài tiếp. Không thể xóa hết UAV trong cấu hình RC5.

**Tự kiểm tra:** số track không bắt buộc bằng số UAV ở mọi thời điểm. Clutter, thiếu detection và logic có thể tạo chênh lệch.

### B08 — Đặt vị trí, hướng và góc anten

**Mục tiêu:** hình dung radar nhìn theo khung anten, không theo tên trục của màn hình.

1. Về baseline, tab Radar đọc vị trí `[0,-500,12]` m. Đổi East thành 100 bằng cách nhập cả vector `[100,-500,12]`.
2. Nhìn vuông radar dịch về Đông. Vì nền đất có thể khác, bấm đặt AGL anten `20` m và kiểm tra lại.
3. Đặt hướng ENU từ 0 thành `90` deg. Trục nhìn quay từ Đông sang Bắc; không làm quỹ đạo UAV đổi hướng.
4. Chuyển 3D, đổi tilt `0→10`, rồi roll `0→15`, quan sát cách chùm đổi định hướng. Làm từng lần để phân biệt tác dụng.
5. Trở về hướng=0, tilt=0, roll=0 rồi tạo dataset đối chứng; tạo thêm dataset sau khi hướng=90 để so khả năng quan sát.
6. Chạy cùng một cấu hình tracker trên hai dataset. Ghi rõ đây là so hai điều kiện quan sát, không phải phép so thuật toán trên cùng dữ liệu.

**Tự kiểm tra:** hướng 0° của app không phải quy ước la bàn 0° Bắc. Khi nhập từ radar thật, phải đổi đúng quy ước của thiết bị.

### B09 — FOV, cự ly tối thiểu và cự ly tối đa

**Mục tiêu:** phân biệt bề rộng góc, vùng quét và cự ly.

1. Về baseline, Radar → **Bề rộng chùm [ngang,đứng]** nhập `[30,20]` deg, Enter.
2. Chùm xem trước hẹp đi; quỹ đạo thật giữ nguyên. Tạo dataset `B09_fov30` để xem các thời đoạn có detection.
3. Về baseline, đổi **Khoảng cách [min,max]** thành `[50,1500]` m. Biên xa của hình chùm ngắn lại.
4. Tạo dataset `B09_range1500`. So với baseline tại những thời điểm UAV ở xa hơn radar; phân biệt range=1500 m là cự ly xiên từ anten.
5. Đổi thành `[800,1500]`. Hình gần radar có thể không đổi vì RC5 chưa vẽ đầy đủ vùng mù min range; phải sinh dataset mới để thấy tác động lên detections.
6. Đọc bảng waypoint và vị trí radar, tự tính một cự ly 3D để dự đoán mục tiêu có bị loại bởi giới hạn range không.

**Tự kiểm tra:** nằm trong range/FOV là điều kiện hình học, không phải bảo đảm phát hiện khi có nhiễu, Pd hoặc che khuất.

### B10 — Quét cơ khí và quét điện tử

**Mục tiêu:** thay đúng tham số đang có hiệu lực.

1. Về baseline, Radar: mode=`Sector`, scan_technology=`Mechanical`, FOV=`[12,40]`, azimuth_scan_limits_deg=`[-60,60]`, scan_rate_deg_s=`20`.
2. Tạo dataset `B10_sector_mechanical`; phát lại. Hướng chùm theo thời gian lấy từ kết quả đã mô phỏng; preview tĩnh chưa chứng minh lịch quét.
3. Đổi scan_rate_deg_s thành `40`, tạo dataset mới và so tốc độ quét/hit ở cùng thời điểm. Đừng chỉ bấm Phát rồi kỳ vọng dữ liệu cũ đổi.
4. Về baseline; chọn mode=`Raster`, technology=`Electronic`, đặt electronic_azimuth_limits_deg=`[-45,45]`, electronic_elevation_limits_deg=`[-10,20]`, FOV=`[20,20]`.
5. Tạo `B10_raster_electronic`, phát lại và quan sát hướng quét; tốc độ/miền cơ khí không phải các nút điều khiển quét điện tử trong adapter này.
6. Thực hành `Mechanical and electronic` bằng cách chọn đúng technology, giữ miền hợp lệ và tạo dataset riêng. Thử `Rotator` riêng nếu muốn quan sát quét vòng; miền Sector không áp y hệt cho Rotator.
7. Cuối cùng chọn `No scanning`; giải thích vì sao thay tốc độ quét khi đó không tạo tác dụng mong muốn.

**Tự kiểm tra:** bài này không cấu hình được mọi lịch quét tùy ý. `HasScanLoss` không có ô vì nhánh này chưa triển khai Custom scanning phù hợp với property đó trong R2025a.

### B11 — Phân biệt Pd, độ phân giải, noise và bias

**Mục tiêu:** đánh giá thay đổi thống kê mà hình học không đổi.

1. Về baseline, giữ seed. Tạo dataset `B11_ref`; ghi số reports trong thư viện hoặc cộng detection_count trong updates.csv.
2. Đổi riêng Pd từ 0.9 thành `0.7`, tạo `B11_Pd070`. So số/thời đoạn detection; không bảo đảm mỗi nhóm nhỏ đúng tỷ lệ 70%.
3. Về baseline, đổi range_resolution_m từ 15 thành `30`, tạo `B11_rangeRes30`. Khi chạy cùng tracker, quan sát độ phân tán và R lưu trong detections CSV; không chỉ nhìn tổng số detection.
4. Về baseline, đặt noise=`false`, các bias=0, tạo `B11_noNoise`. Đây không phải mô hình tuyệt đối không còn sai khác với truth.
5. Giữ noise=false, đặt range_bias_fraction=`0.2`, tạo `B11_bias`. Với resolution=15 m, bias tham số bằng 3 m; khi chiếu vào ENU, dịch từng trục phụ thuộc hướng mục tiêu.
6. Về baseline rồi làm tương tự cho azimuth/elevation resolution hoặc bias, mỗi lần chỉ đổi một trường; xem 2D cho phương vị và 3D cho độ cao.
7. Với tần số hoặc ReferenceRange/ReferenceRCS, thay một giá trị trong dataset riêng và ghi điều kiện tham chiếu; không suy ra radar thật đã đổi công suất hay waveform.

**Tự kiểm tra:** cùng quỹ đạo có thể sinh các tập phép đo khác nhau; phải chạy lại mô phỏng để đánh giá tham số radar mới.

### B12 — DEM, LOS và viewshed

**Mục tiêu:** hiểu địa hình có thể che khuất nhưng không cho biết trực tiếp Pd.

1. Về baseline, tab Địa hình: đọc đường dẫn DEM, N và ghi chú datum. Đây là GeoTIFF thật được đọc; tệp ghi cao độ có thể là DSM chứa bề mặt công trình/cây tùy nguồn.
2. Giữ UAV/anten ở AGL hợp lệ. Bấm **Tính viewshed** với target AGL=100 m; quan sát bản đồ kết quả trong cửa sổ riêng.
3. Đổi viewshed_target_agl_m thành `150`, tính lại. Tham số này thay mục tiêu giả định của bản đồ viewshed, không nâng UAV trong bảng waypoint.
4. Tạo dataset với terrain_los=true; tạo bản khác với false, mọi thứ còn lại giữ nguyên. Ở địa hình bằng/độ cao bay lớn, hai kết quả có thể giống nhau vì không có che khuất cần loại.
5. Muốn dùng DEM khác, bấm **Chọn DEM**, chọn raster một band WGS84 geographic; nhập lat/lon/h gốc và N theo metadata, không đoán từ tên tệp.
6. Kiểm tra lại AGL radar/UAV, miền bay và vị trí trên raster; cần sửa đường bay nếu cảnh mới không nằm trong vùng dữ liệu. Chỉ chạy khi kiểm tra hợp lệ.
7. Nếu chỉ có DEM UTM, dừng nhập trực tiếp; cần bước tái chiếu và xác minh datum trước. Không thay tên tệp thành .tif để coi là đã đúng định dạng.

**Tự kiểm tra:** viewshed là bài hình học khả kiến, không phải bản đồ xác suất phát hiện hoặc mô hình lan truyền nhiều đường hoàn chỉnh.

### B13 — Đổi gốc ENU nhưng giữ vị trí ngoài thực địa

**Mục tiêu:** thấy một điểm vật lý có thể có nhiều bộ tọa độ ENU.

1. Về baseline; ghi LLA waypoint 1 của UAV_1 và thông tin gốc hiện tại.
2. Tab Địa hình → **Đổi mốc ENU**. Tăng vĩ độ gốc thêm 0.0002°, giữ kinh độ và h; đây là dịch nhỏ trong cùng vùng DEM.
3. Bấm OK, đọc lại ENU waypoint và radar: các con số thay đổi. Bounds và hướng anten cũng được chuyển để giữ bố trí vật lý tương ứng.
4. So LLA của waypoint với số ghi trước: phải giữ gần như cũ trong sai số số học. Không yêu cầu hình trên hệ trục mới nằm ở đúng tọa độ màn hình cũ.
5. Lưu `B13_new_origin.json`; mở lại baseline và xác nhận gốc/ENU trở lại.
6. Không dùng trực tiếp detections ENU của gốc cũ với cấu hình gốc mới. Nếu muốn bám dataset cũ, mở chính archive cũ; đổi hệ đo thực cần chuyển cả dữ liệu và covariance.

**Tự kiểm tra:** hiểu vì sao đổi origin có thể làm dataset cũ bị coi là không khớp cấu hình.

### B14 — Báo giả và phản xạ tĩnh

**Mục tiêu:** tách clutter thống kê với một vật phản xạ có vị trí cụ thể.

1. Về baseline, Clutter đặt false_alarms=true và pfa=`1e-6`; giữ scatterers_enabled=false, tạo dataset `B14_falsealarm`.
2. Đổi pfa=`1e-5`, tạo `B14_more_falsealarm`; xem detection_count và những điểm không theo quỹ đạo UAV. Không coi Pfa=1e-5 là chính xác 10 điểm/scan.
3. Về baseline, bật scatterers_enabled=true, giữ báo giả=false. Kiểm tra dòng `[1200,-650,20,0.02]`: 20 là AGL m, không phải Up.
4. Bấm **Thêm điểm tĩnh**, sửa vị trí và RCS từng ô; dấu × trên hình là vị trí cấu hình. Tạo dataset để xem radar có phát hiện nó không.
5. Chạy tracker. Vật phản xạ tĩnh có thể tạo track; RC5 không có bộ loại “mọi track đứng yên” chỉ vì bạn đang quan tâm UAV.
6. Bấm **Xóa điểm cuối** để xóa dòng cuối, không phải dòng đang chọn. Lưu cấu hình nếu muốn giữ bài.
7. Mở tab IQ để nhận ra clutter mặt đất phân bố ở đó là mô hình riêng; bật nó không tự thêm vào dataset vừa tạo.

**Tự kiểm tra:** prior clutter của tracker chỉ là giả định thống kê, không phải số clutter truth được truyền vào để giúp tracker gán đúng.

### B15 — Tạo dataset, mở lại và phát lại đúng dữ liệu

**Mục tiêu:** phân biệt lưu cấu hình, lưu phép đo và sinh dữ liệu lại.

1. Về baseline, bấm **Chọn nơi lưu**, chọn thư mục thí nghiệm. Bấm **Tạo dataset**, đặt tên `B15_fixed_data`.
2. Khi hoàn tất, bấm **Mở kết quả đã lưu**; kiểm tra archive.json, native_session.mat, session.json, detections_enu.csv, updates.csv và assets/terrain.tif.
3. Bấm **Lưu dataset hiện tại**, dùng lại tên `B15_fixed_data`. Thư viện phải có ID/thư mục khác; tên không phải khóa duy nhất và tệp cũ không bị ghi đè.
4. Chọn **Thư viện dataset / run** rồi mở lại bản đầu; xem metadata và số reports. Không cần mô phỏng lại để chạy tracker khác.
5. Đóng app, mở lại và mở dataset từ thư viện để thực hành lưu lâu dài. Thư mục nơi lưu được ghi nhớ; hàng đợi chưa tự phục hồi.
6. Nếu cần di chuyển, sao chép cả thư mục archive, giữ assets và MAT; không chỉ chép CSV. Dùng **Mở phiên** chọn native_session.mat trong archive hoặc đặt thư mục cha đúng cấu trúc datasets/runs cho thư viện.
7. Muốn chạy lại từ lệnh, sau khi đường dẫn project đã thiết lập, chạy replay.m trong archive; configure_session.m là sinh mô phỏng lại, không phải replay điểm đo cũ.

**Tự kiểm tra:** hash MAT/DEM giúp phát hiện bị thay đổi. Tệp MATLAB Custom và toolbox không được tự nhúng vào archive; cần giữ chúng trên path nếu đã sử dụng.

### B16 — So bốn solver GNN trên cùng dataset

**Mục tiêu:** cô lập tác dụng của phép gán.

1. Mở `B15_fixed_data`; Tracking chọn Data association=GNN, State estimation có CV EKF, Track management=History.
2. Chọn solver Jonker–Volgenant, giữ gate/Q/R và ngưỡng; bấm **Thêm vào hàng đợi**.
3. Đổi chỉ solver sang Munkres, thêm tiếp; lặp với Auction và MatchPairs. Chưa cần tạo dataset mới.
4. Bấm **Xem hàng đợi** để kiểm tra danh sách; bấm **Hủy** để không xóa mục nào.
5. Bấm **Chạy hàng đợi**, đặt tên `B16_GNN_solvers`. Đợi bảng trạng thái; FAILED không được tính là một kết quả thành công.
6. Chọn lần lượt từng result trên hình, đọc GOSPA và thời gian trong summary.csv. Các solver có thể cho đường bám giống nhau trong một bài gán đơn giản.
7. Để thấy khác biệt có ý nghĩa, lặp bài trên dataset giao cắt/clutter; giữ cùng dữ liệu trong mỗi phép so.

**Tự kiểm tra:** đã đổi solver chứ không đổi mô hình CV/EKF. Không kết luận solver “không có tác dụng” chỉ vì cùng tối ưu ra một phương án trong cảnh dễ.

### B17 — CV, CA, CT và các họ filter

**Mục tiêu:** phân biệt mô hình chuyển động với cách ước lượng.

1. Mở cùng dataset; chọn GNN/History và solver cố định. Xóa các mục hàng đợi cũ qua **Xem hàng đợi**, chọn hết rồi OK.
2. Chọn CV KF, thêm hàng đợi. Thêm CV EKF, CV UKF, CV CKF với cùng dữ liệu và các tham số Q/R thích hợp đã đọc lại.
3. Chạy `B17_filters_CV`; ở phép đo Cartesian và chuyển động gần tuyến tính, nhiều filter có thể tương tự. EKF/UKF không mặc nhiên tốt hơn KF.
4. Chọn mẫu **05 UAV cơ động: IMM** để tạo dataset cơ động riêng; lưu nó rồi giữ cố định khi so tiếp.
5. Trên dataset cơ động, xếp hàng CV UKF, CA UKF và CT UKF. Đây là đổi mô hình; Q khác đại lượng nên không so số 8 m/s³ với 8 m/s² như cùng mức nhiễu.
6. Xem đoạn đổi hướng, độ trễ bám, số track và GOSPA; đọc State trong **Chi tiết bám**. CV thường dùng [E,vE,N,vN,U,vU]; CA/CT có thứ tự khác.
7. PHD dùng danh mục GM-PHD CV/CA riêng. Danh sách UI chỉ cung cấp các tổ hợp đã có adapter; không tự tạo được KF–CT bằng cách đổi chữ trong JSON.

**Tự kiểm tra:** giải thích được “GNN + CV + UKF + History” đang chọn bốn khía cạnh khác nhau.

### B18 — Điều chỉnh Q, R và gate có kiểm soát

**Mục tiêu:** thay niềm tin của tracker mà giữ nguyên phép đo.

1. Mở một dataset cơ động, chọn GNN CV EKF/History; cố định solver. Ghi Q hiện tại, R scale và gate; thêm cấu hình gốc vào hàng đợi.
2. Đổi `measurement_variance_scale` từ 1 thành `4`, thêm cấu hình. Điểm đỏ phải giữ nguyên; đây là thay mức tracker tin vào phép đo.
3. Trả R scale về 1, đổi `acceleration_std_mps2` từ 12 thành `6`, thêm cấu hình; sau đó thử 18 với R scale=1.
4. Trả Q về giá trị gốc, đổi gate từ 25 thành `16`, thêm; thử tiếp 36. Giữ coarse multiplier không đổi để biết chính xác ngưỡng được tạo.
5. Chạy hàng đợi, xem đường bám ở đoạn đổi hướng và đoạn nhiều clutter; mở diagnostics để kiểm tra chi phí/assignment.
6. Trong summary.csv hoặc MAT, đối chiếu đúng cấu hình từng result. Dropdown tên thuật toán có thể giống nhau, nên số thứ tự/config mới là cách phân biệt.
7. Không đổi metric_cutoff_m giữa các result rồi so số GOSPA như cùng thước đo; nếu đổi metric, ghi rõ và tính lại thống nhất.

**Tự kiểm tra:** tăng Q không đổi quỹ đạo UAV; tăng R không sinh điểm đo mới; tăng gate không là tăng bán kính quan sát radar.

### B19 — Vòng đời track: History và Score

**Mục tiêu:** hiểu độ trễ xác nhận và thời gian giữ track khi mất đo.

1. Chọn mẫu **06 Mất phép đo: radar chậm**, tạo dataset riêng; sau đó giữ cố định dữ liệu này.
2. Tracking chọn GNN CV EKF, History; đặt confirmation `[2,3]`, deletion `[3,5]`, thêm hàng đợi.
3. Đổi confirmation thành `[4,5]`, giữ deletion; thêm. Trả confirmation về `[2,3]`, đổi deletion thành `[5,8]`, thêm.
4. Chọn Score, bảng chuyển sang ngưỡng score; giữ giá trị khởi đầu và đọc Pd/clutter/birth prior. Thêm cấu hình Score.
5. Chạy batch; tại các bước đầu và giai đoạn hụt đo, mở **Chi tiết bám** để xem tentative/confirmed, Age và danh sách ID.
6. So thời gian xuất hiện track xác nhận và khoảng track tiếp tục được giữ. Age tính theo cập nhật của tracker, không quy đổi thành giây bằng cách bỏ qua nhịp radar.
7. Không so ngưỡng Score=15 với History=3 như chúng có chung thang đo. Một cấu hình chậm xác nhận hơn có thể giảm báo bám giả nhưng tăng trễ.

**Tự kiểm tra:** giải thích vì sao đã có detection mà chưa có đường bám confirmed; vì sao đổi deletion không làm radar đo thêm.

### B20 — JPDA, k-best và Integrated

**Mục tiêu:** nghiên cứu gán mềm và xác suất tồn tại.

1. Mở dataset giao cắt hoặc có clutter. Chọn JPDA → CV EKF → History; kiểm tra solver GNN đã bị khóa.
2. Đặt `jpda_max_events=20`, thêm hàng đợi; thử 100 và thêm. Các giá trị là số sự kiện gán tối đa mỗi cụm, không phải số track.
3. Với cảnh nhỏ, nhập `all` và thêm để dùng MaxNumEvents=Inf. Nếu đông đối tượng, bắt đầu với k hữu hạn; full events có thể rất tốn tính.
4. Chọn management=Integrated, đọc `existence_confirmation`, `existence_deletion`, Pd và birth/death prior. Thêm cấu hình mặc định trước khi chỉnh ngưỡng.
5. Chạy batch, đọc trạng thái/thời gian; dùng Hủy tính nếu cần và đợi API hiện tại trả về.
6. Trong diagnostics, xem các cấu trúc/sự kiện/xác suất mà native trả cho JPDA. Không ép chúng thành một cặp ID duy nhất như GNN nếu dữ liệu đang mơ hồ.
7. So khả năng duy trì track qua đoạn gần nhau, nhưng không dùng GOSPA SwitchingPenalty=0 để khẳng định không đổi ID.

**Tự kiểm tra:** Integrated là logic tồn tại của JPDA; nó không biến bộ lọc state thành một thuật toán hoàn toàn khác.

### B21 — TOMHT và GM-PHD

**Mục tiêu:** hiểu giới hạn giả thuyết và hỗn hợp PHD.

1. Mở dataset có hai mục tiêu giao cắt; chọn TOMHT CV EKF, ghi số hypotheses/branches/history và thêm hàng đợi.
2. Đổi tomht_max_hypotheses từ 12 thành 20, giữ các trường khác, thêm. Thử tăng history từ 3 thành 4 ở cấu hình riêng.
3. Chạy, đọc thời gian và diagnostics nhánh; nhiều giả thuyết hơn tăng không gian tính nhưng không bảo đảm cải thiện.
4. Chọn Data association=PHD → GM PHD CV. Dropdown management thể hiện PHD weight; không có solver Munkres áp trực tiếp cho nhánh này.
5. Giữ cấu hình gốc làm đối chứng; thay riêng phd_extraction 0.45→0.6, thêm. Ở một cấu hình khác thay birth/death hoặc merging sau khi đã đọc đúng ý nghĩa trong từ điển tham số.
6. Chạy trên cùng dataset; so số track, thời điểm trích xuất/xác nhận và metric. Trọng số thành phần PHD không phải đơn giản “xác suất UAV này tồn tại”.
7. Lưu kết quả và cấu hình từng result. GM-PHD đang được cấu hình point-target, một detection/đối tượng/lượt theo sensor config; chưa phải bài mục tiêu mở rộng GGIW.

**Tự kiểm tra:** phân biệt max_tracks, max_hypotheses và max_components — ba giới hạn của ba đối tượng dữ liệu khác nhau.

### B22 — Particle Filter và IMM

**Mục tiêu:** thử xấp xỉ bằng hạt và chuyển đổi mô hình.

1. Mở dataset cơ động; chọn GNN CV PF, filter_seed=9201, pf_particles=500; thêm hàng đợi.
2. Giữ seed/các tham số khác, tăng particles=1000, thêm. Ở cấu hình thứ ba giữ 1000 và đổi resampling Systematic→Stratified.
3. Chạy, so thời gian và chất lượng; hai seed khác nhau có thể tạo kết quả khác dù cùng dataset. Lặp với cùng seed nếu muốn kiểm tra tái hiện.
4. Chọn GNN IMM EKF, giữ bank mặc định CV/CA/CT, thêm đối chứng với imm_transition=[] và stay=0.94.
5. Nhập imm_transition=`[[0.8,0.1,0.1],[0.1,0.8,0.1],[0.1,0.1,0.8]]`, initial probabilities=`[0.4,0.3,0.3]`, thêm.
6. Chạy và xem đoạn cơ động. UI chưa có đồ thị xác suất mô hình IMM theo từng thời điểm; không nhìn đường tím rồi khẳng định đang dùng đúng nhánh CT tại giây nào.
7. Trả matrix về `[]` để trường stay có hiệu lực trở lại. Giữ thời gian dt khi so; native định nghĩa xác suất chuyển theo đơn vị thời gian.

**Tự kiểm tra:** số hạt không phải số giả thuyết TOMHT; IMM là phối hợp nhiều mô hình, không phải lấy trung bình tùy ý các đường bám chạy độc lập.

### B23 — Overrides API và Custom initializer

**Mục tiêu:** mở rộng có kiểm tra, biết khi nào không thể chỉ thêm một property.

1. Mở dataset, chọn JPDA CV EKF. Bấm **Tra API đang dùng** để đọc help trackerJPDA của MATLAB đang cài.
2. Tìm InitializationThreshold và điều kiện áp dụng. Trong `tracker_properties_json`, nhập `{"InitializationThreshold":0.1}` rồi chạy một result riêng.
3. Lưu result; kiểm tra JSON config lưu đúng override. Trả trường về `{}` để bỏ override trước khi so cấu hình thường.
4. Chọn GNN, State estimation=CUSTOM. Khi hỏi tên hàm, nhập `initcvckf`; chỉ số vị trí nhập `[1,3,5]`.
5. Chạy trên dataset cũ. Đây là dùng hàm native có sẵn qua đường adapter Custom; chưa cần viết một filter mới.
6. Muốn thêm initializer riêng, nó phải nhận một objectDetection và trả filter tương thích; state phải có E/N/U trực tiếp tại ba chỉ số đã khai báo. Mô hình chỉ góc/MSC không thể làm đúng bằng cách đoán chỉ số.
7. Với Custom assignment, đọc giao diện hàm trong help trackerGNN trước khi chọn. Nút Custom không tự sinh thuật toán hoặc tự đóng gói phụ thuộc hàm vào dataset.

**Tự kiểm tra:** property tồn tại trong toolbox chưa chắc phù hợp với luồng dữ liệu RC5. Những property đổi cổng đầu vào/state hoặc do ô riêng quản lý có thể bị chặn; cần adapter bổ sung thay vì né kiểm tra.

### B24 — Nhập CSV mẫu, có khoảng mất detection

**Mục tiêu:** luyện pipeline nhập dữ liệu; mẫu đi kèm là dữ liệu giả lập định dạng, không phải phép đo radar thật.

1. Dùng gói tài liệu v2/project kèm thư mục `native_lab/examples/csv_schema_demo`. Trong đó có detections_enu.csv, updates.csv và README ghi nguồn SYNTHETIC_SCHEMA_EXAMPLE.
2. Về baseline; Phiên đặt dt=`1` trước, rồi frames=`121`. App co giãn waypoint để không bắt đường bay 2 km diễn ra trong vài giây.
3. Radar đặt update_every_steps=`1`; không đổi mốc ENU khi dùng mẫu. Nguồn mẫu dùng gốc/cảnh baseline theo README, thời gian 0…120 s.
4. Phiên → **Nhập CSV radar ENU**, chọn detections_enu.csv. App tự tìm updates.csv cùng thư mục.
5. **Lưu dataset hiện tại** tên `B24_SCHEMA_ONLY`; không bấm Tạo dataset vì nút đó sẽ sinh mô phỏng mới thay vì lưu CSV đang nhập.
6. Chọn GNN CV EKF History, chạy. Trong khoảng giây 40…50 mẫu không có detection nhưng valid_update=1; xem logic giữ/xóa track và xác nhận lại.
7. Quan sát thông báo dữ liệu CSV không có truth. OSPA/GOSPA trống là đúng, không phải điểm số 0 hoặc lỗi mặc định.
8. Đọc CSV bằng trình bảng tính: r_ee/r_nn/r_uu là phương sai m², ba số chéo còn lại là covariance. Không sửa thành sigma hoặc thêm một cột “độ cao giả” để nhận dữ liệu 2D.

**Tự kiểm tra:** mẫu này chỉ chứng minh định dạng và thao tác nhập; không chứng minh độ chính xác đo ngoài thực địa.

### B25 — IQ, LFM, Doppler, CFAR và ULA

**Mục tiêu:** biết bài tín hiệu làm được gì và chỗ nào đang tách khỏi scene.

1. Về baseline, tab IQ giữ mặc định; bấm nút **Chạy LFM + clutter + matched filter + CFAR + ULA**. Đợi cửa sổ kết quả riêng.
2. Đọc trục: Range m là cự ly đã bù trễ matched filter; Doppler Hz là tần số Doppler; Power dB là thang công suất tương đối của mô hình, không mặc nhiên dBm đã hiệu chuẩn.
3. Đổi bandwidth 1e6→5e5 Hz, chạy lại; so cấu trúc đáp ứng cự ly. Độ phân giải lý tưởng liên quan c/(2B), nhưng kết quả cụ thể còn phụ thuộc lấy mẫu và xử lý.
4. Trả bandwidth, tăng pulses 16→32. Giữ PRF; bước ô Doppler lý tưởng Δf=PRF/pulses nhỏ lại. Quan sát bản đồ, không coi nhiều xung luôn giải quyết mọi mơ hồ Doppler.
5. Đổi speed_mps 0→10 để thử Doppler clutter của platform; đổi gamma_db −20→−10 trong lượt riêng để thử mức clutter.
6. Đổi cfar_pfa 1e-4→1e-3, chạy và xem dấu vượt ngưỡng. Dấu này trong bài hiện tại là vượt ngưỡng trên clutter, không là detection UAV được nối sang tracking.
7. Đổi array_elements 4→8, steer_deg 0→20; xem đồ thị beam chuẩn hóa. Đây là thay đáp ứng ULA được vẽ; mã không dùng steering này để beamform lại chuỗi detections của cảnh.
8. Giữ điều kiện SampleRate/PRF nguyên, pulse width<PRI và echo nằm trong PRI. Nếu báo kích thước cube quá lớn, giảm sample rate/array/pulses; đây là giới hạn app tương tác.
9. Đọc đường dẫn MAT bài IQ trong thông báo. **Chọn nơi lưu** của thư viện dataset/run không chuyển nơi lưu IQ; IQ hiện lưu riêng trong results/native_iq của project.

**Tự kiểm tra:** đổi thông số IQ không làm các điểm đỏ trong dataset scene đã tạo thay đổi. CFAR training/guard cells và nhiều property khác vẫn cố định trong mã, chưa có ô riêng.

### B26 — Hoàn thành một demo có thể kiểm tra lại

**Mục tiêu:** trình diễn một giả thuyết, một thay đổi và bằng chứng có thể mở lại.

1. Chọn một câu hỏi cụ thể, ví dụ “khi hai UAV đi gần nhau, đổi GNN sang JPDA có giúp duy trì track hơn không?”. Tạo/lưu một dataset thích hợp.
2. Lưu cấu hình gốc; thêm GNN và JPDA vào hàng đợi, ghi các tham số khác biệt. Chạy batch và đọc trạng thái từng lượt.
3. Chọn đúng result ở danh sách trên hình; dùng Về đầu/Phát/Dừng/Từng bước để trình diễn đoạn quan trọng. Đổi 2D/3D để chứng minh khác biệt độ cao nếu có.
4. Mở Chi tiết bám tại một lượt đo; chỉ vào ID, trạng thái confirmed và thông tin association. Nếu frame không cập nhật, chuyển tới frame có valid_update=1.
5. Bấm **Lưu kết quả**, đặt tên mô tả; bấm **Mở kết quả đã lưu**, kiểm tra MAT, summary.csv, tracks/metrics CSV và ảnh nếu xuất thành công.
6. Đóng app, mở lại run qua thư viện; kiểm tra có thể thấy lại cùng dữ liệu và result. Đừng dùng result mới phát sinh để thay thế mà không ghi nhận.
7. Ghi kết luận gồm mặt tốt, trường hợp thất bại, thời gian tính, giới hạn metric và seed. Nếu batch PARTIAL, nói rõ cấu hình nào chưa chạy/đã lỗi.
8. Dùng tab Bài học để mở Radar Designer/UAV Scenario Designer nếu muốn tìm hiểu API rộng hơn; sản phẩm trong các app đó chưa tự nhập ngược vào RC5. Sổ tay RC5 này là hướng dẫn hiện hành; B27–B32 dành cho RX-R417C, còn 16 bài cũ trong tab Bài học là tài liệu bổ sung.

**Tự kiểm tra:** người khác nhận archive và các phụ thuộc cần thiết phải biết bạn đã dùng cấu hình gì, dữ liệu gì, thuật toán gì và kết luận dựa vào tệp nào.


## 7. Từ điển thông số: vị trí, đơn vị, tác dụng và ví dụ

Có **138 mục tra cứu**. Giá trị ví dụ của Generic và RX-R417C được phân biệt. Khi dùng RX, các trường cơ khí không áp dụng được ẩn; các giả định không phải số đo kiểm định hãng.

### Phiên

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `seed` | Không đơn vị; số nguyên | Seed đặt trạng thái bộ sinh số ngẫu nhiên cho mô phỏng. Không phải mức nhiễu. | Ví dụ 9201; đổi seed cần dataset mới. |
| `dt` | s | Khoảng thời gian giữa hai frame; tốc độ cập nhật UAV là 1/dt. | Ví dụ 0.64; đổi sẽ co giãn thời gian waypoint. |
| `frames` | Số frame; số nguyên | Bao gồm cả frame t=0; thời điểm cuối=(frames−1)×dt. | RC5 kiểm tra 2…20000, không phải giới hạn MATLAB nói chung. |
| `bounds_enu_m` | m; ma trận 3×2 | Các hàng lần lượt là [Emin,Emax], [Nmin,Nmax], [Umin,Umax]. Còn dùng để tính mật độ clutter prior của tracker. | Ví dụ [[-3000,5000],[-4000,2000],[20,500]]. Không phải range radar. |

### Radar

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `position_enu_m` | m; [E,N,U] | Vị trí anten trong hệ ENU chung, không nhất thiết ở gốc. | [0,-500,12]; kiểm tra AGL anten >0. |
| `heading_enu_deg` | deg | Hướng trục anten theo quy ước ứng dụng: 0 Đông, 90 Bắc, 180 Tây. | Đổi hướng xoay chùm ngay; muốn đo mới phải mô phỏng lại. |
| `tilt_deg` | deg | Góc ngẩng/định hướng pitch anten qua phép đổi trục của adapter. | Thử 0→10 và nhìn 3D. Không thay độ cao anten. |
| `roll_deg` | deg | Góc lăn của khung anten; làm đổi hướng hai trục bề rộng chùm. | Thử 0→15 với FOV ngang/đứng khác nhau; xem 3D. |
| `mode` | Chuỗi; không đơn vị | Chế độ radar Generic: No scanning / Rotator / Sector / Raster. | RX cố định Raster; dòng này được ẩn khi dùng hồ sơ RX. |
| `scan_technology` | Chuỗi | Generic chọn Mechanical / Electronic / Mechanical and electronic. | RX cố định Electronic; dòng này được ẩn. Không gán HasScanLoss vì chưa triển khai Custom scanning. |
| `update_every_steps` | Số bước nguyên ≥1 | Khoảng cách giữa các lượt đo tính bằng frame; khoảng thời gian đo=N×dt. | 1→4 làm radar cập nhật thưa hơn; không làm PRF giảm bốn lần. |
| `scan_rate_deg_s` | deg/s | Giới hạn tốc độ quét phương vị cơ khí. | Chỉ chế độ quét có Mechanical; 20 deg/s không đảm bảo một vòng quét mất thời gian như mọi loại radar thật. |
| `elevation_scan_rate_deg_s` | deg/s | Giới hạn tốc độ quét góc đứng cơ khí. | Có tác dụng theo mẫu quét native và trục đang quét; xem Raster. |
| `electronic_azimuth_limits_deg` | deg; [min,max] | RX: BIÊN vùng Search ngang của mỗi mặt. Generic: giới hạn điện tử đưa tới API. Góc trong khung anten, đơn vị độ. | RX [-45,45]; adapter trừ nửa chùm để tạo miền tâm quét. Focus dùng giới hạn riêng trong tab Radar → Thiết bị & nhiệm vụ. |
| `electronic_elevation_limits_deg` | deg; [min,max] | RX: BIÊN vùng Search đứng; khác tâm chùm. Generic giữ ý nghĩa giới hạn native. | RX [0,60]. Chỉnh [0,20] để thu hẹp vùng và giảm số hướng khi giữ nguyên chùm. |
| `azimuth_scan_limits_deg` | deg; [min,max] | Miền phương vị quét cơ khí tương đối với hướng lắp đặt. | [-60,60]; nhánh RC5 không gán cặp này cho Rotator. |
| `elevation_scan_limits_deg` | deg; [min,max] | Miền góc đứng quét cơ khí. | [-10,20]; dùng trong Sector/Raster khi có Mechanical. |
| `field_of_view_deg` | deg; [ngang,đứng] | Generic: bề rộng chùm đầy đủ. RX: bề rộng tối đa giả định; adapter chia đều vùng phủ thành các ô không vượt giá trị này. | Generic [120,60]; RX [30,20]. Đọc kích thước thực dùng và số hướng trong tab Radar → Thiết bị & nhiệm vụ. Không phải beamwidth hãng đã xác nhận. |
| `range_limits_m` | m; [min,max] | Cự ly xiên từ radar trong đó xét báo cáo. | Generic [50,8000]; RX [200,10000] là lựa chọn thử theo ngưỡng datasheet, không khẳng định vùng mù đúng 200 m. |
| `frequency_hz` | Hz | Tần số mang cho radar thống kê; tab IQ cũng lấy tần số này. | 9.4e9 = 9.4 GHz. Không phải sample rate hoặc PRF; sửa không tự đổi waveform của radar thật. |
| `reference_range_m` | m | Cự ly cùng RCS tham chiếu xác định điều kiện Pd. | Generic 3000; RX 10000 với Pd=0.9 là GIẢ ĐỊNH, không phải số kiểm định hãng. |
| `reference_rcs_m2` | m² | RCS mục tiêu tham chiếu cho mô hình phát hiện. | 0.01 m² = −20 dBsm; adapter đổi sang dBsm cho API. |
| `detection_probability` | Xác suất 0…1, không đơn vị | Pd tại điều kiện tham chiếu. Trong RC5 phải lớn hơn 0 và nhỏ hơn 1. | 0.9→0.7; cần dataset mới. Không nhập 90. |
| `range_resolution_m` | m | Tham số độ phân giải cự ly của mô hình đo native. | 15→30; không đồng nhất với sigma cự ly. |
| `azimuth_resolution_deg` | deg | Độ phân giải góc phương vị của mô hình đo. | 1→2; cùng sai số góc có thể gây sai số ngang lớn hơn ở xa. |
| `elevation_resolution_deg` | deg | Độ phân giải góc đứng của mô hình đo. | 2→4; có thể ảnh hưởng bất định độ cao; xem kết quả 3D. |
| `noise` | true/false | Bật/tắt nhiễu phép đo native. | Tắt không tự xóa bias/khúc xạ. Phải tạo dataset mới. |
| `range_bias_fraction` | Tỷ lệ, không đơn vị | Bias cự ly theo bội của RangeResolution. | 0.2×15 m =3 m là tham số bias; không phải dịch mọi tọa độ East thêm 3 m. |
| `azimuth_bias_fraction` | Tỷ lệ, không đơn vị | Bias góc phương vị theo bội của AzimuthResolution. | 0.2×1°=0.2°; hướng dịch điểm phụ thuộc vị trí mục tiêu. |
| `elevation_bias_fraction` | Tỷ lệ, không đơn vị | Bias góc đứng theo bội của ElevationResolution. | 0.2×2°=0.4°; cần dataset mới để quan sát. |

### UAV và waypoint

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `name` | Chuỗi tên MATLAB hợp lệ | Tên platform để chọn và hiện trên chú giải. | UAV_1; không trùng tên, không dùng dấu cách trong tên platform. |
| `rcs_m2` | m² | RCS hằng của UAV; không phải khối lượng, kích thước hay công suất phát. | 0.01→0.02; biểu tượng giữ cùng kích thước, detections có thể đổi sau mô phỏng. |
| `birth_scan` | Chỉ số frame; bắt đầu từ 1 | Frame đầu UAV được coi là hoạt động trong cảnh/đánh giá. | Frame k ứng với (k−1)dt. Không đồng nghĩa sự kiện cất cánh có động lực học. |
| `death_scan` | Chỉ số frame | Frame cuối UAV hoạt động; không được vượt frames. | Giảm để thử mục tiêu biến mất. Không phải lệnh UAV thật hạ cánh. |
| `speed_limit_mps` | m/s | Ngưỡng kiểm tra tốc độ quỹ đạo; không ép quỹ đạo giảm tốc. | 150; tăng ngưỡng chỉ cho phép tốc độ lớn hơn qua kiểm tra, không thay chuyển động. |
| `waypoints_enu_m` | m; mỗi dòng [E,N,U] | Các mốc vị trí theo thứ tự thời gian. | Bảng có 3 cột số; sửa từng ô hoặc kéo vòng tròn trong 2D. |
| `arrival_s` | s; một thời điểm mỗi waypoint | Thời điểm phải đi qua từng mốc tính từ t=0. | Bắt đầu 0, tăng nghiêm ngặt; cuối đúng (frames−1)dt. Đây là thời điểm, không phải thời gian chặng. |
| `AGL (cột tính/đặt)` | m | Cao trên bề mặt DEM ở waypoint; sửa cột này sẽ đổi tọa độ để đạt AGL. | Nhập 150. AGL giữa các mốc không nhất thiết hằng. |
| `LLA (hộp nhập)` | [deg,deg,m] | Vĩ độ, kinh độ và cao ellipsoid h của waypoint đang chọn. | Dùng số thập phân. Bảng LLA phía dưới chỉ đọc; dùng nút Nhập waypoint LLA để sửa. |

### Địa hình

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `dem_file` | Đường dẫn tệp | Raster cao độ một band, tọa độ địa lý WGS84. Không phải ảnh màu bản đồ. | Chọn GeoTIFF đúng CRS/mốc cao độ; DEM chiếu UTM cần chuyển trước khi nhập. |
| `geoid_offset_m` | m | N hằng dùng trong h=H+N cho toàn cảnh. | 0 là giả định demo; phải xác minh theo dữ liệu khảo sát khi đo thật. |
| `datum_note` | Văn bản | Ghi nguồn/mốc cao độ và giả định dữ liệu. | Ghi chú không tự hiệu chuẩn số đo hoặc chuyển CRS. |
| `terrain_los` | true/false | Dùng Mapping LOS để loại mục tiêu/điểm tĩnh bị địa hình che khỏi danh sách đưa tới radar. | Không tự mô phỏng cây, nhà hoặc multipath ngoài thông tin raster. |
| `effective_earth_factor` | Tỷ lệ không đơn vị | Bán kính Trái Đất hiệu dụng chia bán kính thực trong LOS; mô hình khúc xạ đơn giản. | Mặc định 4/3 trong mã. Chỉ tác động tới LOS/viewshed tương ứng, không phải cấu hình toàn bộ khí quyển radar native. |
| `minimum_agl_m` | m | Mức hở bề mặt tối thiểu khi kiểm tra quỹ đạo tại các mẫu đang hoạt động. | 1; kiểm tra rời rạc không phải chứng nhận tránh va chạm liên tục ngoài thực tế. |
| `viewshed_target_agl_m` | m | Độ cao giả định của mục tiêu trên bề mặt khi tính bản đồ khả kiến. | 100→150; không tự đổi AGL các UAV đã cấu hình. |
| `origin_lla` | [deg,deg,m] | Gốc hệ ENU. Sửa qua nút Đổi mốc ENU hoặc khi chọn DEM. | Không phải tọa độ UAV; h của gốc là cao ellipsoid. |

### Clutter

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `false_alarms` | true/false | Bật báo động giả ngẫu nhiên của radar thống kê. | false→true; chưa đồng nghĩa bật mọi loại clutter vật lý. |
| `pfa` | Xác suất không đơn vị | Xác suất báo giả theo ô/phép thử native. | 1e-6 =0.000001; tăng lên 1e-5 để thử. Cần sinh lại dataset. |
| `scatterers_enabled` | true/false | Bật các platform phản xạ điểm đứng yên. | Dấu × hiển thị vị trí cấu hình; không bảo đảm radar phát hiện chúng ở mọi scan. |
| `scatterers` | [m,m,m,m²] mỗi dòng | [East,North,AGL,RCS] của từng phản xạ tĩnh. | Cột thứ ba là AGL, KHÔNG phải Up. Ví dụ [1200,-650,20,0.02]. |

### Tracking: lựa chọn và tham số chung

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `method` | Mã/tên lựa chọn | Tổ hợp họ tracker, mô hình chuyển động và filter. | Tên _SPH giữ tương thích project gốc; RC5 vẫn đưa vào phép đo Cartesian ENU. |
| `gnn_assignment` | Chuỗi | Bộ giải gán của GNN: Jonker-Volgenant, Munkres, Auction, MatchPairs, Custom. | Chọn bằng dropdown. Trên cảnh dễ, nhiều solver có thể cho cùng kết quả. |
| `gnn_logic` | Chuỗi | History hoặc Score của GNN. | Chọn Track management; bảng chỉ hiện ngưỡng tương ứng. |
| `jpda_logic` | Chuỗi | History hoặc Integrated của JPDA. | Integrated quản lý xác suất tồn tại, không dùng cặp [M,N] cho ngưỡng xác nhận/xóa. |
| `assignment_threshold` | Chi phí chuẩn hóa; không phải m | Ngưỡng gate chi tiết. Nhãn bình phương trong UI là cách ghi giản lược, đọc giá trị chi phí native theo filter. | 25→16 hoặc 36. Tăng gate có thể giữ mục tiêu cơ động nhưng tăng gán nhầm. |
| `coarse_gate_multiplier` | Tỷ lệ không đơn vị ≥1 | Hệ số tạo ngưỡng sơ bộ: coarse=gate×hệ số. | GNN/JPDA dùng [gate,coarse]; TOMHT hiện dùng [0.3g,0.7g,g,coarse]. |
| `measurement_variance_scale` | Tỷ lệ không đơn vị >0 | Nhân toàn bộ R trước khi đưa detection vào tracker, không sửa R của dataset lưu. | 1→4 nghĩa sigma nhân 2. Phép đo giữ nguyên; chạy lại tracker. |
| `metric_cutoff_m` | m | Ngưỡng cắt khoảng cách của OSPA/GOSPA. | 300; đổi metric làm thay thước so sánh, không làm đường bám tốt hơn. |
| `max_tracks` | Số track nguyên | Giới hạn số track bộ bám được quản lý. | 384 trong cấu hình gốc; không phải số UAV truth. Clutter có thể sinh thêm track. |
| `max_initialization_seconds` | s thời gian tính trên máy | Ngưỡng thời gian cho lần đầu gọi native tracker trong vòng chạy. | 120; chỉ là ngưỡng kiểm tra sau khi lời gọi trả về, không là hard timeout ngắt API. |
| `max_scan_seconds` | s thời gian tính trên máy | Ngưỡng kiểm tra mỗi bước sau khởi tạo. | 20; không phải dt hoặc thời gian quay radar. |
| `max_run_seconds` | s thời gian tính cộng dồn | Ngưỡng cộng dồn ngoài lần gọi khởi tạo theo nl_timing_guard. | 180; không phải thời lượng cảnh mô phỏng. |
| `filter_seed` | Số nguyên không đơn vị | Seed riêng cho phần ngẫu nhiên của bộ lọc, đặc biệt PF. | 9201; giữ cố định khi so tham số PF trên cùng dataset. |
| `tracker_properties_json` | Đối tượng JSON | Thuộc tính public bổ sung, áp sau các tham số thông thường. | Ví dụ {"InitializationThreshold":0.1} cho JPDA; thuộc tính sai/không phù hợp có thể lỗi. |
| `filter_properties_json` | Đối tượng JSON | Thuộc tính public bổ sung của filter, áp sau thiết lập adapter; không áp cho GM-PHD trong nhánh này. | Ví dụ {"Alpha":0.01} khi chọn UKF. Override có thể làm tham số tương ứng trên bảng không còn quyết định giá trị cuối. |

### Tracking: trạng thái và độ bất định

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `velocity_std_mps` | m/s | Độ lệch chuẩn vận tốc ngang ban đầu dùng trong P. | 90; nói mức chưa biết vận tốc lúc tạo track, không phải vận tốc UAV. |
| `vertical_velocity_std_mps` | m/s | Độ lệch chuẩn vận tốc theo Up ban đầu. | 10; độc lập với sigma vị trí. |
| `acceleration_std_mps2` | m/s² | Kích thích gia tốc cho CV/CT; adapter bình phương để dựng Q. | 12; thành phần đứng được đặt bằng 0.5 lần thành phần ngang trong adapter hiện tại. |
| `jerk_std_mps3` | m/s³ | Jerk là tốc độ thay đổi gia tốc, dùng làm kích thích của CA. | 8; thành phần đứng dùng hệ số 0.5 trong adapter. |
| `turn_accel_std_degps2` | deg/s² | Độ lệch chuẩn gia tốc góc của mô hình CT. | 3; khác tốc độ quay deg/s. |
| `initial_accel_std_mps2` | m/s² | Bất định gia tốc ban đầu cho CA. | 20; nằm trong P, không phải Q jerk. |
| `initial_turn_std_degps` | deg/s | Bất định tốc độ quay ban đầu của CT. | 8; không phải góc hướng anten. |
| `ukf_alpha` | Không đơn vị | Tham số phân bố các sigma point của UKF. | 1e-3; đổi nhỏ có chủ đích, cùng R/Q/seed. Không phải tham số alpha của GOSPA. |
| `ukf_beta` | Không đơn vị | Tham số UKF về phân bố trạng thái dùng trong trọng số covariance. | 2; không phải Beta mật độ sinh track của GNN Score. |
| `ukf_kappa` | Không đơn vị | Tham số scaling bổ sung của sigma point UKF. | 0; giá trị hợp lệ còn phụ thuộc cấu trúc filter native. |
| `pf_particles` | Số hạt nguyên | Số mẫu dùng xấp xỉ phân bố trạng thái của PF. | 1000→2000; tăng bộ nhớ/thời gian; không đảm bảo mọi metric đều cải thiện. |
| `pf_resampling` | Chuỗi | Cách lấy mẫu lại: Systematic, Multinomial, Residual, Stratified. | Thay thuật toán tái lấy mẫu; không thay số UAV hoặc tần suất radar đo. |
| `imm_cv_accel_std` | m/s² | Kích thích gia tốc của nhánh CV trong IMM. | 1.5; khác acceleration_std_mps2 của một filter CV chạy độc lập. |
| `imm_ca_jerk_std` | m/s³ | Kích thích jerk của nhánh CA trong IMM. | 8; thứ tự bank IMM là CV, CA, CT. |
| `imm_ct_accel_std` | m/s² | Kích thích gia tốc của nhánh CT trong IMM. | 5; kết hợp tham số gia tốc góc CT. |
| `imm_stay_probability` | Xác suất không đơn vị | Xác suất ở lại cùng mô hình, dùng khi imm_transition=[]. Native định nghĩa chuyển xác suất theo đơn vị thời gian. | 0.94; không đơn giản là xác suất bất biến cho mọi dt. |
| `imm_transition` | Ma trận xác suất 3×3 | Hàng i sang cột j theo thứ tự CV,CA,CT; mỗi hàng tổng 1. | [[0.8,0.1,0.1],[0.1,0.8,0.1],[0.1,0.1,0.8]]; [] quay lại tham số stay. |
| `imm_initial_probabilities` | Vector xác suất 3 phần tử | Niềm tin ban đầu vào CV,CA,CT; không phải ma trận chuyển. | [0.4,0.3,0.3], tổng 1. |

### Tracking: association và vòng đời

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `confirmation_history` | [số hit,số cập nhật] | Ngưỡng xác nhận History theo cửa sổ gần nhất. | [2,3] hoặc [4,5]; không phải giây, không bảo đảm luôn phải chờ hết N bước. |
| `deletion_history` | [số miss,số cập nhật] | Ngưỡng xóa theo lịch sử; track tạm còn có quy tắc thất bại xác nhận. | [3,5] hoặc [5,8]; lớn hơn thường giữ track lâu hơn khi mất đo. |
| `score_confirmation` | Điểm log-likelihood; không đơn vị vật lý | Ngưỡng xác nhận của GNN Score. | 15; không nhập % hoặc [M,N]. |
| `score_deletion` | Điểm score theo quy tắc native | Ngưỡng xóa GNN Score, thường âm; liên quan mức giảm bằng chứng của track. | −8; không diễn giải như số miss hoặc giây. Xem help TrackLogic Score. |
| `pd_assumed` | Xác suất không đơn vị | Pd mà tracker giả định khi tính association/logic tương ứng. | 0.9; không đổi Pd thật của dataset. Không dùng ở GNN History của adapter. |
| `clutter_expected_per_update` | Số báo cáo kỳ vọng/lượt đo | Prior số clutter trong miền bounds để quy đổi thành mật độ cho tracker. | 2; đây là giả định cấu hình, không tự đếm đúng số báo giả từ truth. |
| `clutter_density_scale` | Tỷ lệ không đơn vị | Hệ số nhân mật độ clutter prior. | 1; mật độ trong luồng Cartesian được tính trên thể tích bounds, đơn vị báo cáo/m³/lượt đo. |
| `birth_rate_per_second` | Tốc độ sinh mục tiêu/giây theo mô hình | Prior sinh track/đối tượng. GNN Score/TOMHT/JPDA Integrated đổi sang mật độ bằng dt đo và thể tích; PHD nhận BirthRate trực tiếp. | 0.15; không phải birth_scan của UAV. |
| `jpda_max_events` | Số sự kiện nguyên hoặc chuỗi all | Số sự kiện gán tối đa trong k-best JPDA; all ánh xạ MaxNumEvents=Inf. | 50→100 hoặc all; full enumeration có thể rất tốn tính khi cảnh đông. |
| `existence_confirmation` | Xác suất không đơn vị | Ngưỡng tồn tại để xác nhận JPDA Integrated. | 0.98; không phải Pd radar. |
| `existence_deletion` | Xác suất không đơn vị | Ngưỡng tồn tại để xóa JPDA Integrated. | 1e-5; nhỏ hơn thường giữ giả thuyết tồn tại lâu hơn theo mô hình. |
| `tomht_max_hypotheses` | Số giả thuyết nguyên | Giới hạn số giả thuyết toàn cục native xét/duy trì theo cấu hình. | 12; tăng có thể tăng chi phí tổ hợp, không đảm bảo kết quả tốt hơn trên mọi cảnh. |
| `tomht_max_branches` | Số nhánh nguyên | Giới hạn nhánh track theo API TOMHT. | 3; không phải số UAV tối đa của cảnh. |
| `tomht_history_scans` | Số lượt lịch sử | Độ dài lịch sử giữ cho xử lý giả thuyết. | 3; khác với số frame không có radar cập nhật. |
| `tomht_confirmation` | Điểm score không đơn vị vật lý | Ngưỡng xác nhận của TOMHT. | 12; xem trạng thái và score trong diagnostics, không đổi thành %. |
| `tomht_deletion` | Điểm score theo quy tắc native | Ngưỡng xóa nhánh/track của TOMHT. | −8; không phải cặp History. |
| `phd_death_rate` | Xác suất theo 1 đơn vị thời gian; không đơn vị | Native dùng hệ số sống sót (1−DeathRate)^Δt; Δt đo bằng s trong project. Không phải trực tiếp hazard s⁻¹ hoặc xác suất mất mỗi frame. | 0.01; Δt=2 s cho hệ số sống sót 0.99²=0.9801. Dùng cho PHD và JPDA Integrated. |
| `phd_max_components` | Số thành phần hỗn hợp | Giới hạn số thành phần Gaussian của GM-PHD. | 1200; khác max_tracks. Một mục tiêu có thể liên quan nhiều thành phần. |
| `phd_extraction` | Trọng số/cường độ PHD; không đơn vị vật lý | Ngưỡng trích xuất ước lượng từ hỗn hợp. | 0.45; trọng số PHD không đồng nhất xác suất tồn tại của một Bernoulli track. |
| `phd_confirmation` | Trọng số PHD | Ngưỡng xác nhận track trong PHD. | 0.65; không có nghĩa Pd=65%. |
| `phd_deletion_threshold` | Trọng số PHD | Ngưỡng loại thành phần yếu theo API. | 0.0001; là pruning, khác History deletion. |
| `phd_merging_threshold` | Ngưỡng khoảng cách chuẩn hóa | Điều kiện gộp các thành phần hỗn hợp đủ gần theo native. | 16; không phải 16 m. |
| `phd_birth_assignment_threshold` | Chi phí/ngưỡng native | Điều kiện dùng phép đo để bổ sung thành phần sinh mới. | 25; tách biệt gate của GNN/JPDA. |
| `custom_initializer` | Tên hàm MATLAB | Hàm trên path nhận detection, trả filter native tương thích tracker. | Ví dụ initcvckf; Custom không tự chuyển mọi hệ state sang ENU. |
| `custom_position_indices` | Ba chỉ số nguyên trong state | Chỉ số phần tử trực tiếp chứa East,North,Up của filter custom. | [1,3,5] với state CV; mô hình khác phải xác minh đúng thứ tự. |
| `custom_assignment_fcn` | Tên hàm MATLAB | Hàm theo giao diện CustomAssignmentFcn của trackerGNN. | Chỉ có tác dụng khi solver GNN=Custom; các phụ thuộc hàm phải còn trên path khi replay. |

### IQ — bài riêng

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `sample_rate_hz` | Hz = mẫu/s | Tốc độ lấy mẫu tín hiệu thu/xử lý của bài IQ. | 2e6; SampleRate/PRF phải nguyên. Không phải tần số sóng mang. |
| `prf_hz` | Hz = xung/s | Tần số lặp xung; PRI=1/PRF tính bằng s. | 1000; khác update rate của tracker. Điều kiện echo phải nằm trong PRI đang mô phỏng. |
| `pulse_width_s` | s | Thời lượng một xung LFM. | 20e-6 =20 µs; phải nhỏ hơn PRI. |
| `bandwidth_hz` | Hz | Độ rộng dải tần quét trong xung LFM. | 1e6=1 MHz; không tự đặt RangeResolution của tab Radar. |
| `pulses` | Số xung nguyên | Số xung dùng trong khối xử lý Doppler. | 16→32; RC5 kiểm tra 2…256, không phải giới hạn toolbox nói chung. |
| `array_elements` | Số phần tử anten | Số phần tử của ULA; khoảng cách phần tử đang cố định λ/2. | 4→8; RC5 kiểm tra 2…64. Hình array beam thay đổi, không đổi anten radar thống kê. |
| `gamma_db` | dB | Gamma của mô hình constantGammaClutter mặt phẳng đồng nhất. | −20→−10; không phải RCS m² của một UAV. |
| `height_m` | m | Cao radar trên mặt phẳng trong bài IQ. | 30; không lấy AGL anten từ DEM của cảnh. |
| `speed_mps` | m/s | Tốc độ platform radar trong bài IQ; hướng đang cố định trong mã. | 0→10; không phải tốc độ UAV. Doppler clutter có thể thay đổi. |
| `depression_deg` | deg | Góc chúc của anten trong cấu hình clutter IQ. | 5; không phải tilt_deg của radar thống kê. |
| `max_range_m` | m | Cự ly clutter lớn nhất của bài IQ. | 5000; phải lớn hơn height và echo vừa PRI. Độc lập range_limits_m của cảnh. |
| `azimuth_span_deg` | deg | Độ rộng vùng clutter theo phương vị. | 60; tăng có thể tăng số patch/tính toán. |
| `patch_azimuth_deg` | deg | Độ rộng patch theo phương vị để rời rạc hóa clutter. | 5; patch nhỏ hơn thường tăng số phần tử mô hình cần tính. |
| `transmit_erp_w` | W | Tham số biên độ phát mà mã dùng bằng sqrt(giá trị) cho tín hiệu vào clutter. | 1000; tên ERP trong UI không thay thế việc hiệu chuẩn chuỗi Pt/gain/loss/EIRP của radar thật. |
| `cfar_pfa` | Xác suất không đơn vị | Pfa yêu cầu của bộ CFAR trong bài IQ. | 1e-4; không phải pfa của radar thống kê. Cell training=24, guard=4 đang cố định trong mã. |
| `steer_deg` | deg | Hướng steering dùng tính đồ thị đáp ứng ULA chuẩn hóa. | 0→20; không beamform lại cube phát hiện đang xử lý, không lái chùm radar cảnh. |

### RX-R417C: cấu hình thiết bị mô phỏng

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `profile` | Chuỗi | Hồ sơ mô phỏng thiết bị. | Generic hoặc RX-R417C; không phải kết nối phần cứng. |
| `operation` | Chuỗi | Search quét các mặt bật; Focus chỉ dùng một mặt và vùng chỉ định. | Nhập Search hoặc Focus. Focus không phải TAS bám tự động theo mục tiêu. |
| `face_offsets_deg` | deg; 4 số | Hướng tương đối của bốn mặt so với đế; dương theo quy ước ENU. | [0,90,180,270]; đế cân bằng: Đông, Bắc, Tây, Nam khi heading=0. |
| `faces_enabled` | 4 giá trị true/false | Bật hoặc tắt từng mặt 1–4. | [true,false,false,false]; giữ ít nhất một mặt bật. Focus yêu cầu mặt được chọn đang bật. |
| `focus_face` | Số nguyên 1..4 | Số hiệu mặt được dùng khi operation=Focus. | 1→2 chuyển mặt; không tự đổi hướng UAV. |
| `focus_azimuth_deg` | deg; [min,max] | Hai biên phương vị vùng Focus trong khung mặt anten. | [-15,15]→[10,40]; không phải East/North mét. |
| `focus_elevation_deg` | deg; [min,max] | Hai biên góc ngẩng vùng Focus trong khung mặt. | [0,20]→[0,40] làm tăng số hướng nếu giữ chùm tối đa. |
| `scan_aware_tracking` | true/false | GNN/JPDA dùng vị trí track dự đoán để xét cơ hội quan sát trong chùm đang quét. | Không tính miss cho track ngoài chùm; không dùng truth. TOMHT/PHD chưa dùng cơ chế này; CSV nhập độc lập thiếu lịch chùm. |

### Hiển thị RC5

| Tên trường / ô | Đơn vị / dạng | Bản chất | Ví dụ, điều kiện và quan sát |
| --- | --- | --- | --- |
| `OSM` | true/false | Bật lớp bản đồ gốc. | Chỉ hiển thị; không tạo vật cản hoặc clutter. |
| `Tỷ lệ cao độ` | Hệ số Auto hoặc ×1/3/6/12/20 | Tỷ lệ vẽ chiều đứng so với chiều ngang; Auto cân đối khung 3D. | Mặc định Auto; tọa độ và số mét không đổi. |
| `Vùng quét` | true/false | Bật đường biên vùng phủ danh định. | Đường chấm khác đường liền chùm đang quan sát. |
| `Toàn tầm radar` | true/false | Mở rộng giới hạn trục ngang theo range tối đa. | Không mở rộng DEM và miền kiểm tra đường bay. |

## 8. Khi có radar thật: phải bổ sung những gì?

**Không có một bộ giá trị “chuẩn cho mọi radar”.** Cần biết hãng/model, firmware, chế độ xuất dữ liệu và tài liệu giao thức của thiết bị. Các ô RC5 hiện tại cấu hình mô hình trong máy tính; chúng chưa gửi lệnh thay đổi công suất, tần số, chế độ quét hoặc ngưỡng phát hiện của radar ngoài đời.

### 8.1. Xác định đầu ra trước khi nghĩ đến kết nối

| Radar cung cấp | Muốn đưa vào dự án thì cần | RC5 hiện có thể dùng trực tiếp? |
| --- | --- | --- |
| File detections ENU 3D | Xác minh mốc, đơn vị, covariance, thời gian; ánh xạ về schema CSV | Có thể qua adapter CSV nếu đáp ứng đầy đủ điều kiện; không phải tự nhận mọi file |
| Range/azimuth/elevation | Hiệu chuẩn range/góc, đổi khung anten→ENU, đổi covariance bằng Jacobian hoặc mô hình đo native phù hợp | Chưa có bộ nhập trực tiếp trong UI |
| Chỉ range+azimuth của radar 2D | Thiết kế bộ đo/bám 2D, hoặc nguồn thông tin độ cao có mô hình bất định rõ ràng | Không được tự đặt Up=0/100 rồi coi là phép đo 3D thật |
| Góc-only / bearing-only | Mô hình đo không quan sát trực tiếp cự ly; thiết kế khởi tạo/bám phù hợp | Chưa có adapter hiện hành |
| I/Q thô, ADC hoặc radar cube | Giải mã/bù DC/IQ, hiệu chuẩn kênh, FFT hoặc matched filter, Doppler, CFAR, ước lượng góc, covariance | Tab IQ hiện không phải bộ thu và xử lý dữ liệu thiết bị này |
| Track của firmware | Bộ nhập track, hiểu state/covariance/correlation; có thể cần track fusion | Không nên giả làm detections độc lập để chấm chất lượng detector/bộ bám lại |

Tần số có trong datasheet không cho biết đầy đủ radar xuất gì. Một sản phẩm có thể cho nhiều loại dữ liệu tùy license/firmware. Xin file mẫu và tài liệu định dạng trước khi viết adapter.

### 8.2. Phiếu thông tin cần thu thập từ hãng và lúc đo

| Nhóm | Cần ghi cụ thể | Đơn vị/kiểu dữ liệu | Tác dụng |
| --- | --- | --- | --- |
| Danh tính thiết bị | Hãng, model, serial, firmware, phiên bản giao thức, chế độ đang chạy | Văn bản/ID | Tái hiện đúng cách giải mã và cấu hình |
| Giao tiếp | Ethernet/serial/SDK/file; UDP/TCP; IP, port; địa chỉ máy thu | Port là số nguyên; IP/chuỗi | Kết nối nhận dữ liệu; chưa nói nội dung gói nghĩa là gì |
| Gói dữ liệu | Header, độ dài, endian, kiểu số, scale factor, frame/packet counter, CRC/checksum | byte, bit, số nguyên/float | Tránh đọc nhầm byte thành số đo |
| Thời gian đo | Timestamp tại lúc đo hay lúc gửi; UTC/GPS/device ticks; tần số đồng hồ; offset/drift | s, ms, µs hoặc tick cần đổi đúng | Đồng bộ radar với UAV/GNSS và thứ tự dữ liệu |
| Trễ/thiếu gói | Latency, jitter, packet loss, out-of-order, reboot/reset clock | ms, số gói, tỷ lệ | Phân biệt mất dữ liệu với radar không phát hiện |
| Vị trí lắp đặt | LLA của tâm/điểm tham chiếu anten; loại cao độ h/H; datum; mốc ENU | deg, deg, m | Đặt radar đúng chỗ trên bản đồ |
| Độ lệch lắp đặt | Lever arm từ mốc khảo sát/IMU/GNSS tới tâm anten | [m,m,m] | Tránh gán tọa độ mốc đo thay cho vị trí anten |
| Hướng anten | Hướng trục boresight, azimuth zero, chiều dương, tilt/roll, thứ tự Euler, true/magnetic/grid north | deg hoặc rad, quy ước trục | Tránh quay/đảo gương đường bám |
| Phép đo đầu ra | Range xiên hay ngang; azimuth/elevation; radial velocity; vị trí Cartesian | m, deg/rad, m/s | Chọn đúng mô hình đo, không đánh đồng range-rate với vận tốc toàn phần |
| Sai số/hiệu chuẩn | Bias range/góc, sigma/covariance, phụ thuộc range/SNR; độ phân giải | m, deg/rad; covariance theo tích đơn vị | Tạo R và hiệu chỉnh độ lệch có căn cứ |
| Chu kỳ quan sát | Frame rate, dwell, lịch/biên quét, track update, vùng không quan sát | Hz, s, deg | Xác định lượt cập nhật hợp lệ và Pd/logic track |
| Tín hiệu nếu có I/Q | Center frequency, sample rate, bandwidth, pulse/chirp timing, PRF, số kênh, ADC scale | Hz, s, mẫu, bit | Cấu hình bộ xử lý tín hiệu đúng với thiết bị |
| Anten nếu xử lý mảng | Vị trí phần tử, gain/pattern, phân cực, lệch pha/biên độ từng kênh | m, dBi/dB, deg/rad | Beamforming/ước lượng góc có hiệu chuẩn |
| Mốc so sánh | GNSS/RTK hoặc hệ tham chiếu độc lập trên UAV; timestamp, covariance, lever arm | deg/m, s, m² | Đánh giá sai số bám và độ trễ có cơ sở |
| Ngữ cảnh môi trường | DEM/DSM, mốc cao độ, vật cản, cấu hình và trạng thái đo | Tệp/đơn vị tương ứng | Tái hiện điều kiện và giải thích che khuất/clutter |

Các giá trị chưa biết để **chưa xác định**, không điền default mô phỏng rồi coi đó là thông số radar thật. Không cần mua/cài thêm toolbox chỉ vì một giao thức có tên quen thuộc: xác định API/SDK cần dùng trước. MATLAB có `udpport` cho giao tiếp UDP, nhưng nhận được datagram không đồng nghĩa giải mã được giao thức radar của hãng. [API UDP](https://www.mathworks.com/help/instrument/udpport.html)

### 8.3. Chuỗi tích hợp cần làm theo thứ tự

1. **Ghi dữ liệu nguyên gốc.** Lưu gói/file raw, phiên bản firmware, thời gian và cấu hình thiết bị. Giữ bản raw để có thể giải mã lại khi phát hiện sai quy ước.
2. **Viết bộ giải mã theo tài liệu hãng.** Tách frame, kiểm tra độ dài/checksum, đổi đơn vị và ghi cờ chất lượng. Đầu ra phải phân biệt báo cáo thật, báo cáo lỗi và khoảng không có gói.
3. **Đồng bộ thời gian.** Quy đổi về giây trên cùng mốc; ghi riêng thời gian đo, thời gian nhận và trễ nếu có. Không gán mọi timestamp bằng giờ máy tính nhận gói rồi coi là lúc radar đo.
4. **Khảo sát mốc và khung trục.** Đặt tâm anten, hướng, độ lệch lắp đặt; xác minh điểm chuẩn bên Đông/Bắc/cao hơn để phát hiện đảo trục/dấu/góc.
5. **Hiệu chuẩn bias và covariance.** So phép đo với vị trí tham chiếu độc lập; phân biệt sai lệch có hệ thống với phân tán ngẫu nhiên. Ước lượng sai số trong đúng điều kiện range/SNR nếu chúng thay đổi theo điều kiện.
6. **Chọn adapter đo.** Nếu chuyển polar sang ENU, phải chuyển cả covariance. Với phép đổi cục bộ, R_ENU≈J R_polar Jᵀ; đạo hàm theo góc phải dùng radian nhất quán. Chỉ đổi tọa độ rồi giữ R góc/cự ly cũ là sai đơn vị.
7. **Phát lại offline trước.** Giữ raw, tạo dataset đã chuẩn hóa, chạy so các tracker trên cùng phiên đo. Kiểm tra số gói, số detection và những thời điểm trống trước khi chấm thuật toán.
8. **Bổ sung luồng streaming nếu cần trực tiếp.** Cần buffer, hàng đợi, đồng bộ, chiến lược gói trễ/OOSM, ghi log và trạng thái kết nối. RC5 hiện chưa có các thành phần này.
9. **Đánh giá bằng tham chiếu.** Đồng bộ truth/GNSS vào cùng mốc, cùng thời gian; xét cả sai số vị trí, độ trễ, mất bám và đổi ID. CSV hiện hành chưa nhập truth thực để tự tính metric; phải viết phần này hoặc đánh giá ngoài adapter hiện tại.

**Đừng nhầm tốc độ:** RC5 đang đặt HasRangeRate=false. Vận tốc track là ước lượng từ vị trí qua thời gian; chưa sử dụng phép đo Doppler/range-rate trực tiếp. Nếu radar thật xuất v_r, cần thêm thành phần đo, covariance, quy ước dấu và mô hình đo tương ứng. v_r chỉ là thành phần vận tốc theo đường ngắm, không phải vector [vE,vN,vU].

### 8.4. Điều kiện chính xác của CSV RC5 hiện tại

CSV có tiêu đề, dấu phẩy phân cột và số thập phân dùng dấu chấm. Mỗi dòng detections_enu.csv là **một detection**; cùng time_s có thể có nhiều dòng cho nhiều detection. Generic dùng sensor_id=1. Hồ sơ RX-R417C chấp nhận số hiệu của các mặt đang hoạt động; ví dụ Focus mặt 2 dùng sensor_id=2. Dữ liệu nhiều mặt không được đổi tất cả ID thành 1. Thời gian phải nằm trong 0…(frames−1)dt và khớp lưới dt của phiên; không tùy tiện làm tròn dữ liệu thực lệch lưới để qua kiểm tra.

| Cột | Ý nghĩa | Đơn vị |
| --- | --- | --- |
| time_s | Thời điểm đo tính từ mốc bắt đầu phiên | s |
| sensor_id | ID 1 cho Generic; ID của mặt được bật trong RX-R417C | Số nguyên |
| east_m, north_m, up_m | Ba thành phần vị trí trong cùng ENU với cấu hình | m |
| r_ee, r_nn, r_uu | Phương sai sai số từng trục E,N,U | m² |
| r_en, r_eu, r_nu | Các covariance chéo; ma trận đầy đủ được dựng đối xứng | m² |

Một dòng mẫu minh họa: `0,1,600,-600,120,25,25,100,0,0,0`. Nó biểu diễn sigma ngang 5 m và sigma đứng 10 m, các covariance chéo bằng 0 theo **giả định của mẫu**, không là kết quả hiệu chuẩn một radar.

Tệp updates.csv cùng thư mục mô tả **mọi frame**: time_s, valid_update (0/1), detection_count. Importer hiện kiểm tra time_s/valid_update, tự tính lại số detection từ file đo; đừng kỳ vọng cột detection_count không khớp sẽ tự được phát hiện. Mẫu đi kèm giữ các cột nhất quán.

Nếu không có updates.csv, lịch mặc định lấy từ update_every_steps của cấu hình; với dữ liệu thật có lịch khác, điều này có thể dẫn tới cách hiểu miss sai. Cần cung cấp lịch cập nhật đúng thay vì giả định “không có detection” luôn là “radar đã đo nhưng hụt”. Khoảng mất gói không tương đương một lượt đo rỗng đã được thiết bị xác nhận.

### 8.5. Những gì cần cấu hình thêm trong app, thay vì chỉ nhập thông số

| Nhu cầu thực | Thành phần cần phát triển thêm |
| --- | --- |
| Kết nối radar live | Driver/SDK/protocol adapter, buffer và giám sát trạng thái |
| Gửi lệnh tới radar | Adapter điều khiển theo API hãng, đọc lại cấu hình thực sự được áp dụng |
| Dữ liệu không đều thời gian | Timeline theo timestamp thật, xử lý cập nhật và dữ liệu trễ/OOSM |
| Nhiều radar | Sensor ID riêng, extrinsics/covariance/thời gian của từng radar; tracker/fusion đa cảm biến |
| Radar 2D hoặc chỉ góc | Detection schema, state/measurement model và đánh giá phù hợp phần quan sát được |
| Dùng Doppler | Mở rộng vector đo/covariance, dấu v_r và hàm đo tương ứng |
| Track do radar phát sẵn | Adapter objectTrack và xử lý tương quan khi fusion; không coi là detection thô |
| Đánh giá với GNSS thực | Import truth, hiệu chỉnh lever arm, đồng bộ thời gian, các metric sai số/độ trễ/ID |
| I/Q của thiết bị | Bộ xử lý tín hiệu đúng waveform, anten và calibration của thiết bị |

## 9. Lưu trữ, lỗi thường gặp và cách tự kiểm tra

### 9.1. Mỗi kết quả được lưu ở đâu?

Nơi lưu mặc định: **results/native_workspace/datasets** và **results/native_workspace/runs** bên trong project. **Chọn nơi lưu** thay thư mục cha cho các lần lưu tiếp theo; không chuyển dữ liệu đã có. Bài IQ vẫn ở **results/native_iq**, lỗi ở **results/native_errors**, kết quả kiểm thử ở **results/native_tests**.

| Tệp trong archive | Bạn dùng khi nào? |
| --- | --- |
| archive.json | Tra tên/ID/nguồn dataset, trạng thái, release, hash MAT/DEM |
| native_session.mat | Nguồn đầy đủ để mở lại config, detections và các result native |
| session.json | Đọc cấu hình đang hiện hành lúc lưu; từng result còn có config riêng |
| summary.csv | So metric/thời gian và TrackerConfigJSON của từng result |
| detections_enu.csv, updates.csv | Tra phép đo và lịch cập nhật theo từng thời điểm |
| scan_state.csv | Mỗi thời điểm/mặt: hướng chùm ngang/đứng (deg), valid_update, scan_done và số điểm đo; đầy đủ lịch native giữ trong MAT |
| truth_enu.csv | Truth mô phỏng; không phải dữ liệu khảo sát thật |
| *_tracks.csv, *_metrics.csv | Kết quả theo thời gian, riêng từng result |
| attempts.json | Trạng thái và lỗi từng mục batch, có cả cấu hình |
| assets/terrain.tif | DEM được sao chép để archive không mất phụ thuộc vị trí DEM gốc |
| scene.png, metrics.png | Ảnh xuất từ UI nếu xuất ảnh thành công; không thay thế kết quả số |
| replay.m | Chạy lại bộ bám trên phép đo lưu |
| configure_session.m | Dựng cấu hình và sinh mô phỏng mới; khác replay |

COMPLETE nghĩa là quy trình tương ứng hoàn tất, không có nghĩa thuật toán đạt độ chính xác yêu cầu. PARTIAL của batch nghĩa là còn mục lỗi/hủy/chưa chạy; kết quả thành công trước đó vẫn có thể được lưu. Archive chống ghi đè bằng thư mục ID mới và kiểm tra hash, không phải chế độ tệp tuyệt đối không thể sửa ở hệ điều hành.

### 9.2. Các tình huống dễ gặp

| Dấu hiệu | Nguyên nhân cần kiểm tra | Thao tác phù hợp |
| --- | --- | --- |
| Sửa quỹ đạo nhưng track không đổi | Đang xem result cũ hoặc mới chỉ preview | Tạo dataset rồi chạy tracker, xem trạng thái dưới hình |
| Tăng RCS/Pd nhưng hình không khác ngay | Đây là tham số mô hình đo, không đổi hình học | Tạo dataset mới; so thống kê nhiều thời điểm/seed nếu cần |
| UAV exceeds speed limit | Quỹ đạo nội suy nhanh hơn giới hạn | Tăng thời lượng/rút ngắn đường; không gọi tăng speed_limit là giảm tốc |
| Last waypoint time… | Điểm cuối không khớp thời lượng cảnh | Đặt đúng (frames−1)dt và kiểm tra thứ tự thời điểm |
| Outside DEM / NoData | Điểm/gốc ở ngoài raster hoặc vùng rỗng | Kiểm tra LLA, DEM, CRS, mốc và bounds; không thay NaN thành mặt đất 0 tùy ý |
| Antenna underground / minimum AGL | Anten/UAV dưới bề mặt theo datum hiện tại | Kiểm tra N/h/H và dùng nút/cột đặt AGL đúng |
| Không có detections | FOV/range/hướng/lịch quét/LOS/Pd hoặc dữ liệu nhập | Kiểm tra từng điều kiện, trước hết hình học và valid_update |
| Có detections, chưa có confirmed track | Cần thêm bằng chứng, gate không phù hợp, nhịp đo thưa | Mở Chi tiết bám và đọc logic, Q/R, gate |
| Track chạy lệch hoặc đảo trục sau nhập | Sai ENU/NED, đơn vị góc, gốc, hướng anten hoặc thời gian | Đối chiếu một điểm chuẩn trước khi chỉnh Q/R để che lỗi |
| Metric trống | CSV không có truth hoặc frame không cập nhật | Đây có thể là trạng thái đúng; không đổi NaN thành 0 |
| So hai filter nhưng mọi kết quả giống nhau | Cảnh/measurement model gần tuyến tính; cùng assignment | Kiểm tra config đã áp, rồi thiết kế cảnh cơ động; không cần ép kết quả khác nhau |
| Property không tồn tại/không liên quan | Sai tên, sai class hoặc điều kiện API | Tra help R2025a; bỏ override; không tắt cảnh báo để coi là đã chạy đúng |
| Dataset/config không khớp | Đã sửa radar/địa hình/quỹ đạo/seed sau khi tạo dữ liệu | Mở lại archive đúng hoặc tạo dataset mới |
| Lỗi thời gian TOMHT/JPDA/PF | Quá nhiều giả thuyết/sự kiện/hạt, cold start hoặc máy chậm | Xem log; giảm độ phức tạp hoặc điều chỉnh giới hạn có căn cứ; không gán FAILED thành PASS |
| CHECK có found=false | Không tìm thấy API trên path, có thể thiếu sản phẩm hoặc path | Đọc đúng tên API; CHECK không kiểm tra thực thi/license |

### 9.3. Kiểm thử trước một buổi demo

Trong Command Window, sau khi đặt đúng thư mục project:

```matlab
NATIVE_LAB_CHECK
NATIVE_LAB_TESTS('rx')
NATIVE_LAB_TESTS('workflow')
NATIVE_LAB_TESTS('tracking')
NATIVE_LAB_TESTS
START_NATIVE_LAB
```

Chạy từng lệnh, đọc kết quả trước khi sang lệnh tiếp. `workflow` kiểm tra lưu/mở/di chuyển, hash, batch lỗi/hủy và marker. `tracking` kiểm tra các tổ hợp mở rộng. Không đối số chạy core; `all` thêm cả IQ và các suite. Dấu found=true không thay cho Passed. Sổ tay này đã hợp nhất phần RC5 với nền tài liệu v2. RC5.2 gộp cấu hình thiết bị vào tab Radar và chỉnh bố cục 3D; chưa có thêm bằng chứng chạy runtime tại môi trường đóng gói. Suite rx kiểm tra bốn mặt, lịch chùm, dữ liệu và giao diện mới.

## 10. Từ điển thuật ngữ bổ sung

| Thuật ngữ | Cách hiểu đúng trong ngữ cảnh này | Đơn vị nếu có |
| --- | --- | --- |
| WGS84 | Hệ tham chiếu trắc địa; RC5 dùng ellipsoid WGS84 và tọa độ địa lý tương ứng | Không có một đơn vị riêng; lat/lon deg, h m |
| CRS | Coordinate Reference System, mô tả cách tọa độ gắn với Trái Đất | Tùy CRS; không mặc định mọi cặp x/y là m ENU |
| Datum | Mốc/hệ tham chiếu của vị trí hoặc cao độ; không chỉ là một offset tùy ý | Phải mô tả hệ, cao độ liên quan m |
| DEM / DSM | Mô hình cao độ dạng raster; DSM mô tả bề mặt có thể gồm công trình/cây | Cao độ m theo datum nguồn; độ phân giải raster có đơn vị riêng |
| Raster / GeoTIFF / NoData | Lưới giá trị / định dạng tệp có tham chiếu địa lý / ô không có dữ liệu hợp lệ | Tùy nội dung; ở đây một band cao độ m |
| NED | North–East–Down, khung trục khác ENU; dấu trục đứng đảo | m cho vị trí; m/s cho vận tốc |
| Yaw / pitch / roll | Ba góc mô tả tư thế theo quy ước trục và thứ tự quay; không được bỏ qua quy ước | deg trong các ô RC5 |
| Azimuth / elevation | Góc phương vị / góc nâng trong khung đo | deg trong mô hình; thiết bị có thể xuất rad hoặc số mã hóa |
| Boresight / FOV | Trục nhìn danh định của anten / bề rộng góc nhìn tức thời | FOV deg |
| LOS / viewshed | Line of sight: có đường nhìn giữa hai điểm; viewshed: vùng có đường nhìn từ vị trí quan sát với giả định độ cao | Kết quả khả kiến logic; độ cao đầu vào m |
| Occlusion / clutter / false alarm | Che khuất / tán xạ không quan tâm / báo cáo phát hiện giả; ba khái niệm không đồng nhất | Tùy mô hình, không có đơn vị duy nhất |
| RCS / dBsm | Tiết diện radar tương đương / thang log so với 1 m² | RCS_dBsm=10log10(RCS_m²/1 m²) |
| dB / dBm / dBi | Tỷ số theo log / công suất so 1 mW / gain so anten đẳng hướng | dB cần biết đại lượng tham chiếu; không tự đổi Power dB trên hình thành dBm |
| SNR | Signal-to-noise ratio, tỷ số công suất tín hiệu và nhiễu | Tỷ số hoặc dB; không có ô SNR scene độc lập trong RC5 |
| PRF / PRI | Số xung mỗi giây / khoảng thời gian giữa xung | Hz và s, PRI=1/PRF |
| I/Q | Hai thành phần vuông pha tạo mẫu phức của tín hiệu | Biên độ phụ thuộc thang ADC/hiệu chuẩn, không mặc định volt hoặc watt |
| LFM / bandwidth | Linear frequency modulation: tần số quét theo thời gian trong xung / bề rộng dải tần | Bandwidth Hz, pulse width s |
| Matched filter | Bộ lọc phù hợp dạng tín hiệu đã biết, dùng tăng khả năng nhận biết/xử lý xung theo mô hình | Đầu ra theo thang tín hiệu của chuỗi xử lý |
| Doppler / range-rate | Đổi tần do chuyển động tương đối / tốc độ thay đổi cự ly xiên | Hz / m/s; dấu phụ thuộc quy ước |
| CFAR | Constant false alarm rate: cách đặt ngưỡng theo ước lượng nền trong điều kiện mô hình | Pfa không đơn vị; training/guard là số cell |
| ULA / steering | Uniform linear array: mảng phần tử thẳng đều / chọn hướng đáp ứng mảng | Khoảng cách m; góc deg; gain thường chuẩn hóa dB |
| CV / CA / CT | Constant velocity / constant acceleration / constant turn: các mô hình chuyển động | Vận tốc m/s; gia tốc m/s²; tốc độ quay deg/s trong CT native đang dùng |
| KF / EKF | Kalman filter tuyến tính / extended Kalman filter dùng tuyến tính hóa cục bộ | State/covariance có đơn vị theo mô hình |
| UKF / CKF | Unscented / cubature Kalman filter: dùng các điểm đại diện để lan truyền moment qua phép biến đổi | Không có đơn vị riêng cho tên phương pháp |
| PF / particle | Particle filter: xấp xỉ phân bố bằng các mẫu có trọng số | Số hạt nguyên; trọng số không đơn vị |
| IMM | Interacting multiple model: phối hợp các bộ lọc/mô hình chuyển động và xác suất mô hình | Xác suất không đơn vị, chuyển xác suất gắn quy ước thời gian |
| GNN / JPDA / TOMHT | Gán tổng thể gần nhất / gán xác suất liên hợp / bám nhiều giả thuyết hướng track | Chi phí và xác suất theo mô hình native |
| PHD / RFS / GGIW | Mật độ giả thuyết xác suất / random finite set / mô hình phân bố cho mục tiêu mở rộng | Trọng số PHD tích phân liên quan số mục tiêu kỳ vọng; không là một xác suất tồn tại đơn giản |
| Hypothesis / branch | Một khả năng giải thích dữ liệu / nhánh lịch sử track theo khả năng gán | Số lượng nguyên khi đặt giới hạn |
| Tentative / confirmed / coasted | Track tạm / đủ điều kiện xác nhận / được dự báo khi chưa có cập nhật đo thích hợp | Cờ logic; Age là số cập nhật theo API |
| Covariance / sigma | Ma trận moment sai số bậc hai / độ lệch chuẩn | Sigma cùng đơn vị đại lượng; covariance có tích đơn vị |
| Prior / posterior | Niềm tin trước khi dùng dữ liệu mới / niềm tin sau cập nhật | Tùy phân bố; không đồng nghĩa truth |
| Seed / Monte Carlo | Khởi tạo ngẫu nhiên để tái hiện / lặp nhiều thí nghiệm ngẫu nhiên để đánh giá | Seed không đơn vị; số trial nguyên; RC5 chưa có batch Monte Carlo scene tự động trong UI |
| API / SDK / adapter | Giao diện lập trình / bộ công cụ hãng / lớp chuyển dữ liệu và lời gọi giữa hệ thống | Không có đơn vị vật lý |
| Dataset / run / archive | Tập phép đo cố định / một lần xử lý cấu hình thuật toán / gói lưu có cấu hình và dữ liệu | Dữ liệu có đơn vị từng trường; ID không phải đơn vị |
| Timestamp / latency / OOSM | Thời điểm đo / độ trễ / phép đo đến không đúng thứ tự thời gian | s hoặc đơn vị cần quy đổi; không mặc định thời gian nhận là thời gian đo |
| GNSS / RTK / lever arm | Định vị vệ tinh / kỹ thuật tăng độ chính xác tương đối GNSS / vector lệch giữa các điểm tham chiếu lắp đặt | Tọa độ và độ lệch m; chất lượng phụ thuộc nghiệm và điều kiện |
| RMSE / OSPA / GOSPA | Sai số căn trung bình bình phương / các metric tập đối tượng có xét vị trí và số lượng | m khi dùng khoảng cách vị trí mét; cần giữ cùng thiết lập khi so |
| SHA-256 | Hàm băm kiểm tra nội dung tệp có thay đổi | Không chứng minh số đo đúng vật lý; chỉ kiểm tra toàn vẹn nội dung |

## 11. Lộ trình tự đánh giá năng lực

| Mốc | Bạn phải tự làm và giải thích được |
| --- | --- |
| A — tọa độ và giao diện | B01–B06; giải thích LLA/ENU/AGL, thời điểm đến và nhịp radar; sửa đúng waypoint và quan sát |
| B — kịch bản/radar/môi trường | B07–B14; chỉ ra tham số hình học và thống kê; thiết kế một cảnh có điều kiện quan sát xác định |
| C — thí nghiệm tracking | B15–B23; giữ dataset cố định, thay từng lớp, đọc diagnostics, lưu/tái hiện và kết luận có căn cứ |
| D — dữ liệu và tín hiệu | B24–B26; hiểu giới hạn CSV/IQ; trình diễn đầy đủ và biết còn thiếu gì trước khi nối radar thật |

Hoàn thành các bài giúp làm chủ **phạm vi RC5 đã triển khai**, không phải chứng nhận đã dùng toàn bộ mọi API của các toolbox. Để mở rộng chuẩn, đi theo yêu cầu dữ liệu/ứng dụng cụ thể rồi bổ sung adapter, tham số, hiển thị và kiểm thử tương ứng.


## 12. Bản đồ tệp để đọc mã khi đã quen giao diện

Không cần sửa các tệp này để làm B01–B32. Khi cần kiểm tra một tính năng, tìm đúng nơi xử lý thay vì mở ngẫu nhiên toàn project.

| Tệp, tính từ thư mục project | Vai trò |
| --- | --- |
| `START_NATIVE_LAB.m` | Điểm mở ứng dụng. |
| `NATIVE_LAB_CHECK.m` | Kiểm tra API có trên path. |
| `NATIVE_LAB_TESTS.m` | Chạy suite core/workflow/tracking/rx/all; rx dành cho các thay đổi RC5. |
| `src/make_tracker.m` | Factory gốc vẫn giữ nguyên; nhánh mới có adapter riêng. |
| `src/configure_filter.m` | Quy tắc đặt Q/P của các mô hình, được nhánh mới sử dụng. |
| `src/track_positions.m` | Đọc vị trí từ state theo các mô hình gốc. |
| `data/datasets` | 80 dataset gốc, giữ nguyên. |
| `data/dem` | Địa hình gốc dùng cho các bài mặc định. |
| `training` | Nhánh bài học/toolbox trước Native Lab; có phạm vi riêng. |
| `native_lab/tests` | Các test MATLAB; không thay cho file kết quả Passed sau thực thi. |
| `native_lab/nl_device.m` | Các trường hồ sơ Generic/RX-R417C, nhiệm vụ và bật/tắt mặt. |
| `native_lab/nl_faces.m` | Đổi biên vùng phủ thành lưới tâm chùm, hướng và kích thước chùm của từng mặt. |
| `native_lab/nl_sensor_bank.m` | Tạo radarDataGenerator riêng cho từng mặt; giữ SensorIndex. |
| `native_lab/nl_rx_preset.m` | Preset 07/08 theo datasheet, tách rõ các giả định chưa có số hãng. |
| `native_lab/nl_rotation.m` | Phép quay hướng lắp đặt và hướng chùm theo quy ước NED/ENU. |
| `native_lab/nl_scan_preview.m` | Lấy chuỗi LookAngle từ API radar native để xem trước và lưu đệm. |
| `native_lab/nl_in_beam.m` | Xét vị trí track dự đoán trong chùm; không đọc truth để hỗ trợ gán. |
| `native_lab/nl_osm.m` | Đổi XY bản đồ gốc qua lưới địa lý gốc, phủ lên DEM hiện tại và đổi sang ENU. |
| `native_lab/nl_plot_map.m` | Vẽ mặt địa hình xanh và các lớp OSM, không sinh phép đo/clutter. |
| `native_lab/nl_app.m` | Tạo giao diện, nhận thao tác, phát lại và gọi các bước xử lý; không phải thuật toán radar. |
| `native_lab/nl_apply_properties.m` | Áp JSON property public, kiểm tra thuộc tính và các trường bị bảo vệ. |
| `native_lab/nl_archive.m` | Lưu dataset/run mới, sao DEM, tính hash, ghi metadata sau cùng. |
| `native_lab/nl_batch.m` | Chạy hàng đợi trên dữ liệu cố định; phân biệt COMPLETE/FAILED/CANCELLED/NOT_RUN. |
| `native_lab/nl_commands.m` | Chuyển config thành mã MATLAB để đọc và tái tạo; không phải live hardware command. |
| `native_lab/nl_defaults.m` | Lấy thông số xuất phát từ project cũ và thêm các trường Native Lab. |
| `native_lab/nl_export.m` | Xuất MAT/CSV và script; được nl_archive dùng để tạo archive đầy đủ. |
| `native_lab/nl_fields.m` | Định nghĩa các dòng thông số, nhãn và cột thông tin hiện trong bảng UI. |
| `native_lab/nl_ground.m` | Tra cao độ bề mặt và tính LLA/AGL tại điểm ENU. |
| `native_lab/nl_import_csv.m` | Nhập ENU 3D theo lưới dt; SensorIndex phải thuộc mặt đang hoạt động (Generic: 1). Chưa là driver hãng. |
| `native_lab/nl_init_filter.m` | Khởi tạo filter, Q/P, UKF, PF, IMM hoặc initializer tùy chọn. |
| `native_lab/nl_iq.m` | Bài tín hiệu/clutter/ULA riêng; không sinh detections cho scene tracking. |
| `native_lab/nl_legend.m` | Vẽ chú giải bằng marker thật của MATLAB phù hợp các lớp trên hình. |
| `native_lab/nl_lessons.m` | Đọc nội dung 16 bài học cũ từ lessons_vi.json. |
| `native_lab/nl_library.m` | Lập danh sách dataset/run có archive.json tại nơi lưu hiện tại. |
| `native_lab/nl_los.m` | Gọi Mapping los2 để kiểm tra đường nhìn radar–mục tiêu. |
| `native_lab/nl_make_tracker.m` | Tạo tracker native theo cấu hình; dùng ánh xạ dựa trên factory project cũ. |
| `native_lab/nl_method_label.m` | Rút gọn cách hiện mã phương pháp thành nhãn dễ đọc. |
| `native_lab/nl_open_archive.m` | Kiểm tra hash, mở MAT và khôi phục đường dẫn DEM theo vị trí archive. |
| `native_lab/nl_positions.m` | Lấy vị trí E/N/U từ state theo mô hình hoặc ba chỉ số Custom. |
| `native_lab/nl_preset.m` | Định nghĩa tám preset; 01–06 Generic và 07–08 RX-R417C Search/Focus. |
| `native_lab/nl_preview.m` | Tạo waypointTrajectory, lấy mẫu đường bay/tốc độ, kiểm tra bounds/AGL/tốc độ. |
| `native_lab/nl_radar.m` | Tạo radarDataGenerator và profile RCS; chỉ gán property theo mode thích hợp. |
| `native_lab/nl_rebase.m` | Đổi gốc ENU của các điểm/khung anten nhưng giữ bố trí địa lý. |
| `native_lab/nl_registry.m` | Giữ mã 17 tổ hợp cũ và bổ sung các lựa chọn tích hợp/custom của RC5. |
| `native_lab/nl_root.m` | Xác định thư mục gốc project để tìm dữ liệu và các tệp cấu hình. |
| `native_lab/nl_run_label.m` | Bổ sung solver/logic vào nhãn result để dễ phân biệt. |
| `native_lab/nl_set_agl.m` | Đặt cao độ so với raster tại điểm đang xét, giữ vị trí địa lý ngang. |
| `native_lab/nl_signature.m` | Tạo dấu nhận dạng cấu hình sinh phép đo; bỏ qua thay đổi riêng tracker/IQ. |
| `native_lab/nl_simulate.m` | Chạy uavScenario theo một đồng hồ, tạo detections và lưu truth riêng. |
| `native_lab/nl_storage.m` | Ghi nhớ thư mục cha của thư viện dataset/run. |
| `native_lab/nl_summary.m` | Tạo bảng tổng hợp metric, thời gian và cấu hình từng result. |
| `native_lab/nl_terrain.m` | Đọc DEM GeoTIFF và tạo lưới địa hình ENU; không tự thay bằng dữ liệu giả. |
| `native_lab/nl_timing_guard.m` | Kiểm tra thời gian tính sau khi native call trả về; không cưỡng bức ngắt API. |
| `native_lab/nl_track.m` | Chạy tracker trên cùng phép đo, ghi states/diagnostics/timing và metric. |
| `native_lab/nl_tracking_defaults.m` | Bổ sung trường mới khi mở cấu hình tracking cũ. |
| `native_lab/nl_tracking_keys.m` | Chọn các trường tracking nên hiện theo họ tracker/filter/logic. |
| `native_lab/nl_validate.m` | Kiểm tra cấu hình cảnh, thời gian, vùng bay, radar và UAV trước khi chạy. |
| `native_lab/nl_validate_tracking.m` | Kiểm tra cấu hình các lựa chọn tracking bổ sung. |
| `native_lab/nl_value.m` | Đọc số/vector/JSON nhập từ bảng; không dùng eval để thực thi chuỗi nhập. |
| `native_lab/nl_viewshed.m` | Gọi Mapping viewshed để tính vùng nhìn thấy theo AGL mục tiêu giả định. |

Các bản hướng dẫn RC2/RC3 và hướng dẫn ngắn RC5 trước đây có thể còn trong gói để tra lịch sử. **WORKFLOW_RC5.html là sổ tay hợp nhất hiện hành; WORKFLOW_RC4.html là bản sao tương thích cho nút Hướng dẫn đầy đủ**; các nhãn/mô tả cũ phải đối chiếu lại với bản này.

## 13. Nguồn và trạng thái kiểm chứng

Khái niệm được giải thích bằng lời mới, đối chiếu mã RC5 và tài liệu MathWorks. Chi tiết property R2025a được kiểm tra bằng help/mã API cài tại máy biên soạn. Trang web MathWorks có thể hiển thị release mới hơn; khi khác biệt, dùng help của release đang chạy.

- [Hệ tọa độ và chuyển ENU](https://www.mathworks.com/help/map/ref/geodetic2enu.html)
- [Cao ellipsoid và cao trực chuẩn](https://www.mathworks.com/help/map/ellipsoid-geoid-and-orthometric-height.html)
- [Tạo quỹ đạo waypoint](https://www.mathworks.com/help/robotics/ref/waypointtrajectory-system-object.html)
- [Độ chính xác, bias và độ phân giải radar](https://www.mathworks.com/help/radar/ug/measurement-accuracy-bias-and-resolution.html)
- [Các bộ lọc ước lượng](https://www.mathworks.com/help/fusion/estimation-filters.html)
- [Các bộ bám nhiều đối tượng](https://www.mathworks.com/help/fusion/multi-object-trackers.html)

Lần cập nhật này kiểm tra độ phủ tài liệu với các trường UI trong mã, cấu trúc CSV mẫu, liên kết nội bộ HTML và toàn vẹn gói ZIP. Mã RC5 có các thay đổi bốn mặt/OSM/3D; RC5.2 chỉnh bố cục hiển thị và hợp nhất sổ tay, giữ thuật toán mô phỏng RC5. Runtime RC5 vẫn chưa được xác minh tại môi trường biên soạn do lỗi khởi động MATLAB. Các dự đoán “quan sát được” trong bài là cơ chế dự kiến từ mã, không phải ảnh/kết quả đo đã thực thi.