<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bản đồ WebGIS - Quản lý Đường bộ</title>
    
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    
    <style>
        /* Cấu hình bản đồ tràn toàn màn hình */
        html, body {
            margin: 0;
            padding: 0;
            height: 100%;
            width: 100%;
        }
        #map {
            width: 100%;
            height: 100vh;
        }
        /* Định dạng bong bóng thông tin khi click */
        .popup-custom {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            font-size: 14px;
            line-height: 1.5;
        }
    </style>
</head>
<body>

    <div id="map"></div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    
    <script>
        // 3. Khởi tạo bản đồ, đặt vị trí mặc định ban đầu ở TP.HCM
        var map = L.map('map').setView([10.762622, 106.660172], 13);

        // 4. Thêm lớp bản đồ nền OpenStreetMap (Bản đồ đường phố thế giới)
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);

        // 5. Dùng Fetch API gọi tới file PHP lấy dữ liệu JSON bạn vừa chạy thành công lúc nãy
        fetch('api/get_parcels.php')
            .then(response => response.json())
            .then(geoJsonData => {
                
                // 6. Đưa dữ liệu không gian lên bản đồ và tạo hiệu ứng vẽ đường
                var vectorLayer = L.geoJSON(geoJsonData, {
                    style: function (feature) {
                        return {
                            color: "#ff4d4d", // Đường viền màu đỏ nổi bật
                            weight: 4,        // Độ dày của nét vẽ tuyến đường
                            opacity: 0.85
                        };
                    },
                    // 7. Tạo sự kiện khi click vào từng tuyến đường sẽ hiện thông tin
                    onEachFeature: function (feature, layer) {
                        var roadName = feature.properties.name ? feature.properties.name : "Đường chưa đặt tên";
                        var osmId = feature.properties.osm_id ? feature.properties.osm_id : "N/A";
                        
                        var popupContent = `
                            <div class="popup-custom">
                                <h4 style="margin: 0 0 5px 0; color: #ff4d4d;">📍 Thông tin Tuyến đường</h4>
                                <b>Tên đường:</b> ${roadName}<br>
                                <b>Mã OSM ID:</b> ${osmId}
                            </div>
                        `;
                        layer.bindPopup(popupContent);
                    }
                }).addTo(map);

                // 8. Tự động zoom và di chuyển bản đồ đến đúng vùng có dữ liệu Shapefile của bạn
                if (geoJsonData.length > 0 || (geoJsonData.features && geoJsonData.features.length > 0)) {
                    map.fitBounds(vectorLayer.getBounds());
                }

            })
            .catch(error => {
                console.error("Lỗi khi kết nối API lấy dữ liệu:", error);
                alert("Không thể tải dữ liệu không gian lên bản đồ!");
            });
    </script>
</body>
</html>