package account

// Utility functions for handling accounts.

import (
	"api/core/server/email"
	"api/core/util"
	db "api/db"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/labstack/echo"
)

// Minimum age a user can be
const minimumAge = 18

const testCreateEmail = "a@a.com"

const AuthHeaderKey = "QRHome-Auth"
const EmailHeaderKey = "QRHome-Email"
const authExpiresIn = time.Hour * 72
const linkCodeQueryParam = "code"

const passwordSalt = "fqfl3pgmlv"

const twoFACodeExpiry = time.Minute * 5

var acceptableCaseworkerDomains = []string{
	"@interfaithsanctuary.org",
	"@cityofboise.org",
	"@ihfa.org",
	"@jessetreeidaho.org",
	"@rescue.org",
	"@eladacap.org",
	"@u.boisestate.edu",
}

// Request struct for creating an account.
type CreateAccountRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	FirstName   string `json:"first"`
	LastName    string `json:"last"`
	DateOfBirth string `json:"dob"`
	AccountType string `json:"type"`
}

type AuthenticateRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// Response struct from creating an account.
type CreateAccountResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

type AuthenticateResponse struct {
	Success     bool   `json:"success"`
	Challenge   bool   `json:"challenge"`
	Error       string `json:"error"`
	AuthToken   string `json:"auth_token"`
	AccountType string `json:"type"`
	Email       string `json:"email"`
}

// idk if i need this, might delete
type TwoFARequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

type GetAccountLinkResponse struct {
	Success bool   `json:"success"`
	Code    string `json:"code"`
	Error   string `json:"error"`
}

type GetAccountLinkMetaResponse struct {
	Success   bool   `json:"success"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
	Error     string `json:"error"`
}

type ValidateAuthResponse struct {
	Valid bool `json:"valid"`
}

type Validate2FAAuthResponse struct {
	Valid bool `json:"valid"`
}

type DeleteAccountRequest struct {
	Email string `json:"email"`
}

type DeleteAccountResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

type LinkAccountsRequest struct {
	LinkCode string `json:"link_code"`
}

type LinkAccountsResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

type BaseUserInfo struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
}

type GetAccountClientsResponse struct {
	Success bool           `json:"success"`
	Users   []BaseUserInfo `json:"users"`
	Error   string         `json:"error"`
}

type UnlinkAccountRequest struct {
	OtherEmail string `json:"other_email"`
}

type UnlinkAccountResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

func Mock(lastAuth time.Time, authCode string, linkCode string, twoFACode string, twoFAExpiry time.Time) func() {
	ogCreateAuth := createAuth
	ogGenerateCode := generateCode
	ogGenerate2FACode := generate2FACode
	createAuth = func(email string) (time.Time, string) {
		return lastAuth, authCode
	}
	generateCode = func(length int) string {
		return linkCode
	}
	generate2FACode = func() (string, time.Time) {
		return twoFACode, twoFAExpiry
	}

	return func() {
		createAuth = ogCreateAuth
		generateCode = ogGenerateCode
		generate2FACode = ogGenerate2FACode
	}
}

// Mockable functions

// createAuth generates an authentication code and time of authentication.
var createAuth func(email string) (lastAuth time.Time, authCode string) = _createAuth
var generateCode func(length int) string = util.GenerateCode

// generate2FACode generates a one time code for 2FA
var generate2FACode func() (code string, expiry time.Time) = _generate2FACode

// _generate2FACode is the default implementation of generate2FACode.
func _generate2FACode() (code string, expiry time.Time) {
	code = util.GenerateNumberCode(6)
	expiry = time.Now().Add(twoFACodeExpiry)
	return
}

// _createAuth is the default implementation of createAuth.
func _createAuth(email string) (lastAuth time.Time, authCode string) {
	lastAuth = time.Now()
	authCode = CreateHash(fmt.Sprintf("%v:%v", email, lastAuth.UnixNano()))
	return
}

func salt(password string) []byte {
	return []byte(fmt.Sprintf("%v%v", password, passwordSalt))
}

// CreateHash builds a hash for a password. It uses BCrypt, which provides
// salting automatically.
func CreateHash(password string) string {
	bytes := sha256.Sum256(salt(password))
	return fmt.Sprintf("%x", bytes)
}

// validateHash confirms that a password results in a given hash.
func validateHash(password string, expectedHash string) bool {
	passwordHash := CreateHash(password)
	return strings.Compare(passwordHash, expectedHash) == 0
}

// validateEmail confirms that a given string is, likely, a valid email.
func validateEmail(email string) bool {
	res, _ := regexp.MatchString("^[\\w-\\+\"]+(\\.[\\w-\\+\"]+)*@(\\[[a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)+\\]|[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)+)$", email)
	return res
}

// validatePassword ensures that a given password meets our standards.
func validatePassword(password string) bool {
	return len(password) >= 13 && strings.ContainsAny(password, "@!$#%^&*.[]{}()=+_-|\\/?<>~`'\"") && strings.ContainsAny(password, "abcdefghijklmnopqrstuvwxyz") && strings.ContainsAny(password, "ABCDEFGHIJKLMNOPQRSTUVWXYZ") && strings.ContainsAny(password, "1234567890")
}

