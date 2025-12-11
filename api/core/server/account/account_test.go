package account

// Account related unit tests

import (
	testutil "api/core/test_util"
	"api/core/util"
	"api/db"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/labstack/echo"
	"github.com/stretchr/testify/assert"
)

var mock_lastAuth = time.Now()
var mock_authCode = CreateHash(fmt.Sprintf("%v:%v", "test@gmail.com", mock_lastAuth.UnixNano()))
var mock_personalDataA = db.PersonalInfoModel{
	InnerPersonalInfo: db.InnerPersonalInfo{
		ID:        1,
		FirstName: "Jane",
		LastName:  "Doe",
		Dob:       time.Date(2000, time.April, 1, 0, 0, 0, 0, time.UTC),
	},
}
var mock_userA = db.UserModel{
	InnerUser: db.InnerUser{
		ID:             1,
		Email:          "test@gmail.com",
		PasswordHash:   "2a080412df038de523a12c302b5ce04ce8caf7c2d92ac89779b1332843d17c14", // helloWorld@123
		LastAuth:       nil,
		AuthCode:       nil,
		Type:           db.UserTypeClient,
		TwoFAEnabled:   false, //added fields for 2fa
		PersonalInfoID: mock_personalDataA.ID,
	},
	RelationsUser: db.RelationsUser{},
}
var mock_linkCode = "abcdefghijkl"
var mock_2faCode = "123456"
var mock_2faExpiry = time.Now().Add(time.Hour * 50)

// setup initializes state for running unit tests,
// then returns a function pointer for teardown
func setup() func() {
	accountMockTeardown := Mock(mock_lastAuth, mock_authCode, mock_linkCode, mock_2faCode, mock_2faExpiry)

	return func() {
		accountMockTeardown()
	}
}

// createAccount forms an http test on the CreateAccount endpoint and
// asserts the expected results
func createAccount(t *testing.T, email string, password string, firstName string, lastName string, dob string, accountType string, expectedCode int, expectedResult CreateAccountResponse) {
	jsonData, jsonErr := json.Marshal(CreateAccountRequest{
		Email:       email,
		Password:    password,
		FirstName:   firstName,
		LastName:    lastName,
		DateOfBirth: dob,
		AccountType: accountType,
	})
	assert.NoError(t, jsonErr, "Failed to encode json request")

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/api/account/create", strings.NewReader(string(jsonData)))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	client, mock, ensure := db.NewMock()

	if expectedCode == 200 {
		defer ensure(t)
		parsedTime, _ := util.ParseTime(dob)
		passwordHash := CreateHash(password)
		userPersonalInfo := db.PersonalInfoModel{
			InnerPersonalInfo: db.InnerPersonalInfo{
				ID:        1,
				FirstName: firstName,
				LastName:  lastName,
				Dob:       parsedTime,
			},
		}
		user := db.UserModel{
			InnerUser: db.InnerUser{
				ID:             1,
				Email:          email,
				PasswordHash:   passwordHash,
				LastAuth:       nil,
				AuthCode:       nil,
				Type:           db.UserType(accountType),
				TwoFAEnabled:   false,
				PersonalInfoID: userPersonalInfo.ID,
			},
		}
		fam := db.FamilyMemberModel{
			InnerFamilyMember: db.InnerFamilyMember{
				ID:        1,
				FirstName: firstName,
				LastName:  lastName,
				Birthday:       parsedTime,
				Relationship: "Self",
				Gender: "Other",
				Ssn: "000-00-0000",
			},
		}
		famLink := db.FamilyLinkModel{
			InnerFamilyLink: db.InnerFamilyLink{
				PersonalInfoID: userPersonalInfo.ID,
				FamilyMemberID: fam.ID,
			},
			RelationsFamilyLink: db.RelationsFamilyLink{
				PersonalInfo:           &userPersonalInfo,
				FamilyMember: &fam,
			},
		}

		// CreateOne Personal Data
		mock.PersonalInfo.Expect(
			client.PersonalInfo.CreateOne(
				db.PersonalInfo.FirstName.Set(firstName),
				db.PersonalInfo.LastName.Set(lastName),
				db.PersonalInfo.Dob.Set(parsedTime),
			),
		).Returns(userPersonalInfo)

		mock.FamilyMember.Expect(
			client.FamilyMember.CreateOne(
				db.FamilyMember.FirstName.Set(firstName),
				db.FamilyMember.LastName.Set(lastName),
				db.FamilyMember.Birthday.Set(parsedTime),
				db.FamilyMember.Ssn.Set("000-00-0000"),
				db.FamilyMember.Gender.Set("Other"),
				db.FamilyMember.Relationship.Set("Self"),
			),
		).Returns(fam)

		mock.FamilyLink.Expect(
			client.FamilyLink.CreateOne(
				db.FamilyLink.Relationship.Set("Self"),
				db.FamilyLink.PersonalInfo.Link(
					db.PersonalInfo.ID.Equals(userPersonalInfo.ID),
				),
				db.FamilyLink.FamilyMember.Link(
					db.FamilyMember.ID.Equals(fam.ID),
				),
			),
		).Returns(famLink)

		// CreateOne User
		mock.User.Expect(
			client.User.CreateOne(
				db.User.Email.Set(email),
				db.User.PasswordHash.Set(passwordHash),
				db.User.PersonalInfo.Link(
					db.PersonalInfo.ID.Equals(userPersonalInfo.ID),
				),
				db.User.Type.Set(db.UserType(accountType)),
			),
		).Returns(user)
	}

	createErr := CreateAccount(c, client)
	assert.NoError(t, createErr, "Failed to create account")
	assert.Equal(t, expectedCode, rec.Code, "Bad status code")

	resData, _ := json.Marshal(expectedResult)
	assert.Equal(t, string(resData)+"\n", rec.Body.String(), "Bad return body")
}

