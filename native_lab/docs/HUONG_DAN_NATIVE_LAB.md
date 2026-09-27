# Nội Bài Radar — Native Interactive Lab 1.0 RC2

Nhánh `training/native-interactive`, xây trên project Nội Bài Radar v8.4 và nhánh training trước đó. Mã và dữ liệu gốc được giữ nguyên; các chức năng mới nằm trong `native_lab/` và ba entry point mới ở thư mục gốc.

**Trạng thái kiểm chứng:** đã kiểm tra tĩnh bằng Code Analyzer R2025a và kiểm tra tính toàn vẹn khi đóng gói. Chưa chạy được mô phỏng hoặc xem giao diện trong MATLAB ở môi trường xây gói: MATLAB dừng ngay khi khởi động với lỗi `System Error: File system inconsistency`. Không có tuyên bố runtime PASS, không có ảnh kết quả giả. Bộ kiểm thử MATLAB đi kèm để kiểm tra trên máy người dùng.

## Bắt đầu trong MATLAB — từng bước

1. Giải nén toàn bộ ZIP vào một thư mục có quyền ghi. Không chạy các tệp khi chúng còn nằm trong ZIP. Không chép đè lên bản project cũ đang làm việc.
2. Mở MATLAB R2025a. Ở ô Current Folder, chuyển tới thư mục vừa giải nén có `START_NATIVE_LAB.m`, `config`, `data`, `src`, `native_lab`.
3. Trong Command Window, nhập `NATIVE_LAB_CHECK`. Bảng này chỉ kiểm tra tìm thấy API; true không chứng minh thuật toán đã chạy được.
4. Nhập `NATIVE_LAB_TESTS` để chạy bộ core (gồm thử dựng giao diện ẩn và các tracker gốc). Nếu muốn thử bài IQ, chạy thêm `NATIVE_LAB_TESTS('all')`. Kết quả lưu trong `results/native_tests`. Không bỏ qua FAILED/INCOMPLETE.
5. Nhập `START_NATIVE_LAB`. Cửa sổ có bảng cấu hình bên trái, cảnh 2D/3D bên phải và trạng thái bên dưới.
6. Chọn preset “01 Cơ bản: hai UAV”, nhấn “1. Mô phỏng + bám”. Chờ thông báo hoàn tất. App tự lưu một thư mục kết quả mới; không ghi đè lượt trước.
7. Bấm Phát/Dừng, Từng bước hoặc kéo thanh thời gian để xem. Làm các bài theo thứ tự phía dưới. Trong mỗi bảng, nhấp đúp ô Giá trị rồi nhập số; mảng dùng dạng `[1,2,3]`, bật/tắt dùng `true`/`false`.

## Các sản phẩm và thuật toán thực sự được dùng

MATLAB điều khiển UI, lưu dữ liệu và vẽ. Mapping Toolbox đọc GeoTIFF, chuyển tọa độ, nội suy cao độ và tính LOS/viewshed. UAV Toolbox tạo waypointTrajectory và uavScenario/uavPlatform; radar lấy pose từ `read(uavPlatform)` theo một đồng hồ chung. Radar Toolbox tạo phép đo thống kê bằng radarDataGenerator với profile RCS. Sensor Fusion and Tracking Toolbox chạy các bộ tracker qua factory gốc và tính OSPA/GOSPA native. Phased Array System Toolbox dùng cho bài IQ/array riêng. Nhánh mới không gọi Python để tạo dữ liệu hay chạy mô phỏng.

17 kết hợp tracker từ `src/method_registry.m` được giữ: GNN/JPDA/TOMHT với CV-EKF, CV-UKF, IMM-EKF, CA-UKF, CT-UKF; GM-PHD CV/CA. Tên có hậu tố _SPH được giữ để đối chiếu registry gốc, nhưng nhánh mới đưa vào **Cartesian ENU**, không tuyên bố đang lọc phép đo spherical. Ma trận covariance đầy đủ được giữ. Không chạy temporal-support của benchmark gốc trong nhánh mới.

OSPA/GOSPA dùng khoảng cách vị trí Euclidean, p=2, cutoff lấy từ cấu hình; GOSPA alpha=2, switching penalty=0. Đây là metric sai số tập hợp theo từng lượt đo, không đánh giá toàn bộ danh tính quỹ đạo dài hạn. Không mặc định số liệu bằng metric tự viết của luồng benchmark cũ nếu chưa đối chiếu định nghĩa.

## Có gì trong giao diện