// validateAge ensures that a given date of birth confirms the user is at or over
// the minimum age
func validateAge(dob *time.Time, now time.Time) bool {
	return (dob.Year()+minimumAge < now.Year()) || (dob.Year()+minimumAge == now.Year() && dob.Month() < now.Month()) || (dob.Year()+minimumAge == now.Year() && dob.Month() == now.Month() && dob.Day() <= now.Day())
}

// CreateAccount is an echo request handler that grabs request parameters from the JSON
// body of the request, and attempts to create an account.
func CreateAccount(c echo.Context, client *db.PrismaClient) error {
	var request CreateAccountRequest
	err := json.NewDecoder(c.Request().Body).Decode(&request)
	if err != nil {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Failed to decode body"})
	}

	if !validateEmail(request.Email) {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Invalid email"})
	}

	if !(request.AccountType == string(db.UserTypeCaseWorker) || request.AccountType == string(db.UserTypeClient)) {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Invalid account type"})
	}

	if request.AccountType == string(db.UserTypeCaseWorker) {
		domain := request.Email[strings.Index(request.Email, "@"):]
		accepted := false
		for _, acceptableDomain := range acceptableCaseworkerDomains {
			if strings.EqualFold(domain, acceptableDomain) {
				accepted = true
				break
			}
		}
		if !accepted {
			return c.JSON(500, CreateAccountResponse{Success: false, Error: "Invalid caseworker email domain"})
		}
	}

	if !validatePassword(request.Password) {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Invalid password"})
	}

	hash := CreateHash(request.Password)

	if request.AccountType != string(db.UserTypeAdmin) && request.AccountType != string(db.UserTypeCaseWorker) && request.AccountType != string(db.UserTypeClient) {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Invalid account type"})
	}

	// TODO: This work?
	parsedTime, dateErr := util.ParseTime(request.DateOfBirth)
	if dateErr != nil {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Invalid date of birth"})
	}

	if !validateAge(&parsedTime, time.Now()) {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Too young"})
	}

	// If this email is used, abort account creation and send success reponse.
	if strings.Compare(request.Email, testCreateEmail) == 0 {
		fmt.Printf("Testing account creation successful\n")
		return c.JSON(200, CreateAccountResponse{Success: true, Error: ""})
	}

	personalInfo, personalInfoErr := client.PersonalInfo.CreateOne(
		db.PersonalInfo.FirstName.Set(request.FirstName),
		db.PersonalInfo.LastName.Set(request.LastName),
		db.PersonalInfo.Dob.Set(parsedTime),
	).Exec(context.Background())

	if personalInfoErr != nil {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Failed to create personal information"})
	}

	// Create self family member
	if request.AccountType == string(db.UserTypeClient) {
		fam, famErr := client.FamilyMember.CreateOne(
			db.FamilyMember.FirstName.Set(request.FirstName),
			db.FamilyMember.LastName.Set(request.LastName),
			db.FamilyMember.Birthday.Set(parsedTime),
			db.FamilyMember.Ssn.Set("000-00-0000"),
			db.FamilyMember.Gender.Set("Other"),
			db.FamilyMember.Relationship.Set("Self"),
		).Exec(context.Background())
		if famErr != nil {
			return c.JSON(500, CreateAccountResponse{Success: false, Error: "Failed to create self as family member"})
		}

		_, famLinkErr := client.FamilyLink.CreateOne(
			db.FamilyLink.Relationship.Set("Self"),
			db.FamilyLink.PersonalInfo.Link(
				db.PersonalInfo.ID.Equals(personalInfo.ID),
			),
			db.FamilyLink.FamilyMember.Link(
				db.FamilyMember.ID.Equals(fam.ID),
			),
		).Exec(context.Background())
		if famLinkErr != nil {
			return c.JSON(500, CreateAccountResponse{Success: false, Error: "Failed to link self as family member"})
		}
	}

	_, accountErr := client.User.CreateOne(
		db.User.Email.Set(request.Email),
		db.User.PasswordHash.Set(hash),
		db.User.PersonalInfo.Link(
			db.PersonalInfo.ID.Equals(personalInfo.ID),
		),
		db.User.Type.Set(db.UserType(request.AccountType)),
	).Exec(context.Background())

	if accountErr != nil {
		return c.JSON(500, CreateAccountResponse{Success: false, Error: "Failed to create account"})
	}

	return c.JSON(200, CreateAccountResponse{Success: true, Error: ""})
}

