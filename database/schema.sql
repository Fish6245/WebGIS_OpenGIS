-- -------------------------------------------------------------------------
-- BƯỚC 1: KÍCH HOẠT TIỆN ÍCH MỞ RỘNG POSTGIS 
-- -------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis;

-- -------------------------------------------------------------------------
-- BƯỚC 2: TẠO CÁC BẢNG TẠM NHẬP LIỆU 
-- -------------------------------------------------------------------------
-- Bảng tạm cho giai đoạn 2015 - 2019
CREATE TABLE tmp_gia_2015_2019 (
    namapdung TEXT,
    stt INT,
    tenduong TEXT,
    tudiem TEXT,
    dendiem TEXT,
    phuong TEXT,
    quanhuyen TEXT,
    gia NUMERIC
);

-- Bảng tạm cho giai đoạn 2020 - 2025
CREATE TABLE tmp_gia_2020_2025 (
    namapdung TEXT,
    stt INT,
    tenduong TEXT,
    tudiem TEXT,
    dendiem TEXT,
    phuong TEXT,
    quanhuyen TEXT,
    gia NUMERIC
);

-- -------------------------------------------------------------------------
-- BƯỚC 3: TẠO BẢNG ĐÍCH CHÍNH THỨC 
-- -------------------------------------------------------------------------
CREATE TABLE gia_dat_tuyen_duong (
    id SERIAL PRIMARY KEY,
    ten_duong TEXT,
    phuong TEXT,
    quan_huyen TEXT,
    tu_diem TEXT,
    den_diem TEXT,
    gia_2015_2019 NUMERIC DEFAULT 0,
    gia_2020_2025 NUMERIC DEFAULT 0,
    geom geometry(MultiLineString, 4326) 
);

-- -------------------------------------------------------------------------
-- BƯỚC 4: LỆNH NẠP FILE CSV VÀO BẢNG TẠM 
-- Lưu ý: Hãy thay đổi đường dẫn '/path/to/your/project/...' bên dưới 
-- thành đường dẫn thực tế đến thư mục chứa file CSV trên máy tính của bạn.
-- -------------------------------------------------------------------------
COPY tmp_gia_2015_2019(namapdung, stt, tenduong, tudiem, dendiem, phuong, quanhuyen, gia) 
FROM '/path/to/your/project/data/GiaDat2015_2019.csv' 
WITH (FORMAT csv, DELIMITER ',', HEADER, QUOTE '"');

COPY tmp_gia_2020_2025(namapdung, stt, tenduong, tudiem, dendiem, phuong, quanhuyen, gia) 
FROM '/path/to/your/project/data/GiaDat2020_2025.csv' 
WITH (FORMAT csv, DELIMITER ',', HEADER, QUOTE '"');

-- -------------------------------------------------------------------------
-- BƯỚC 5: XỬ LÝ KHỬ TRÙNG CHUỖI, GỘP DỮ LIỆU VÀO BẢNG CHÍNH THỨC
-- Sử dụng FULL OUTER JOIN để tránh mất dữ liệu nếu đường chỉ xuất hiện ở 1 trong 2 file
-- -------------------------------------------------------------------------
INSERT INTO gia_dat_tuyen_duong (
    ten_duong, phuong, quan_huyen, tu_diem, den_diem, gia_2015_2019, gia_2020_2025, geom
)
SELECT 
    TRIM(COALESCE(t20.tenduong, t15.tenduong)) AS ten_duong,
    TRIM(COALESCE(t20.phuong, t15.phuong)) AS phuong,
    TRIM(COALESCE(t20.quanhuyen, t15.quanhuyen)) AS quan_huyen,
    TRIM(COALESCE(t20.tudiem, t15.tudiem)) AS tu_diem,
    TRIM(COALESCE(t20.dendiem, t15.dendiem)) AS den_diem,
    COALESCE(t15.gia, 0) AS gia_2015_2019,
    COALESCE(t20.gia, 0) AS gia_2020_2025,
    NULL::geometry AS geom
FROM tmp_gia_2020_2025 t20
FULL OUTER JOIN tmp_gia_2015_2019 t15 
    ON LOWER(TRIM(t20.tenduong)) = LOWER(TRIM(t15.tenduong)) 
    AND LOWER(TRIM(t20.quanhuyen)) = LOWER(TRIM(t15.quanhuyen))
    AND LOWER(TRIM(t20.phuong)) = LOWER(TRIM(t15.phuong));

