# Script khoi dong he thong Land Price Map
Write-Host "Khoi dong he thong Land Price Map..." -ForegroundColor Green

# Kiem tra Docker dang chay
 = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if (-not ) {
    Write-Host "Docker Desktop chua chay! Mo Docker Desktop truoc." -ForegroundColor Red
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "Cho Docker khoi dong (30 giay)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# Khoi dong cac container
Write-Host "Khoi dong PostgreSQL + GeoServer + Backend..." -ForegroundColor Yellow
docker compose up -d

# Cho PostgreSQL san sang
Write-Host "Cho PostgreSQL san sang..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Kiem tra trang thai
Write-Host "Trang thai cac container:" -ForegroundColor Green
docker compose ps

Write-Host "Xong! He thong dang chay." -ForegroundColor Green
Write-Host "GeoServer: http://localhost:8080/geoserver/web" -ForegroundColor Cyan
Write-Host "Backend API: http://localhost:3000" -ForegroundColor Cyan
