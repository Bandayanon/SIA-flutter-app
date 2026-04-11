<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';
include 'mailer.php';

$data         = json_decode(file_get_contents("php://input"), true);
$assessmentId = (int)($data['assessmentId'] ?? 0);
$action       = $data['action'] ?? ''; 
$counselorId  = (int)($data['counselorId'] ?? 0);
$notes        = $data['notes'] ?? '';

if (!$assessmentId || !in_array($action, ['approved', 'rejected']) || !$counselorId) {
    echo json_encode(["status" => "error", "message" => "Missing required fields"]);
    exit();
}

$upd = $conn->prepare("UPDATE assessments SET Status = ? WHERE AssessmentID = ?");
$upd->bind_param("si", $action, $assessmentId);
if (!$upd->execute()) {
    echo json_encode(["status" => "error", "message" => "Failed to update status"]);
    exit();
}

$fb = $conn->prepare("
    INSERT INTO counselor_feedback (AssessmentID, CounselorID, Action, FeedbackNotes, ReviewedAt)
    VALUES (?, ?, ?, ?, NOW())
    ON DUPLICATE KEY UPDATE Action = VALUES(Action), FeedbackNotes = VALUES(FeedbackNotes), ReviewedAt = NOW()
");
$fb->bind_param("iiss", $assessmentId, $counselorId, $action, $notes);
$fb->execute();

$stuQuery = $conn->prepare("
    SELECT s.Email, s.FirstName 
    FROM assessments a
    JOIN students s ON a.StudentID = s.StudentID
    WHERE a.AssessmentID = ?
");
$stuQuery->bind_param("i", $assessmentId);
$stuQuery->execute();
$stuRes = $stuQuery->get_result();
if ($stuRow = $stuRes->fetch_assoc()) {
    // We call this but don't let it crash the script if it fails
    try {
        sendAssessmentEmail($stuRow['Email'], $stuRow['FirstName'], $action, $notes, 'sam.bandayanon@jmc.edu.ph');
    } catch (Exception $e) {
        error_log("Non-fatal mailer error: " . $e->getMessage());
    }
}

echo json_encode(["status" => "success", "message" => "Assessment $action successfully"]);
$conn->close();
?>