// TestCreateAccounts tries to create a number of accounts and
// checks the responses from the endpoint.
func TestCreateAccounts(t *testing.T) {
	createAccount(t, "hunterbarclay@u.boisestate.edu", "hellowWrld@123", "Hunter", "Barclay", "2002-12-18", "CLIENT", 200, CreateAccountResponse{Success: true, Error: ""})
	createAccount(t, "hunterbarclay@u.boisestate.edu", "hellowWrld", "Hunter", "Barclay", "2002-12-18", "CLIENT", 500, CreateAccountResponse{Success: false, Error: "Invalid password"})
	createAccount(t, "hunterbarclay@u.boises@tate.edu", "hellowWrld@123", "Hunter", "Barclay", "2002-12-18", "CLIENT", 500, CreateAccountResponse{Success: false, Error: "Invalid email"})
	createAccount(t, "hunterbarclay@u.boisestate.edu", "hellowWrld@123", "Hunter", "Barclay", "2022-12-18", "CLIENT", 500, CreateAccountResponse{Success: false, Error: "Too young"})
}

// TestValidateEmails tests a number of valid and invalid emails
// against the email validator.
func TestValidateEmail(t *testing.T) {
	validEmails := [...]string{
		"email@example.com",
		"firstname.lastname@example.com",
		"email@subdomain.example.com",
		"firstname+lastname@example.com",
		"email@123.123.123.123",
		"email@[123.123.123.123]",
		"\"email\"@example.com",
		"1234567890@example.com",
		"email@example-one.com",
		"_______@example.com",
		"email@example.name",
		"email@example.museum",
		"email@example.co.jp",
		"firstname-lastname@example.com",
	}

	invalidEmails := [...]string{
		"plainaddress",
		"#@%^%#$@#$@#.com",
		"@example.com",
		"Joe Smith <email@example.com>",
		"email.example.com",
		"email@example@example.com",
		".email@example.com",
		"email.@example.com",
		"email..email@example.com",
		"あいうえお@example.com",
		"email@example.com (Joe Smith)",
		"email@example",
		"email@example..com",
		"Abc..123@example.com",
	}

	for _, email := range validEmails {
		assert.True(t, validateEmail(email), fmt.Sprintf("Valid email didn't correctly validate: %v", email))
	}

	for _, email := range invalidEmails {
		assert.False(t, validateEmail(email), fmt.Sprintf("Invalid email were deemed valid: %v", email))
	}
}

// TestValidatePassword tests number of valid and invalid passwords against
// the password validator. For the invalid passwords, I copied like 10 random
// passwords from rockyou.txt.
func TestValidatePassword(t *testing.T) {
	validPasswords := [...]string{
		"5R.d5P$UWwGZ[",
		"-TWa3geBK6WNt",
		"HH@Uqh{BQ.=E2",
		"dbrFc(.hB2n=n",
		"k%Py3{.>]Pdzf",
		"hbcsVpvqk%$V9",
		"?K]3A*hNk9{/v",
		"AN?xc>C)5NjcL",
		"H9s/+ghX5Hwq^",
		"bS*Bjx*54.A6Z",
	}

	invalidPasswords := [...]string{
		"12345678",
		"abc123",
		"nicole",
		"daniel",
		"babygirl",
		"monkey",
		"lovely",
		"jessica",
		"654321",
		"michael",
		"ashley",
		"qwerty",
		"111111",
		"iloveu",
	}

	for _, password := range validPasswords {
		assert.True(t, validatePassword(password), fmt.Sprintf("Valid password didn't correctly validate: %v", password))
	}

	for _, password := range invalidPasswords {
		assert.False(t, validatePassword(password), fmt.Sprintf("Invalid password was deemed valid: %v", password))
	}
}

