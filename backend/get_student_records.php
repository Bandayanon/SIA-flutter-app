<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$status       = $_GET['status']       ?? 'all'; 
$gradeLevel   = $_GET['gradeLevel']   ?? 'all';
$strand       = $_GET['strand']       ?? 'all';
$dominantType = $_GET['dominantType'] ?? 'all'; 
$dateFrom     = $_GET['dateFrom']     ?? '';
$dateTo       = $_GET['dateTo']       ?? '';
$search       = $_GET['search']       ?? '';

$where = ["1=1"];
$params = [];
$types  = "";

if ($status !== 'all') {
    $where[] = "a.Status = ?";
    $params[] = $status;
    $types   .= "s";
}
if ($gradeLevel !== 'all') {
    $where[] = "pi.GradeLevel = ?";
    $params[] = $gradeLevel;
    $types   .= "s";
}
if ($strand !== 'all') {
    $where[] = "pi.Strand LIKE ?";
    $params[] = "%$strand%";
    $types   .= "s";
}
if ($dominantType !== 'all') {
    $where[] = "ar.PrimaryType = ?";
    $params[] = $dominantType;
    $types   .= "s";
}
if (!empty($dateFrom)) {
    $where[] = "DATE(a.SubmittedAt) >= ?";
    $params[] = $dateFrom;
    $types   .= "s";
}
if (!empty($dateTo)) {
    $where[] = "DATE(a.SubmittedAt) <= ?";
    $params[] = $dateTo;
    $types   .= "s";
}
if (!empty($search)) {
    $where[] = "(pi.FirstName LIKE ? OR pi.LastName LIKE ? OR s.StudentID LIKE ?)";
    $params[] = "%$search%";
    $params[] = "%$search%";
    $params[] = "%$search%";
    $types   .= "sss";
}

$whereClause = implode(" AND ", $where);

$query = "
    SELECT
        a.AssessmentID,
        a.Status,
        a.SubmittedAt,
        pi.FirstName,
        pi.LastName,
        pi.MiddleName,
        pi.Strand,
        pi.GradeLevel,
        pi.Gender,
        pi.Age,
        s.StudentID,
        ar.PrimaryType,
        ar.SecondaryType,
        ar.TertiaryType,
        ar.R_Percentage,
        ar.I_Percentage,
        ar.A_Percentage,
        ar.S_Percentage,
        ar.E_Percentage,
        ar.C_Percentage,
        cf.Action AS CounselorAction,
        cf.FeedbackNotes,
        cf.ReviewedAt
    FROM assessments a
    JOIN personal_information pi ON pi.PI_ID = a.PI_ID
    JOIN students s ON s.StudentID = a.StudentID
    LEFT JOIN assessment_results ar ON ar.AssessmentID = a.AssessmentID
    LEFT JOIN counselor_feedback cf ON cf.AssessmentID = a.AssessmentID
    WHERE $whereClause
    ORDER BY a.SubmittedAt DESC
";

if (!empty($params)) {
    $stmt = $conn->prepare($query);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = $conn->query($query);
}

$records = [];
while ($row = $result->fetch_assoc()) {
    $records[] = [
        "assessmentId"   => $row['AssessmentID'],
        "studentId"      => $row['StudentID'],
        "studentName"    => trim($row['FirstName'] . ' ' . ($row['MiddleName'] ? $row['MiddleName'] . ' ' : '') . $row['LastName']),
        "strand"         => $row['Strand'],
        "gradeLevel"     => $row['GradeLevel'],
        "gender"         => $row['Gender'],
        "age"            => $row['Age'],
        "status"         => $row['Status'],
        "submittedAt"    => $row['SubmittedAt'],
        "primaryType"    => $row['PrimaryType'],
        "secondaryType"  => $row['SecondaryType'],
        "tertiaryType"   => $row['TertiaryType'],
        "scores" => [
            "R" => $row['R_Percentage'],
            "I" => $row['I_Percentage'],
            "A" => $row['A_Percentage'],
            "S" => $row['S_Percentage'],
            "E" => $row['E_Percentage'],
            "C" => $row['C_Percentage'],
        ],
        "counselorAction" => $row['CounselorAction'],
        "feedbackNotes"   => $row['FeedbackNotes'],
        "reviewedAt"      => $row['ReviewedAt']
    ];
}

echo json_encode([
    "status"  => "success",
    "records" => $records,
    "total"   => count($records)
]);

$conn->close();
?>
