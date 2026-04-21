<?php
header("Content-Type: text/plain");
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "--- DATABASE CONNECTION TEST ---\n";

function get_env_var($key, $default) {
    $val = getenv($key);
    if ($val === false) $val = $_ENV[$key] ?? null;
    if ($val === null)  $val = $_SERVER[$key] ?? null;
    return ($val !== null && $val !== "") ? $val : $default;
}

$host = get_env_var('DB_HOST', "db");
$db   = get_env_var('DB_NAME', "riasec_db");
$user = get_env_var('DB_USER', "riasec_user");
$pass = get_env_var('DB_PASS', "riasec_password");
$port = get_env_var('DB_PORT', "3306");

echo "Attempting connection to $host:$port...\n";

$conn = mysqli_init();
mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);

if (!@mysqli_real_connect($conn, $host, $user, $pass, $db, $port, NULL, MYSQLI_CLIENT_SSL)) {
    echo "❌ CONNECTION FAILED!\n";
    echo "Error: " . mysqli_connect_error() . "\n";
} else {
    echo "✅ CONNECTION SUCCESSFUL!\n";
    echo "--- TABLE STRUCTURE: riasec_courses ---\n";
    $res = mysqli_query($conn, "DESCRIBE riasec_courses");
    if ($res) {
        while($row = mysqli_fetch_assoc($res)) {
            echo "Field: {$row['Field']} | Type: {$row['Type']}\n";
        }
    } else {
        echo "❌ Table 'riasec_courses' DOES NOT EXIST!\n";
    }
    
    echo "--- QUERY TEST: riasec_courses ---\n";
    $test_query = "SELECT CourseID, CourseName, ExplanationTip FROM riasec_courses WHERE RIASECCategory = 'R' LIMIT 1";
    $test_res = mysqli_prepare($conn, $test_query);
    if ($test_res) {
        echo "✅ QUERY PREPARE SUCCESSFUL!\n";
    } else {
        echo "❌ QUERY PREPARE FAILED!\n";
        echo "SQL Error: " . mysqli_error($conn) . "\n";
    }
    mysqli_close($conn);
}
?>
