<?php
// Quiet Shield: Prevent PHP from sending HTML errors that break the Flutter JSON
@ini_set('display_errors', 0);
@error_reporting(0);
@header("Content-Type: application/json");

// Database credentials from environment variables
$host = getenv('DB_HOST') ?: "db";
$db   = getenv('DB_NAME') ?: "riasec_db";
$user = getenv('DB_USER') ?: "riasec_user";
$pass = getenv('DB_PASS') ?: "riasec_password";
$port = getenv('DB_PORT') ?: "3306";

$conn = mysqli_init();
if (!$conn) {
    die(json_encode(["status" => "error", "message" => "mysqli_init failed"]));
}

// DigitalOcean managed databases REQUIRE SSL.
@mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);

if (!@mysqli_real_connect($conn, $host, $user, $pass, $db, $port, NULL, MYSQLI_CLIENT_SSL)) {
    die(json_encode([
        "status" => "error",
        "message" => "Database connection failed! Please check your DigitalOcean Trusted Sources."
    ]));
}

@mysqli_set_charset($conn, "utf8mb4");
?>