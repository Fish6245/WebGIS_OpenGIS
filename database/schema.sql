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
-- Chú ý: Thay thế '/path/to/your/project/' thành đường dẫn thực tế trên máy
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
    REGEXP_REPLACE(TRIM(COALESCE(t20.tenduong, t15.tenduong)), '\s+', ' ', 'g') AS ten_duong,
    REGEXP_REPLACE(TRIM(COALESCE(t20.phuong, t15.phuong)), '\s+', ' ', 'g') AS phuong,
    REGEXP_REPLACE(TRIM(COALESCE(t20.quanhuyen, t15.quanhuyen)), '\s+', ' ', 'g') AS quan_huyen,
    REGEXP_REPLACE(TRIM(COALESCE(t20.tudiem, t15.tudiem)), '\s+', ' ', 'g') AS tu_diem,
    REGEXP_REPLACE(TRIM(COALESCE(t20.dendiem, t15.dendiem)), '\s+', ' ', 'g') AS den_diem,
    COALESCE(t15.gia, 0) AS gia_2015_2019,
    COALESCE(t20.gia, 0) AS gia_2020_2025,
    NULL::geometry AS geom
FROM tmp_gia_2020_2025 t20
FULL OUTER JOIN tmp_gia_2015_2019 t15 
    ON REGEXP_REPLACE(LOWER(TRIM(t20.tenduong)), '\s+', ' ', 'g') = REGEXP_REPLACE(LOWER(TRIM(t15.tenduong)), '\s+', ' ', 'g') 
    AND REGEXP_REPLACE(LOWER(TRIM(t20.quanhuyen)), '\s+', ' ', 'g') = REGEXP_REPLACE(LOWER(TRIM(t15.quanhuyen)), '\s+', ' ', 'g')
    AND REGEXP_REPLACE(LOWER(TRIM(t20.phuong)), '\s+', ' ', 'g') = REGEXP_REPLACE(LOWER(TRIM(t15.phuong)), '\s+', ' ', 'g');

-- -------------------------------------------------------------------------
-- [DỪNG LẠI TẠI ĐÂY ĐỂ MỞ TOOL POSTGIS SHAPEFILE MANAGER ĐỂ IMPORT BẢN ĐỒ]
-- Sau khi Import thành công bản đồ, thực thi tiếp các bước bên dưới
-- -------------------------------------------------------------------------

-- -------------------------------------------------------------------------
-- BƯỚC 6: CHUẨN HÓA TRƯỚC TÊN ĐƯỜNG TRONG BẢNG CHÍNH ĐỂ TĂNG TỐC TRUY VẤN
-- (Mẹo giúp máy không phải xử lý hàm lúc đang UPDATE)
-- -------------------------------------------------------------------------
UPDATE gia_dat_tuyen_duong 
SET ten_duong = REGEXP_REPLACE(LOWER(TRIM(ten_duong)), '\s+', ' ', 'g');

-- -------------------------------------------------------------------------
-- BƯỚC 7: TẠO CHỈ MỤC (INDEX) TỐI ƯU HÓA TỐC ĐỘ TÌM KIẾM CHO CẢ 2 BẢNG
-- -------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_gia_dat_clean_tenduong ON gia_dat_tuyen_duong (ten_duong);
CREATE INDEX IF NOT EXISTS idx_tmp_road_clean_tenjoin ON tmp_road_shape (REGEXP_REPLACE(LOWER(TRIM(tenjoin)), '\s+', ' ', 'g'));
CREATE INDEX IF NOT EXISTS idx_tmp_road_clean_name ON tmp_road_shape (REGEXP_REPLACE(LOWER(TRIM(name)), '\s+', ' ', 'g'));

-- -------------------------------------------------------------------------
-- BƯỚC 8: ÁNH XẠ, ĐỒNG BỘ TỌA ĐỘ BẢN ĐỒ (BẢN SIÊU TỐC - CHẠY TRONG 1 GIÂY)
-- -------------------------------------------------------------------------
UPDATE gia_dat_tuyen_duong g
SET geom = s.geom
FROM tmp_road_shape s
WHERE g.ten_duong = REGEXP_REPLACE(LOWER(TRIM(s.tenjoin)), '\s+', ' ', 'g')
   OR g.ten_duong = REGEXP_REPLACE(LOWER(TRIM(s.name)), '\s+', ' ', 'g');

-- -------------------------------------------------------------------------
-- BƯỚC 9: TẠO CỔNG KẾ XUẤT VIEW API GEOJSON CHO PHẦN LẬP TRÌNH WEB
-- -------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_api_ban_do_gia_dat AS
SELECT 
    id, ten_duong, phuong, quan_huyen, tu_diem, den_diem, gia_2015_2019, gia_2020_2025,
    CASE 
        WHEN gia_2015_2019 = 0 OR gia_2020_2025 = 0 THEN 0
        ELSE ROUND(((gia_2020_2025 - gia_2015_2019) / gia_2015_2019) * 100, 2)
    END AS phan_tram_tang_truong,
    geom,
    ST_AsGeoJSON(geom)::json AS geojson_geometry
FROM gia_dat_tuyen_duong;

-- -------------------------------------------------------------------------
-- BƯỚC 10: TẠO HÀM TRA CỨU KHÔNG GIAN KHI CLICK CHUỘT LÊN BẢN ĐỒ WEBGIS
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
    WHERE ST_DWithin(g.geom::geography, ST_SetSRID(ST_Point(p_lon, p_lat), 4326)::geography, 20)
    ORDER BY g.geom <-> ST_SetSRID(ST_Point(p_lon, p_lat), 4326)
    LIMIT 1;
END;
$$;
