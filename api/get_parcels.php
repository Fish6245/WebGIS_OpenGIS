<?php
require_once '../config/db.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// 1. LẤY THAM SỐ PHÂN TRANG
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 5000; //  mặc định thành 5000 tuyến đường/trang
if ($page < 1) $page = 1;
if ($limit < 1 || $limit > 10000) $limit = 5000; //  giới hạn tối đa lên 10000 để 5000 có thể lọt qua
$offset = ($page - 1) * $limit;


// 2. TỐI ƯU NGÀY 6: CẤU HÌNH FILE CACHING
$cache_dir = '../cache/';
if (!is_dir($cache_dir)) {
    mkdir($cache_dir, 0777, true); // Tự động tạo thư mục cache nếu chưa có
}
// Tạo tên file cache riêng biệt cho từng trang để tránh trùng lặp dữ liệu
$cache_file = $cache_dir . "parcels_page_{$page}_limit_{$limit}.json";
$cache_time = 3600; // Thời gian lưu cache: 1 tiếng (3600 giây)

// Kiểm tra xem file cache đã tồn tại và còn hạn sử dụng hay không
if (file_exists($cache_file) && (time() - filemtime($cache_file) < $cache_time)) {
    header('X-Cache: HIT'); // Đánh dấu phản hồi được lấy từ bộ nhớ đệm Cache
    echo file_get_contents($cache_file);
    exit;
}

header('X-Cache: MISS'); // Đánh dấu phản hồi real-time từ Database khi chưa có cache

try {
    // 3. TRUY VẤN DỮ LIỆU CÓ PHÂN TRANG
    $sql = "SELECT osm_id, name, ST_AsGeoJSON(geom) as geojson 
            FROM bando_chuan 
            LIMIT :limit OFFSET :offset";
            
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    
    $features = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $geometry = json_decode($row['geojson']);
        $features[] = [
            'type' => 'Feature',
            'geometry' => $geometry,
            'properties' => [
                'osm_id' => $row['osm_id'],
                'name' => $row['name'] ? $row['name'] : 'Đường không tên'
            ]
        ];
    }

    $geojson = [
        'type' => 'FeatureCollection',
        'page' => $page,
        'limit' => $limit,
        'features' => $features
    ];

    $response_data = json_encode($geojson);
    
    // 4. GHI KẾT QUẢ VÀO FILE CACHE CHO LẦN GỌI TIẾP THEO
    file_put_contents($cache_file, $response_data);

    echo $response_data;

} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Lỗi kết nối dữ liệu: ' . $e->getMessage()
    ]);
}
?>