func TestParseTime(t *testing.T) {
	parsedTime, err := util.ParseTime("1995-03-14")
	assert.NoError(t, err, "Error while parsing time")
	year, month, day := parsedTime.Date()
	assert.Equal(t, 1995, year, "Year is incorrect")
	assert.Equal(t, month, time.March, "Month is incorrect")
	assert.Equal(t, day, 14, "Day is incorrect")
}

// TestValidateAge tests a number of birth dates against the age validator.
func TestValidateAge(t *testing.T) {
	dob := time.Date(2002, 12, 18, 0, 0, 0, 0, time.UTC)
	nowA := dob.AddDate(18, 0, 0)
	nowB := dob.AddDate(17, 11, 20)
	nowC := dob.AddDate(18, 0, 1)
	assert.True(t, validateAge(&dob, nowA), "Failed to validate nowA")
	assert.False(t, validateAge(&dob, nowB), "Failed to invalidate nowB")
	assert.True(t, validateAge(&dob, nowC), "Failed to validate nowC")

	nowD := time.Date(2020, 12, 18, 0, 0, 0, 0, time.UTC)
	nowE := time.Date(2020, 12, 17, 23, 59, 59, 0, time.UTC)
	assert.True(t, validateAge(&dob, nowD), "Failed to validate nowD")
	assert.False(t, validateAge(&dob, nowE), "Failed to invalidate nowE")
}

func TestPasswordHash(t *testing.T) {
	passwords := [...]string{
		"helloWorld@123",
		"-TWa3geBK6WNt",
		"HH@Uqh{BQ.=E2",
		"dbrFc(.hB2n=n",
		"k%Py3{.>]Pdzf",
		"hbcsVpvqk%$V9",
		"?K]3A*hNk9{/v",
		"AN?xc>C)5NjcL",
		"H9s/+ghX5Hwq^",
		"bS*Bjx*54.A6Z",
	}

	for _, password := range passwords {
		hash := CreateHash(password)
		fmt.Printf("%v\n", hash)
		assert.True(t, validateHash(password, hash), "Password hash invalid")
		assert.False(t, validateHash(password, hash+"1"), "Failed to invalidate hash")
	}
}

