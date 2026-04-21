<?php
header("Content-Type: text/plain");
echo "--- PHP ENVIRONMENT CHECK ---\n";
echo "DB_HOST: " . (getenv('DB_HOST') ?: "MISSING") . "\n";
echo "DB_PORT: " . (getenv('DB_PORT') ?: "MISSING") . "\n";
echo "DB_USER: " . (getenv('DB_USER') ?: "MISSING") . "\n";
echo "DB_NAME: " . (getenv('DB_NAME') ?: "MISSING") . "\n";
echo "---------------------------\n";
echo "ALL ENV VARS (keys only):\n";
print_r(array_keys($_ENV));
print_r(array_keys($_SERVER));
?>
