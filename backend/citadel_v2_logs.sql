-- Citadel V2: System Logging Infrastructure

CREATE TABLE IF NOT EXISTS `system_logs` (
  `LogID` bigint(20) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `AdminID` bigint(20) NOT NULL,
  `Action` varchar(255) NOT NULL, -- e.g., 'CREATE_USER', 'BLOCK_USER', 'PASSWORD_RESET'
  `TargetType` varchar(50) NOT NULL, -- e.g., 'student', 'counselor', 'admin'
  `TargetID` bigint(20) DEFAULT NULL,
  `Details` text DEFAULT NULL, -- JSON or plain text details
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  FOREIGN KEY (`AdminID`) REFERENCES `admins`(`AdminID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
