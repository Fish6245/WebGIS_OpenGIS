# HUONG DAN KHOI DONG HE THONG BAN DO GIA DAT TPHCM

## Yeu cau
- Windows 10/11
- Docker Desktop da cai dat va dang chay
- Git da cai dat

## Buoc 1: Lay code moi nhat
cd "C:\Users\Tam Nhu\land-price-map"
git pull origin main

## Buoc 2: Khoi dong he thong
docker compose up -d

## Buoc 3: Cho he thong san sang (khoang 30 giay)
Cho den khi thay 4 container Started/Healthy

## Buoc 4: Kiem tra he thong
powershell -ExecutionPolicy Bypass -File scripts/monitor.ps1

## Cac duong dan truy cap
- Backend API:  http://localhost:3000
- GeoServer:    http://localhost:8080/geoserver/web (admin/geoserver)
- Nginx:        http://localhost/health

## Tat he thong sau khi demo
docker compose down

## Luu y
- Phai mo Docker Desktop truoc khi chay docker compose
- GeoServer khoi dong cham (~2-3 phut), doi icon xanh
- Du lieu gia dat: 3,288 dong (2015-2019) va 4,192 dong (2020-2025)
