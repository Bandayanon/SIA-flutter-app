-- RIASEC Version 3.0: Production Sanitization Script
-- This script wipes all test data and sets up the final SuperAdmin account.

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Wipe all transactional telemetry and student data
TRUNCATE TABLE `assessment_answers`;
TRUNCATE TABLE `assessment_results`;
TRUNCATE TABLE `riasec_recommendations`;
TRUNCATE TABLE `counselor_feedback`;
TRUNCATE TABLE `live_sessions`;
TRUNCATE TABLE `assessments`;
TRUNCATE TABLE `personal_information`;
TRUNCATE TABLE `system_logs`;

-- 2. Wipe all User accounts (including admins)
DELETE FROM `students`;
DELETE FROM `counselors`;
DELETE FROM `admins`;

-- 3. Ensure official Roles are present
INSERT IGNORE INTO `roles` (`RoleID`, `RoleName`) VALUES (1, 'student');
INSERT IGNORE INTO `roles` (`RoleID`, `RoleName`) VALUES (2, 'guidance_counselor');
INSERT IGNORE INTO `roles` (`RoleID`, `RoleName`) VALUES (3, 'admin');
INSERT IGNORE INTO `roles` (`RoleID`, `RoleName`) VALUES (4, 'super_admin');

-- 4. INSERT THE FINAL SUPERADMIN MASTER KEY
-- Email: sam.bandayanon@jmc.edu.ph
-- Password: [Powering_C0U10R5123]
INSERT INTO `admins` (`RoleID`, `FirstName`, `LastName`, `Email`, `Password`) 
VALUES (4, 'Sam', 'Bandayanon', 'sam.bandayanon@jmc.edu.ph', '$2y$12$3USCkb9qqFGPK1USw/tJPuquMnY6oKjW5dAjPEXYfuZ8eUM.JxdPi');

SET FOREIGN_KEY_CHECKS = 1;
