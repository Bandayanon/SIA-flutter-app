<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-Admin-Pin");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$headers = getallheaders();
$pin = $headers['X-Admin-Pin'] ?? $_SERVER['HTTP_X_ADMIN_PIN'] ?? '';

if ($pin !== '1234567') {
    echo json_encode(["status" => "error", "message" => "Unauthorized access. Invalid Admin PIN."]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $assessmentId = (int)($_GET['assessmentId'] ?? 0);
    
    if ($assessmentId > 0) {
        $details = [];
        $res = $conn->query("SELECT * FROM assessment_results WHERE AssessmentID = $assessmentId");
        if ($res && $resRow = $res->fetch_assoc()) {
            $details['results'] = $resRow;
            $resultId = $resRow['ResultID'];
            $reqs = $conn->query("SELECT r.*, c.CourseName FROM riasec_recommendations r JOIN riasec_courses c ON r.CourseID = c.CourseID WHERE r.ResultID = $resultId ORDER BY r.Rank ASC");
            $recommendations = [];
            if ($reqs) {
                while($reqRow = $reqs->fetch_assoc()) $recommendations[] = $reqRow;
            }
            $details['recommendations'] = $recommendations;
        }
        echo json_encode(["status" => "success", "details" => $details]);
        exit();
    }

    $archives = [];
    $query = "
        SELECT 
            a.AssessmentID, a.Status, a.StartedAt, a.SubmittedAt,
            s.FirstName, s.LastName, s.Email,
            ar.R_Score, ar.I_Score, ar.A_Score, ar.S_Score, ar.E_Score, ar.C_Score,
            ar.PrimaryType, ar.SecondaryType, ar.TertiaryType
        FROM assessments a
        JOIN students s ON a.StudentID = s.StudentID
        LEFT JOIN assessment_results ar ON a.AssessmentID = ar.AssessmentID
        ORDER BY a.StartedAt DESC
    ";
    $res = $conn->query($query);
    if ($res) {
        while($r = $res->fetch_assoc()) {
            $archives[] = $r;
        }
    }
    echo json_encode(["status" => "success", "archives" => $archives]);

} elseif ($method === 'PUT') {
    $data = json_decode(file_get_contents("php://input"), true);
    $assessmentId = (int)($data['assessmentId'] ?? 0);
    $status = $data['status'] ?? 'declined'; 
    
    if ($status === 'invalid') {
        $status = 'declined';
    }

    $stmt = $conn->prepare("UPDATE assessments SET Status = ? WHERE AssessmentID = ?");
    $stmt->bind_param("si", $status, $assessmentId);
    if ($stmt->execute()) {
         echo json_encode(["status" => "success", "message" => "Record status updated to $status"]);
    } else {
         echo json_encode(["status" => "error", "message" => "Failed to update record"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method"]);
}

$conn->close();
?>
