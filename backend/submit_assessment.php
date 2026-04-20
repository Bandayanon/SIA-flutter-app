<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

register_shutdown_function(function() {
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        echo json_encode(["status" => "error", "message" => "PHP Fatal: " . $error['message'] . " on line " . $error['line']]);
    }
});

include 'db_connect.php';

$data         = json_decode(file_get_contents("php://input"), true);
$assessmentId = (int)($data['assessmentId'] ?? 0);
$answers      = $data['answers'] ?? [];

if (empty($assessmentId) || empty($answers)) {
    echo json_encode(["status" => "error", "message" => "Missing assessmentId or answers"]);
    exit();
}

$maxScores = ['R' => 45, 'I' => 35, 'A' => 30, 'S' => 30, 'E' => 35, 'C' => 35];
$rawScores = ['R' => 0,  'I' => 0,  'A' => 0,  'S' => 0,  'E' => 0,  'C' => 0];

foreach ($answers as $answer) {
    $questionId = (int)$answer['questionId'];
    $score      = max(1, min(5, (int)$answer['score']));

    $q = $conn->prepare("SELECT RIASECCategory FROM riasec_questions WHERE QuestionID = ?");
    $q->bind_param("i", $questionId);
    $q->execute();
    $qResult  = $q->get_result()->fetch_assoc();
    $category = $qResult['RIASECCategory'] ?? null;
    if (!$category) continue;

    $rawScores[$category] += $score;

    $ins = $conn->prepare("INSERT INTO assessment_answers (AssessmentID, QuestionID, Score) VALUES (?, ?, ?)");
    $ins->bind_param("iii", $assessmentId, $questionId, $score);
    $ins->execute();
}

$percentages = [];
foreach ($rawScores as $cat => $score) {
    $percentages[$cat] = round(($score / $maxScores[$cat]) * 100, 2);
}

arsort($percentages);
$top3          = array_keys(array_slice($percentages, 0, 3, true));
$primaryType   = $top3[0] ?? null;
$secondaryType = $top3[1] ?? null;
$tertiaryType  = $top3[2] ?? null;

$rScore = (int)$rawScores['R']; $iScore = (int)$rawScores['I'];
$aScore = (int)$rawScores['A']; $sScore = (int)$rawScores['S'];
$eScore = (int)$rawScores['E']; $cScore = (int)$rawScores['C'];

$rPct = (float)$percentages['R']; $iPct = (float)$percentages['I'];
$aPct = (float)$percentages['A']; $sPct = (float)$percentages['S'];
$ePct = (float)$percentages['E']; $cPct = (float)$percentages['C'];

$res = $conn->prepare("
    INSERT INTO assessment_results
    (AssessmentID, R_Score, I_Score, A_Score, S_Score, E_Score, C_Score,
    R_Percentage, I_Percentage, A_Percentage, S_Percentage, E_Percentage, C_Percentage,
    PrimaryType, SecondaryType, TertiaryType)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
    R_Score=VALUES(R_Score), I_Score=VALUES(I_Score), A_Score=VALUES(A_Score), 
    S_Score=VALUES(S_Score), E_Score=VALUES(E_Score), C_Score=VALUES(C_Score),
    R_Percentage=VALUES(R_Percentage), I_Percentage=VALUES(I_Percentage), A_Percentage=VALUES(A_Percentage),
    S_Percentage=VALUES(S_Percentage), E_Percentage=VALUES(E_Percentage), C_Percentage=VALUES(C_Percentage),
    PrimaryType=VALUES(PrimaryType), SecondaryType=VALUES(SecondaryType), TertiaryType=VALUES(TertiaryType)
");
$res->bind_param(
    "iiiiiiiddddddsss",
    $assessmentId,
    $rScore, $iScore, $aScore, $sScore, $eScore, $cScore,
    $rPct,   $iPct,   $aPct,   $sPct,   $ePct,   $cPct,
    $primaryType, $secondaryType, $tertiaryType
);

if (!$res->execute()) {
    echo json_encode(["status" => "error", "message" => "Failed to save results: " . $res->error]);
    exit();
}
$resultId = (int)$conn->insert_id;

$rank = 1;
    foreach ($top3 as $type) {
        $courses = $conn->prepare("
            SELECT CourseID, CourseName, ExplanationTip FROM riasec_courses
            WHERE RIASECCategory = ? ORDER BY RAND() LIMIT 1
        ");
        $courses->bind_param("s", $type);
        $courses->execute();
        $courseResult = $courses->get_result();

        while ($course = $courseResult->fetch_assoc()) {
            if ($rank > 6) break;
            
            $matchScore = (float)$percentages[$type];
            // Provide the unique course explanation instead of a generic one
            $explanation = $course['ExplanationTip'] ?? "This course aligns with your {$type} interest profile.";

            $recStmt = $conn->prepare("
                INSERT INTO riasec_recommendations (ResultID, CourseID, MatchScore, Explanation, `Rank`)
                VALUES (?, ?, ?, ?, ?)
            ");
            $recStmt->bind_param("iidsi", $resultId, $course['CourseID'], $matchScore, $explanation, $rank);
            $recStmt->execute();
            $rank++;
        }
    }

$upd = $conn->prepare("UPDATE assessments SET Status = 'pending_review', SubmittedAt = NOW() WHERE AssessmentID = ?");
$upd->bind_param("i", $assessmentId);
$upd->execute();

$cls = $conn->prepare("UPDATE live_sessions SET IsActive = FALSE WHERE AssessmentID = ?");
$cls->bind_param("i", $assessmentId);
$cls->execute();

echo json_encode([
    "status"        => "success",
    "resultId"      => $resultId,
    "primaryType"   => $primaryType,
    "secondaryType" => $secondaryType,
    "tertiaryType"  => $tertiaryType,
    "percentages"   => $percentages
]);

$conn->close();
?>
