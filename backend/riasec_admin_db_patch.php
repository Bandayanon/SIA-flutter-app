<?php
include 'db_connect.php';

$queries = [
    "ALTER TABLE students ADD IsBlocked TINYINT(1) NOT NULL DEFAULT 0",
    "ALTER TABLE counselors ADD IsBlocked TINYINT(1) NOT NULL DEFAULT 0"
];

foreach ($queries as $q) {
    if ($conn->query($q)) {
        echo "Success: $q\n";
    } else {
        echo "Error/Skipped (might already exist): " . $conn->error . "\n";
    }
}
$conn->close();
?>
