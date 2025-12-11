package data

import (
	"api/core/server/account"
	"api/core/server/data/application"
	testutil "api/core/test_util"
	"api/db"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

var mock_lastAuth = time.Now()
var mock_authCode = account.CreateHash(fmt.Sprintf("%v:%v", "test@gmail.com", mock_lastAuth.UnixNano()))
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
	accountMockTeardown := account.Mock(mock_lastAuth, mock_authCode, mock_linkCode, mock_2faCode, mock_2faExpiry)

	return func() {
		accountMockTeardown()
	}
}

func TestGetPersonalInfo(t *testing.T) {
	teardown := setup()
	defer teardown()

	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userA := mock_userA
	userA.InnerUser.LastAuth = &mock_lastAuth
	userA.InnerUser.AuthCode = &mock_authCode

	// Mock auth validation
	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userA.Email),
			db.User.AuthCode.Equals(*userA.InnerUser.AuthCode),
		),
	).Returns(userA)

	// Mock find personal info
	mock.PersonalInfo.Expect(
		client.PersonalInfo.FindUnique(
			db.PersonalInfo.ID.Equals(mock_personalDataA.ID),
		),
	).Returns(mock_personalDataA)

	rec, c, reqErr := testutil.PrepareRequestParams(http.MethodGet, "/api/data/personal", nil)
	assert.NoError(t, reqErr, "Failed to prepare request")
	c.Request().Header.Set(account.EmailHeaderKey, userA.InnerUser.Email)
	c.Request().Header.Set(account.AuthHeaderKey, *userA.InnerUser.AuthCode)
	GetPersInfoHandler(c, client)

	assert.Equal(t, 200, rec.Code, "Bad status code")
	var response GetPersInfoResponse
	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, unmarshalErr, "Error while parsing response body")

	assert.Empty(t, response.Error, "Error message found")
	assert.True(t, response.Success, "Unsuccessful")
	assert.Empty(t, response.PhoneNumber, "Phone number not empty")
	assert.Equal(t, mock_personalDataA.FirstName, response.FirstName, "Incorrect first name")
	assert.Equal(t, mock_personalDataA.LastName, response.LastName, "Incorrect last name")
	assert.Equal(t, "2000-04-01", response.Dob, "Incorrect last name")
}

func TestUpdatePersonalInfo(t *testing.T) {
	teardown := setup()
	defer teardown()

	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userA := mock_userA
	userA.InnerUser.LastAuth = &mock_lastAuth
	userA.InnerUser.AuthCode = &mock_authCode

	phoneNumber := "5556789506"
	updatedInfo := mock_personalDataA
	updatedInfo.InnerPersonalInfo.PhoneNumber = &phoneNumber

	params := UpdatePersInfoRequest{
		PhoneNumber: phoneNumber,
	}

	// Mock auth validation
	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userA.Email),
			db.User.AuthCode.Equals(*userA.InnerUser.AuthCode),
		),
	).Returns(userA)

	// Mock update personal info
	mock.PersonalInfo.Expect(
		client.PersonalInfo.FindUnique(
			db.PersonalInfo.ID.Equals(userA.PersonalInfoID),
		).Update(
			db.PersonalInfo.PhoneNumber.SetOptional(&params.PhoneNumber),
		),
	).Returns(updatedInfo)

	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodPost, "/api/data/personal", params)
	assert.NoError(t, reqErr, "Failed to prepare request")
	c.Request().Header.Set(account.EmailHeaderKey, userA.InnerUser.Email)
	c.Request().Header.Set(account.AuthHeaderKey, *userA.InnerUser.AuthCode)
	UpdatePersInfoHandler(c, client)

	assert.Equal(t, 200, rec.Code, "Bad status code")
	var response UpdatePersInfoResponse
	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, unmarshalErr, "Error while parsing response body")

	assert.Empty(t, response.Error, "Error message found")
	assert.True(t, response.Success, "Unsuccessful")
}

/**
 *  Families Tests
 */

var mock_familyMember = db.FamilyMemberModel{
	InnerFamilyMember: db.InnerFamilyMember{
		ID:        42,
		FirstName: "Jack",
		LastName:  "Doe",
		Birthday:  time.Date(2010, 7, 15, 0, 0, 0, 0, time.UTC),
		Ssn:       "123456789",
		Gender:    "Male",
	},
}

var mock_familyLink = db.FamilyLinkModel{
	InnerFamilyLink: db.InnerFamilyLink{
		ID:             1,
		Relationship:   "Child",
		PersonalInfoID: mock_userA.PersonalInfoID,
		FamilyMemberID: mock_familyMember.ID,
	},
	RelationsFamilyLink: db.RelationsFamilyLink{
		FamilyMember: &mock_familyMember,
		PersonalInfo: &mock_personalDataA,
	},
}

