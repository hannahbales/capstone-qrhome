package data

import (
	"api/core/server/account"
	"api/core/server/data/application"
	"api/core/util"
	"api/db"
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"time"

	"github.com/labstack/echo"
)

var validGenders = map[string]bool{
	"Male":              true,
	"Female":            true,
	"Non-Binary":        true,
	"Prefer not to say": true,
	"Other":             true,
}

var validRelationships = map[string]bool{
	"Spouse": true,
	"Child":  true,
	"Parent": true,
	"Other":  true,
}

type GetPersInfoResponse struct {
	Success     bool   `json:"success"`
	Error       string `json:"error"`
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	Dob         string `json:"dob"`
	PhoneNumber string `json:"phone_number"`
}

type UpdatePersInfoRequest struct {
	PhoneNumber string `json:"phone_number"`
}

type UpdatePersInfoResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

func validatePhoneNumber(pn string) bool {
	match, _ := regexp.MatchString("^\\d{10}$", pn)
	return match
}

func GetPersInfoHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.JSON(500, GetPersInfoResponse{Success: false, Error: "Failed to authenticate"})
	}

	info, infoErr := client.PersonalInfo.FindUnique(
		db.PersonalInfo.ID.Equals(user.PersonalInfoID),
	).Exec(context.Background())
	if infoErr != nil {
		return c.JSON(500, GetPersInfoResponse{Success: false, Error: "Failed to get personal info"})
	}

	phoneNumber, ok := info.PhoneNumber()
	if !ok {
		phoneNumber = ""
	}

	return c.JSON(200, GetPersInfoResponse{
		Success:     true,
		FirstName:   info.FirstName,
		LastName:    info.LastName,
		Dob:         fmt.Sprintf("%d-%02d-%02d", info.Dob.Year(), info.Dob.Month(), info.Dob.Day()),
		PhoneNumber: phoneNumber,
	})
}

func UpdatePersInfoHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.JSON(500, UpdatePersInfoResponse{Success: false, Error: "Failed to authenticate"})
	}

	var request UpdatePersInfoRequest
	err := json.NewDecoder(c.Request().Body).Decode(&request)
	if err != nil {
		return c.JSON(500, UpdatePersInfoResponse{Success: false, Error: "Failed to decode body"})
	}

	if !validatePhoneNumber(request.PhoneNumber) {
		return c.JSON(500, UpdatePersInfoResponse{Success: false, Error: "Invalid phone number"})
	}

	_, updateErr := client.PersonalInfo.FindUnique(
		db.PersonalInfo.ID.Equals(user.PersonalInfoID),
	).Update(
		db.PersonalInfo.PhoneNumber.SetOptional(&request.PhoneNumber),
	).Exec(context.Background())
	if updateErr != nil {
		fmt.Printf("Failed to update personal info: %v\n", updateErr)
		return c.JSON(500, UpdatePersInfoResponse{Success: false, Error: "Failed to update personal info"})
	}

	return c.JSON(200, UpdatePersInfoResponse{Success: true})
}

/**
 *  Application Data
 */

type GetApplicationDataResponse struct {
	Success bool                        `json:"success"`
	Error   string                      `json:"error"`
	HasData bool                        `json:"has_data"`
	Data    application.ApplicationData `json:"application_data"`
}

type UpdateApplicationDataRequest struct {
	Data application.ApplicationData `json:"application_data"`
}

type UpdateApplicationDataResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

var applicationWith = []db.ApplicationDataRelationWith{
	db.ApplicationData.HousingPreferenceRankings.Fetch(),
	db.ApplicationData.AbsentFamilyMembers.Fetch(),
	db.ApplicationData.HudRecipients.Fetch(),
	db.ApplicationData.AccessibilityMembers.Fetch(),
	db.ApplicationData.MembersNeedingHelp.Fetch(),
	db.ApplicationData.CurrentResidence.Fetch().With(
		db.ResidenceInfo.NonResidingMembers.Fetch(),
	),
	db.ApplicationData.PreviousResidences.Fetch().With(
		db.ResidenceInfo.NonResidingMembers.Fetch(),
	),
	db.ApplicationData.LifetimeOffenders.Fetch(),
	db.ApplicationData.ViolentOffenders.Fetch(),
	db.ApplicationData.MethOffenders.Fetch(),
	db.ApplicationData.DrugOffenders.Fetch(),
	db.ApplicationData.OtherCrimes.Fetch().With(
		db.CrimeEntry.FamilyMember.Fetch(),
	),
	db.ApplicationData.IncomeAssetEntries.Fetch().With(
		db.IncomeAssetEntry.FamilyMember.Fetch(),
	),
}

func GetApplicationDataHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.JSON(400, GetApplicationDataResponse{Success: false, Error: "Failed to authenticate"})
	}

	// Get the data
	ownerEmail := c.QueryParam("email")
	var applicationData *db.ApplicationDataModel
	var personalInfo *db.PersonalInfoModel
	if ownerEmail == user.Email {
		var applicationDataErr error
		applicationData, applicationDataErr = client.ApplicationData.FindFirst(
			db.ApplicationData.UserID.Equals(user.ID),
		).With(
			applicationWith...,
		).Exec(context.Background())

		if applicationDataErr != nil && applicationDataErr != db.ErrNotFound {
			fmt.Printf("[ERROR] Failed to get application data: %v\n", applicationDataErr)
			return c.JSON(500, GetApplicationDataResponse{Success: false, Error: "Failed to retrieve application data"})
		}

		if applicationData == nil {
			fmt.Printf("[INFO] No application data found for user %d\n", user.ID)
			return c.JSON(200, GetApplicationDataResponse{Success: true, HasData: false})
		}

		var personalInfoErr error
		personalInfo, personalInfoErr = client.PersonalInfo.FindUnique(
			db.PersonalInfo.ID.Equals(user.PersonalInfoID),
		).Exec(context.Background())

		if personalInfoErr != nil {
			fmt.Printf("[ERROR] Failed to get personal info: %v\n", personalInfoErr)
			return c.JSON(500, GetApplicationDataResponse{Success: false, Error: "Failed to retrieve personal info"})
		}
	} else {
		userLink, userLinkErr := client.UserLink.FindFirst(
			db.UserLink.Caseworker.Where(
				db.User.Email.Equals(user.Email),
			),
			db.UserLink.Client.Where(
				db.User.Email.Equals(ownerEmail),
			),
		).Exec(context.Background())
		if userLinkErr != nil || userLink == nil {
			fmt.Printf("[ERROR] Not a caseworker for owner email: %s, %v\n", ownerEmail, userLinkErr)
			return c.JSON(400, GetApplicationDataResponse{
				Success: false,
				Error:   "Not a caseworker for account",
			})
		}

		ownerUser, ownerUserErr := client.User.FindUnique(
			db.User.Email.Equals(ownerEmail),
		).With(
			db.User.CaseworkerLinks.Fetch(),
			db.User.ApplicationData.Fetch().With(
				applicationWith...,
			),
			db.User.PersonalInfo.Fetch(),
		).Exec(context.Background())

		if ownerUserErr != nil || ownerUser == nil {
			fmt.Printf("[ERROR] Invalid Owner Email (Owner Email: %s), %v\n", ownerEmail, ownerUserErr)
			return c.JSON(400, GetApplicationDataResponse{Success: false, Error: "Invalid owner email"})
		}

		applicationData, _ = ownerUser.ApplicationData()
		if applicationData == nil {
			fmt.Printf("[INFO] No application data found for user %d\n", ownerUser.ID)
			return c.JSON(200, GetApplicationDataResponse{Success: true, HasData: false})
		}

		personalInfo = ownerUser.PersonalInfo()
	}

	housingPreferenceRankings := make(map[string]string)
	dbRankings := applicationData.HousingPreferenceRankings()
	fmt.Printf("[DEBUG] Housing Preference Rankings Legnth: %d\n", len(dbRankings))
	for _, ranking := range applicationData.HousingPreferenceRankings() {
		housingPreferenceRankings[ranking.Preference] = ranking.Rank
	}

	currentResidence, hasCurrentResidence := applicationData.CurrentResidence()
	var currentResidenceData *application.ResidenceData = nil
	if hasCurrentResidence {
		data := application.ToResidenceData(currentResidence)
		currentResidenceData = &data
	}

	// Parse it into horrific json compat structs
	return c.JSON(200, GetApplicationDataResponse{
		Success: true,
		HasData: true,
		Data: application.ApplicationData{
			PersonalInfo: application.PersonalInfo{
				FirstName:     personalInfo.FirstName,
				LastName:      personalInfo.LastName,
				Email:         ownerEmail,
				Dob:           personalInfo.Dob.Format("2006-01-02"),
				Phone:         util.WrapDefault(personalInfo.PhoneNumber, ""),
				SSN:           applicationData.Ssn,
				Address:       applicationData.Address,
				Gender:        applicationData.Gender,
				IsStudent:     applicationData.IsStudent,
				IsVeteran:     applicationData.IsVeteran,
				HasDisability: applicationData.HasDisability,
			},
			HousingPreferences: application.HousingPreferences{
				Rankings:          housingPreferenceRankings,
				DesiredMoveInDate: applicationData.DesiredMoveInDate,
			},
			Household: application.HouseholdData{
				HasPet:                     applicationData.HasPets,
				PetDescription:             applicationData.PetDescription,
				IsSmoker:                   applicationData.IsSmoker,
				MoreThanOneResidence:       applicationData.MoreThanOneResidence,
				AbsentMembersExplanation:   applicationData.AbsentMembersExplanation,
				AbsentMembers:              application.ToFamilyMembers(applicationData.AbsentFamilyMembers()),
				CompositionChanges:         applicationData.CompositionChanges,
				CompositionExplanation:     applicationData.CompositionChangeExplanation,
				Custody:                    applicationData.Custody,
				CustodyExplanation:         applicationData.CustodyExplanation,
				ElderlyEligibility:         applicationData.ElderlyEligibility,
				DisabledEligibility:        applicationData.DisabledEligibility,
				ReceivedHudJan2010:         applicationData.ReceivedHudJan2010,
				HudRecipients:              application.ToFamilyMembers(applicationData.HudRecipients()),
				HudPropertyName:            applicationData.HudPropertyName,
				NeedsAccessibility:         applicationData.NeedsAccessibility,
				AccessibilityMembers:       application.ToFamilyMembers(applicationData.AccessibilityMembers()),
				MobilityAccessibility:      applicationData.MobilityAccessible,
				VisionAccessibility:        applicationData.VisionAccessible,
				HearingAccessibility:       applicationData.HearingAccessible,
				NeedsSpecialAccommodations: applicationData.NeedsSpecialAccommodations,
				MembersNeedingHelp:         application.ToFamilyMembers(applicationData.MembersNeedingHelp()),
				AccommodationDescription:   applicationData.AccommodationDescription,
			},
			History: application.HistoryData{
				CurrentResidence:      currentResidenceData,
				PreviousResidences:    application.ToResidenceDataList(applicationData.PreviousResidences()),
				AssistanceTerminated:  applicationData.AssistanceTerminated,
				AssistanceExplanation: applicationData.AssistanceExplanation,
				Evicted:               applicationData.Evicted,
				EvicitionExplanation:  applicationData.EvictionExplanation,
				OwesMoney:             applicationData.OwesMoney,
				DebtExplanation:       applicationData.DebtExplanation,
				MakingPayments:        applicationData.MakingPayments,
				BedBugs:               applicationData.BedBugs,
				IsLifetimeSexOffender: applicationData.IsLifetimeSexOffender,
				LifetimeOffenders:     application.ToFamilyMembers(applicationData.LifetimeOffenders()),
				IsViolentOffender:     applicationData.IsViolentOffender,
				ViolentOffenders:      application.ToFamilyMembers(applicationData.ViolentOffenders()),
				IsMethConviction:      applicationData.IsMethConviction,
				MethOffenders:         application.ToFamilyMembers(applicationData.MethOffenders()),
				HasDrugCharges:        applicationData.HasDrugCharges,
				DrugOffenders:         application.ToFamilyMembers(applicationData.DrugOffenders()),
				OtherCrimes:           application.ToCrimeDataList(applicationData.OtherCrimes()),
			},
			Income: application.IncomeAndAssetsData{
				IncomeAssetEntires:          application.ToIncomeAndAssetDataList(applicationData.IncomeAssetEntries()),
				ReceivesGovAssistance:       applicationData.ReceivesGovAssistance,
				AssistanceProgramName:       applicationData.AssistanceProgramName,
				ReceivesFromCurrentProperty: applicationData.ReceivesFromCurrentProperty,
			},
			UploadedFiles: []application.FileUploadData{},
		},
	})
}