- Radar: vị trí ENU/AGL, yaw/pitch/roll, chùm nhìn, cự ly, tần số, tham chiếu RCS/range/Pd, phân giải, bias, nhiễu, mode/technology quét, tốc độ/giới hạn cơ khí và điện tử, nhịp cập nhật.
- UAV: nhiều UAV, waypoint kéo trong 2D hoặc bảng số, nhập LLA, AGL/Up, thời gian đến, giới hạn tốc độ, RCS đẳng hướng và lịch tham gia.
- Địa hình: GeoTIFF geographic WGS84, N geoid hằng, nhập DEM/mốc mới, đổi mốc ENU giữ vị trí địa lý, LOS và viewshed.
- Clutter: báo động giả native theo Pfa và các điểm phản xạ tĩnh RCS đặt trong cảnh. Clutter phân bố trong bài IQ riêng sử dụng constantGammaClutter.
- Tracking: chọn 17 kết hợp và các tham số factory gốc thực sự sử dụng. Một tham số chỉ có tác dụng với loại tracker/filter tương ứng; xem bảng tham số phía sau.
- Phiên: dt/frames/seed/bounds, nhập CSV ENU, lưu/mở cấu hình, xuất MAT/CSV/script.
- IQ: LFM, clutter mặt đất phẳng, matched filter, CFAR, range-Doppler và beam ULA. Các đỉnh tín hiệu clutter không phải detection UAV.
- Bài học: 16 bài hướng dẫn trong app; nút mở UAV Scenario Designer và Radar Designer riêng của MathWorks. **Chưa có import/export tự đồng bộ giữa hai Designer và app này.** Dùng Xem lệnh để tra cấu hình và mã API thật của nhánh.

## Giới hạn được thiết kế rõ ràng

Luồng tích hợp là một radar monostatic cố định, phép đo vị trí 3D, không range-rate. Chưa có nhiều radar đồng bộ trong UI; chưa có bistatic/ESM, waveform-to-track, ghost/multipath, mô phỏng khí động 6DOF hoặc flight controller. OSM của project gốc được giữ, nhưng không biến thành vật cản điện từ trong nhánh mới. Cảnh mới vẽ DSM và không vẽ lại toàn bộ overlay OSM của viewer gốc.

DEM đầu vào phải là cao độ trực giao mét trên raster geographic WGS84 một band. Nhánh không tự chuyển mọi CRS/datum. N geoid hằng mặc định 0 là giả định demo; trước đo thật phải thay bằng thông tin đo/chuẩn cao độ phù hợp. Đổi mốc dùng tọa độ ENU cục bộ; không phục vụ thay đổi hệ quy chiếu toàn cầu tùy ý.

Kéo waypoint: hình gấp khúc thay đổi trong lúc kéo; khi thả mới tính lại quỹ đạo native. Thay cấu hình sensor/scenario làm kết quả cũ mất hiệu lực. Đổi tracker có thể chạy lại cùng điểm đo. Tracking/mô phỏng/viewshed/IQ nặng không được hứa chạy tức thì. Hủy tác vụ có tác dụng khi lời gọi toolbox hiện tại trả quyền điều khiển; không ngắt cưỡng bức giữa phép tính native.

Phần `training/` cũ vẫn có các bài mở rộng Navigation, Antenna, Optimization, Simulink, Coder... Chúng chưa được đồng bộ vào UI này. Hai cảnh báo training_check cũ (`design`, `normfit`) vẫn thuộc checker/bài cũ; nhánh mới không dùng chúng làm điều kiện bắt buộc cho core. `design` có thể là phương thức cần kiểm tra bằng đối tượng, không đủ kết luận thiếu Antenna Toolbox chỉ từ which('design').

## Các bài thực hành
### 01 — Chạy và phân biệt ba lớp dữ liệu

1. Mở START_NATIVE_LAB trong thư mục gốc đã giải nén. Chọn preset “01 Cơ bản: hai UAV” ở góc trên trái. Nếu có lỗi, đọc khung trạng thái dưới cùng trước khi tiếp tục.

2. Chọn 2D. Bật “Đường thật”. Các đường màu là đường UAV do bạn cấu hình; vòng tròn là waypoint của UAV đang chọn. Hình vuông đen là radar. Hình xanh nhạt chỉ là biên chùm quan sát danh định.

3. Nhấn “1. Mô phỏng + bám”. Chờ khung dưới cùng báo hoàn tất và đường dẫn thư mục tự lưu. Trong quá trình chạy, không đổi thông số. Có thể bấm “Hủy tính”; lượt bị hủy không được công bố là kết quả hoàn chỉnh.

4. Bật “Điểm đo” và “Đường bám”, rồi nhấn “Phát / Dừng”. Chấm đỏ là phép đo; đường có nhãn T là track. Bấm “Từng bước” để xem từng thời điểm.

5. Tự kiểm tra: tắt từng lớp và giải thích được lớp nào do UAV Toolbox tạo, lớp nào do Radar Toolbox sinh, lớp nào do thuật toán tracking ước lượng. Không dùng đường thật làm đầu vào tracker.

### 02 — Chỉnh tọa độ, Up và AGL

