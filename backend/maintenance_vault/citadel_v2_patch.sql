-- Citadel V2: Dedicated Administration System Patch

-- 1. Create Admins Table (keeping Admins cleanly separated)
CREATE TABLE IF NOT EXISTS `admins` (
  `AdminID` bigint(20) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `RoleID` int(11) NOT NULL DEFAULT 3, -- 3 for Admin, 4 for SuperAdmin
  `FirstName` varchar(100) NOT NULL,
  `LastName` varchar(100) NOT NULL,
  `Email` varchar(150) NOT NULL UNIQUE,
  `Password` varchar(255) NOT NULL,
  `OTP_Code` varchar(6) NULL DEFAULT NULL,
  `OTP_Expiry` datetime NULL DEFAULT NULL,
  `LastLogin` timestamp NULL DEFAULT NULL,
  `IsBlocked` TINYINT(1) NOT NULL DEFAULT 0,
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. Define Admin Roles
INSERT IGNORE INTO `roles` (`RoleID`, `RoleName`) VALUES (3, 'admin');
INSERT IGNORE INTO `roles` (`RoleID`, `RoleName`) VALUES (4, 'super_admin');

-- 3. Resolve Potential Email Conflicts
-- If the super admin's email is already registered as a student, rename the student's email to avoid conflicts.
UPDATE `students` 
SET `Email` = 'sam.bandayanon.student@jmc.edu.ph' 
WHERE `Email` = 'sam.bandayanon@jmc.edu.ph';

-- 4. Invalidate previous generic admin if it exists
DELETE FROM `counselors` WHERE `Email` = 'admin@citadel.com';

-- 5. Revert counselor@school.com back to regular Counselor (if it was upgraded)
UPDATE `counselors` SET `RoleID` = 2 WHERE `Email` = 'counselor@school.com';

-- 6. Insert the Original SuperAdmin
INSERT IGNORE INTO `admins` (`RoleID`, `FirstName`, `LastName`, `Email`, `Password`) 
VALUES (4, 'Sam', 'Bandayanon', 'sam.bandayanon@jmc.edu.ph', '$2y$12$jzVg8mRoXpurFcfrgkQab.FGL.qx9evVSjM7c7qT6QRg37daoU3am');
