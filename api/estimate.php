<?php
require_once '../config/db.php'; // Đường dẫn thư mục ngang hàng
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Cho phép Frontend gọi API không bị lỗi CORS

// Kiểm tra xem Frontend có truyền mã ID của ô đất/tuyến đường lên không
if (!isset($_GET['osm_id'])) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Thiếu tham số osm_id để dự toán giá!'
    ]);
    exit;
}

$osm_id = $_GET['osm_id'];

try {
    // 1. Lấy thông tin thuộc tính và tính toán Diện tích/Chiều dài trực tiếp từ PostGIS bằng ST_Area hoặc ST_Length
    
    $sql = "SELECT osm_id, name, 
                   ST_Length(geom::geography) as chieu_dai 
            FROM bando_chuan 
            WHERE osm_id = :osm_id 
            LIMIT 1";
            
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['osm_id' => $osm_id]);
    $parcel = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$parcel) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Không tìm thấy dữ liệu cho mã osm_id: ' . $osm_id
        ]);
        exit;
    }

    // 2. Giả lập mô hình Hồi quy tuyến tính (ML Regression) của TV9 để demo tạm thời
    // Công thức giả lập: Giá đất = Hệ số cơ bản + (Chiều dài * Hệ số vị trí)
    $he_so_co_ban = 15000000; // 15 triệu/m2 gốc
    $he_so_vi_tri = 50000;    // Thêm 50k dựa trên độ dài hoặc đặc trưng không gian
    $chieu_dai = $parcel['chieu_dai'] ? floatval($parcel['chieu_dai']) : 100; // Nếu không có chiều dài thì mặc định 100

    // Tính toán tổng giá trị dự toán
    $gia_du_toan = $he_so_co_ban + ($chieu_dai * $he_so_vi_tri);

    // 3. Đóng gói kết quả trả về đúng chuẩn JSON cho Frontend (TV4 & TV5) sử dụng
    $response = [
        'status' => 'success',
        'data' => [
            'osm_id' => $parcel['osm_id'],
            'name' => $parcel['name'] ? $parcel['name'] : 'Đường không tên (Dữ liệu đang cập nhật)',
            'calculated_features' => [
                'length_meter' => round($chieu_dai, 2)
            ],
            'ml_model_info' => [
                'algorithm' => 'Linear Regression (Giả lập demo Ngày 4)',
                'r2_score_expected' => 0.85 // Độ chính xác kỳ vọng từ TV9
            ],
            'estimated_price_m2' => round($gia_du_toan, 0),
            'currency' => 'VND'
        ]
    ];

    echo json_encode($response);

} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Lỗi hệ thống: ' . $e->getMessage()
    ]);
}
?>