1. Chọn tab UAV, chọn UAV_1. Bảng waypoint có East, North, Up, Đến lúc s, AGL. Chỉ sửa ô số, không mở JSON. East tăng là đi về Đông; North tăng là đi về Bắc; đơn vị mét.

2. Ở dòng waypoint số 3, tăng East thêm 100 rồi Enter. Đường bay nội suy native được tính lại và hình cập nhật. Kết quả cũ bị ẩn, có thông báo cần chạy lại.

3. Ở cùng dòng, nhập AGL = 100. Chương trình tính cao độ ellipsoid từ DEM + N + AGL, rồi đổi về ENU. Quan sát Up và bảng kinh/vĩ độ phía dưới cùng thay đổi nhất quán.

4. Chọn dòng waypoint rồi bấm “Nhập waypoint LLA”. Điền vĩ độ, kinh độ và h ellipsoid bằng số thập phân. Không nhập độ cao trên mặt đất vào ô h ellipsoid.

5. Tự kiểm tra: AGL gần 100 m nhưng Up không nhất thiết bằng 100 m. Vào tab Radar, nhấn “Đặt chiều cao anten AGL (m)” để thử anten 20 m. Bảng Up radar phải phản ánh địa hình tại vị trí anten.

### 03 — Kéo quỹ đạo và chỉnh thời gian

1. Chọn tab UAV và chế độ 2D. Giữ chuột trên một vòng tròn waypoint và kéo nhẹ sang trái hoặc phải. Đường gấp khúc cập nhật trong lúc kéo; thả chuột để tính lại waypointTrajectory và kiểm tra tốc độ/địa hình.

2. Nếu quỹ đạo vi phạm tốc độ hoặc xuyên địa hình, app báo lý do và trả cấu hình về trước thao tác đó. Đây không phải lỗi cần bỏ qua; cần đổi khoảng cách, cao độ hoặc thời gian bay.

3. Để chèn điểm, chọn một dòng trong bảng, bấm “Chèn waypoint”. Điểm mới được chèn giữa dòng đã chọn và dòng tiếp theo. Khi chọn dòng cuối, điểm được chèn trước điểm cuối. “Xóa waypoint” giữ ít nhất hai điểm.

4. Đổi thời gian đến của một waypoint trung gian, giữ thứ tự tăng dần. Điểm đầu phải ở 0 s; điểm cuối bằng (frames - 1)*dt. Để đổi tổng thời gian, sửa dt hoặc frames ở tab Phiên; app co giãn toàn bộ mốc thời gian.

5. Tự kiểm tra bằng biểu đồ tốc độ: cùng một đường hình học có thể cần tốc độ khác khi thời gian đến đổi. Muốn thử hover, thêm hai waypoint liên tiếp cùng tọa độ, thời gian khác nhau, rồi kiểm tra native trajectory và tốc độ; không mặc định đường nội suy nào cũng tạo đoạn dừng đúng ý.

### 04 — Nhiều UAV, RCS và lịch xuất hiện

1. Trong tab UAV, bấm “Thêm UAV”. UAV mới sao chép đường bay UAV đang chọn và nâng Up 20 m. Nếu vượt miền/cao độ, thao tác được từ chối để tránh tạo cấu hình không hợp lệ.

2. Chọn UAV mới trong hộp chọn. Đổi tên thành một định danh như UAV_3; tên phải duy nhất. Chỉnh đường và thời gian để tạo tình huống cắt nhau.

3. Đổi RCS m² của một UAV từ 0.01 xuống 0.003. Giá trị được đổi sang dBsm cho rcsSignature. Đây là RCS đẳng hướng, chưa phải signature thay đổi theo góc nhìn/aspect.

4. Đổi “Bắt đầu ở bước” và “Kết thúc ở bước” để UAV chỉ tham gia radar/truth trong một khoảng. Quỹ đạo vẫn được định nghĩa trên toàn phiên.

5. Chạy lại và quan sát điểm đo/track. Không kết luận Pd từ một lượt ngắn; so nhiều seed và giữ các thông số khác cố định.

### 05 — Vị trí và hướng radar

1. Chọn tab Radar. Dòng “Vị trí anten [E,N,U]” nhận ba số như [0,-500,12]. Có thể di chuyển ngang bằng East/North, sau đó dùng nút AGL để đặt anten trên địa hình.

2. Đổi “Hướng: 0 Đông, 90 Bắc” từ 0 sang 30. Quan sát biên chùm quay trên hình. Đây là góc trong ENU; app đổi sang quy ước MountingAngles NED khi tạo radarDataGenerator.

3. Đổi “Bề rộng chùm [ngang,đứng]” từ [120,60] sang [30,30]. Chọn 3D để nhìn chiều đứng. Đổi góc ngẩng để hướng chùm lên/xuống.

