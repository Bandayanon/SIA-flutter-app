<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$filter = $_GET['filter'] ?? 'all'; 

$dateCondition = "1=1";
switch ($filter) {
    case 'today':
        $dateCondition = "DATE(a.SubmittedAt) = CURDATE()";
        break;
    case 'week':
        $dateCondition = "a.SubmittedAt >= DATE_SUB(NOW(), INTERVAL 1 WEEK)";
        break;
    case 'month':
        $dateCondition = "a.SubmittedAt >= DATE_SUB(NOW(), INTERVAL 1 MONTH)";
        break;
}

$pending = $conn->query("
    SELECT COUNT(*) as count FROM assessments a WHERE a.Status = 'pending_review' AND $dateCondition
")->fetch_assoc()['count'];

$totalStudents = $conn->query("SELECT COUNT(*) as count FROM students")->fetch_assoc()['count'];

$assessmentsToday = $conn->query("
    SELECT COUNT(*) as count FROM assessments WHERE DATE(SubmittedAt) = CURDATE()
")->fetch_assoc()['count'];

$feedbackGiven = $conn->query("
    SELECT COUNT(*) as count FROM counselor_feedback cf
    JOIN assessments a ON a.AssessmentID = cf.AssessmentID
    WHERE $dateCondition
")->fetch_assoc()['count'];

$approved = $conn->query("
    SELECT COUNT(*) as count FROM assessments a WHERE a.Status = 'approved' AND $dateCondition
")->fetch_assoc()['count'];

$total = $conn->query("
    SELECT COUNT(*) as count FROM assessments a WHERE a.Status != 'in_progress' AND $dateCondition
")->fetch_assoc()['count'];

$approvalRate = $total > 0 ? round(($approved / $total) * 100, 1) : 0;

echo json_encode([
    "status"         => "success",
    "pendingCount"   => (int)$pending,
    "totalStudents"  => (int)$totalStudents,
    "assessmentsToday" => (int)$assessmentsToday,
    "feedbackGiven"  => (int)$feedbackGiven,
    "approvalRate"   => $approvalRate,
    "inProgress"     => (int)$conn->query("SELECT COUNT(*) as count FROM live_sessions ls JOIN assessments a ON a.AssessmentID = ls.AssessmentID WHERE ls.IsActive = TRUE AND a.Status = 'in_progress'")->fetch_assoc()['count']
]);

$conn->close();
?>
