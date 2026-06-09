# Script kiem tra trang thai he thong
Write-Host "=== KIEM TRA HE THONG LAND PRICE MAP ===" -ForegroundColor Cyan

# Kiem tra cac container
Write-Host "
TRANG THAI CONTAINER:" -ForegroundColor Yellow
docker compose ps

# Kiem tra PostgreSQL
Write-Host "
KIEM TRA POSTGRESQL:" -ForegroundColor Yellow
docker exec landprice_db psql -U landuser -d landprice -c "SELECT version();"
if ($LASTEXITCODE -eq 0) {
    Write-Host "PostgreSQL: OK" -ForegroundColor Green
} else {
    Write-Host "PostgreSQL: LOI" -ForegroundColor Red
}

# Kiem tra Backend API
Write-Host "
KIEM TRA BACKEND API:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
    Write-Host "Backend API: OK (Status $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "Backend API: LOI" -ForegroundColor Red
}

# Kiem tra GeoServer
Write-Host "
KIEM TRA GEOSERVER:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/geoserver/web" -TimeoutSec 5
    Write-Host "GeoServer: OK (Status $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "GeoServer: LOI" -ForegroundColor Red
}

Write-Host "
=== XONG ===" -ForegroundColor Cyan
