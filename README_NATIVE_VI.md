# Native Lab RC5.1 · RX-R417C

Mô phỏng bốn mặt quét điện tử, nền OSM offline và giãn trục độ cao 3D.

Đọc [hướng dẫn RC5](native_lab/docs/RX_R417C_RC5.html). Sổ tay nền: [RC4 V2](native_lab/docs/WORKFLOW_RC4.html).

Native Interactive Lab RC5.1 - RX-R417C | MATLAB R2025a

1. Giai nen FULL_RC5 vao thu muc moi. Current Folder: thu muc co START_NATIVE_LAB.m.
2. Chay NATIVE_LAB_CHECK, sau do NATIVE_LAB_TESTS('rx').
3. Chay START_NATIVE_LAB. Mac dinh preset 07: bon mat quet dien tu.
4. Huong dan moi: native_lab/docs/RX_R417C_RC5.html (tab Radar).
5. OSM bat san; chon 2D/3D va Ty le cao do: Auto.
6. Tao dataset / Mo phong + bam: luu cau hinh, du lieu, scan_state.csv va ket qua.

Mo hinh thu nghiem theo datasheet, khong dieu khien thiet bi that.
Cac gia dinh chua du thong so hang duoc ghi ro trong huong dan.
MATLAB runtime chua xac minh do loi khoi dong File system inconsistency tai moi truong dong goi.
Xem native_lab/docs/RC5_STATIC_VERIFICATION.json de phan biet kiem tra tinh va runtime.
Kiem thu them: NATIVE_LAB_TESTS('core'), ('workflow'), ('tracking'), ('all').
Thu muc luu mac dinh: results/native_workspace/datasets va runs.
150 tep ZIP goc va 80 dataset goc giu nguyen. Khong can Python de chay project.
