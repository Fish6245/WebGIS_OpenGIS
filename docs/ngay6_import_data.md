# Nhat ky Ngay 6 - Import du lieu vao PostgreSQL

## Cong viec da hoan thanh
- Import schema database tu file database/schema.sql
- Import du lieu gia dat 2015-2019: 3,288 dong
- Import du lieu gia dat 2020-2025: 4,192 dong
- Tong cong: 7,480 dong du lieu gia dat TPHCM

## Cac bang da tao
- tmp_gia_2015_2019
- tmp_gia_2020_2025
- gia_dat_tuyen_duong
- spatial_ref_sys

## Lenh kiem tra du lieu
docker exec -it landprice_db psql -U landuser -d landprice -c "SELECT COUNT(*) FROM tmp_gia_2015_2019;"
docker exec -it landprice_db psql -U landuser -d landprice -c "SELECT COUNT(*) FROM tmp_gia_2020_2025;"