func TestAddFamilyMemberHandler(t *testing.T) {
	teardown := setup()
	defer teardown()

	client, mock, ensure := db.NewMock()
	defer ensure(t)

	userA := mock_userA
	userA.InnerUser.LastAuth = &mock_lastAuth
	userA.InnerUser.AuthCode = &mock_authCode

	req := AddFamilyMemberRequest{
		Data: application.FamilyMember{
			FirstName:    "Jack",
			LastName:     "Doe",
			Birthday:     "2010-07-15",
			SSN:          "123456789",
			Gender:       "Male",
			Relationship: "Child",
		},
	}

	birthdayParsed, _ := time.Parse("2006-01-02", req.Data.Birthday)

	mockCreatedMember := db.FamilyMemberModel{
		InnerFamilyMember: db.InnerFamilyMember{
			ID:        10,
			FirstName: req.Data.FirstName,
			LastName:  req.Data.LastName,
			Birthday:  birthdayParsed,
			Ssn:       req.Data.SSN,
			Gender:    req.Data.Gender,
			Relationship: req.Data.Relationship,
		},
	}

	mock.User.Expect(
		client.User.FindFirst(
			db.User.Email.Equals(userA.Email),
			db.User.AuthCode.Equals(*userA.InnerUser.AuthCode),
		),
	).Returns(userA)

	mock.FamilyMember.Expect(
		client.FamilyMember.CreateOne(
			db.FamilyMember.FirstName.Set(req.Data.FirstName),
			db.FamilyMember.LastName.Set(req.Data.LastName),
			db.FamilyMember.Birthday.Set(birthdayParsed),
			db.FamilyMember.Ssn.Set(req.Data.SSN),
			db.FamilyMember.Gender.Set(req.Data.Gender),
			db.FamilyMember.Relationship.Set(req.Data.Relationship),
		),
	).Returns(mockCreatedMember)

	mock.FamilyLink.Expect(
		client.FamilyLink.CreateOne(
			db.FamilyLink.Relationship.Set(req.Data.Relationship),
			db.FamilyLink.PersonalInfo.Link(
				db.PersonalInfo.ID.Equals(userA.PersonalInfoID),
			),
			db.FamilyLink.FamilyMember.Link(
				db.FamilyMember.ID.Equals(mockCreatedMember.ID),
			),
		),
	).Returns(db.FamilyLinkModel{})

	rec, c, reqErr := testutil.PrepareRequestJSON(http.MethodPost, "/api/data/family", req)
	assert.NoError(t, reqErr)
	c.Request().Header.Set(account.EmailHeaderKey, userA.InnerUser.Email)
	c.Request().Header.Set(account.AuthHeaderKey, *userA.InnerUser.AuthCode)
	AddFamilyMemberHandler(c, client)

	assert.Equal(t, 200, rec.Code)
	var response map[string]interface{}
	err := json.Unmarshal(rec.Body.Bytes(), &response)
	assert.Nil(t, err)
	assert.True(t, response["success"].(bool))
}

// func TestGetFamilyMembersHandler(t *testing.T) {
// 	teardown := setup()
// 	defer teardown()

// 	client, mock, ensure := db.NewMock()
// 	defer ensure(t)

// 	userA := mock_userA
// 	userA.InnerUser.LastAuth = &mock_lastAuth
// 	userA.InnerUser.AuthCode = &mock_authCode

// 	personalDataA := mock_personalDataA
// 	personalDataA.FamilyLinks
// 	userA.RelationsUser = db.RelationsUser{
// 		PersonalInfo: &personalDataA,
// 	}

// 	// Auth validation
// 	mock.User.Expect(
// 		client.User.FindFirst(
// 			db.User.Email.Equals(userA.Email),
// 			db.User.AuthCode.Equals(*userA.InnerUser.AuthCode),
// 		),
// 	).Returns(userA)

// 	mock.PersonalInfo.Expect(
// 		client.PersonalInfo.FindUnique(
// 			db.PersonalInfo.ID.Equals(personalDataA.ID),
// 		).With(
// 			db.PersonalInfo.FamilyLinks.Fetch().With(
// 				db.FamilyLink.FamilyMember.Fetch(),
// 			),
// 		),
// 	)

// 	rec, c, reqErr := testutil.PrepareRequestParams(http.MethodGet, "/api/data/family", nil)
// 	assert.NoError(t, reqErr)
// 	c.Request().Header.Set(account.EmailHeaderKey, userA.InnerUser.Email)
// 	c.Request().Header.Set(account.AuthHeaderKey, *userA.InnerUser.AuthCode)

// 	err := GetFamilyMembersHandler(c, client)
// 	assert.NoError(t, err)
// 	assert.Equal(t, 200, rec.Code)

// 	var response GetFamilyMembersResponse
// 	unmarshalErr := json.Unmarshal(rec.Body.Bytes(), &response)
// 	assert.Nil(t, unmarshalErr, "Failed to parse response body")
// 	assert.True(t, response.Success)
// 	assert.Len(t, response.Family, 1)
// 	assert.Equal(t, "Jack", response.Family[0].FirstName)
// 	assert.Equal(t, "Child", response.Family[0].Relationship)
// }
