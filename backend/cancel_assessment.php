<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);
$assessmentId = (int)($data['assessmentId'] ?? 0);

if ($assessmentId > 0) {
    $conn->query("DELETE FROM live_sessions WHERE AssessmentID = $assessmentId");
    $conn->query("DELETE FROM assessment_answers WHERE AssessmentID = $assessmentId");
    $conn->query("DELETE FROM assessments WHERE AssessmentID = $assessmentId");
    
    echo json_encode(["status" => "success", "message" => "Ghost Session Deleted."]);
} else {
    echo json_encode(["status" => "error", "message" => "Invalid assessmentId"]);
}
$conn->close();
?>
