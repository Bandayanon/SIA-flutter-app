<?php
// admin_users_v2.php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

// Fetch All Users
if ($method === 'GET') {
    // We expect the frontend to pass the AdminID and RoleID as query params for tracking
    $adminId = $_GET['adminId'] ?? null;
    $roleId = $_GET['roleId'] ?? null;
    
    if (!$adminId) {
        die(json_encode(["status" => "error", "message" => "Unauthorized access."]));
    }
    
    $response = [
        "admins" => [],
        "counselors" => [],
        "students" => []
    ];
    
    // Only SuperAdmin (4) can view other Admins
    if ((int)$roleId === 4) {
        $res = $conn->query("SELECT AdminID as id, FirstName as firstName, LastName as lastName, Email as email, RoleID as roleId, IsBlocked as isBlocked FROM admins ORDER BY RoleID DESC");
        while ($row = $res->fetch_assoc()) {
            $response['admins'][] = $row;
        }
    }
    
    $res = $conn->query("SELECT CounselorID as id, FirstName as firstName, LastName as lastName, Email as email, IsBlocked as isBlocked FROM counselors");
    while ($row = $res->fetch_assoc()) {
        $response['counselors'][] = $row;
    }
    
    $res = $conn->query("SELECT StudentID as id, FirstName as firstName, LastName as lastName, Email as email FROM students");
    while ($row = $res->fetch_assoc()) {
        // We'll mimic IsBlocked for students by checking if they are allowed (assume 0 for now)
        $row['isBlocked'] = 0; 
        $response['students'][] = $row;
    }
    
    echo json_encode(["status" => "success", "data" => $response]);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $action = $data['action'] ?? '';
    
    $adminId = $data['reqAdminId'] ?? null;
    $roleId = (int)($data['reqRoleId'] ?? 0);
    
    if (!$adminId || $roleId < 3) {
        die(json_encode(["status" => "error", "message" => "Unauthorized Citadel transaction."]));
    }

    if ($action === 'create') {
        $targetType = $data['targetType']; // admin, counselor, student
        $email = $data['email'];
        $password = password_hash($data['password'], PASSWORD_DEFAULT);
        $fn = $data['firstName'];
        $ln = $data['lastName'];
        
        if ($targetType === 'admin') {
            if ($roleId !== 4) die(json_encode(["status" => "error", "message" => "Only Super Admins can create Admins."]));
            $stmt = $conn->prepare("INSERT INTO admins (RoleID, FirstName, LastName, Email, Password) VALUES (3, ?, ?, ?, ?)");
            $stmt->bind_param("ssss", $fn, $ln, $email, $password);
            
        } elseif ($targetType === 'counselor') {
            $stmt = $conn->prepare("INSERT INTO counselors (RoleID, FirstName, LastName, Email, Password) VALUES (2, ?, ?, ?, ?)");
            $stmt->bind_param("ssss", $fn, $ln, $email, $password);
            
        } elseif ($targetType === 'student') {
            $strand = $data['strand'] ?? 'STEM';
            $grade = $data['gradeLevel'] ?? 'Grade 11';
            $sex = $data['sex'] ?? 'Male';
            $age = $data['age'] ?? 16;
            
            // Requires PI insertion first
            $pi = $conn->prepare("INSERT INTO personal_information (FirstName, LastName, Strand, GradeLevel, Sex, Age) VALUES (?, ?, ?, ?, ?, ?)");
            $pi->bind_param("sssssi", $fn, $ln, $strand, $grade, $sex, $age);
            $pi->execute();
            $pi_id = $pi->insert_id;
            
            $stmt = $conn->prepare("INSERT INTO students (PI_ID, FirstName, LastName, Email, Password) VALUES (?, ?, ?, ?, ?)");
            $stmt->bind_param("issss", $pi_id, $fn, $ln, $email, $password);
        }
        
        if (isset($stmt) && $stmt->execute()) {
            echo json_encode(["status" => "success", "message" => ucfirst($targetType) . " created successfully."]);
        } else {
            echo json_encode(["status" => "error", "message" => "Failed to create user or email already exists."]);
        }
        exit();
    }

    if ($action === 'toggle_block' || $action === 'delete' || $action === 'change_password') {
        $targetType = $data['targetType']; // admin, counselor
        $targetId = $data['targetId'];
        
        if ($targetType === 'admin' && $roleId !== 4) {
            die(json_encode(["status" => "error", "message" => "Only Super Admins can alter Admin accounts."]));
        }
        
        $table = ($targetType === 'admin') ? 'admins' : 'counselors';
        $idCol = ($targetType === 'admin') ? 'AdminID' : 'CounselorID';
        
        if ($action === 'toggle_block') {
            $status = (int)$data['isBlocked'];
            $stmt = $conn->prepare("UPDATE $table SET IsBlocked = ? WHERE $idCol = ?");
            $stmt->bind_param("ii", $status, $targetId);
            $stmt->execute();
            echo json_encode(["status" => "success", "message" => "Account status updated."]);
            
        } elseif ($action === 'delete') {
            $stmt = $conn->prepare("DELETE FROM $table WHERE $idCol = ?");
            $stmt->bind_param("i", $targetId);
            $stmt->execute();
            echo json_encode(["status" => "success", "message" => "Account permanently deleted."]);
            
        } elseif ($action === 'change_password') {
            $password = password_hash($data['newPassword'], PASSWORD_DEFAULT);
            $stmt = $conn->prepare("UPDATE $table SET Password = ? WHERE $idCol = ?");
            $stmt->bind_param("si", $password, $targetId);
            $stmt->execute();
            echo json_encode(["status" => "success", "message" => "Keys rotated successfully."]);
        }
        exit();
    }
}
$conn->close();
?>