4. Đổi khoảng cách [min,max]. Giới hạn nhỏ nhất tạo vùng không đo gần radar; giới hạn lớn nhất chỉ là giới hạn quan sát, không đảm bảo mọi mục tiêu trong đó đều được phát hiện.

5. Nhấn “Mô phỏng + bám” và dừng ở lúc UAV ra khỏi chùm. Phân biệt mất điểm đo do hình học, do LOS địa hình và do xác suất phát hiện.

### 06 — Độ phân giải, nhiễu và bias radar

1. Chọn preset cơ bản. Chạy một lần và lưu thư mục kết quả. Giữ nguyên seed để thí nghiệm có thể lặp lại.

2. Trong tab Radar, tăng “Độ phân giải cự ly” từ 15 lên 40 m. Chạy lại. Tham số đưa vào RangeResolution; không diễn giải nó là sigma = 40 m.

3. Lần lượt thử độ phân giải góc ngang/đứng. Sai số vị trí do sai số góc thường biểu hiện rõ hơn ở xa. Ma trận MeasurementNoise native được giữ trong dữ liệu kết quả.

4. Thử tắt “Thêm nhiễu đo” bằng false. Bias là tham số riêng: đặt các bias fraction về 0 khi muốn khảo sát trường hợp không nhiễu và không bias.

5. Thử bias cự ly 0.1 với các điều kiện khác giữ nguyên. Xem sự lệch có hệ thống khác với nhiễu ngẫu nhiên. Tham chiếu khoảng cách/RCS/Pd mô tả điểm làm việc của radar thống kê; tần số đơn lẻ không thay thế một thiết kế link budget đầy đủ.

### 07 — Quét cơ khí, điện tử và lượt đo

1. Chọn preset “04 Radar quét sector”. Tab Radar cho biết mode Sector, góc quét và tốc độ. Chạy mô phỏng; góc look ghi lại từ đối tượng radar native được dùng để phát lại biên chùm.

2. Thử Raster. “Cách quét” có Mechanical, Electronic hoặc Mechanical and electronic. Giới hạn cơ khí và điện tử là các thông số khác nhau; tham số chỉ có tác dụng khi loại quét tương ứng bật.

3. Thử Rotator + Mechanical để quay toàn vòng. Preset Rotator sử dụng giới hạn cơ khí native toàn vòng; app không lấy giới hạn sector để thay thế vòng quay.

4. Tăng “Đo mỗi N bước” từ 1 lên 4. Radar chỉ sinh phép đo ở các thời điểm cách nhau dt*N. Bước không có lượt đo không bị tính thành một lần radar bỏ sót.

5. Quan sát file updates.csv: valid_update=0 khác với valid_update=1 và detection_count=0. Đường bám hiển thị lịch sử tại các lượt cập nhật; không nội suy một track mới rồi gọi đó là đầu ra tracker.

### 08 — Báo động giả và clutter prior

1. Chọn tab Clutter. Bật “Báo động giả ngẫu nhiên” bằng true. Bắt đầu Pfa = 0.000001, chạy, xem số điểm đo.

2. Tăng Pfa lên 0.00001, chạy lại cùng seed. Pfa là xác suất theo ô phân giải; số điểm giả phụ thuộc vùng quan sát và số ô, không bằng Pfa nhân số UAV.

3. Qua tab Tracking, tìm “Số clutter kỳ vọng mỗi lượt đo”. Đây là prior cho tracker, không phải tham số sinh điểm giả. Chỉnh prior rồi dùng “Chạy lại tracker” để giữ nguyên tập điểm đo.

4. So cách GNN/JPDA/TOMHT xử lý cùng dữ liệu báo giả. Đừng dùng nhãn truth để lọc điểm giả trước khi tracking.

5. Tự kiểm tra: phân biệt c.clutter.pfa của sensor và c.tracking.clutter_expected_per_update của tracker. Trong bảng đo/track có thể xuất hiện thêm điểm hoặc track; số lượng không bắt buộc tăng đơn điệu trong mọi lượt ngẫu nhiên.

### 09 — Điểm phản xạ tĩnh trong cảnh

1. Trong tab Clutter, bật “Bật điểm phản xạ tĩnh”. Mỗi dòng phía dưới có East, North, AGL và RCS m². Nhấn “Thêm điểm tĩnh” hoặc “Xóa điểm cuối” để thay số lượng.

2. Đặt một điểm gần tuyến bay, với AGL dương và RCS như 0.02 m². Hình dấu x xám phải hiện tại vị trí đó.

3. Chạy mô phỏng. Điểm tĩnh là một platform không vận tốc với rcsSignature; phép đo của nó do radarDataGenerator sinh. Nó có thể bị giới hạn FOV/range/LOS như đối tượng khác.