func TestAuthAccount(t *testing.T) {
	teardown := setup()
	defer teardown()

	client, mock, ensure := db.NewMock()
	defer ensure(t)

	reqGood := AuthenticateRequest{
		Email:    mock_userA.Email,
		Password: "helloWorld@123",
	}
	reqBad := AuthenticateRequest{
		Email:    mock_userA.Email,
		Password: "helloWorld123",
	}

	// user without 2FA enabled
	userPreAuth := mock_userA
	userPostAuth := mock_userA
	userPostAuth.InnerUser.LastAuth = &mock_lastAuth
	userPostAuth.InnerUser.AuthCode = &mock_authCode

	mock.User.Expect(
		client.User.FindUnique(
			db.User.Email.Equals(userPreAuth.InnerUser.Email),
		),
	).Returns(userPreAuth)
	mock.User.Expect(
		client.User.FindUnique(
			db.User.ID.Equals(userPreAuth.InnerUser.ID),
		).Update(
			db.User.AuthCode.Set(mock_authCode),
			db.User.LastAuth.Set(mock_lastAuth),
		),
	).Returns(userPostAuth)

	// test auth without 2FA & correct password
	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodPost, "/api/account/auth", reqGood)
	assert.NoError(t, reqErr, "Failed to prepare request")
	authErr := AuthenticateAccount(c, client)
	assert.NoError(t, authErr, "Error while authenticating")

	var authResponse AuthenticateResponse
	assert.Equal(t, 200, rec.Code, "Bad status code")
	resGood := rec.Result()
	defer resGood.Body.Close()

	emailHeader := resGood.Header.Get(EmailHeaderKey)
	authHeader := resGood.Header.Get(AuthHeaderKey)

	assert.NotEmpty(t, authHeader, "No auth cookie found")
	assert.NotEmpty(t, emailHeader, "No email cookie found")
	assert.Equal(t, *userPostAuth.InnerUser.AuthCode, authHeader, "Invalid authcode cookie value")
	assert.Equal(t, userPostAuth.InnerUser.Email, emailHeader, "Invalid email cookie value")
	jsonResErr := json.Unmarshal(rec.Body.Bytes(), &authResponse)
	assert.NoError(t, jsonResErr, "Failed to parse response body")
	assert.True(t, authResponse.Success, "Unsuccessful in Authentication")
	assert.False(t, authResponse.Challenge, "Challenged when it wasn't supposed to")
	assert.Empty(t, authResponse.Error, "Error was given")

	// authentication with incorrect password
	rec, c, reqErr = testutil.PrepareRequestJSON(http.MethodPost, "/api/account/auth", reqBad)
	assert.NoError(t, reqErr, "Failed to prepare request")
	authErr = AuthenticateAccount(c, client)
	assert.NoError(t, authErr, "Error while authenticating")

	assert.Equal(t, 400, rec.Code, "Bad status code")
	resBad := rec.Result()
	defer resBad.Body.Close()

	emailHeader = resBad.Header.Get(EmailHeaderKey)
	authHeader = resBad.Header.Get(AuthHeaderKey)

	assert.Empty(t, emailHeader, "Invalid email header")
	assert.Empty(t, authHeader, "Invalid auth header")

	jsonResErr = json.Unmarshal(rec.Body.Bytes(), &authResponse)

	assert.NoError(t, jsonResErr, "Failed to parse resonse body")
	assert.False(t, authResponse.Success, "Successful in Authentication")
	assert.False(t, authResponse.Challenge, "Challenged when it wasn't suppose to")
	assert.Equal(t, "Incorrect login", authResponse.Error, "Incorrect error message")
}

func TestValidateAuth(t *testing.T) {
	teardown := setup()
	defer teardown()

	// client := db.NewClient()
	client, mock, ensure := db.NewMock()
	defer ensure(t)

	expiredTime := time.Unix(0, time.Now().UnixNano()-int64(authExpiresIn)-int64(time.Second))
	expiredAuthCode := CreateHash(fmt.Sprintf("%v:%v", mock_userA.Email, expiredTime.UnixNano()))

	userA := mock_userA
	userA.InnerUser.LastAuth = &mock_lastAuth
	userA.InnerUser.AuthCode = &mock_authCode
	userB := mock_userA
	userB.InnerUser.LastAuth = &expiredTime
	userB.InnerUser.AuthCode = &expiredAuthCode

	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userA.InnerUser.Email),
			db.User.AuthCode.Equals(*userA.InnerUser.AuthCode),
		),
	).Returns(userA)

	_, c, reqErr := testutil.PrepareRequestJSON(http.MethodPost, "/api/account/auth", true)
	c.Request().Header.Set(EmailHeaderKey, userA.InnerUser.Email)
	c.Request().Header.Set(AuthHeaderKey, *userA.InnerUser.AuthCode)
	assert.NoError(t, reqErr, "Failed to prepare request")
	assert.NotNil(t, ValidateAuth(c, client), "Unable to validate request")

	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userB.InnerUser.Email),
			db.User.AuthCode.Equals(*userB.InnerUser.AuthCode),
		),
	).Returns(userB)

	_, c, reqErr = testutil.PrepareRequestJSON(http.MethodPost, "/api/account/auth", true)
	assert.NoError(t, reqErr, "Failed to prepare request")
	c.Request().Header.Set(EmailHeaderKey, userB.InnerUser.Email)
	c.Request().Header.Set(AuthHeaderKey, *userB.InnerUser.AuthCode)
	assert.Nil(t, ValidateAuth(c, client), "Able to validate request")

	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals("fake@email.com"),
			db.User.AuthCode.Equals(""),
		),
	).Errors(fmt.Errorf("No user found"))

	_, c, reqErr = testutil.PrepareRequestJSON(http.MethodGet, "/api/account/auth", true)
	assert.NoError(t, reqErr, "Failed to prepare request")
	c.Request().Header.Set(EmailHeaderKey, "fake@email.com")
	c.Request().Header.Set(AuthHeaderKey, "")
	assert.Nil(t, ValidateAuth(c, client), "Able to validate request")
}