-- -------------------------------------------------------------------------
-- [DỪNG LẠI TẠI ĐÂY ĐỂ MỞ TOOL POSTGIS SHAPEFILE MANAGER ĐỂ IMPORT BẢN ĐỒ]
-- Thêm file .shp vào, đặt tên bảng là 'tmp_road_shape', chọn SRID '4326', Mode 'Create'
-- Sau khi Import thành công, chạy tiếp các bước bên dưới:
-- -------------------------------------------------------------------------

-- -------------------------------------------------------------------------
-- BƯỚC 6: TẠO CHỈ MỤC TỐI ƯU HÓA TỐC ĐỘ SO KHỚP CHUỖI KHÔNG GIAN
-- -------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_tmp_road_lower_tenjoin ON tmp_road_shape (LOWER(TRIM(tenjoin)));
CREATE INDEX IF NOT EXISTS idx_tmp_road_lower_name ON tmp_road_shape (LOWER(TRIM(name)));
CREATE INDEX IF NOT EXISTS idx_gia_dat_lower_tenduong ON gia_dat_tuyen_duong (LOWER(TRIM(ten_duong)));

-- -------------------------------------------------------------------------
-- BƯỚC 7: ÁNH XẠ, ĐỒNG BỘ TỌA ĐỘ TỪ BẢNG SHAPEFILE SANG BẢNG CHÍNH
-- -------------------------------------------------------------------------
UPDATE gia_dat_tuyen_duong g
SET geom = s.geom
FROM tmp_road_shape s
WHERE LOWER(TRIM(g.ten_duong)) = LOWER(TRIM(s.tenjoin))
   OR LOWER(TRIM(g.ten_duong)) = LOWER(TRIM(s.name));

-- Xóa bảng tạm hình học sau khi đồng bộ xong để dọn dẹp hệ thống
DROP TABLE IF EXISTS tmp_road_shape;

-- -------------------------------------------------------------------------
-- BƯỚC 8: TẠO CỔNG KẾ XUẤT VIEW API GEOJSON CHO PHẦN LẬP TRÌNH WEB
-- -------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_api_ban_do_gia_dat AS
SELECT 
    id, ten_duong, phuong, quan_huyen, tu_diem, den_diem, gia_2015_2019, gia_2020_2025,
    CASE 
        WHEN gia_2015_2019 > 0 THEN ROUND(((gia_2020_2025 - gia_2015_2019) / gia_2015_2019) * 100, 2)
        ELSE 0 
    END AS phan_tram_tang_truong,
    ST_AsGeoJSON(geom)::json AS geojson_geometry
FROM gia_dat_tuyen_duong;

-- -------------------------------------------------------------------------
-- BƯỚC 9: TẠO HÀM TRA CỨU KHÔNG GIAN KHI CLICK CHUỘT LÊN BẢN ĐỒ WEBGIS
-- Sử dụng GiST Spatial Index ngầm định cùng toán tử KNN <-> tối ưu 
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_gia_dat_theo_toa_do(
    p_lon DOUBLE PRECISION,
    p_lat DOUBLE PRECISION
)
RETURNS TABLE(
    ten_duong TEXT, phuong TEXT, quan_huyen TEXT, gia_2015_2019 NUMERIC, gia_2020_2025 NUMERIC, khoang_cach_met DOUBLE PRECISION
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.ten_duong::TEXT, g.phuong::TEXT, g.quan_huyen::TEXT, g.gia_2015_2019, g.gia_2020_2025,
        ST_Distance(g.geom::geography, ST_SetSRID(ST_Point(p_lon, p_lat), 4326)::geography) AS khoang_cach_met
    FROM gia_dat_tuyen_duong g
    WHERE ST_DWithin(g.geom::geography, ST_SetSRID(ST_Point(p_lon, p_lat), 4326)::geography, 20) -- Phạm vi tìm kiếm 20 mét xung quanh điểm click
    ORDER BY g.geom <-> ST_SetSRID(ST_Point(p_lon, p_lat), 4326)
    LIMIT 1;
END;
$$;