func resetCrimeEntries(client *db.PrismaClient, applicationRequest *application.ApplicationData, applicationDb *db.ApplicationDataModel) error {
	// Delete any existing entries
	ids := make([]int, len(applicationDb.OtherCrimes()))
	for i, entry := range applicationDb.OtherCrimes() {
		ids[i] = entry.ID
	}
	_, err := client.CrimeEntry.FindMany(
		db.CrimeEntry.ID.In(ids),
	).Delete().Exec(context.Background())
	if err != nil {
		return err
	}

	// Create new entries
	for _, crime := range applicationRequest.History.OtherCrimes {
		_, err := client.CrimeEntry.CreateOne(
			db.CrimeEntry.FamilyMember.Link(
				db.FamilyMember.ID.Equals(crime.FamilyMember.ID),
			),
			db.CrimeEntry.Application.Link(
				db.ApplicationData.ID.Equals(applicationDb.ID),
			),

			db.CrimeEntry.Year.Set(crime.Year),
			db.CrimeEntry.Crime.Set(crime.Crime),
			db.CrimeEntry.City.Set(crime.City),
			db.CrimeEntry.State.Set(crime.State),
		).Exec(context.Background())
		if err != nil {
			return err
		}
	}
	return nil
}

func resetIncomeAssetEntries(client *db.PrismaClient, applicationRequest *application.ApplicationData, applicationDb *db.ApplicationDataModel) error {
	// Delete any existing entries
	ids := make([]int, len(applicationDb.IncomeAssetEntries()))
	for i, entry := range applicationDb.IncomeAssetEntries() {
		ids[i] = entry.ID
	}
	_, err := client.IncomeAssetEntry.FindMany(
		db.IncomeAssetEntry.ID.In(ids),
	).Delete().Exec(context.Background())
	if err != nil {
		return err
	}

	// Create new entries
	for _, income := range applicationRequest.Income.IncomeAssetEntires {
		_, err := client.IncomeAssetEntry.CreateOne(
			db.IncomeAssetEntry.FamilyMember.Link(
				db.FamilyMember.ID.Equals(income.FamilyMember.ID),
			),
			db.IncomeAssetEntry.Application.Link(
				db.ApplicationData.ID.Equals(applicationDb.ID),
			),

			db.IncomeAssetEntry.Type.Set(income.Type),
			db.IncomeAssetEntry.Source.Set(income.Source),
			db.IncomeAssetEntry.Amount.Set(income.Amount),
			db.IncomeAssetEntry.FrequencyOrLocation.Set(income.FrequencyOrLocation),
			db.IncomeAssetEntry.MonthlyOrValue.Set(income.MonthlyOrValue),
		).Exec(context.Background())
		if err != nil {
			return err
		}
	}
	return nil
}

func resetPreferenceRankings(client *db.PrismaClient, applicationRequest *application.ApplicationData, applicationDb *db.ApplicationDataModel) error {
	// Delete any existing entries
	ids := make([]int, len(applicationDb.HousingPreferenceRankings()))
	for i, entry := range applicationDb.HousingPreferenceRankings() {
		ids[i] = entry.ID
	}
	_, err := client.HousingPreferenceRanking.FindMany(
		db.HousingPreferenceRanking.ID.In(ids),
	).Delete().Exec(context.Background())
	if err != nil {
		return err
	}

	// Create new entries
	for preference_, rank := range applicationRequest.HousingPreferences.Rankings {
		_, err := client.HousingPreferenceRanking.CreateOne(
			db.HousingPreferenceRanking.Application.Link(
				db.ApplicationData.ID.Equals(applicationDb.ID),
			),
			db.HousingPreferenceRanking.Preference.Set(preference_),
			db.HousingPreferenceRanking.Rank.Set(rank),
		).Exec(context.Background())
		if err != nil {
			return err
		}
	}
	return nil
}