func AuthenticateAccount(c echo.Context, client *db.PrismaClient) error {
	var request AuthenticateRequest
	err := json.NewDecoder(c.Request().Body).Decode(&request)
	if err != nil {
		return c.JSON(400, AuthenticateResponse{
			Success:     false,
			Challenge:   false,
			Error:       "Failed to parse parameters",
			AuthToken:   "",
			AccountType: "",
			Email:       "",
		})
	}

	user, userErr := client.User.FindUnique(
		db.User.Email.Equals(request.Email),
	).Exec(context.Background())
	if userErr != nil {
		fmt.Println("User lookup error:", userErr)
		return c.JSON(400, AuthenticateResponse{
			Success:     false,
			Challenge:   false,
			Error:       "Incorrect login",
			AuthToken:   "",
			AccountType: "",
			Email:       "",
		})
	}
	fmt.Println("User found:", user.Email)

	if !validateHash(request.Password, user.PasswordHash) {
		return c.JSON(400, AuthenticateResponse{
			Success:     false,
			Challenge:   false,
			Error:       "Incorrect login",
			AuthToken:   "",
			AccountType: "",
			Email:       "",
		})
	}

	// force 2FA enabled for case workers
	if user.Type == db.UserTypeCaseWorker && !user.TwoFAEnabled {
		_, updateErr := client.User.FindUnique(
			db.User.ID.Equals(user.ID),
		).Update(
			db.User.TwoFAEnabled.Set(true),
		).Exec(context.Background())

		if updateErr != nil {
			fmt.Println("Error enabling 2FA for caseworker:", updateErr)
			return c.JSON(http.StatusInternalServerError, AuthenticateResponse{
				Success:     false,
				Challenge:   false,
				Error:       "Failed to enable 2FA for this account",
				AuthToken:   "",
				AccountType: "",
				Email:       "",
			})
		}

		user.TwoFAEnabled = true
	}

	// 2FA if enabled
	if user.TwoFAEnabled {
		fmt.Println("2FA is enabled, issuing challenge.")
		twoFACode, expiry := generate2FACode()

		_, createErr := client.TwoFactorCode.CreateOne(
			db.TwoFactorCode.User.Link(
				db.User.ID.Equals(user.ID),
			),
			db.TwoFactorCode.Code.Set(twoFACode),
			db.TwoFactorCode.ExpiresAt.Set(expiry),
		).Exec(context.Background())

		if createErr != nil {
			fmt.Println("Error creating 2FA code:", createErr)
			return c.JSON(http.StatusInternalServerError, AuthenticateResponse{
				Success:     false,
				Challenge:   false,
				Error:       "Failed to generate 2FA code",
				AuthToken:   "",
				AccountType: "",
				Email:       "",
			})
		}

		// If it fails, it's fine
		email.Send2FACodeEmail(user.Email, twoFACode)

		if user.Email == "brandnewtestuser2@gmail.com" {
			fmt.Println("Test account login code:", twoFACode)
		}

		// ensure challenge set to true when 2FA is required
		return c.JSON(http.StatusOK, AuthenticateResponse{
			Success:     true,
			Challenge:   true, // triggers the expected 2FA challenge
			Error:       "",
			AuthToken:   "",
			AccountType: string(user.Type),
			Email:       user.Email,
		})
	}

	// upon success, add auth code to user
	lastAuth, authCode := createAuth(user.Email)

	_, updateErr := client.User.FindUnique(
		db.User.ID.Equals(user.ID),
	).Update(
		db.User.AuthCode.Set(authCode),
		db.User.LastAuth.Set(lastAuth),
	).Exec(context.Background())

	if updateErr != nil {
		return c.JSON(400, AuthenticateResponse{
			Success:     false,
			Challenge:   false,
			Error:       "Failed to assign auth code",
			AuthToken:   "",
			AccountType: "",
			Email:       "",
		})
	}

	// Store auth code in cookie
	c.Response().Header().Set(EmailHeaderKey, user.Email)
	c.Response().Header().Set(AuthHeaderKey, authCode)

	return c.JSON(200, AuthenticateResponse{
		Success:     true,
		Challenge:   false,
		Error:       "",
		AuthToken:   authCode,
		AccountType: string(user.Type),
		Email:       user.Email,
	})
}

func ValidateAuth(c echo.Context, client *db.PrismaClient) *db.UserModel {
	auth := c.Request().Header.Get(AuthHeaderKey)
	email := c.Request().Header.Get(EmailHeaderKey)

	user, userErr := client.User.FindFirst(
		db.User.Email.Equals(email),
		db.User.AuthCode.Equals(auth),
	).Exec(context.Background())

	if userErr != nil || user.InnerUser.LastAuth == nil {
		return nil
	}

	expiredTime := user.InnerUser.LastAuth.Add(authExpiresIn)

	if expiredTime.Unix() < time.Now().Unix() {
		return nil
	}

	return user
}

