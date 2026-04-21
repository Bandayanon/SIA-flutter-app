-- v3_final_schema.sql
-- FORCED REBUILD: Deletes broken tables to ensure 100% column accuracy

SET FOREIGN_KEY_CHECKS = 0;

-- Drop old broken tables
DROP TABLE IF EXISTS `riasec_recommendations`;
DROP TABLE IF EXISTS `riasec_courses`;

-- 1. Courses Table (Rebuilt with ExplanationTip)
CREATE TABLE `riasec_courses` (
  `CourseID` bigint(20) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `CourseName` varchar(255) NOT NULL,
  `CourseCode` varchar(50) DEFAULT NULL,
  `RIASECCategory` char(1) NOT NULL,
  `Description` text DEFAULT NULL,
  `ExplanationTip` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. Recommendations Table
CREATE TABLE `riasec_recommendations` (
  `RecID` bigint(20) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `ResultID` bigint(20) NOT NULL,
  `CourseID` bigint(20) NOT NULL,
  `MatchScore` decimal(5,2) DEFAULT NULL,
  `Explanation` text DEFAULT NULL,
  `Rank` int(11) DEFAULT NULL,
  KEY `ResultID` (`ResultID`),
  KEY `CourseID` (`CourseID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 3. Ensure other core tables exist (Safety check)
CREATE TABLE IF NOT EXISTS `assessment_results` (
  `ResultID` bigint(20) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `AssessmentID` bigint(20) NOT NULL,
  `R_Score` int(11) DEFAULT 0,
  `I_Score` int(11) DEFAULT 0,
  `A_Score` int(11) DEFAULT 0,
  `S_Score` int(11) DEFAULT 0,
  `E_Score` int(11) DEFAULT 0,
  `C_Score` int(11) DEFAULT 0,
  `R_Percentage` decimal(5,2) DEFAULT 0.00,
  `I_Percentage` decimal(5,2) DEFAULT 0.00,
  `A_Percentage` decimal(5,2) DEFAULT 0.00,
  `S_Percentage` decimal(5,2) DEFAULT 0.00,
  `E_Percentage` decimal(5,2) DEFAULT 0.00,
  `C_Percentage` decimal(5,2) DEFAULT 0.00,
  `PrimaryType` char(1) DEFAULT NULL,
  `SecondaryType` char(1) DEFAULT NULL,
  `TertiaryType` char(1) DEFAULT NULL,
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