func resetResidences(client *db.PrismaClient, applicationRequest *application.ApplicationData, applicationDb *db.ApplicationDataModel) error {
	// Remove any existing entries
	ids := make([]int, len(applicationDb.PreviousResidences()))
	for i, entry := range applicationDb.PreviousResidences() {
		ids[i] = entry.ID
	}
	currentResidence, hasCurrentResidence := applicationDb.CurrentResidence()
	if hasCurrentResidence {
		ids = append(ids, currentResidence.ID)
	}
	_, err := client.ResidenceInfo.FindMany(
		db.ResidenceInfo.ID.In(ids),
	).Delete().Exec(context.Background())
	if err != nil {
		return err
	}

	// Create new entries
	for _, residence := range applicationRequest.History.PreviousResidences {
		// parsedTimeIn, parseInErr := util.ParseTime(residence.DateIn)
		// parsedTimeOut, parseOutErr := util.ParseTime(residence.DateOut)
		// if parseInErr != nil {
		// 	parsedTimeIn = time.Now()
		// }
		// if parseOutErr != nil {
		// 	parsedTimeOut = time.Now()
		// }
		dbResidence, err := client.ResidenceInfo.CreateOne(
			db.ResidenceInfo.Address.Set(residence.Address),
			db.ResidenceInfo.City.Set(residence.City),
			db.ResidenceInfo.State.Set(residence.State),
			db.ResidenceInfo.ZipCode.Set(residence.ZipCode),
			db.ResidenceInfo.DateIn.Set(residence.DateIn),
			db.ResidenceInfo.DateOut.Set(residence.DateOut),
			db.ResidenceInfo.LandlordName.Set(residence.LandlordName),
			db.ResidenceInfo.LandlordPhone.Set(residence.LandlordPhone),
			db.ResidenceInfo.MonthlyPayment.Set(residence.MonthlyPayment),
			db.ResidenceInfo.ResidenceType.Set(residence.ResidenceType),
			db.ResidenceInfo.OtherResidenceType.Set(residence.OtherResidenceType),
			db.ResidenceInfo.AllReside.Set(residence.AllReside),

			// db.ResidenceInfo.NonResidingMembers.Link(
			// 	db.FamilyMember.ID.In(
			// 		nonResiding,
			// 	),
			// ),
			db.ResidenceInfo.PreviousResidences.Link(
				db.ApplicationData.ID.Equals(applicationDb.ID),
			),
		).Exec(context.Background())
		if err != nil {
			return err
		}

		for _, member := range residence.NonResidingMembers {
			_, err := client.FamilyMember.FindUnique(
				db.FamilyMember.ID.Equals(member.ID),
			).Update(
				db.FamilyMember.NonResidingMember.Link(
					db.ResidenceInfo.ID.Equals(dbResidence.ID),
				),
			).Exec(context.Background())
			if err != nil {
				return err
			}
		}
	}
	if applicationRequest.History.CurrentResidence != nil {
		residence := applicationRequest.History.CurrentResidence
		// parsedTimeIn, parseInErr := util.ParseTime(residence.DateIn)
		// parsedTimeOut, parseOutErr := util.ParseTime(residence.DateOut)
		// if parseInErr != nil {
		// 	parsedTimeIn = time.Now()
		// }
		// if parseOutErr != nil {
		// 	parsedTimeOut = time.Now()
		// }
		dbResidence, err := client.ResidenceInfo.CreateOne(
			db.ResidenceInfo.Address.Set(residence.Address),
			db.ResidenceInfo.City.Set(residence.City),
			db.ResidenceInfo.State.Set(residence.State),
			db.ResidenceInfo.ZipCode.Set(residence.ZipCode),
			db.ResidenceInfo.DateIn.Set(residence.DateIn),
			db.ResidenceInfo.DateOut.Set(residence.DateOut),
			db.ResidenceInfo.LandlordName.Set(residence.LandlordName),
			db.ResidenceInfo.LandlordPhone.Set(residence.LandlordPhone),
			db.ResidenceInfo.MonthlyPayment.Set(residence.MonthlyPayment),
			db.ResidenceInfo.ResidenceType.Set(residence.ResidenceType),
			db.ResidenceInfo.OtherResidenceType.Set(residence.OtherResidenceType),
			db.ResidenceInfo.AllReside.Set(residence.AllReside),

			db.ResidenceInfo.CurrentResidence.Link(
				db.ApplicationData.ID.Equals(applicationDb.ID),
			),
		).Exec(context.Background())
		if err != nil {
			return err
		}

		for _, member := range residence.NonResidingMembers {
			_, err := client.FamilyMember.FindUnique(
				db.FamilyMember.ID.Equals(member.ID),
			).Update(
				db.FamilyMember.NonResidingMember.Link(
					db.ResidenceInfo.ID.Equals(dbResidence.ID),
				),
			).Exec(context.Background())
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func UpdateApplicationDataHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		return c.JSON(400, UpdateApplicationDataResponse{Success: false, Error: "Failed to authenticate"})
	}

	var request UpdateApplicationDataRequest
	err := json.NewDecoder(c.Request().Body).Decode(&request)
	if err != nil {
		return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to decode body"})
	}

	pretty, prettyErr := json.MarshalIndent(request, "", "  ")
	if prettyErr != nil {
		fmt.Printf("[ERROR] Failed to pretty print request: %v\n", prettyErr)
	} else {
		fmt.Printf("[INFO] Update Application Data:\n%s\n", pretty)
	}

	// Update/Create the Application Data
	applicationData, appDataErr := client.ApplicationData.FindUnique(
		db.ApplicationData.UserID.Equals(user.ID),
	).With(
		applicationWith...,
	).Exec(context.Background())
	if appDataErr != nil && appDataErr != db.ErrNotFound {
		fmt.Printf("[ERROR] Failed to get application data: %v\n", appDataErr)
		return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Error while attempting to retrieve application data"})
	}

	absentMembers := make([]int, len(request.Data.Household.AbsentMembers))
	for i, member := range request.Data.Household.AbsentMembers {
		absentMembers[i] = member.ID
	}
	hudRecipients := make([]int, len(request.Data.Household.HudRecipients))
	for i, member := range request.Data.Household.HudRecipients {
		hudRecipients[i] = member.ID
	}
	accessibilityMembers := make([]int, len(request.Data.Household.AccessibilityMembers))
	for i, member := range request.Data.Household.AccessibilityMembers {
		accessibilityMembers[i] = member.ID
	}
	membersNeedingHelp := make([]int, len(request.Data.Household.MembersNeedingHelp))
	for i, member := range request.Data.Household.MembersNeedingHelp {
		membersNeedingHelp[i] = member.ID
	}
	lifetimeOffenders := make([]int, len(request.Data.History.LifetimeOffenders))
	for i, member := range request.Data.History.LifetimeOffenders {
		lifetimeOffenders[i] = member.ID
	}
	violentOffenders := make([]int, len(request.Data.History.ViolentOffenders))
	for i, member := range request.Data.History.ViolentOffenders {
		violentOffenders[i] = member.ID
	}
	methOffenders := make([]int, len(request.Data.History.MethOffenders))
	for i, member := range request.Data.History.MethOffenders {
		methOffenders[i] = member.ID
	}
	drugOffenders := make([]int, len(request.Data.History.DrugOffenders))
	for i, member := range request.Data.History.DrugOffenders {
		drugOffenders[i] = member.ID
	}

	if applicationData == nil {
		applicationData, appDataErr = client.ApplicationData.CreateOne(
			db.ApplicationData.User.Link(
				db.User.ID.Equals(user.ID),
			),

			db.ApplicationData.Ssn.Set(request.Data.PersonalInfo.SSN),
			db.ApplicationData.Address.Set(request.Data.PersonalInfo.Address),
			db.ApplicationData.Gender.Set(request.Data.PersonalInfo.Gender),
			db.ApplicationData.IsStudent.Set(request.Data.PersonalInfo.IsStudent),
			db.ApplicationData.IsVeteran.Set(request.Data.PersonalInfo.IsVeteran),
			db.ApplicationData.HasDisability.Set(request.Data.PersonalInfo.HasDisability),

			db.ApplicationData.DesiredMoveInDate.Set(request.Data.HousingPreferences.DesiredMoveInDate),

			db.ApplicationData.HasPets.Set(request.Data.Household.HasPet),
			db.ApplicationData.PetDescription.Set(request.Data.Household.PetDescription),
			db.ApplicationData.IsSmoker.Set(request.Data.Household.IsSmoker),
			db.ApplicationData.MoreThanOneResidence.Set(request.Data.Household.MoreThanOneResidence),
			db.ApplicationData.AbsentMembersExplanation.Set(request.Data.Household.AbsentMembersExplanation),
			// db.ApplicationData.AbsentFamilyMembers.Link(
			// 	db.FamilyMember.ID.In(
			// 		absentMembers,
			// 	),
			// ),
			db.ApplicationData.CompositionChanges.Set(request.Data.Household.CompositionChanges),
			db.ApplicationData.CompositionChangeExplanation.Set(request.Data.Household.CompositionExplanation),
			db.ApplicationData.Custody.Set(request.Data.Household.Custody),
			db.ApplicationData.CustodyExplanation.Set(request.Data.Household.CustodyExplanation),
			db.ApplicationData.ElderlyEligibility.Set(request.Data.Household.ElderlyEligibility),
			db.ApplicationData.DisabledEligibility.Set(request.Data.Household.DisabledEligibility),
			db.ApplicationData.ReceivedHudJan2010.Set(request.Data.Household.ReceivedHudJan2010),
			// db.ApplicationData.HudRecipients.Link(
			// 	db.FamilyMember.ID.In(
			// 		hudRecipients,
			// 	),
			// ),
			db.ApplicationData.HudPropertyName.Set(request.Data.Household.HudPropertyName),
			db.ApplicationData.NeedsAccessibility.Set(request.Data.Household.NeedsAccessibility),
			// db.ApplicationData.AccessibilityMembers.Link(
			// 	db.FamilyMember.ID.In(
			// 		accessibilityMembers,
			// 	),
			// ),
			db.ApplicationData.MobilityAccessible.Set(request.Data.Household.MobilityAccessibility),
			db.ApplicationData.VisionAccessible.Set(request.Data.Household.VisionAccessibility),
			db.ApplicationData.HearingAccessible.Set(request.Data.Household.HearingAccessibility),
			db.ApplicationData.NeedsSpecialAccommodations.Set(request.Data.Household.NeedsSpecialAccommodations),
			// db.ApplicationData.MembersNeedingHelp.Link(
			// 	db.FamilyMember.ID.In(
			// 		membersNeedingHelp,
			// 	),
			// ),
			db.ApplicationData.AccommodationDescription.Set(request.Data.Household.AccommodationDescription),

			db.ApplicationData.AssistanceTerminated.Set(request.Data.History.AssistanceTerminated),
			db.ApplicationData.AssistanceExplanation.Set(request.Data.History.AssistanceExplanation),
			db.ApplicationData.Evicted.Set(request.Data.History.Evicted),
			db.ApplicationData.EvictionExplanation.Set(request.Data.History.EvicitionExplanation),
			db.ApplicationData.OwesMoney.Set(request.Data.History.OwesMoney),
			db.ApplicationData.DebtExplanation.Set(request.Data.History.DebtExplanation),
			db.ApplicationData.MakingPayments.Set(request.Data.History.MakingPayments),
			db.ApplicationData.BedBugs.Set(request.Data.History.BedBugs),
			db.ApplicationData.IsLifetimeSexOffender.Set(request.Data.History.IsLifetimeSexOffender),
			// db.ApplicationData.LifetimeOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		lifetimeOffenders,
			// 	),
			// ),
			db.ApplicationData.IsViolentOffender.Set(request.Data.History.IsViolentOffender),
			// db.ApplicationData.ViolentOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		violentOffenders,
			// 	),
			// ),
			db.ApplicationData.IsMethConviction.Set(request.Data.History.IsMethConviction),
			// db.ApplicationData.MethOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		methOffenders,
			// 	),
			// ),
			db.ApplicationData.HasDrugCharges.Set(request.Data.History.HasDrugCharges),
			// db.ApplicationData.DrugOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		drugOffenders,
			// 	),
			// ),

			db.ApplicationData.ReceivesGovAssistance.Set(request.Data.Income.ReceivesGovAssistance),
			db.ApplicationData.AssistanceProgramName.Set(request.Data.Income.AssistanceProgramName),
			db.ApplicationData.ReceivesFromCurrentProperty.Set(request.Data.Income.ReceivesFromCurrentProperty),
		).With(
			applicationWith...,
		).Exec(context.Background())
		if appDataErr != nil {
			fmt.Printf("[ERROR] Failed to create application data: %v\n", appDataErr)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to create application data"})
		}
	} else {
		_, err := client.ApplicationData.FindUnique(
			db.ApplicationData.ID.Equals(applicationData.ID),
		).Update(
			db.ApplicationData.Ssn.Set(request.Data.PersonalInfo.SSN),
			db.ApplicationData.Address.Set(request.Data.PersonalInfo.Address),
			db.ApplicationData.Gender.Set(request.Data.PersonalInfo.Gender),
			db.ApplicationData.IsStudent.Set(request.Data.PersonalInfo.IsStudent),
			db.ApplicationData.IsVeteran.Set(request.Data.PersonalInfo.IsVeteran),
			db.ApplicationData.HasDisability.Set(request.Data.PersonalInfo.HasDisability),

			db.ApplicationData.DesiredMoveInDate.Set(request.Data.HousingPreferences.DesiredMoveInDate),

			db.ApplicationData.HasPets.Set(request.Data.Household.HasPet),
			db.ApplicationData.PetDescription.Set(request.Data.Household.PetDescription),
			db.ApplicationData.IsSmoker.Set(request.Data.Household.IsSmoker),
			db.ApplicationData.MoreThanOneResidence.Set(request.Data.Household.MoreThanOneResidence),
			db.ApplicationData.AbsentMembersExplanation.Set(request.Data.Household.AbsentMembersExplanation),
			db.ApplicationData.AbsentFamilyMembers.Unlink(),
			// db.ApplicationData.AbsentFamilyMembers.Link(
			// 	db.FamilyMember.ID.In(
			// 		absentMembers,
			// 	),
			// ),
			db.ApplicationData.CompositionChanges.Set(request.Data.Household.CompositionChanges),
			db.ApplicationData.CompositionChangeExplanation.Set(request.Data.Household.CompositionExplanation),
			db.ApplicationData.Custody.Set(request.Data.Household.Custody),
			db.ApplicationData.CustodyExplanation.Set(request.Data.Household.CustodyExplanation),
			db.ApplicationData.ElderlyEligibility.Set(request.Data.Household.ElderlyEligibility),
			db.ApplicationData.DisabledEligibility.Set(request.Data.Household.DisabledEligibility),
			db.ApplicationData.ReceivedHudJan2010.Set(request.Data.Household.ReceivedHudJan2010),
			db.ApplicationData.HudRecipients.Unlink(),
			// db.ApplicationData.HudRecipients.Link(
			// 	db.FamilyMember.ID.In(
			// 		hudRecipients,
			// 	),
			// ),
			db.ApplicationData.HudPropertyName.Set(request.Data.Household.HudPropertyName),
			db.ApplicationData.NeedsAccessibility.Set(request.Data.Household.NeedsAccessibility),
			db.ApplicationData.AccessibilityMembers.Unlink(),
			// db.ApplicationData.AccessibilityMembers.Link(
			// 	db.FamilyMember.ID.In(
			// 		accessibilityMembers,
			// 	),
			// ),
			db.ApplicationData.MobilityAccessible.Set(request.Data.Household.MobilityAccessibility),
			db.ApplicationData.VisionAccessible.Set(request.Data.Household.VisionAccessibility),
			db.ApplicationData.HearingAccessible.Set(request.Data.Household.HearingAccessibility),
			db.ApplicationData.NeedsSpecialAccommodations.Set(request.Data.Household.NeedsSpecialAccommodations),
			db.ApplicationData.MembersNeedingHelp.Unlink(),
			// db.ApplicationData.MembersNeedingHelp.Link(
			// 	db.FamilyMember.ID.In(
			// 		membersNeedingHelp,
			// 	),
			// ),
			db.ApplicationData.AccommodationDescription.Set(request.Data.Household.AccommodationDescription),

			db.ApplicationData.AssistanceTerminated.Set(request.Data.History.AssistanceTerminated),
			db.ApplicationData.AssistanceExplanation.Set(request.Data.History.AssistanceExplanation),
			db.ApplicationData.Evicted.Set(request.Data.History.Evicted),
			db.ApplicationData.EvictionExplanation.Set(request.Data.History.EvicitionExplanation),
			db.ApplicationData.OwesMoney.Set(request.Data.History.OwesMoney),
			db.ApplicationData.DebtExplanation.Set(request.Data.History.DebtExplanation),
			db.ApplicationData.MakingPayments.Set(request.Data.History.MakingPayments),
			db.ApplicationData.BedBugs.Set(request.Data.History.BedBugs),
			db.ApplicationData.IsLifetimeSexOffender.Set(request.Data.History.IsLifetimeSexOffender),
			db.ApplicationData.LifetimeOffenders.Unlink(),
			// db.ApplicationData.LifetimeOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		lifetimeOffenders,
			// 	),
			// ),
			db.ApplicationData.IsViolentOffender.Set(request.Data.History.IsViolentOffender),
			db.ApplicationData.ViolentOffenders.Unlink(),
			// db.ApplicationData.ViolentOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		violentOffenders,
			// 	),
			// ),
			db.ApplicationData.IsMethConviction.Set(request.Data.History.IsMethConviction),
			db.ApplicationData.MethOffenders.Unlink(),
			// db.ApplicationData.MethOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		methOffenders,
			// 	),
			// ),
			db.ApplicationData.HasDrugCharges.Set(request.Data.History.HasDrugCharges),
			db.ApplicationData.DrugOffenders.Unlink(),
			// db.ApplicationData.DrugOffenders.Link(
			// 	db.FamilyMember.ID.In(
			// 		drugOffenders,
			// 	),
			// ),

			db.ApplicationData.ReceivesGovAssistance.Set(request.Data.Income.ReceivesGovAssistance),
			db.ApplicationData.AssistanceProgramName.Set(request.Data.Income.AssistanceProgramName),
			db.ApplicationData.ReceivesFromCurrentProperty.Set(request.Data.Income.ReceivesFromCurrentProperty),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update application data: %v\n", err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update application data"})
		}

	}

	for _, member := range request.Data.Household.AbsentMembers {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.AbsentFamilyMember.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update absent family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update absent family member"})
		}
	}
	for _, member := range request.Data.Household.HudRecipients {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.HudRecipient.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update hud recipient family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update hud recipient family member"})
		}
	}
	for _, member := range request.Data.Household.AccessibilityMembers {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.Accessibility.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update accessibility family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update accessibility family member"})
		}
	}
	for _, member := range request.Data.Household.MembersNeedingHelp {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.MembersNeedingHelp.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update needing help family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update needing help family member"})
		}
	}
	for _, member := range request.Data.History.LifetimeOffenders {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.LifetimeOffender.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update lifetime offender family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update lifetime offender family member"})
		}
	}
	for _, member := range request.Data.History.ViolentOffenders {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.ViolentOffender.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update violent offender family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update violent offender family member"})
		}
	}
	for _, member := range request.Data.History.MethOffenders {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.MethConviction.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update meth offender family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update meth offender family member"})
		}
	}
	for _, member := range request.Data.History.DrugOffenders {
		_, err := client.FamilyMember.FindUnique(
			db.FamilyMember.ID.Equals(member.ID),
		).Update(
			db.FamilyMember.DrugConviction.Link(
				db.ApplicationData.ID.Equals(applicationData.ID),
			),
		).Exec(context.Background())
		if err != nil {
			fmt.Printf("[ERROR] Failed to update drug offender family member %d: %v\n", member.ID, err)
			return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update drug offender family member"})
		}
	}

	crimeErr := resetCrimeEntries(client, &request.Data, applicationData)
	resErr := resetResidences(client, &request.Data, applicationData)
	prefErr := resetPreferenceRankings(client, &request.Data, applicationData)
	incomeErr := resetIncomeAssetEntries(client, &request.Data, applicationData)
	if crimeErr != nil {
		fmt.Printf("[ERROR] Failed to update crime entries: %v\n", err)
		return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update crime entries"})
	}
	if resErr != nil {
		fmt.Printf("[ERROR] Failed to update residence entries: %v\n", err)
		return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update residence entries"})
	}
	if prefErr != nil {
		fmt.Printf("[ERROR] Failed to update preference rankings: %v\n", err)
		return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update preference rankings"})
	}
	if incomeErr != nil {
		fmt.Printf("[ERROR] Failed to update income entries: %v\n", err)
		return c.JSON(500, UpdateApplicationDataResponse{Success: false, Error: "Failed to update income entries"})
	}

	return c.JSON(200, UpdateApplicationDataResponse{Success: true, Error: ""})
}