// TODO: working?
func ValidateAuth2FA(email, twoFACode string, client *db.PrismaClient) bool {
	// fetch the user by email, including TwoFactorCodes relation
	user, userErr := client.User.FindUnique(
		db.User.Email.Equals(email),
	).With(
		db.User.TwoFACodes.Fetch(),
	).Exec(context.Background())

	if userErr != nil || len(user.TwoFACodes()) == 0 {
		return false
	}

	// iterate over the 2FA codes to find a valid one
	for _, code := range user.TwoFACodes() {
		if code.ExpiresAt.Before(time.Now()) {
			// delete expired code
			_, deleteErr := client.TwoFactorCode.FindMany(
				db.TwoFactorCode.UserID.Equals(code.UserID),
			).Delete().Exec(context.Background())

			if deleteErr != nil {
				fmt.Println("Failed to delete expired 2FA code:", deleteErr)
			} else {
				fmt.Println("Deleted expired 2FA code:", code.UserID)
			}
			continue
		}

		// check for valid match
		if code.Code == twoFACode {
			fmt.Println("Code matches expected!")

			// delete the used 2FA code
			_, deleteErr := client.TwoFactorCode.FindMany(
				db.TwoFactorCode.UserID.Equals(code.UserID),
			).Delete().Exec(context.Background())

			if deleteErr != nil {
				fmt.Println("Failed to delete used 2FA code:", deleteErr)
			} else {
				fmt.Println("Deleted used 2FA code:", code.UserID)
			}
			return true
		}
	}
	fmt.Println("Code did not match expected!")
	return false
}

func Validate2FAHandler(c echo.Context, client *db.PrismaClient) error {
	var request TwoFARequest
	if err := c.Bind(&request); err != nil {
		return c.JSON(400, map[string]interface{}{
			"success": false,
			"error":   "Invalid request format",
		})
	}

	// check if the provided 2FA code is valid
	isValid := ValidateAuth2FA(request.Email, request.Code, client)

	if isValid {
		// retrieve user from the database
		user, userErr := client.User.FindUnique(
			db.User.Email.Equals(request.Email),
		).Exec(context.Background())
		if userErr != nil {
			fmt.Println("User lookup error:", userErr)
			return c.JSON(400, map[string]interface{}{
				"success": false,
				"error":   "User not found",
			})
		}
		fmt.Println("User found:", user.Email)

		// generate new authentication token after successful 2FA
		lastAuth, token := createAuth(request.Email)
		fmt.Println("Auth code added to user.")

		// update the user's auth code and last authentication timestamp
		_, updateErr := client.User.FindUnique(
			db.User.ID.Equals(user.ID),
		).Update(
			db.User.AuthCode.Set(token),
			db.User.LastAuth.Set(lastAuth),
		).Exec(context.Background())

		if updateErr != nil {
			fmt.Println("Failed to update auth token after 2FA:", updateErr)
			return c.JSON(500, map[string]interface{}{
				"success": false,
				"error":   "Failed to complete 2FA authorization",
			})
		}

		// return the authentication token to the client
		return c.JSON(200, map[string]interface{}{
			"success":    true,
			"auth_token": token,
			"type":       string(user.Type),
		})
	}

	// return an error if the 2FA code is invalid
	return c.JSON(401, map[string]interface{}{
		"success": false,
		"error":   "Invalid 2FA code",
	})
}

func Enable2FAHandler(c echo.Context, client *db.PrismaClient) error {
	email := c.QueryParam("email") // Get email from query params

	if email == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Email is required"})
	}

	user, err := client.User.FindUnique(db.User.Email.Equals(email)).Exec(context.Background())
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "User not found"})
	}

	_, updateErr := client.User.FindUnique(db.User.ID.Equals(user.ID)).
		Update(db.User.TwoFAEnabled.Set(true)).
		Exec(context.Background())

	if updateErr != nil {
		fmt.Println("Prisma update error:", updateErr)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to enable 2FA"})
	}

	fmt.Println("2FA enabled for user:", email) // Print instead of sending an email

	return c.JSON(http.StatusOK, map[string]string{"message": "2FA enabled successfully"})
}

func Disable2FAHandler(c echo.Context, client *db.PrismaClient) error {
	email := c.QueryParam("email") // Get email from query params

	if email == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Email is required"})
	}

	user, err := client.User.FindUnique(db.User.Email.Equals(email)).Exec(context.Background())
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "User not found"})
	}

	_, updateErr := client.User.FindUnique(db.User.ID.Equals(user.ID)).
		Update(db.User.TwoFAEnabled.Set(false)).
		Exec(context.Background())

	if updateErr != nil {
		fmt.Println("Prisma update error:", updateErr)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to disable 2FA"})
	}

	fmt.Println("2FA disabled for user:", email) // Print instead of sending an email

	return c.JSON(http.StatusOK, map[string]string{"message": "2FA disabled successfully"})
}

func Get2FAStatus(c echo.Context, client *db.PrismaClient) error {
	email := c.QueryParam("email") // Get email from query params

	if email == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Email is required"})
	}

	user, err := client.User.FindUnique(db.User.Email.Equals(email)).Exec(context.Background())
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "User not found"})
	}

	return c.JSON(http.StatusOK, map[string]bool{"twoFAEnabled": user.TwoFAEnabled})
}

func ValidateAuthHandler(c echo.Context, client *db.PrismaClient) error {
	if ValidateAuth(c, client) == nil {
		return c.JSON(401, ValidateAuthResponse{Valid: false})
	} else {
		return c.JSON(200, ValidateAuthResponse{Valid: true})
	}
}

