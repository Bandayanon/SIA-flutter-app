<?php
// admin_archive.php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
$adminId = $_GET['adminId'] ?? null;

if ($method === 'GET' && isset($_GET['listOnly'])) {
    if (!$adminId) { echo json_encode(["status" => "error", "message" => "Unauthorized."]); exit(); }

    $res = $conn->query("
        SELECT a.AssessmentID, a.StudentID, s.FirstName, s.LastName,
               pi.Strand, pi.GradeLevel,
               r.Result_Code1, r.Result_Code2, r.Result_Code3,
               a.Status, a.SubmittedAt
        FROM assessments a
        JOIN students s ON s.StudentID = a.StudentID
        JOIN personal_information pi ON pi.PI_ID = s.PI_ID
        LEFT JOIN results r ON r.AssessmentID = a.AssessmentID
        WHERE a.Status != 'in_progress'
        ORDER BY a.SubmittedAt DESC
    ");

    $records = [];
    while ($row = $res->fetch_assoc()) { $records[] = $row; }
    echo json_encode(["status" => "success", "records" => $records]);
    exit();
}

if ($method === 'GET' && isset($_GET['exportCsv'])) {
    
    // We export the completed assessments for Archiving / Analysis
    $res = $conn->query("
        SELECT a.AssessmentID, a.StudentID, s.FirstName, s.LastName, 
               pi.Strand, pi.GradeLevel,
               r.Result_Code1, r.Result_Code2, r.Result_Code3,
               a.Status, a.SubmittedAt
        FROM assessments a
        JOIN students s ON s.StudentID = a.StudentID
        JOIN personal_information pi ON pi.PI_ID = s.PI_ID
        LEFT JOIN results r ON r.AssessmentID = a.AssessmentID
        WHERE a.Status != 'in_progress'
        ORDER BY a.SubmittedAt DESC
    ");
    
    $filename = "citadel_assessment_export_" . date('Y-m-d') . ".csv";
    
    // Stream direct CSV response
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename='. $filename);
    
    $output = fopen('php://output', 'w');
    fputcsv($output, array('Assessment ID', 'Student ID', 'First Name', 'Last Name', 'Strand', 'Grade Level', 'Top 1', 'Top 2', 'Top 3', 'Status', 'Date Submitted'));
    
    while ($row = $res->fetch_assoc()) {
        fputcsv($output, [
            $row['AssessmentID'],
            $row['StudentID'],
            $row['FirstName'],
            $row['LastName'],
            $row['Strand'],
            $row['GradeLevel'],
            $row['Result_Code1'],
            $row['Result_Code2'],
            $row['Result_Code3'],
            $row['Status'],
            $row['SubmittedAt']
        ]);
    }
    fclose($output);
    exit();
}

$conn->close();
?>
