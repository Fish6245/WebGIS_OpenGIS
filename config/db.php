<?php
$host = 'localhost';
$port = '5433';          //  THAY SỐ NÀY bằng số Port của bạn
$db   = 'webgis_db';     
$user = 'postgres';      
$pass = '123456';        // Mật khẩu postgres của bạn

try {
    // Đã thêm port=$port vào câu lệnh kết nối dưới đây
    $pdo = new PDO("pgsql:host=$host;port=$port;dbname=$db", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Lỗi kết nối CSDL: " . $e->getMessage());
}
?>