func CreateDefaultAccounts(client *db.PrismaClient) {
	userACheck, _ := client.User.FindUnique(
		db.User.Email.Equals("brandnewtestuser@gmail.com"),
	).Exec(context.Background())

	if userACheck == nil {
		personalA, personalErrA := client.PersonalInfo.CreateOne(
			db.PersonalInfo.FirstName.Set("Jane"),
			db.PersonalInfo.LastName.Set("Doe"),
			db.PersonalInfo.Dob.Set(time.Date(2000, time.April, 1, 0, 0, 0, 0, time.UTC)),
		).Exec(context.Background())

		if personalErrA == nil {
			fam, famErr := client.FamilyMember.CreateOne(
				db.FamilyMember.FirstName.Set("Jane"),
				db.FamilyMember.LastName.Set("Doe"),
				db.FamilyMember.Birthday.Set(time.Date(2000, time.April, 1, 0, 0, 0, 0, time.UTC)),
				db.FamilyMember.Ssn.Set("000-00-0000"),
				db.FamilyMember.Gender.Set("Female"),
				db.FamilyMember.Relationship.Set("Self"),
			).Exec(context.Background())
			if famErr == nil {
				_, famLinkErr := client.FamilyLink.CreateOne(
					db.FamilyLink.Relationship.Set("Self"),
					db.FamilyLink.PersonalInfo.Link(
						db.PersonalInfo.ID.Equals(personalA.ID),
					),
					db.FamilyLink.FamilyMember.Link(
						db.FamilyMember.ID.Equals(fam.ID),
					),
				).Exec(context.Background())

				if famLinkErr == nil {
					client.User.CreateOne(
						db.User.Email.Set("brandnewtestuser@gmail.com"),
						db.User.PasswordHash.Set(CreateHash("helloWorld@123")),
						db.User.PersonalInfo.Link(
							db.PersonalInfo.ID.Equals(personalA.ID),
						),
						db.User.Type.Set(db.UserTypeClient),
					).Exec(context.Background())
				}
			}
		}
	}

	userBCheck, _ := client.User.FindUnique(
		db.User.Email.Equals("brandnewtestuser2@gmail.com"),
	).Exec(context.Background())

	if userBCheck == nil {
		personalB, personalErrB := client.PersonalInfo.CreateOne(
			db.PersonalInfo.FirstName.Set("John"),
			db.PersonalInfo.LastName.Set("Smith"),
			db.PersonalInfo.Dob.Set(time.Date(2000, time.April, 1, 0, 0, 0, 0, time.UTC)),
		).Exec(context.Background())

		if personalErrB == nil {
			client.User.CreateOne(
				db.User.Email.Set("brandnewtestuser2@gmail.com"),
				db.User.PasswordHash.Set(CreateHash("helloWorld@123")),
				db.User.PersonalInfo.Link(
					db.PersonalInfo.ID.Equals(personalB.ID),
				),
				db.User.Type.Set(db.UserTypeCaseWorker),
			).Exec(context.Background())
		}
	}
}

func CreateDefaultCWAccount(client *db.PrismaClient) (*db.UserModel, error) {
	personal, personalErr := client.PersonalInfo.CreateOne(
		db.PersonalInfo.FirstName.Set("Case"),
		db.PersonalInfo.LastName.Set("Worker"),
		db.PersonalInfo.Dob.Set(time.Date(2000, time.April, 1, 0, 0, 0, 0, time.UTC)),
	).Exec(context.Background())

	if personalErr != nil {
		return nil, personalErr
	}

	return client.User.CreateOne(
		db.User.Email.Set("caseworker@gmail.com"),
		db.User.PasswordHash.Set(CreateHash("helloWorld@123")),
		db.User.PersonalInfo.Link(
			db.PersonalInfo.ID.Equals(personal.ID),
		),
		db.User.Type.Set(db.UserTypeCaseWorker),
	).Exec(context.Background())
}

func GetAccountLinkCode(c echo.Context, client *db.PrismaClient) error {
	user := ValidateAuth(c, client)
	if user == nil {
		return c.JSON(500, GetAccountLinkResponse{Success: false, Code: "", Error: "Failed to authenticate"})
	}

	link, linkErr := client.UserLinkCode.FindUnique(
		db.UserLinkCode.UserID.Equals(user.ID),
	).Exec(context.Background())

	if linkErr == nil {
		fmt.Printf("Reusing link code: %s\n", link.Code)
		return c.JSON(200, GetAccountLinkResponse{Success: true, Code: link.Code})
	} else {
		code := generateCode(12)
		fmt.Printf("Assigning new link code: %s\n", code)
		_, linkErr := client.UserLinkCode.CreateOne(
			db.UserLinkCode.User.Link(
				db.User.ID.Equals(user.ID),
			),
			db.UserLinkCode.Code.Set(code),
		).Exec(context.Background())

		if linkErr != nil {
			return c.JSON(500, GetAccountLinkResponse{Success: false, Code: "", Error: "Failed to generate link code"})
		}
		return c.JSON(200, GetAccountLinkResponse{Success: true, Code: code})
	}
}

