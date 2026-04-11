<?php
include 'db_connect.php';

$queries = [
    "INSERT IGNORE INTO `roles` (`RoleID`, `RoleName`) VALUES (3, 'super_admin')",
    "ALTER TABLE `counselors` ADD COLUMN `OTP_Code` VARCHAR(6) NULL DEFAULT NULL AFTER `IsBlocked`",
    "ALTER TABLE `counselors` ADD COLUMN `OTP_Expiry` DATETIME NULL DEFAULT NULL AFTER `OTP_Code`",
    "ALTER TABLE `counselors` ADD COLUMN `LastLogin` TIMESTAMP NULL DEFAULT NULL AFTER `OTP_Expiry`",
    "UPDATE `counselors` SET `RoleID` = 3 WHERE `Email` = 'counselor@school.com'",
    "INSERT IGNORE INTO `counselors` (`FirstName`, `LastName`, `Email`, `Password`, `RoleID`) VALUES ('System', 'Admin', 'admin@citadel.com', '$2y$10$3GQlCqHy4nNH6c/EF3bP0ecqMOVdMHyLpboVYckRZgnlTN1ufWTuu', 3)"
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