/**
 *  Families
 */

type GetFamilyMembersResponse struct {
	Success bool                       `json:"success"`
	Family  []application.FamilyMember `json:"family"`
	Error   string                     `json:"error"`
}

type AddFamilyMemberRequest struct {
	Data application.FamilyMember `json:"data"`
}

type AddFamilyMemberResponse struct {
	ID      int    `json:"id"`
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

type UpdateFamilyMemberRequest struct {
	Data application.FamilyMember `json:"data"`
}

type UpdateFamilyMemberResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

type DeleteFamilyMemberRequest struct {
	ID int `json:"id"`
}

type DeleteFamilyMemberResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
}

func validateFamilyMember(member *application.FamilyMember) (birthday time.Time, err error) {
	if !validGenders[member.Gender] {
		err = fmt.Errorf("Invalid gender value: %v", member.Gender)
	}

	if !validRelationships[member.Relationship] {
		err = fmt.Errorf("Invalid relationship value: %v", member.Relationship)
	}

	birthday, err = util.ParseTime(member.Birthday)
	return
}

func GetFamilyMembersHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		fmt.Printf("[ERROR] User not authenticated\n")
		return c.JSON(500, GetFamilyMembersResponse{
			Success: false,
			Error:   "Authentication failed",
		})
	}

	ownerEmail := c.QueryParam("email")
	if ownerEmail != user.Email {
		userLink, userLinkErr := client.UserLink.FindFirst(
			db.UserLink.Caseworker.Where(
				db.User.Email.Equals(user.Email),
			),
			db.UserLink.Client.Where(
				db.User.Email.Equals(ownerEmail),
			),
		).Exec(context.Background())

		if userLink == nil || userLinkErr != nil {
			fmt.Printf("[ERROR] Not a caseworker for owner email: %s\n", ownerEmail)
			return c.JSON(400, GetFamilyMembersResponse{
				Success: false,
				Error:   "Not a caseworker for account",
			})
		}
	}

	personalData, personalDataErr := client.PersonalInfo.FindFirst(
		db.PersonalInfo.User.Where(
			db.User.Email.Equals(ownerEmail),
		),
	).With(
		db.PersonalInfo.FamilyLinks.Fetch().With(
			db.FamilyLink.FamilyMember.Fetch(),
		),
	).Exec(context.Background())

	if personalDataErr != nil {
		fmt.Printf("[ERROR] Failed to retrieve personal data: %v\n", personalDataErr)
		return c.JSON(500, GetFamilyMembersResponse{
			Success: false,
			Error:   "Failed to retrieve personal data",
		})
	}

	members := make([]application.FamilyMember, len(personalData.FamilyLinks()))
	for i, link := range personalData.FamilyLinks() {
		members[i] = application.ToFamilyMember(link.FamilyMember())
	}

	return c.JSON(200, GetFamilyMembersResponse{
		Success: true,
		Family:  members,
	})
}

func AddFamilyMemberHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		fmt.Printf("[ERROR] User not authenticated\n")
		return c.JSON(500, AddFamilyMemberResponse{Success: false, Error: "Authentication failed"})
	}

	var req AddFamilyMemberRequest
	if err := json.NewDecoder(c.Request().Body).Decode(&req); err != nil {
		fmt.Printf("[ERROR] Failed to decode request body: %v\n", err)
		return c.JSON(500, AddFamilyMemberResponse{Success: false, Error: "Invalid request"})
	}

	birthday, err := validateFamilyMember(&req.Data)
	if err != nil {
		fmt.Printf("[ERROR] Failed to validate family member: %v\n", err)
		return c.JSON(500, AddFamilyMemberResponse{Success: false, Error: "Failed to validate family member"})
	}

	member, err := client.FamilyMember.CreateOne(
		db.FamilyMember.FirstName.Set(req.Data.FirstName),
		db.FamilyMember.LastName.Set(req.Data.LastName),
		db.FamilyMember.Birthday.Set(birthday),
		db.FamilyMember.Ssn.Set(req.Data.SSN),
		db.FamilyMember.Gender.Set(req.Data.Gender),
		db.FamilyMember.Relationship.Set(req.Data.Relationship),
	).Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to create family member: %v\n", err)
		return c.JSON(500, AddFamilyMemberResponse{Success: false, Error: "Failed to create family member"})
	}

	_, err = client.FamilyLink.CreateOne(
		db.FamilyLink.Relationship.Set(req.Data.Relationship),
		db.FamilyLink.PersonalInfo.Link(db.PersonalInfo.ID.Equals(user.PersonalInfoID)),
		db.FamilyLink.FamilyMember.Link(db.FamilyMember.ID.Equals(member.ID)),
	).Exec(context.Background())

	if err != nil {
		fmt.Printf("[ERROR] Failed to create family link: %v\n", err)
		return c.JSON(500, AddFamilyMemberResponse{Success: false, Error: "Failed to create family link"})
	}

	return c.JSON(200, AddFamilyMemberResponse{
		ID:      member.ID,
		Success: true,
	})
}

func UpdateFamilyMemberHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		fmt.Printf("[ERROR] User not authenticated\n")
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Authentication failed"})
	}

	var req UpdateFamilyMemberRequest
	if err := json.NewDecoder(c.Request().Body).Decode(&req); err != nil {
		fmt.Printf("[ERROR] Failed to decode request body: %v\n", err)
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Invalid request"})
	}

	birthday, err := validateFamilyMember(&req.Data)
	if err != nil {
		fmt.Printf("[ERROR] Failed to validate family member: %v\n", err)
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Failed to validate family member"})
	}

	member, err := client.FamilyMember.FindUnique(
		db.FamilyMember.ID.Equals(req.Data.ID),
	).With(
		db.FamilyMember.FamilyLink.Fetch(),
	).Update(
		db.FamilyMember.FirstName.Set(req.Data.FirstName),
		db.FamilyMember.LastName.Set(req.Data.LastName),
		db.FamilyMember.Birthday.Set(birthday),
		db.FamilyMember.Ssn.Set(req.Data.SSN),
		db.FamilyMember.Gender.Set(req.Data.Gender),
		db.FamilyMember.Relationship.Set(req.Data.Relationship),
	).Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to update family member: %v\n", err)
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Failed to update family member"})
	}

	familyLink, hasFamilyLink := member.FamilyLink()
	if !hasFamilyLink {
		fmt.Printf("[ERROR] Family link not found for member: %v\n", err)
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Family link not found"})
	}
	_, err = client.FamilyLink.FindUnique(
		db.FamilyLink.ID.Equals(familyLink.ID),
	).Update(
		db.FamilyLink.Relationship.Set(req.Data.Relationship),
	).Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to update family link: %v\n", err)
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Failed to update family link"})
	}
	return c.JSON(200, UpdateFamilyMemberResponse{
		Success: true,
		Error:   "",
	})
}