func GetAccountLinkCodeMeta(c echo.Context, client *db.PrismaClient) error {
	user := ValidateAuth(c, client)
	if user == nil {
		return c.JSON(500, GetAccountLinkMetaResponse{Success: false, FirstName: "", LastName: "", Email: "", Error: "Failed to authenticate"})
	}

	if !c.QueryParams().Has(linkCodeQueryParam) {
		return c.JSON(500, GetAccountLinkMetaResponse{Success: false, FirstName: "", LastName: "", Email: "", Error: "No link code included"})
	}

	linkCode := c.QueryParam(linkCodeQueryParam)
	user, userErr := client.User.FindFirst(
		db.User.LinkCode.Where(
			db.UserLinkCode.Code.Equals(linkCode),
		),
	).With(
		db.User.PersonalInfo.Fetch(),
	).Exec(context.Background())

	if userErr != nil {
		return c.JSON(500, GetAccountLinkMetaResponse{Success: false, FirstName: "", LastName: "", Email: "", Error: "Failed to find user with code"})
	}

	info := user.PersonalInfo()
	if info == nil {
		return c.JSON(500, GetAccountLinkMetaResponse{Success: false, FirstName: "", LastName: "", Email: "", Error: "Failed to get user info"})
	}

	return c.JSON(200, GetAccountLinkMetaResponse{Success: true, FirstName: info.FirstName, LastName: info.LastName, Email: user.Email, Error: ""})
}

