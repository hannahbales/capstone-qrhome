package application

import (
	"api/db"
	"fmt"
)

type ApplicationData struct {
	PersonalInfo       PersonalInfo        `json:"personal_info"`
	HousingPreferences HousingPreferences  `json:"housing_preferences"`
	Household          HouseholdData       `json:"household"`
	History            HistoryData         `json:"history"`
	Income             IncomeAndAssetsData `json:"income"`
	UploadedFiles      []FileUploadData    `json:"uploaded_files"`
}

type PersonalInfo struct {
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	Email         string `json:"email"`
	Dob		      string `json:"dob"`
	Phone         string `json:"phone"`
	SSN           string `json:"ssn"`
	Address       string `json:"address"`
	Gender        string `json:"gender"`
	IsStudent     bool   `json:"is_student"`
	IsVeteran     bool   `json:"is_veteran"`
	HasDisability bool   `json:"has_disability"`
}

type HousingPreferences struct {
	Rankings          map[string]string `json:"rankings"`
	DesiredMoveInDate string            `json:"desired_move_in_date"`
}

type HouseholdData struct {
	HasPet                     bool           `json:"has_pet"`
	PetDescription             string         `json:"pet_description"`
	IsSmoker                   bool           `json:"is_smoker"`
	MoreThanOneResidence       bool           `json:"more_than_one_residence"`
	AbsentMembersExplanation   string         `json:"absent_members_explanation"`
	AbsentMembers              []FamilyMember `json:"absent_members"`
	CompositionChanges         bool           `json:"composition_changes"`
	CompositionExplanation     string         `json:"composition_explanation"`
	Custody                    bool           `json:"custody"`
	CustodyExplanation         string         `json:"custody_explanation"`
	ElderlyEligibility         bool           `json:"elderly_eligibility"`
	DisabledEligibility        bool           `json:"disabled_eligibility"`
	ReceivedHudJan2010         bool           `json:"received_hud_jan_2010"`
	HudRecipients              []FamilyMember `json:"hud_recipients"`
	HudPropertyName            string         `json:"hud_property_name"`
	NeedsAccessibility         bool           `json:"needs_accessibility"`
	AccessibilityMembers       []FamilyMember `json:"accessibility_members"`
	MobilityAccessibility      bool           `json:"mobility_accessible"`
	VisionAccessibility        bool           `json:"vision_accessible"`
	HearingAccessibility       bool           `json:"hearing_accessible"`
	NeedsSpecialAccommodations bool           `json:"needs_special_accommodations"`
	MembersNeedingHelp         []FamilyMember `json:"members_needing_help"`
	AccommodationDescription   string         `json:"accommodation_description"`
}

type HistoryData struct {
	CurrentResidence      *ResidenceData  `json:"current_residence,omitempty"`
	PreviousResidences    []ResidenceData `json:"previous_residences"`
	AssistanceTerminated  bool            `json:"assistance_terminated"`
	AssistanceExplanation string          `json:"assistance_explanation"`
	Evicted               bool            `json:"evicted"`
	EvicitionExplanation  string          `json:"eviction_explanation"`
	OwesMoney             bool            `json:"owes_money"`
	DebtExplanation       string          `json:"debt_explanation"`
	MakingPayments        bool            `json:"making_payments"`
	BedBugs               bool            `json:"bed_bugs"`
	IsLifetimeSexOffender bool            `json:"is_lifetime_sex_offender"`
	LifetimeOffenders     []FamilyMember  `json:"lifetime_offenders"`
	IsViolentOffender     bool            `json:"is_violent_offender"`
	ViolentOffenders      []FamilyMember  `json:"violent_offenders"`
	IsMethConviction      bool            `json:"is_meth_conviction"`
	MethOffenders         []FamilyMember  `json:"meth_offenders"`
	HasDrugCharges        bool            `json:"has_drug_charges"`
	DrugOffenders         []FamilyMember  `json:"drug_offenders"`
	OtherCrimes           []CrimeData     `json:"other_crimes"`
}

type IncomeAndAssetsData struct {
	IncomeAssetEntires          []IncomeAndAssetData `json:"income_asset_entries"`
	ReceivesGovAssistance       bool                 `json:"receives_gov_assistance"`
	AssistanceProgramName       string               `json:"assistance_program_name"`
	ReceivesFromCurrentProperty bool                 `json:"receives_from_current_property"`
}

type FamilyMember struct {
	ID           int    `json:"id"`
	FirstName    string `json:"first_name"`
	LastName     string `json:"last_name"`
	Birthday     string `json:"birthday"`
	SSN          string `json:"ssn"`
	Gender       string `json:"gender"`
	Relationship string `json:"relationship"`
}

