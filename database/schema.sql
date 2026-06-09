-- BƯỚC 1: Khởi tạo tiện ích không gian PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;


-- BƯỚC 2: Khởi tạo bảng dữ liệu chính thức và các chỉ mục không gian bản đồ
CREATE TABLE IF NOT EXISTS gia_dat_tuyen_duong (
    id SERIAL PRIMARY KEY,
    ten_duong TEXT,
    phuong TEXT,
    quan_huyen TEXT,
    tu_diem TEXT,
    den_diem TEXT,
    gia_2015_2019 NUMERIC,
    gia_2020_2025 NUMERIC,
    geom GEOMETRY(MultiLineString, 4326)
);

CREATE INDEX IF NOT EXISTS idx_gia_dat_tuyen_duong_geom ON gia_dat_tuyen_duong USING GiST (geom);
CREATE INDEX IF NOT EXISTS idx_gia_dat_tuyen_duong_search ON gia_dat_tuyen_duong (quan_huyen, ten_duong);


-- BƯỚC 3: Khởi tạo cấu trúc các bảng tạm để import tệp dữ liệu thô (CSV)
CREATE TABLE IF NOT EXISTS tmp_gia_2015_2019 (
    NamApDung TEXT,
    QuanHuyen TEXT,
    STT INT,
    TenDuong TEXT,
    Phuong TEXT,
    TuDiem TEXT,
    DenDiem TEXT,
    GiaDat2015_2019 NUMERIC
);

CREATE TABLE IF NOT EXISTS tmp_gia_2020_2025 (
    STT INT,
    TenDuong TEXT,
    Phuong TEXT,
    TuDiem TEXT,
    DenDiem TEXT,
    GiaDieuChinh NUMERIC,
    QuanHuyen TEXT
);


-- BƯỚC 4: Chuẩn hóa dữ liệu chuỗi và Gộp dữ liệu giá đất thô từ 2 giai đoạn vào bảng chính
-- (Lưu ý: Chạy lệnh INSERT này sau khi đã thực hiện Import thành công 2 file CSV vào bảng tạm)
INSERT INTO gia_dat_tuyen_duong (
    ten_duong, phuong, quan_huyen, tu_diem, den_diem, gia_2015_2019, gia_2020_2025, geom
)
SELECT 
    TRIM(COALESCE(t20.TenDuong, t15.TenDuong)) AS ten_duong,
    TRIM(COALESCE(t20.Phuong, t15.Phuong)) AS phuong,
    TRIM(COALESCE(t20.QuanHuyen, t15.QuanHuyen)) AS quan_huyen,
    TRIM(COALESCE(t20.TuDiem, t15.TuDiem)) AS tu_diem,
    TRIM(COALESCE(t20.DenDiem, t15.DenDiem)) AS den_diem,
    t15.GiaDat2015_2019 AS gia_2015_2019,
    t20.GiaDieuChinh AS gia_2020_2025,
    NULL::geometry AS geom
FROM tmp_gia_2020_2025 t20
FULL OUTER JOIN tmp_gia_2015_2019 t15 
    ON LOWER(TRIM(t20.TenDuong)) = LOWER(TRIM(t15.TenDuong)) 
    AND LOWER(TRIM(t20.QuanHuyen)) = LOWER(TRIM(t15.QuanHuyen));


-- BƯỚC 5: Tối ưu hiệu năng tìm kiếm chuỗi và Đồng bộ tọa độ không gian từ Shapefile bản đồ đường vào bảng chính
-- (Lưu ý: Chạy lệnh UPDATE này sau khi đã sử dụng tool PostGIS Import file .shp thành bảng độc lập tên `tmp_road_shape`)
CREATE INDEX IF NOT EXISTS idx_tmp_road_lower_tenjoin ON tmp_road_shape (LOWER(TRIM(tenjoin)));
CREATE INDEX IF NOT EXISTS idx_tmp_road_lower_name ON tmp_road_shape (LOWER(TRIM(name)));
CREATE INDEX IF NOT EXISTS idx_gia_dat_lower_tenduong ON gia_dat_tuyen_duong (LOWER(TRIM(ten_duong)));

UPDATE gia_dat_tuyen_duong g
SET geom = s.geom
FROM tmp_road_shape s
WHERE LOWER(TRIM(g.ten_duong)) = LOWER(TRIM(s.tenjoin))
   OR LOWER(TRIM(g.ten_duong)) = LOWER(TRIM(s.name));

DROP TABLE IF EXISTS tmp_road_shape;


-- BƯỚC 6: Tạo cổng kết xuất dữ liệu VIEW cấu trúc API GeoJSON bàn giao cho Frontend/Backend
CREATE OR REPLACE VIEW v_api_ban_do_gia_dat AS
SELECT 
    id, 
    ten_duong, 
    phuong, 
    quan_huyen, 
    tu_diem, 
    den_diem, 
    gia_2015_2019, 
    gia_2020_2025,
    CASE 
        WHEN gia_2015_2019 > 0 THEN ROUND(((gia_2020_2025 - gia_2015_2019) / gia_2015_2019) * 100, 2)
        ELSE 0 
    END AS phan_tram_tang_truong,
    ST_AsGeoJSON(geom)::json AS geojson_geometry
FROM gia_dat_tuyen_duong;


-- BƯỚC 7: STORED PROCEDURE TRA CỨU GIÁ ĐẤT THEO TỌA ĐỘ CLICK TRÊN BẢN ĐỒ
-- Hàm nhận vào: Kinh độ (p_lon), Vĩ độ (p_lat) -> Trả về con đường gần nhất trong bán kính 20 mét
CREATE OR REPLACE FUNCTION get_gia_dat_theo_toa_do(
    p_lon DOUBLE PRECISION,
    p_lat DOUBLE PRECISION
)
RETURNS TABLE(
    ten_duong TEXT, 
    phuong TEXT, 
    quan_huyen TEXT, 
    gia_2015_2019 NUMERIC, 
    gia_2020_2025 NUMERIC, 
    khoang_cach_met DOUBLE PRECISION
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.ten_duong::TEXT, 
        g.phuong::TEXT, 
        g.quan_huyen::TEXT, 
        g.gia_2015_2019, 
        g.gia_2020_2025,
        ST_Distance(g.geom::geography, ST_SetSRID(ST_Point(p_lon, p_lat), 4326)::geography) AS khoang_cach_met
    FROM gia_dat_tuyen_duong g
    WHERE ST_DWithin(g.geom::geography, ST_SetSRID(ST_Point(p_lon, p_lat), 4326)::geography, 20)
    ORDER BY g.geom <-> ST_SetSRID(ST_Point(p_lon, p_lat), 4326)
    LIMIT 1;
END;
$$;