func DeleteAccount(c echo.Context, client *db.PrismaClient) error {
	var request DeleteAccountRequest
	err := json.NewDecoder(c.Request().Body).Decode(&request)
	if err != nil {
		return c.JSON(http.StatusBadRequest, DeleteAccountResponse{
			Success: false,
			Error:   "Invalid request body",
		})
	}

	fmt.Println("DELETE endpoint hit")
	fmt.Println("DEBUG: Received request to delete account for email:", request.Email)

	// find the user by email (include personal info ID)
	user, userErr := client.User.FindUnique(
		db.User.Email.Equals(request.Email),
	).Exec(context.Background())
	if userErr != nil || user == nil {
		return c.JSON(http.StatusNotFound, DeleteAccountResponse{
			Success: false,
			Error:   "User not found",
		})
	}

	fmt.Println("DEBUG: Found user ID", user.ID, "with personalInfoID", user.PersonalInfoID)

	// delete TwoFactorCodes
	fmt.Println("DEBUG: Deleting TwoFactorCodes...")
	_, err = client.TwoFactorCode.FindMany(
		db.TwoFactorCode.UserID.Equals(user.ID),
	).Delete().Exec(context.Background())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete 2FA codes",
		})
	}

	// delete UserLink (if exists)
	fmt.Println("DEBUG: Deleting UserLink as client...")
	_, err = client.UserLink.
		FindMany(
			db.UserLink.ClientID.Equals(user.ID),
		).
		Delete().
		Exec(context.Background())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete user link as client",
		})
	}

	fmt.Println("DEBUG: Deleting UserLink as caseworker...")
	_, err = client.UserLink.
		FindMany(
			db.UserLink.CaseworkerID.Equals(user.ID),
		).
		Delete().
		Exec(context.Background())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete user link as caseworker",
		})
	}

	// delete FamilyLinks for user's personalInfo (if exists)
	if user.PersonalInfoID != 0 {
		fmt.Println("DEBUG: Deleting FamilyLinks for personalInfoID:", user.PersonalInfoID)
		_, err = client.FamilyLink.FindMany(
			db.FamilyLink.PersonalInfoID.Equals(user.PersonalInfoID),
		).Delete().Exec(context.Background())
		if err != nil {
			return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
				Success: false,
				Error:   "Failed to delete family links",
			})
		}
	}

	fmt.Printf("DEBUG: Deleting UserLink Codes...\n")
	_, err = client.UserLinkCode.FindMany(
		db.UserLinkCode.UserID.Equals(user.ID),
	).Delete().Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to delete UserLinkCodes for user %d: %v\n", user.ID, err)
		return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete user link codes",
		})
	}

	// Delete Family and Application Data
	userWhole, userWholeErr := client.User.FindUnique(
		db.User.ID.Equals(user.ID),
	).With(
		db.User.ApplicationData.Fetch(),
		db.User.PersonalInfo.Fetch().With(
			db.PersonalInfo.FamilyLinks.Fetch().With(
				db.FamilyLink.FamilyMember.Fetch(),
			),
		),
	).Exec(context.Background())
	if userWholeErr != nil || userWhole == nil {
		fmt.Printf("[ERROR] Failed to find user %d: %v\n", user.ID, userWholeErr)
		return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete user account",
		})
	}

	applicationData, hasApplicationData := userWhole.ApplicationData()
	if hasApplicationData {
		_, delResErr := client.ResidenceInfo.FindMany(
			db.ResidenceInfo.CurrentResidence.Where(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
			db.ResidenceInfo.Or(
				db.ResidenceInfo.PreviousResidences.Where(
					db.ApplicationData.ID.Equals(applicationData.ID),
				),
			),
		).Delete().Exec(context.Background())
		if delResErr != nil {
			fmt.Printf("[ERROR] Failed to delete residence info for user %d: %v\n", user.ID, delResErr)
			return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
				Success: false,
				Error:   "Failed to delete residence info",
			})
		}

		_, delCrimeErr := client.CrimeEntry.FindMany(
			db.CrimeEntry.ApplicationID.Equals(applicationData.ID),
		).Delete().Exec(context.Background())
		if delCrimeErr != nil {
			fmt.Printf("[ERROR] Failed to delete crime entries for user %d: %v\n", user.ID, delCrimeErr)
			return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
				Success: false,
				Error:   "Failed to delete crime entries",
			})
		}

		_, rankPrefDelErr := client.HousingPreferenceRanking.FindMany(
			db.HousingPreferenceRanking.ApplicationID.Equals(applicationData.ID),
		).Delete().Exec(context.Background())
		if rankPrefDelErr != nil {
			fmt.Printf("[ERROR] Failed to delete housing preference rankings for user %d: %v\n", user.ID, rankPrefDelErr)
			return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
				Success: false,
				Error:   "Failed to delete housing preference rankings",
			})
		}

		_, incomeDelErr := client.IncomeAssetEntry.FindMany(
			db.IncomeAssetEntry.ApplicationID.Equals(applicationData.ID),
		).Delete().Exec(context.Background())
		if incomeDelErr != nil {
			fmt.Printf("[ERROR] Failed to delete income asset entries for user %d: %v\n", user.ID, incomeDelErr)
			return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
				Success: false,
				Error:   "Failed to delete income asset entries",
			})
		}
	}

	familyLinks := userWhole.PersonalInfo().FamilyLinks()
	linkIds := make([]int, 0, len(familyLinks))
	familyMemberIds := make([]int, 0, len(familyLinks))
	for i, familyLink := range familyLinks {
		linkIds[i] = familyLink.ID
		familyMemberIds[i] = familyLink.FamilyMember().ID
	}
	_, deleteLinksErr := client.FamilyLink.FindMany(
		db.FamilyLink.ID.In(linkIds),
	).Delete().Exec(context.Background())
	if deleteLinksErr != nil {
		fmt.Printf("[ERROR] Failed to delete family links for user %d: %v\n", user.ID, deleteLinksErr)
		return c.JSON(500, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete family links",
		})
	}
	_, deleteFamilyMembersErr := client.FamilyMember.FindMany(
		db.FamilyMember.ID.In(familyMemberIds),
	).Delete().Exec(context.Background())
	if deleteFamilyMembersErr != nil {
		fmt.Printf("[ERROR] Failed to delete family members for user %d: %v\n", user.ID, deleteFamilyMembersErr)
		return c.JSON(500, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete family members",
		})
	}

	_, delAppDataErr := client.ApplicationData.FindUnique(
		db.ApplicationData.ID.Equals(applicationData.ID),
	).Delete().Exec(context.Background())
	if delAppDataErr != nil {
		fmt.Printf("[ERROR] Failed to delete application data for user %d: %v\n", user.ID, delAppDataErr)
		return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete application data",
		})
	}

	// delete the User
	fmt.Println("DEBUG: Deleting User...")
	_, err = client.User.FindUnique(
		db.User.ID.Equals(user.ID),
	).Delete().Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to delete user %d: %v\n", user.ID, err)
		return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
			Success: false,
			Error:   "Failed to delete user account",
		})
	}

	// delete PersonalInfo (after deleting User)
	if user.PersonalInfoID != 0 {
		fmt.Println("DEBUG: Deleting PersonalInfo...")
		_, err = client.PersonalInfo.FindUnique(
			db.PersonalInfo.ID.Equals(user.PersonalInfoID),
		).Delete().Exec(context.Background())
		if err != nil {
			fmt.Println("DEBUG: Failed to delete PersonalInfo:", err)
			return c.JSON(http.StatusInternalServerError, DeleteAccountResponse{
				Success: false,
				Error:   "Failed to delete personal info",
			})
		}
	}

	return c.JSON(http.StatusOK, DeleteAccountResponse{
		Success: true,
		Error:   "",
	})
}

func LinkAccountsHandler(c echo.Context, client *db.PrismaClient) error {
	var request LinkAccountsRequest
	if err := json.NewDecoder(c.Request().Body).Decode(&request); err != nil {
		return c.JSON(500, LinkAccountsResponse{Success: false, Error: "Failed to parse request body"})
	}

	userA := ValidateAuth(c, client)
	if userA == nil {
		return c.JSON(400, LinkAccountsResponse{Success: false, Error: "Failed to authenticate"})
	}

	linkOwner, linkOwnerErr := client.UserLinkCode.FindUnique(
		db.UserLinkCode.Code.Equals(request.LinkCode),
	).With(
		db.UserLinkCode.User.Fetch(),
	).Exec(context.Background())

	if linkOwnerErr != nil {
		return c.JSON(500, LinkAccountsResponse{Success: false, Error: "Failed to find link owner"})
	}

	if userA.Type != db.UserTypeCaseWorker || linkOwner.User().Type != db.UserTypeClient {
		return c.JSON(500, LinkAccountsResponse{Success: false, Error: "Invalid account types"})
	}

	_, userLinkErr := client.UserLink.CreateOne(
		db.UserLink.Client.Link(
			db.User.ID.Equals(linkOwner.User().ID),
		),
		db.UserLink.Caseworker.Link(
			db.User.ID.Equals(userA.ID),
		),
	).Exec(context.Background())

	if userLinkErr != nil {
		return c.JSON(500, LinkAccountsResponse{Success: false, Error: "Failed to link accounts"})
	}

	return c.JSON(200, LinkAccountsResponse{Success: true, Error: ""})
}