type ResidenceData struct {
	Address            string         `json:"address"`
	City               string         `json:"city"`
	State              string         `json:"state"`
	ZipCode            string         `json:"zip_code"`
	DateIn             string         `json:"date_in"`
	DateOut            string         `json:"date_out"`
	LandlordName       string         `json:"landlord_name"`
	LandlordPhone      string         `json:"landlord_phone"`
	MonthlyPayment     string         `json:"monthly_payment"`
	ResidenceType      string         `json:"residence_type"`
	OtherResidenceType string         `json:"other_residence_type"`
	AllReside          bool           `json:"all_reside"`
	NonResidingMembers []FamilyMember `json:"non_residing_members"`
}

type CrimeData struct {
	FamilyMember FamilyMember `json:"member"`
	Year         string       `json:"year"`
	Crime        string       `json:"crime"`
	City         string       `json:"city"`
	State        string       `json:"state"`
}

type IncomeAndAssetData struct {
	FamilyMember        FamilyMember `json:"member"`
	Type                string       `json:"type"`
	Source              string       `json:"source"`
	Amount              string       `json:"amount"`
	FrequencyOrLocation string       `json:"frequency_or_location"`
	MonthlyOrValue      string       `json:"monthly_or_value"`
}

type FileUploadData struct {
	Name string `json:"name"`
	Path string `json:"path"`
}

func ToFamilyMember(member *db.FamilyMemberModel) FamilyMember {
	return FamilyMember{
		ID:           member.ID,
		FirstName:    member.FirstName,
		LastName:     member.LastName,
		Birthday:     member.Birthday.Format("2006-01-02"),
		SSN:          member.Ssn,
		Gender:       member.Gender,
		Relationship: member.Relationship,
	}
}

func ToFamilyMembers(members []db.FamilyMemberModel) []FamilyMember {
	familyMembers := make([]FamilyMember, len(members))
	for i, member := range members {
		familyMembers[i] = ToFamilyMember(&member)
	}
	return familyMembers
}

func (member *FamilyMember) Hash() string {
	return fmt.Sprintf("%s-%s-%s-%s-%s-%s", member.FirstName, member.LastName, member.Birthday, member.SSN, member.Gender, member.Relationship)
}

func Equal(a *FamilyMember, b *FamilyMember) bool {
	return a.FirstName == b.FirstName && a.LastName == b.LastName && a.Birthday == b.Birthday && a.SSN == b.SSN && a.Gender == b.Gender && a.Relationship == b.Relationship
}

func ToResidenceData(residence *db.ResidenceInfoModel) ResidenceData {
	return ResidenceData{
		Address:            residence.Address,
		City:               residence.City,
		State:              residence.State,
		ZipCode:            residence.ZipCode,
		// DateIn:             residence.DateIn.Format("2006-01-02"),
		// DateOut:            residence.DateOut.Format("2006-01-02"),
		DateIn: 			residence.DateIn,
		DateOut:            residence.DateOut,
		LandlordName:       residence.LandlordName,
		LandlordPhone:      residence.LandlordPhone,
		MonthlyPayment:     residence.MonthlyPayment,
		ResidenceType:      residence.ResidenceType,
		OtherResidenceType: residence.OtherResidenceType,
		AllReside:          residence.AllReside,
		NonResidingMembers: ToFamilyMembers(residence.NonResidingMembers()),
	}
}

func ToResidenceDataList(residences []db.ResidenceInfoModel) []ResidenceData {
	residenceDataList := make([]ResidenceData, len(residences))
	for i, residence := range residences {
		residenceDataList[i] = ToResidenceData(&residence)
	}
	return residenceDataList
}

func ToCrimeData(crime *db.CrimeEntryModel) CrimeData {
	return CrimeData{
		FamilyMember: ToFamilyMember(crime.FamilyMember()),
		Year:         crime.Year,
		Crime:        crime.Crime,
		City:         crime.City,
		State:        crime.State,
	}
}

func ToCrimeDataList(crimes []db.CrimeEntryModel) []CrimeData {
	crimeDataList := make([]CrimeData, len(crimes))
	for i, crime := range crimes {
		crimeDataList[i] = ToCrimeData(&crime)
	}
	return crimeDataList
}

func ToIncomeAndAssetData(entry *db.IncomeAssetEntryModel) IncomeAndAssetData {
	return IncomeAndAssetData{
		FamilyMember:        ToFamilyMember(entry.FamilyMember()),
		Type:                entry.Type,
		Source:              entry.Source,
		Amount:              entry.Amount,
		FrequencyOrLocation: entry.FrequencyOrLocation,
		MonthlyOrValue:      entry.MonthlyOrValue,
	}
}

func ToIncomeAndAssetDataList(entries []db.IncomeAssetEntryModel) []IncomeAndAssetData {
	incomeAndAssetDataList := make([]IncomeAndAssetData, len(entries))
	for i, entry := range entries {
		incomeAndAssetDataList[i] = ToIncomeAndAssetData(&entry)
	}
	return incomeAndAssetDataList
}
