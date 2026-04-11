<?php
// Quiet Shield
ini_set('display_errors', 0);
error_reporting(0);

include 'db_connect.php';

$sqlFile = __DIR__ . '/citadel_v2_patch.sql';

if (file_exists($sqlFile)) {
    $sql = file_get_contents($sqlFile);
    if ($conn->multi_query($sql)) {
        do {
            if ($result = $conn->store_result()) {
                $result->free();
            }
        } while ($conn->more_results() && $conn->next_result());
        echo "<h2 style='color:green; font-family:sans-serif;'>Citadel V2 Patch Applied Successfully!</h2>";
        echo "<p style='font-family:sans-serif;'>The new admins table is ready. You may now close this page and log in.</p>";
    } else {
        echo "<h2 style='color:red; font-family:sans-serif;'>Error applying patch: " . htmlspecialchars($conn->error) . "</h2>";
    }
} else {
    echo "<h2 style='color:red; font-family:sans-serif;'>Patch file not found.</h2>";
}

$conn->close();
?>