func getLinkedClients(client *db.PrismaClient, user *db.UserModel) ([]BaseUserInfo, error) {
	// Fetch clients linked to the caseworker
	clients, err := client.UserLink.FindMany(
		db.UserLink.CaseworkerID.Equals(user.ID),
	).With(
		db.UserLink.Client.Fetch().With(
			db.User.PersonalInfo.Fetch(),
		),
	).Exec(context.Background())

	if err != nil {
		return nil, err
	}

	clientList := make([]BaseUserInfo, len(clients))
	for i, link := range clients {
		clientList[i] = BaseUserInfo{
			FirstName: link.Client().PersonalInfo().FirstName,
			LastName:  link.Client().PersonalInfo().LastName,
			Email:     link.Client().Email,
		}
	}

	return clientList, nil
}

func getLinkedCaseworkers(client *db.PrismaClient, user *db.UserModel) ([]BaseUserInfo, error) {
	// Fetch clients linked to the caseworker
	caseworkers, err := client.UserLink.FindMany(
		db.UserLink.ClientID.Equals(user.ID),
	).With(
		db.UserLink.Caseworker.Fetch().With(
			db.User.PersonalInfo.Fetch(),
		),
	).Exec(context.Background())

	if err != nil {
		return nil, err
	}

	caseworkerList := make([]BaseUserInfo, len(caseworkers))
	for i, link := range caseworkers {
		caseworkerList[i] = BaseUserInfo{
			FirstName: link.Caseworker().PersonalInfo().FirstName,
			LastName:  link.Caseworker().PersonalInfo().LastName,
			Email:     link.Caseworker().Email,
		}
	}

	return caseworkerList, nil
}

func GetAccountConnections(c echo.Context, client *db.PrismaClient) error {
	user := ValidateAuth(c, client)
	if user == nil {
		return c.JSON(400, GetAccountClientsResponse{Success: false, Error: "Failed to authenticate"})
	}

	var userInfos []BaseUserInfo
	var userInfosErr error
	if user.Type == db.UserTypeCaseWorker {
		userInfos, userInfosErr = getLinkedClients(client, user)
	} else if user.Type == db.UserTypeClient {
		userInfos, userInfosErr = getLinkedCaseworkers(client, user)
	} else {
		return c.JSON(500, GetAccountClientsResponse{Success: false, Error: "Invalid user type"})
	}
	if userInfosErr != nil {
		return c.JSON(500, GetAccountClientsResponse{Success: false, Error: fmt.Sprintf("Failed to get linked accounts. %v", userInfosErr)})
	}

	return c.JSON(200, GetAccountClientsResponse{Success: true, Users: userInfos, Error: ""})
}

func UnlinkAccountHandler(c echo.Context, client *db.PrismaClient) error {
	user := ValidateAuth(c, client)
	if user == nil {
		return c.JSON(400, UnlinkAccountResponse{Success: false, Error: "Failed to authenticate"})
	}

	var request UnlinkAccountRequest
	if err := json.NewDecoder(c.Request().Body).Decode(&request); err != nil {
		return c.JSON(500, UnlinkAccountResponse{Success: false, Error: "Failed to parse request body"})
	}

	userUnlink, userUnlinkErr := client.User.FindUnique(
		db.User.Email.Equals(request.OtherEmail),
	).Exec(context.Background())

	if userUnlinkErr != nil {
		return c.JSON(500, UnlinkAccountResponse{Success: false, Error: "Failed to find user to unlink"})
	}

	var caseworkerId int
	var clientId int
	if user.Type == db.UserTypeClient {
		clientId = user.ID
		caseworkerId = userUnlink.ID
	} else if user.Type == db.UserTypeCaseWorker {
		clientId = userUnlink.ID
		caseworkerId = user.ID
	} else {
		return c.JSON(500, UnlinkAccountResponse{Success: false, Error: "Failed to find caseworker account"})
	}

	fmt.Printf("Unlinking accounts: %d, %d\n", caseworkerId, clientId)

	// Find existing link and remove it
	_, linksErr := client.UserLink.FindUnique(
		db.UserLink.UserlinkID(
			db.UserLink.ClientID.Equals(clientId),
			db.UserLink.CaseworkerID.Equals(caseworkerId),
		),
	).Delete().Exec(context.Background())

	if linksErr != nil {
		return c.JSON(500, UnlinkAccountResponse{Success: false, Error: fmt.Sprintf("Failed to unlink accounts. %v", linksErr)})
	}

	return c.JSON(200, UnlinkAccountResponse{Success: true, Error: ""})
}
