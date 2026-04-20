<?php
header("Content-Type: text/html");
ini_set('display_errors', 1);
error_reporting(E_ALL);

include 'db_connect.php';

$sqlFiles = [
    'citadel_v2_patch.sql',
    'citadel_v2_logs.sql',
    'v3_course_update.sql'
];

foreach ($sqlFiles as $filename) {
    $sqlFile = __DIR__ . '/' . $filename;
    if (file_exists($sqlFile)) {
        $sql = file_get_contents($sqlFile);
        if ($conn->multi_query($sql)) {
            do {
                if ($result = $conn->store_result()) {
                    $result->free();
                }
            } while ($conn->more_results() && $conn->next_result());
            echo "<h3 style='color:green; font-family:sans-serif;'>Patch Applied: $filename</h3>";
        } else {
            echo "<h3 style='color:red; font-family:sans-serif;'>Error applying $filename: " . htmlspecialchars($conn->error) . "</h3>";
        }
    } else {
        echo "<h3 style='color:orange; font-family:sans-serif;'>File Not Found: $filename</h3>";
    }
}

$conn->close();
?>