func TestGetAccountLinkExisting(t *testing.T) {
	teardown := setup()
	defer teardown()

	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userA := mock_userA
	userA.InnerUser.LastAuth = &mock_lastAuth
	userA.InnerUser.AuthCode = &mock_authCode
	userALinkCode := db.UserLinkCodeModel{
		InnerUserLinkCode: db.InnerUserLinkCode{
			UserID: userA.ID,
			Code:   mock_linkCode,
		},
	}
	userA.RelationsUser = db.RelationsUser{
		LinkCode: &userALinkCode,
	}

	// Mock auth validation
	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userA.Email),
			db.User.AuthCode.Equals(*userA.InnerUser.AuthCode),
		),
	).Returns(userA)

	// Mock find userlink
	mock.UserLinkCode.Expect(
		client.UserLinkCode.FindUnique(
			db.UserLinkCode.UserID.Equals(userA.ID),
		),
	).Returns(userALinkCode)

	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodGet, "/api/account/link", true)
	assert.NoError(t, reqErr, "Failed to prepare request")
	c.Request().Header.Set(EmailHeaderKey, userA.InnerUser.Email)
	c.Request().Header.Set(AuthHeaderKey, *userA.InnerUser.AuthCode)
	GetAccountLinkCode(c, client)

	assert.Equal(t, 200, rec.Code, "Bad status code")
	var response GetAccountLinkResponse
	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, unmarshalErr, "Error while parsing response body")

	assert.Empty(t, response.Error, "Error message found")
	assert.True(t, response.Success, "Unsuccessful")
	assert.Equal(t, mock_linkCode, response.Code)
}

func TestGetAccountLinkMissing(t *testing.T) {
	teardown := setup()
	defer teardown()

	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userAPre := mock_userA
	userAPre.InnerUser.LastAuth = &mock_lastAuth
	userAPre.InnerUser.AuthCode = &mock_authCode
	userAPost := userAPre
	userAPost.RelationsUser = db.RelationsUser{
		LinkCode: &db.UserLinkCodeModel{
			InnerUserLinkCode: db.InnerUserLinkCode{
				UserID: userAPost.ID,
				Code:   mock_linkCode,
			},
		},
	}

	// Mock auth validation
	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userAPre.Email),
			db.User.AuthCode.Equals(*userAPre.InnerUser.AuthCode),
		),
	).Returns(userAPre)

	// Mock find userlink
	mock.UserLinkCode.Expect(
		client.UserLinkCode.FindUnique(
			db.UserLinkCode.UserID.Equals(userAPre.ID),
		),
	).Errors(fmt.Errorf("No userlink found for user id %d", userAPre.ID))

	mock.UserLinkCode.Expect(
		client.UserLinkCode.CreateOne(
			db.UserLinkCode.User.Link(
				db.User.ID.Equals(userAPre.ID),
			),
			db.UserLinkCode.Code.Set(mock_linkCode),
		),
	).Returns(*userAPost.RelationsUser.LinkCode)

	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodGet, "/api/account/link", true)
	assert.NoError(t, reqErr, "Failed to prepare request")
	c.Request().Header.Set(EmailHeaderKey, userAPre.InnerUser.Email)
	c.Request().Header.Set(AuthHeaderKey, *userAPre.InnerUser.AuthCode)
	GetAccountLinkCode(c, client)

	assert.Equal(t, 200, rec.Code, "Bad status code")
	var response GetAccountLinkResponse
	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, unmarshalErr, "Error while parsing response body")

	assert.Empty(t, response.Error, "Error message found")
	assert.True(t, response.Success, "Unsuccessful")
	assert.Equal(t, mock_linkCode, response.Code)
}

// TestGenerate2FA tests generating a 2FA authentication code.     PASS
func TestGenerate2FA(t *testing.T) {
	code, _ := _generate2FACode()
	assert.Len(t, code, 6, "Generated 2FA code should be 6 digits long")
}

// TestSend2FACode tests that Send2FACode works as expected    // PASS
func TestSend2FACode(t *testing.T) {
	// create a mock server
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// verify request method
		if r.Method != http.MethodPost {
			t.Errorf("expected POST request, got %s", r.Method)
		}

		// verify query parameters
		email := r.URL.Query().Get("email")
		code := r.URL.Query().Get("code")
		if email != "test@example.com" || code != "123456" {
			t.Errorf("unexpected query params: email=%s, code=%s", email, code)
		}

		// return success response
		w.WriteHeader(http.StatusOK)
	}))
	defer mockServer.Close()

	// override the function to use the test server URL
	send2FACode := func(email, code string) error {
		req, err := http.NewRequest("POST", mockServer.URL, nil)
		if err != nil {
			return err
		}

		q := req.URL.Query()
		q.Add("email", email)
		q.Add("code", code)
		req.URL.RawQuery = q.Encode()

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			return err
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			return fmt.Errorf("failed to send 2FA email")
		}
		return nil
	}

	// run test
	err := send2FACode("test@example.com", "123456")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
}

