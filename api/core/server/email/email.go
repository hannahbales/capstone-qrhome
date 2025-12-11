package email

import (
	"fmt"
	"net/smtp"
	"os"
)

// EmailConfig holds SMTP server settings
type EmailConfig struct {
	SMTPHost string
	SMTPPort string
	Sender   string
	Password string
}

// getEmailConfig returns the SMTP config from env
func getEmailConfig() EmailConfig {
	return EmailConfig{
		SMTPHost: os.Getenv("SMTP_HOST"),
		SMTPPort: os.Getenv("SMTP_PORT"),
		Sender:   os.Getenv("SMTP_USER"),
		Password: os.Getenv("SMTP_PASS"),
	}
}

// sendEmail sends the actual email with a subject and body
func sendEmail(to string, subject string, body string) error {
	config := getEmailConfig()

	message := fmt.Sprintf("From: %s\nTo: %s\nSubject: %s\n\n%s",
		config.Sender, to, subject, body)

	auth := smtp.PlainAuth("", config.Sender, config.Password, config.SMTPHost)

	err := smtp.SendMail(config.SMTPHost+":"+config.SMTPPort, auth, config.Sender, []string{to}, []byte(message))
	if err != nil {
		fmt.Printf("Failed to send email: %v\n", err)
		return fmt.Errorf("failed to send email: %v", err)
	}

	fmt.Println("Email sent successfully to", to)
	return nil
}

// build2FAEmail returns subject and body for 2FA
func build2FAEmail(code string) (string, string) {
	subject := "Your 2FA Login Code"
	body := fmt.Sprintf("Your login code is: %s\n\nIt will expire shortly. Do not share this code.\n\nBest regards,\nQR Home", code)
	return subject, body
}

// Send2FACodeEmail is the public function to send a 2FA code
func Send2FACodeEmail(email, code string) error {
	subject, body := build2FAEmail(code)
	return sendEmail(email, subject, body)
}