func DeleteFamilyMemberHandler(c echo.Context, client *db.PrismaClient) error {
	user := account.ValidateAuth(c, client)
	if user == nil {
		fmt.Printf("[ERROR] User not authenticated\n")
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Authentication failed"})
	}

	var req DeleteFamilyMemberRequest
	if err := json.NewDecoder(c.Request().Body).Decode(&req); err != nil {
		fmt.Printf("[ERROR] Failed to decode request body: %v\n", err)
		return c.JSON(500, UpdateFamilyMemberResponse{Success: false, Error: "Invalid request"})
	}

	member, err := client.FamilyMember.FindUnique(
		db.FamilyMember.ID.Equals(req.ID),
	).With(
		db.FamilyMember.FamilyLink.Fetch(),
	).Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to find family member: %v\n", err)
		return c.JSON(500, DeleteFamilyMemberResponse{Success: false, Error: "Failed to find family member"})
	}

	if member.Relationship == "Self" {
		fmt.Printf("[ERROR] Cannot delete self from family members\n")
		return c.JSON(500, DeleteFamilyMemberResponse{Success: false, Error: "Cannot delete self from family members"})
	}

	familyLink, hasFamilyLink := member.FamilyLink()
	if !hasFamilyLink {
		fmt.Printf("[ERROR] Family link not found for member: %v\n", err)
		return c.JSON(500, DeleteFamilyMemberResponse{Success: false, Error: "Family link not found"})
	}

	_, err = client.FamilyLink.FindUnique(
		db.FamilyLink.ID.Equals(familyLink.ID),
	).Delete().Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to delete family link: %v\n", err)
		return c.JSON(500, DeleteFamilyMemberResponse{Success: false, Error: "Failed to delete family link"})
	}
	_, err = client.FamilyMember.FindUnique(
		db.FamilyMember.ID.Equals(member.ID),
	).Delete().Exec(context.Background())
	if err != nil {
		fmt.Printf("[ERROR] Failed to delete family member: %v\n", err)
		return c.JSON(500, DeleteFamilyMemberResponse{Success: false, Error: "Failed to delete family member"})
	}

	return c.JSON(200, DeleteFamilyMemberResponse{
		Success: true,
		Error:   "",
	})
}