// TestValidate2FA tests validating a correct, incorrect, and expired 2FA code.
// query expectation error
func TestValidateAuth2FA(t *testing.T) {
	validTwoFACode := "123456"
	invalidCode := "654321"
	createdTime := time.Now()
	expiryTime := createdTime.Add(5 * time.Minute)

	// test valid code
	client, mock, ensure := db.NewMock()

	userValid := mock_userA
	userValid.TwoFAEnabled = true
	mockCode := db.TwoFactorCodeModel{
		InnerTwoFactorCode: db.InnerTwoFactorCode{
			UserID:    userValid.ID,
			Code:      validTwoFACode,
			ExpiresAt: expiryTime,
			CreatedAt: createdTime,
		},
	}
	userValid.RelationsUser.TwoFACodes = []db.TwoFactorCodeModel{mockCode}

	mock.User.Expect(
		client.User.FindUnique(
			db.User.Email.Equals(userValid.Email),
		).With(
			db.User.TwoFACodes.Fetch(),
		),
	).Returns(userValid)

	mock.TwoFactorCode.Expect(
		client.TwoFactorCode.FindMany(
			db.TwoFactorCode.UserID.Equals(userValid.ID),
		).Delete(),
	).Returns(mockCode)

	assert.True(t, ValidateAuth2FA(userValid.Email, validTwoFACode, client), "Valid 2FA code should pass")
	ensure(t)

	// invalid code
	client, mock, ensure = db.NewMock()

	userInvalid := mock_userA
	userInvalid.TwoFAEnabled = true
	userInvalid.RelationsUser.TwoFACodes = []db.TwoFactorCodeModel{mockCode} // same code, test mismatch

	mock.User.Expect(
		client.User.FindUnique(
			db.User.Email.Equals(userInvalid.Email),
		).With(
			db.User.TwoFACodes.Fetch(),
		),
	).Returns(userInvalid)

	assert.False(t, ValidateAuth2FA(userInvalid.Email, invalidCode, client), "Invalid 2FA code should fail")
	ensure(t)

	// expired code
	client, mock, ensure = db.NewMock()

	userExpired := mock_userA
	userExpired.TwoFAEnabled = true
	expiredCode := db.TwoFactorCodeModel{
		InnerTwoFactorCode: db.InnerTwoFactorCode{
			UserID:    userExpired.ID,
			Code:      validTwoFACode,
			ExpiresAt: time.Now().Add(-5 * time.Minute), // expired
			CreatedAt: createdTime,
		},
	}
	userExpired.RelationsUser.TwoFACodes = []db.TwoFactorCodeModel{expiredCode}

	mock.User.Expect(
		client.User.FindUnique(
			db.User.Email.Equals(userExpired.Email),
		).With(
			db.User.TwoFACodes.Fetch(),
		),
	).Returns(userExpired)

	mock.TwoFactorCode.Expect(
		client.TwoFactorCode.FindMany(
			db.TwoFactorCode.UserID.Equals(userExpired.ID),
		).Delete(),
	).Returns(expiredCode)

	assert.False(t, ValidateAuth2FA(userExpired.Email, validTwoFACode, client), "Expired 2FA code should fail")
	ensure(t)
}

