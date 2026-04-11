<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-Admin-Pin");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$headers = getallheaders();
$pin = $headers['X-Admin-Pin'] ?? $_SERVER['HTTP_X_ADMIN_PIN'] ?? '';
$envPin = getenv('ADMIN_PIN') ?: '1234567';

if ($pin !== $envPin) {
    echo json_encode(["status" => "error", "message" => "Unauthorized Citadel access."]);
    exit();
}

$stats = [];

// 1. Total Counselors
$stats['totalCounselors'] = (int)$conn->query("SELECT COUNT(*) FROM counselors")->fetch_row()[0];

// 2. Total Students
$stats['totalStudents'] = (int)$conn->query("SELECT COUNT(*) FROM students")->fetch_row()[0];

// 3. Completed Assessments
$stats['completedAssessments'] = (int)$conn->query("SELECT COUNT(*) FROM assessments WHERE Status IN ('approved', 'declined')")->fetch_row()[0];

// 4. Currently active sessions
$stats['activeSessions'] = (int)$conn->query("SELECT COUNT(*) FROM live_sessions WHERE IsActive = TRUE")->fetch_row()[0];

echo json_encode(["status" => "success", "stats" => $stats]);

$conn->close();
?>