4. Điểm tĩnh không nằm trong truth UAV. Nếu tracker bám nó thành một track, metric theo bài toán chỉ theo dõi UAV xem đó là track thừa.

5. Tự kiểm tra: phân biệt phản xạ tĩnh với báo động giả ngẫu nhiên. Không gọi tập điểm RCS này là clutter bề mặt phân bố, ray tracing, phản xạ nhiều đường hoặc mô hình OSM công trình.

### 10 — DEM, LOS và vùng nhìn thấy

1. Trong tab Địa hình, giữ DEM Nội Bài đi kèm để học trước. Bật terrain_los. App đọc GeoTIFF thật; không thay bằng terrain.mat mà không báo.

2. Hạ cao anten bằng nút AGL trong tab Radar hoặc hạ UAV bằng cột AGL. Chạy lại để xem LOS ảnh hưởng tập mục tiêu đưa vào radar như thế nào.

3. Trong tab Địa hình, đặt AGL mục tiêu cho viewshed, ví dụ 100 m. Bấm “Tính viewshed”. Hình riêng biểu diễn khả năng nhìn thấy mục tiêu ở cao độ đó trên địa hình; không phải bản đồ Pd.

4. Muốn nhập DEM khác, bấm “Chọn DEM”, chọn GeoTIFF geographic WGS84, rồi nhập mốc ENU và N geoid cho vùng mới. Đường bay ENU được đặt quanh mốc mới; đây là chuyển cảnh sang địa điểm mới. Raster hệ tọa độ chiếu cần được chuyển sang định dạng hỗ trợ trước.

5. N=0 mặc định chỉ là giả định demo. DEM đi kèm là DSM; có thể chứa bề mặt công trình/cây. Không cộng OSM như vật cản vật lý lần nữa nếu chưa xác định dữ liệu. Giới hạn mô hình: LOS hình học/bán kính hiệu dụng, không phải mô phỏng điện từ đa đường.

### 11 — Đổi mốc ENU đúng nghĩa

1. Chọn một waypoint trong tab UAV và ghi lại vĩ độ, kinh độ, h ellipsoid ở bảng dưới. Lưu cấu hình trước khi làm bài.

2. Trong tab Địa hình, nhấn “Đổi mốc ENU”. Thử tăng vĩ độ mốc một lượng nhỏ, ví dụ 0.0002 độ, giữ mốc vẫn nằm trong DEM.

3. App đổi toàn bộ tọa độ waypoint/radar/điểm tĩnh và miền ENU theo mốc mới. Các giá trị East/North/Up thay đổi trong khi vị trí địa lý của waypoint phải giữ nguyên trong sai số số học.

4. Không nhầm thao tác này với “Chọn DEM” và đặt lại mốc cho một địa điểm mới. Một thao tác đổi cách biểu diễn, thao tác kia di chuyển cấu hình cảnh sang khu vực bạn nhập.

5. Tự kiểm tra bằng bảng LLA trước/sau và test rebase. Hướng radar cũng được đổi theo trục ENU mới. Phiên bản này dùng vùng cục bộ và một N geoid hằng, không phải dịch vụ chuyển datum địa lý toàn cầu.

### 12 — CV, UKF, IMM và tham số lọc

1. Chọn preset “05 UAV cơ động: IMM” hoặc tạo đường có đổi hướng. Chạy mô phỏng một lần.

2. Ở tab Tracking, chọn GNN_CV_EKF_SPH rồi “Chạy lại tracker”. Sau đó chọn GNN_CV_UKF_SPH hoặc GNN_IMM_EKF_SPH và chạy lại. Tên _SPH được giữ từ danh mục cũ; nhánh này cung cấp phép đo Cartesian ENU cho các bộ khởi tạo native.

3. Biểu đồ GOSPA vẽ các kết quả trên cùng tập phép đo. Hộp chọn phía trên cảnh chọn đường bám nào để xem. Cấu hình từng lượt nằm trong results của native_session.mat.

4. Thử acceleration_std_mps2 với CV/CT, jerk_std_mps3 với CA, hoặc các tham số imm_* khi dùng IMM. Không phải mọi tham số Q tác dụng lên mọi mô hình.

5. Thử measurement_variance_scale = 4. Đây là R nhân 4, tương đương sigma nhân 2 khi xét từng phương sai, không phải sigma nhân 4. Điểm đo lưu sẵn không bị sửa; tracker mới nhận bản sao với R thay đổi.

### 13 — Gating, xác nhận/xóa và ghép đa mục tiêu

1. Chọn kịch bản có hai UAV gần hoặc cắt nhau, có báo giả. Chạy một lần. Nhấn “So sánh 3 bộ” để chạy GNN, JPDA, TOMHT với cùng CV-EKF và cùng điểm đo.

2. Sau khi hoàn tất, chọn từng kết quả ở hộp phía trên cảnh và quan sát nhãn track, khoảng mất bám và GOSPA. Tham số khởi đầu chưa được tuyên bố tối ưu.