// // TestAuthAcc2FA tests that account authorization works with 2FA enabled
// // separated from TestAuthAccount because mocks were overlapping and causing failures
func TestAuthAcc2FA(t *testing.T) {
	teardown := setup()
	defer teardown()

	client, mock, ensure := db.NewMock()
	defer ensure(t)

	reqGood := AuthenticateRequest{
		Email:    mock_userA.Email,
		Password: "helloWorld@123",
	}

	// user with 2FA enabled
	user2FA := mock_userA
	user2FA.InnerUser.TwoFAEnabled = true

	// Find User
	mock.User.Expect(
		client.User.FindUnique(
			db.User.Email.Equals(user2FA.InnerUser.Email),
		),
	).Returns(user2FA)

	code := db.TwoFactorCodeModel{
		InnerTwoFactorCode: db.InnerTwoFactorCode{
			UserID:    user2FA.ID,
			Code:      mock_2faCode,
			ExpiresAt: mock_2faExpiry, // Expired.
			CreatedAt: time.Now(),
		},
	}

	// Create 2fa code
	mock.TwoFactorCode.Expect(
		client.TwoFactorCode.CreateOne(
			db.TwoFactorCode.User.Link(
				db.User.ID.Equals(user2FA.ID),
			),
			db.TwoFactorCode.Code.Set(mock_2faCode),
			db.TwoFactorCode.ExpiresAt.Set(mock_2faExpiry),
		),
	).Returns(code)

	var jsonResErr error
	var authResponse AuthenticateResponse
	// test auth with 2FA enabled
	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodPost, "/api/account/auth", reqGood)
	assert.NoError(t, reqErr, "Failed to prepare request")
	authErr := AuthenticateAccount(c, client)
	assert.NoError(t, authErr, "Error while authenticating")

	assert.Equal(t, 200, rec.Code, "Bad status code")
	res2FA := rec.Result()
	defer res2FA.Body.Close()

	jsonResErr = json.Unmarshal(rec.Body.Bytes(), &authResponse)
	assert.NoError(t, jsonResErr, "Failed to parse response body")
	assert.True(t, authResponse.Success, "Unsuccessful in Authentication")
	assert.True(t, authResponse.Challenge, "2FA Challenge was not issued when expected")
	assert.Empty(t, authResponse.Error, "Error was given when not expected")
}

func TestLinkAccounts(t *testing.T) {
	teardown := setup()
	defer teardown()

	// client := db.NewClient()
	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userClient := mock_userA
	userCaseworker := mock_userA
	userCaseworker.InnerUser.ID = 2
	userCaseworker.InnerUser.LastAuth = &mock_lastAuth
	userCaseworker.InnerUser.AuthCode = &mock_authCode
	userCaseworker.InnerUser.Type = db.UserTypeCaseWorker

	clientLinkCode := db.UserLinkCodeModel{
		InnerUserLinkCode: db.InnerUserLinkCode{
			UserID: userClient.ID,
			Code:   mock_linkCode,
		},
		RelationsUserLinkCode: db.RelationsUserLinkCode{
			User: &userClient,
		},
	}
	// userClient.RelationsUser.LinkCode = &clientLinkCode

	userLink := db.UserLinkModel{
		InnerUserLink: db.InnerUserLink{
			ClientID:     userClient.ID,
			CaseworkerID: userCaseworker.ID,
		},
		RelationsUserLink: db.RelationsUserLink{},
	}

	// Mock auth
	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userCaseworker.InnerUser.Email),
			db.User.AuthCode.Equals(*userCaseworker.InnerUser.AuthCode),
		),
	).Returns(userCaseworker)

	// Mock find userlink code
	mock.UserLinkCode.Expect(
		client.UserLinkCode.FindUnique(
			db.UserLinkCode.Code.Equals(mock_linkCode),
		).With(
			db.UserLinkCode.User.Fetch(),
		),
	).Returns(clientLinkCode)

	// Mock create user link
	mock.UserLink.Expect(
		client.UserLink.CreateOne(
			db.UserLink.Client.Link(
				db.User.ID.Equals(userClient.ID),
			),
			db.UserLink.Caseworker.Link(
				db.User.ID.Equals(userCaseworker.ID),
			),
		),
	).Returns(userLink)

	request := LinkAccountsRequest{
		LinkCode: mock_linkCode,
	}

	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodPost, "/api/account/link", request)
	c.Request().Header.Set(EmailHeaderKey, userCaseworker.InnerUser.Email)
	c.Request().Header.Set(AuthHeaderKey, *userCaseworker.InnerUser.AuthCode)
	assert.NoError(t, reqErr, "Failed to prepare request")
	assert.NoError(t, LinkAccountsHandler(c, client), "Error while creating link")
	assert.Equal(t, 200, rec.Code, "Bad status code")

	var response LinkAccountsResponse
	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, unmarshalErr, "Error while parsing response body")

	assert.Empty(t, response.Error, "Error message found")
	assert.True(t, response.Success, "Unsuccessful")
}

