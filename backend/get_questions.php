<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$result = $conn->query("SELECT QuestionID, QuestionText, RIASECCategory FROM riasec_questions ORDER BY QuestionID");

$questions = [];
while ($row = $result->fetch_assoc()) {
    $questions[] = [
        "id"       => (int)$row['QuestionID'],
        "question" => $row['QuestionText'],
        "category" => $row['RIASECCategory']
    ];
}

echo json_encode(["status" => "success", "questions" => $questions]);

$conn->close();
?>
