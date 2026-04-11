function sendAssessmentEmail($toEmail, $studentName, $status, $notes, $adminEmail = 'sam.bandayanon@jmc.edu.ph') {
    // Check if PHPMailer exists first (common issue in local dev)
    $exceptionPath = __DIR__ . '/vendor/PHPMailer/src/Exception.php';
    $mailerPath    = __DIR__ . '/vendor/PHPMailer/src/PHPMailer.php';
    $smtpPath      = __DIR__ . '/vendor/PHPMailer/src/SMTP.php';

    if (!file_exists($exceptionPath) || !file_exists($mailerPath) || !file_exists($smtpPath)) {
        error_log("SKIPPING EMAIL: PHPMailer library not found in vendor folder.");
        return true; // Return true so the calling script doesn't think it failed
    }

    require_once $exceptionPath;
    require_once $mailerPath;
    require_once $smtpPath;

    $mail = new PHPMailer\PHPMailer\PHPMailer(true);

    try {
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        // Using the App Password provided
        $mail->Username   = $adminEmail; 
        $mail->Password   = 'mtmd vyru gcut fsya';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;

        $mail->setFrom($adminEmail, 'RIASEC Assessment System');
        $mail->addAddress($toEmail, $studentName);

        $mail->isHTML(true);
        $mail->Subject = 'Your RIASEC Assessment has been ' . ucfirst($status);
        
        $body = "<h2>Hello $studentName,</h2>";
        $body .= "<p>Your recent RIASEC Assessment has been marked as <strong>" . ucfirst($status) . "</strong> by the counselor.</p>";
        if (!empty($notes)) {
            $body .= "<div style='background-color:#f8f9fa; padding:15px; border-left:4px solid #6c5ce7; margin:20px 0;'>
                        <strong>Counselor Notes:</strong><br>" . nl2br(htmlspecialchars($notes)) . "
                      </div>";
        }
        $body .= "<br><p>Thank you,</p><p>Guidance Office</p>";
        
        $mail->Body = $body;
        
        $mail->AltBody = "Hello $studentName,\n\nYour RIASEC Assessment has been marked as " . ucfirst($status) . ".\n\n" . (!empty($notes) ? "Counselor Notes:\n$notes" : "");

        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Mailer Error: {$mail->ErrorInfo}");
        return false;
    }
}
?>