3. Trong tab Tracking, GNN có History hoặc Score; JPDA có History hoặc Integrated. Với History, cặp [M,N] của xác nhận/xóa có ý nghĩa khác với các ngưỡng score/existence.

4. Tăng assignment_threshold từng ít một để nới gate. Tăng gate có thể nhận được nhiều ứng viên hơn nhưng cũng làm ghép sai dễ hơn; không mặc định càng lớn càng tốt.

5. Chọn GM_PHD_CV_CART hoặc GM_PHD_CA_CART để học thêm birth/death, số component, extraction/confirmation/merging. Đọc mã make_tracker của project gốc bằng nút Xem lệnh. So thuật toán trên dữ liệu giữ nguyên; khi đổi cảnh phải sinh dữ liệu mới.

### 14 — Clutter IQ, LFM, matched filter, CFAR và ULA

1. Chọn tab IQ. Đây là bài tín hiệu riêng, cần Radar Toolbox và Phased Array System Toolbox. Cảnh UAV bên phải không được dùng làm echo cho bài này.

2. Giữ mặc định rồi bấm nút Chạy trong tab IQ. Các đối tượng native gồm constantGammaClutter, phased.LinearFMWaveform, phased.MatchedFilter, phased.CFARDetector, phased.ULA và phased.SteeringVector.

3. Đổi gamma_db từ -20 lên -10, chạy lại và quan sát công suất clutter. Thử chiều cao, tốc độ radar, góc chúc, vùng clutter. Mô hình giả định mặt đất phẳng đồng nhất và truyền tự do; không dùng DSM Nội Bài.

4. Đổi băng thông xung và PRF trong giới hạn hợp lệ. PRF quyết định khoảng lấy mẫu theo xung; SampleRate/PRF phải nguyên. Echo phải nằm trong một PRI. Thử thay Pfa CFAR để quan sát các vượt ngưỡng.

5. Đổi số phần tử và hướng steer để xem đồ thị ULA chuẩn hóa. Beam này là bài array riêng, không tự cài vào radar thống kê. Các đỉnh CFAR của tín hiệu chỉ có clutter không được gọi là phát hiện UAV. Không có echo UAV/nhiễu máy thu trong bài IQ này.

### 15 — Lưu, mở lại và demo có thể tái hiện

1. Nhấn “Lưu cấu hình” để lưu những gì đang chỉnh. JSON là định dạng lưu, bạn không cần tự sửa JSON để thực hành.

2. Sau mỗi lượt mô phỏng/tracking hoàn tất, app tự tạo một thư mục mới trong results/native_lab. “Xuất thí nghiệm” tạo thêm một bản có ảnh cảnh hiện tại.

3. Trong thư mục có native_session.mat, session.json, configure_session.m, replay.m, detections_enu.csv, truth_enu.csv, updates.csv và CSV track/metric của từng kết quả.

4. Dùng “Mở phiên” để mở native_session.mat và xem lại kết quả; mở JSON thì chỉ nạp cấu hình và cần chạy lại. Không sửa cấu hình rồi trình bày track cũ như kết quả mới.

5. Khi dùng DEM ngoài project, giữ tệp ở đường dẫn cấu hình hoặc đóng gói nó cùng dữ liệu của bạn. Không gửi riêng MAT rồi cho rằng mọi tệp địa hình ngoài project cũng đã được nhúng. Để demo trên máy khác, dùng toàn bộ project và DEM liên quan.

### 16 — Nhập phép đo thật qua schema rõ ràng

1. Trước tiên xác định radar xuất IQ, detections hay tracks. Bộ nhập hiện tại chỉ nhận detections Cartesian ENU từ một sensor, không giải mã định dạng riêng của thiết bị.

2. Chuẩn bị CSV với cột time_s,sensor_id,east_m,north_m,up_m,r_ee,r_nn,r_uu,r_en,r_eu,r_nu. sensor_id=1; tọa độ mét; các r_* là covariance m². Thời gian tính từ 0 và khớp lưới dt của phiên.

3. Đặt đúng mốc ENU, dt, frames và nhịp đo trước khi nhập. Nếu có updates.csv cùng thư mục, app đọc lịch valid_update từ đó. Nếu không có, app dùng nhịp đo cấu hình và coi các lượt không có điểm là lượt đo rỗng.

4. Chọn tab Phiên → “Nhập CSV radar ENU” → chọn tệp. Sau đó nhấn “Chạy lại tracker”. App ẩn quỹ đạo mô phỏng khi xem CSV thật và không tính OSPA/GOSPA vì chưa có nguồn tham chiếu đồng bộ.

