
## 📁 1. Cấu Trúc Tài Nguyên Dự Án

Thư mục mã nguồn được tổ chức theo quy chuẩn quản lý mã nguồn Git:
* 📁 **`database/`**: Chứa tệp nguồn duy nhất `schema.sql` khởi tạo toàn bộ cấu trúc cơ sở dữ liệu, các thuật toán đồng bộ và xử lý API ngầm.
* 📁 **`data/`**: Chứa kho lưu trữ dữ liệu thô phục vụ cài đặt ban đầu:
    * `GiaDat2015_2019.csv`: Dữ liệu thuộc tính bảng giá đất giai đoạn 1.
    * `GiaDat2020_2025.csv`: Dữ liệu thuộc tính bảng giá đất giai đoạn 2.
    * `shapefile_bando.zip`: Tệp nén không gian chứa các lớp bản đồ hình học dạng tuyến (LineString/MultiLineString).

---

## 🚀 2. Hướng Dẫn Cài Đặt & Cấu Hình Cơ Sở Dữ Liệu

Do đặc thù cơ chế phân quyền bảo mật của hệ điều hành Windows đối với tiến trình chạy ngầm của PostgreSQL, quy trình thiết lập Database bắt buộc phải tuân thủ theo **3 đợt thao tác** thứ tự như sau:

### 🔹 Đợt 1: Khởi tạo khung sườn hệ thống (pgAdmin)
1. Kết nối vào Server PostgreSQL của bạn, tạo một cơ sở dữ liệu mới dễ nhớ (vd:`map_db`).
2. Chuột phải vào cơ sở dữ liệu đó (vd:`map_db`) chọn **Query Tool**.
3. Mở file `database/schema.sql`, bôi đen và thực thi (**Execute/Play**) từ **BƯỚC 1 đến BƯỚC 3** để kích hoạt extension `postgis`, tạo bảng chính và cấu trúc các bảng tạm (`tmp_gia_2015_2019`, `tmp_gia_2020_2025`).

### 🔹 Đợt 2: Nạp và Chuẩn hóa dữ liệu thuộc tính (CSV)
1. Bản chất lệnh `COPY` trong lõi PostgreSQL yêu cầu đường dẫn tuyệt đối sạch. Thực hiện chạy khối lệnh ở **BƯỚC 4** trong file `schema.sql`.
> *Lưu ý kỹ thuật:* Đảm bảo đường dẫn tệp CSV trong đoạn code `FROM '-/-/data/...'` trỏ chính xác đến vị trí lưu trữ trên máy của bạn và không chứa ký tự ẩn của Windows Explorer. Nếu dính lỗi phân quyền, cấp quyền truy cập `Everyone` cho thư mục chứa file.
2. Chạy tiếp lệnh gộp ở BƯỚC 5. Hệ thống sử dụng hàm `FULL OUTER JOIN` kết hợp biểu thức chính quy `REGEXP_REPLACE` để tự động dọn dẹp khoảng trắng thừa ở đầu, cuối và cả ở giữa chữ. Dữ liệu sẽ được so khớp theo 3 điều kiện: Tên đường, Quận huyện, Phường xã, đảm bảo tính toán phần trăm tăng trưởng không bị lỗi.

### 🔹 Đợt 3: Đồng bộ thực thể không gian (Shapefile) & Kích hoạt API
1. Khởi động phần mềm **PostGIS Shapefile Import/Export Manager**, kết nối tới database vừa tạo (vd:`map_db`).
2. Giải nén tệp `data/shapefile_bando.zip` dưới máy tính.
3. Trên phần mềm Tool, bấm **Add Shape File** Chọn file `.shp` vừa giải nén.
4. Cấu hình bắt buộc:
   * **SRID**: Điền `4326` (Hệ tọa độ chuẩn quốc tế WGS 84 địa hình phẳng).
   * **Table**: Điền chính xác là `tmp_road_shape`.
   * **Mode**: Chọn `Create`.
5. Bấm **Import** và đợi thông báo thành công.
6. Quay lại Query Tool trên pgAdmin, thực thi toàn bộ các câu lệnh còn lại từ BƯỚC 6 đến BƯỚC 10 (Bản cập nhật siêu tốc):
   * Bước 6 & 7: Làm sạch trước tên đường ở bảng chính và tạo `INDEX` để máy không bị đơ/treo.
   * Bước 8: Chạy lệnh `UPDATE` bắn tọa độ bản đồ sang bảng chính chỉ trong vòng 1 giây.
   * Bước 9 & 10: Biên dịch View API GeoJSON (`v_api_ban_do_gia_dat`) và Hàm click chuột chọn đường (`get_gia_dat_theo_toa_do`).

---