func TestGetAccountClients(t *testing.T) {
	teardown := setup()
	defer teardown()

	// client := db.NewClient()
	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userCaseworker := mock_userA
	userCaseworker.InnerUser.LastAuth = &mock_lastAuth
	userCaseworker.InnerUser.AuthCode = &mock_authCode
	userCaseworker.InnerUser.Type = db.UserTypeCaseWorker

	userClient := mock_userA
	userClient.InnerUser.ID = 2
	userClient.RelationsUser = db.RelationsUser{
		PersonalInfo: &mock_personalDataA,
	}

	userLink := db.UserLinkModel{
		InnerUserLink: db.InnerUserLink{
			ClientID:     userClient.ID,
			CaseworkerID: userCaseworker.ID,
		},
		RelationsUserLink: db.RelationsUserLink{
			Client: &userClient,
		},
	}

	// Mock auth
	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userCaseworker.InnerUser.Email),
			db.User.AuthCode.Equals(*userCaseworker.InnerUser.AuthCode),
		),
	).Returns(userCaseworker)

	// Mock find userlink code
	mock.UserLink.Expect(
		client.UserLink.FindMany(
			db.UserLink.CaseworkerID.Equals(userCaseworker.ID),
		).With(
			db.UserLink.Client.Fetch().With(
				db.User.PersonalInfo.Fetch(),
			),
		),
	).ReturnsMany([]db.UserLinkModel{userLink})

	rec, c, reqErr := testutil.PrepareRequestParams(http.MethodPost, "/api/account/link", nil)
	c.Request().Header.Set(EmailHeaderKey, userCaseworker.InnerUser.Email)
	c.Request().Header.Set(AuthHeaderKey, *userCaseworker.InnerUser.AuthCode)
	assert.NoError(t, reqErr, "Failed to prepare request")
	assert.NoError(t, GetAccountConnections(c, client), "Error while getting clients")
	assert.Equal(t, 200, rec.Code, "Bad status code")

	var response GetAccountClientsResponse
	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, unmarshalErr, "Error while parsing response body")

	assert.Empty(t, response.Error, "Error message found")
	assert.True(t, response.Success, "Unsuccessful")
	assert.Len(t, response.Users, 1, "Incorrect number of clients found")
	assert.Equal(t, userClient.InnerUser.Email, response.Users[0].Email, "Incorrect client ID found")
	assert.Equal(t, userClient.RelationsUser.PersonalInfo.FirstName, response.Users[0].FirstName, "Incorrect client first name found")
	assert.Equal(t, userClient.RelationsUser.PersonalInfo.LastName, response.Users[0].LastName, "Incorrect client last name found")
}

func TestUnlinkAccount(t *testing.T) {
	teardown := setup()
	defer teardown()

	// client := db.NewClient()
	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userCaseworker := mock_userA
	userCaseworker.InnerUser.LastAuth = &mock_lastAuth
	userCaseworker.InnerUser.AuthCode = &mock_authCode
	userCaseworker.InnerUser.Type = db.UserTypeCaseWorker

	userClient := mock_userA
	userClient.InnerUser.ID = 2
	userClient.RelationsUser = db.RelationsUser{
		PersonalInfo: &mock_personalDataA,
	}

	userLink := db.UserLinkModel{
		InnerUserLink: db.InnerUserLink{
			ClientID:     userClient.ID,
			CaseworkerID: userCaseworker.ID,
		},
	}

	// Mock auth
	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userCaseworker.InnerUser.Email),
			db.User.AuthCode.Equals(*userCaseworker.InnerUser.AuthCode),
		),
	).Returns(userCaseworker)

	// Mock find other user
	mock.User.Expect(
		client.User.FindUnique(
			db.User.Email.Equals(userClient.InnerUser.Email),
		),
	).Returns(userClient)

	// Mock remove userlink
	mock.UserLink.Expect(
		client.UserLink.FindUnique(
			db.UserLink.UserlinkID(
				db.UserLink.ClientID.Equals(userClient.ID),
				db.UserLink.CaseworkerID.Equals(userCaseworker.ID),
			),
		).Delete(),
	).Returns(userLink)

	request := UnlinkAccountRequest{
		OtherEmail: userClient.InnerUser.Email,
	}
	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodPost, "/api/account/unlink", request)
	c.Request().Header.Set(EmailHeaderKey, userCaseworker.InnerUser.Email)
	c.Request().Header.Set(AuthHeaderKey, *userCaseworker.InnerUser.AuthCode)
	assert.NoError(t, reqErr, "Failed to prepare request")
	assert.NoError(t, UnlinkAccountHandler(c, client), "Error while unlinking")
	assert.Equal(t, 200, rec.Code, "Bad status code")

	var response UnlinkAccountResponse
	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, unmarshalErr, "Error while parsing response body")

	assert.Empty(t, response.Error, "Error message found")
	assert.True(t, response.Success, "Unsuccessful")
}