5. Bước nối thiết bị cụ thể còn cần tài liệu hoặc tệp mẫu: datum, hướng anten, thứ tự góc, timestamp, latency, covariance và lever arm. Không tự nhận log GPS là truth hoàn hảo. Bộ nhập không giả định những thông tin chưa được cung cấp.
## Tham số tracking: chỉnh đúng nhóm mới có tác dụng

| Nhóm | Tham số chính | Tác dụng |
|---|---|---|
| Khởi tạo | velocity_std_mps, vertical_velocity_std_mps | Covariance vận tốc ban đầu |
| CV / CT | acceleration_std_mps2 | Độ lệch chuẩn nhiễu gia tốc đưa vào ProcessNoise |
| CA | jerk_std_mps3, initial_accel_std_mps2 | Nhiễu jerk và covariance gia tốc ban đầu |
| CT | turn_accel_std_degps2, initial_turn_std_degps | Nhiễu gia tốc quay và covariance tốc độ quay |
| IMM | imm_cv_accel_std, imm_ca_jerk_std, imm_ct_accel_std, imm_stay_probability | Bank CV/CA/CT native và xác suất chuyển mô hình |
| Mọi phép đo | measurement_variance_scale | Nhân R của bản sao phép đo; không sửa dữ liệu lưu |
| Gating | assignment_threshold, coarse_gate_multiplier | Ngưỡng ghép và ngưỡng sơ bộ trong factory gốc |
| GNN History / JPDA History | confirmation_history, deletion_history | Ngưỡng [M,N] của quản lý track |
| GNN Score | score_confirmation, score_deletion | Ngưỡng score, khác với cặp lịch sử |
| JPDA Integrated | existence_confirmation, existence_deletion | Ngưỡng xác suất tồn tại; birth/death có vai trò |
| JPDA | jpda_max_events | Giới hạn số sự kiện liên kết |
| TOMHT | tomht_max_hypotheses, tomht_max_branches, tomht_history_scans, tomht_confirmation, tomht_deletion | Quản lý giả thuyết/nhánh và ngưỡng track |
| PHD | phd_max_components, phd_extraction, phd_confirmation, phd_deletion_threshold, phd_merging_threshold, phd_birth_assignment_threshold | Quản lý phân bố/component và trích xuất track |
| Prior | pd_assumed, clutter_expected_per_update, clutter_density_scale, birth_rate_per_second, phd_death_rate | Giả định đầu vào tracker; không dùng nhãn truth để ước lượng |
| Tài nguyên | max_tracks, max_run_seconds, max_scan_seconds | Giới hạn track và thời gian mềm; kết quả không hoàn tất không được chấm điểm |
| Đánh giá | metric_cutoff_m | Cutoff cho metric native |

Q không phải một số vạn năng: factory gốc tạo ma trận ProcessNoise theo CV/CA/CT. R trong nhánh mới là covariance Cartesian ENU đầy đủ. Không so trực tiếp số thô của hai loại ma trận mà bỏ qua thứ tự state, đơn vị và mô hình.

## Cấu trúc phần mới và mối nối với project cũ

| Tệp | Chứa gì / khi nào đọc |
|---|---|
| START_NATIVE_LAB.m | Entry point thêm đường dẫn và mở app |
| NATIVE_LAB_CHECK.m | Bảng API presence; không thử execution/license |
| NATIVE_LAB_TESTS.m | Chạy MATLAB unit tests core hoặc all |
| native_lab/nl_app.m | Cửa sổ cấu hình, sự kiện chỉnh/kéo, chạy/phát lại, lưu/mở |
| native_lab/nl_defaults.m | Cấu hình mới lấy waypoint/radar/tracker/DEM gốc làm nền |
| native_lab/nl_validate.m | Kiểm tra miền, thời gian, xác suất, tên và schema |
| native_lab/nl_fields.m | Nhãn, đơn vị và mapping thông số UI → API |
| native_lab/nl_value.m | Đọc ô nhập an toàn bằng JSON literal; không eval |
| native_lab/nl_terrain.m | Đọc đúng GeoTIFF, NoData, tạo bề mặt ENU |
| native_lab/nl_ground.m | Tọa độ địa lý, cao độ và AGL tại điểm |
| native_lab/nl_set_agl.m | Chỉnh AGL, giữ vị trí địa lý ngang |
| native_lab/nl_los.m | Mapping los2, mốc cao độ và bán kính hiệu dụng |
| native_lab/nl_viewshed.m | Mapping viewshed cho AGL mục tiêu đã chọn |
| native_lab/nl_rebase.m | Đổi mốc ENU, bảo toàn các điểm địa lý và hướng radar |
| native_lab/nl_preview.m | Native waypointTrajectory, kiểm tra speed/AGL/bounds |
| native_lab/nl_radar.m | radarDataGenerator và rcsSignature/profile trong radarScenario |
| native_lab/nl_simulate.m | Một đồng hồ uavScenario; đọc platform → radar → objectDetection ENU |
| native_lab/nl_track.m | Gọi make_tracker / track_positions gốc và metric native |
| native_lab/nl_signature.m | Phân biệt thay sensor/scenario với thay tracker/IQ |
| native_lab/nl_export.m | MAT, CSV, cấu hình, script; thư mục mới mỗi lượt |
| native_lab/nl_import_csv.m | Schema phép đo ENU một sensor và lịch lượt đo |
| native_lab/nl_commands.m | Sinh script cấu hình đầy đủ để học/chạy lại |
| native_lab/nl_iq.m | Bài tín hiệu clutter/LFM/CFAR/ULA riêng |
| native_lab/nl_preset.m | Sáu cấu hình xuất phát, chưa có kết quả giả tạo sẵn |
| native_lab/nl_lessons.m | Đọc bài học tiếng Việt |
| native_lab/nl_root.m | Tìm thư mục gốc theo vị trí mã |
| native_lab/lessons/lessons_vi.json | Nội dung từng bước xuất hiện trong tab Bài học |
| native_lab/tests/test_native_lab.m | Các kiểm thử thực thi, gồm frame/covariance/AGL/native trackers |

Đọc `BAN_DO_PROJECT_TRUOC_NHANH_NATIVE.html` trong cùng thư mục docs để tra toàn bộ 185 tệp trước khi thêm nhánh này. Danh mục đó là ảnh chụp cấu trúc trước nhánh native; bảng trên và manifest đi kèm mô tả phần bổ sung. Luồng run_mixed/run_full/view_dataset gốc vẫn dùng schema dữ liệu và cách đánh giá của nó. Tệp native_session.mat không được đưa thẳng vào run_mixed như một bộ MAT 20 cột cũ; nhánh mới không xuất chuyển đổi làm mất covariance một cách im lặng.

## Đọc lỗi và kiểm chứng trên máy bạn

Nếu NATIVE_LAB_CHECK báo false ở một API core, chạy `which tên_hàm -all` và `ver` trong MATLAB để xem đường dẫn/cài đặt. Không lấy một chữ true để bỏ qua lỗi license, sai property hoặc lỗi thực thi.

Nếu app báo sai thời gian waypoint, sửa thời điểm tăng dần, điểm đầu 0 và điểm cuối khớp tổng thời gian. Nếu báo vượt tốc độ, tăng tổng thời gian ở tab Phiên hoặc giảm quãng đường. Nếu báo dưới địa hình, sửa cột AGL/chiều cao anten. Nếu báo ngoài DEM, chọn vị trí trong vùng dữ liệu hoặc nhập DEM/mốc phù hợp. Nếu native tracker báo lỗi, xem thông báo đầy đủ trong `results/native_errors`, không sửa bỏ assert rồi coi là đã chạy đúng.

Các bài IQ là optional; core không cần normfit, design, Simulink hoặc MATLAB Coder. Core tests không chạy IQ; chế độ all có chạy IQ. Kết quả kiểm thử của môi trường xây gói nằm trong `BUILD_VERIFICATION.md`; kết quả bạn chạy sau giải nén nằm trong `results/native_tests`.

## Nguồn API đã đối chiếu

Đối chiếu ưu tiên phần help/mã API công khai trong bản MATLAB R2025a cài trên máy xây gói. Các trang online có thể đã chuyển sang release mới hơn; không suy từ đó rằng một tính năng mới cũng có trong R2025a.

- [radarDataGenerator](https://www.mathworks.com/help/radar/ref/radardatagenerator-system-object.html)
- [Radar Toolbox Reference R2025a](https://www.mathworks.com/help/releases/r2025a/pdf_doc/radar/radar_ref.pdf)
- [UAV Scenario Designer](https://www.mathworks.com/help/uav/ref/uavscenariodesigner-app.html)
- [uavPlatform](https://www.mathworks.com/help/uav/ref/uavplatform.html)
- [radarDesigner](https://www.mathworks.com/help/radar/ref/radardesigner-app.html)
- [Mapping los2](https://www.mathworks.com/help/map/ref/los2.html)
- [Mapping viewshed](https://www.mathworks.com/help/map/ref/viewshed.html)
- [trackGOSPAMetric](https://www.mathworks.com/help/fusion/ref/trackgospametric-system-object.html)
- [constantGammaClutter](https://www.mathworks.com/help/radar/ref/constantgammaclutter-system-object.html)

Đây là phần mở rộng phục vụ học và kiểm chứng mô hình trên nền project gốc; không phải cấu hình đã hiệu chuẩn với radar hay UAV thật chưa được cung cấp dữ liệu.


RC2: xem native_lab/docs/RC2_FIXES.md (hoặc RC2_FIXES.md cùng thư mục docs) để đọc các sửa đổi và bằng chứng runtime RC1.
