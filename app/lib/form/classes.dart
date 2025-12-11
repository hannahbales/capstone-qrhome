import 'package:app/util/util.dart';

class ApplicationData {
  PersonalInfo personalInfo = PersonalInfo();
  HousingPreferences housingPreferences = HousingPreferences();
  HouseholdInfo household = HouseholdInfo();
  HistoryInfo history = HistoryInfo();
  IncomeAndAssets income = IncomeAndAssets();
  List<FileUpload> uploadedFiles = [];

  factory ApplicationData.empty() {
    return ApplicationData(
      personalInfo: PersonalInfo(),
      housingPreferences: HousingPreferences(),
      household: HouseholdInfo(),
      history: HistoryInfo(),
      income: IncomeAndAssets(),
      uploadedFiles: [],
    );
  }

  ApplicationData({
    required this.personalInfo,
    required this.housingPreferences,
    required this.household,
    required this.history,
    required this.income,
    required this.uploadedFiles,
  });

  Object toJson() {
    return {
      'personal_info': personalInfo.toJson(),
      'housing_preferences': housingPreferences.toJson(),
      'household': household.toJson(),
      'history': history.toJson(),
      'income': income.toJson(),
      'uploaded_files':
          uploadedFiles.map((f) => {'name': f.name, 'path': f.path}).toList(),
    };
  }

  factory ApplicationData.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'personal_info': Map<String, dynamic> personalInfo,
        'housing_preferences': Map<String, dynamic> housingPreferences,
        'household': Map<String, dynamic> household,
        'history': Map<String, dynamic> history,
        'income': Map<String, dynamic> income,
        'uploaded_files': List<dynamic> uploadedFiles,
      } =>
        ApplicationData(
          personalInfo: PersonalInfo.fromJson(personalInfo),
          housingPreferences: HousingPreferences.fromJson(housingPreferences),
          household: HouseholdInfo.fromJson(household),
          history: HistoryInfo.fromJson(history),
          income: IncomeAndAssets.fromJson(income),
          uploadedFiles: uploadedFiles
              .map((f) => FileUpload(name: f['name'], path: f['path']))
              .toList(),
        ),
      _ => throw const FormatException('Failed to parse application data json'),
    };
  }
}

class PersonalInfo {
  String? firstName;
  String? lastName;
  String? email;
  String? dob;
  String? phone;
  String? ssn;
  String? address;
  String? gender;
  bool? isStudent;
  bool? isVeteran;
  bool? hasDisability;

  PersonalInfo({
    this.firstName,
    this.lastName,
    this.email,
    this.dob,
    this.phone,
    this.ssn,
    this.address,
    this.gender,
    this.isStudent,
    this.isVeteran,
    this.hasDisability,
  });

  Object toJson() {
    final map = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'dob': dob,
      'phone': phone,
      'ssn': ssn,
      'address': address,
      'gender': gender,
      'is_student': isStudent,
      'is_veteran': isVeteran,
      'has_disability': hasDisability,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'first_name': String firstName,
        'last_name': String lastName,
        'email': String email,
        'dob': String dob,
        'phone': String phone,
        'ssn': String ssn,
        'address': String address,
        'gender': String gender,
        'is_student': bool isStudent,
        'is_veteran': bool isVeteran,
        'has_disability': bool hasDisability,
      } =>
        PersonalInfo(
          firstName: firstName,
          lastName: lastName,
          email: email,
          dob: dob,
          phone: phone,
          ssn: ssn,
          address: address,
          gender: gender,
          isStudent: isStudent,
          isVeteran: isVeteran,
          hasDisability: hasDisability,
        ),
      _ => throw const FormatException('Failed to parse personal info json'),
    };
  }
}

class FamilyMember {
  int id;
  String firstName;
  String lastName;
  DateTime birthday;
  String ssn;
  String gender;
  String relationship;

  FamilyMember({
    this.id = 0,
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.ssn,
    required this.gender,
    required this.relationship,
  });

  Object toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birthday': dateToStringAPI(birthday),
      'ssn': ssn,
      'gender': gender,
      'relationship': relationship,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      birthday: DateTime.parse(json['birthday']),
      ssn: json['ssn'] ?? '',
      gender: json['gender'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }
}

class HousingPreferences {
  Map<String, String> rankings = {};
  String? desiredMoveInDate;

  HousingPreferences({
    this.rankings = const {},
    this.desiredMoveInDate,
  });

  Object toJson() {
    return {
      'rankings': rankings,
      'desired_move_in_date': desiredMoveInDate ?? '',
    };
  }

  factory HousingPreferences.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'rankings': Map<String, dynamic> rankings,
        'desired_move_in_date': String desiredMoveInDate,
      } =>
        HousingPreferences(
          rankings:
              rankings.map((key, value) => MapEntry(key, value as String)),
          desiredMoveInDate: desiredMoveInDate,
        ),
      _ =>
        throw const FormatException('Failed to parse housing preferences json'),
    };
  }
}

class HouseholdInfo {
  bool? hasPet;
  String? petDescription;
  bool? isSmoker;

  bool? moreThanOneResidence;
  String? absentMembersExplanation;
  List<FamilyMember> absentMembers = [];

  bool? compositionChanges;
  String? compositionExplanation;
  bool? custody;
  String? custodyExplanation;

  bool? elderlyEligibility;
  bool? disabledEligibility;
  bool? receivedHudJan2010;
  List<FamilyMember> hudRecipients = [];
  String? hudPropertyName;

  // Accessibility
  bool? needsAccessibility;
  List<FamilyMember> accessibilityMembers = [];
  bool? mobilityAccessible;
  bool? visionAccessible;
  bool? hearingAccessible;

  // Accommodations
  bool? needsSpecialAccommodations;
  List<FamilyMember> membersNeedingHelp = [];
  String? accommodationDescription;

  HouseholdInfo({
    this.hasPet,
    this.petDescription,
    this.isSmoker,
    this.moreThanOneResidence,
    this.absentMembersExplanation,
    List<FamilyMember>? absentMembers,
    this.compositionChanges,
    this.compositionExplanation,
    this.custody,
    this.custodyExplanation,
    this.elderlyEligibility,
    this.disabledEligibility,
    this.receivedHudJan2010,
    List<FamilyMember>? hudRecipients,
    this.hudPropertyName,
    this.needsAccessibility,
    List<FamilyMember>? accessibilityMembers,
    this.mobilityAccessible,
    this.visionAccessible,
    this.hearingAccessible,
    this.needsSpecialAccommodations,
    List<FamilyMember>? membersNeedingHelp,
    this.accommodationDescription,
  }) {
    this.absentMembers = absentMembers ?? [];
    this.hudRecipients = hudRecipients ?? [];
    this.accessibilityMembers = accessibilityMembers ?? [];
    this.membersNeedingHelp = membersNeedingHelp ?? [];
  }

  Object toJson() {
    return {
      'has_pet': hasPet ?? false,
      'pet_description': petDescription ?? '',
      'is_smoker': isSmoker ?? false,
      'more_than_one_residence': moreThanOneResidence ?? false,
      'absent_members_explanation': absentMembersExplanation ?? '',
      'absent_members': absentMembers.map((m) => m.toJson()).toList(),
      'composition_changes': compositionChanges ?? false,
      'composition_explanation': compositionExplanation ?? '',
      'custody': custody ?? false,
      'custody_explanation': custodyExplanation ?? '',
      'elderly_eligibility': elderlyEligibility ?? false,
      'disabled_eligibility': disabledEligibility ?? false,
      'received_hud_jan_2010': receivedHudJan2010 ?? false,
      'hud_recipients': hudRecipients.map((m) => m.toJson()).toList(),
      'hud_property_name': hudPropertyName ?? '',
      'needs_accessibility': needsAccessibility ?? false,
      'accessibility_members':
          accessibilityMembers.map((m) => m.toJson()).toList(),
      'mobility_accessible': mobilityAccessible ?? false,
      'vision_accessible': visionAccessible ?? false,
      'hearing_accessible': hearingAccessible ?? false,
      'needs_special_accommodations': needsSpecialAccommodations ?? false,
      'members_needing_help':
          membersNeedingHelp.map((m) => m.toJson()).toList(),
      'accommodation_description': accommodationDescription ?? '',
    };
  }

  factory HouseholdInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'has_pet': bool hasPet,
        'pet_description': String petDescription,
        'is_smoker': bool isSmoker,
        'more_than_one_residence': bool moreThanOneResidence,
        'absent_members_explanation': String absentMembersExplanation,
        'absent_members': List<dynamic> absentMembers,
        'composition_changes': bool compositionChanges,
        'composition_explanation': String compositionExplanation,
        'custody': bool custody,
        'custody_explanation': String custodyExplanation,
        'elderly_eligibility': bool elderlyEligibility,
        'disabled_eligibility': bool disabledEligibility,
        'received_hud_jan_2010': bool receivedHudJan2010,
        'hud_recipients': List<dynamic> hudRecipients,
        'hud_property_name': String hudPropertyName,
        'needs_accessibility': bool needsAccessibility,
        'accessibility_members': List<dynamic> accessibilityMembers,
        'mobility_accessible': bool mobilityAccessible,
        'vision_accessible': bool visionAccessible,
        'hearing_accessible': bool hearingAccessible,
        'needs_special_accommodations': bool needsSpecialAccommodations,
        'members_needing_help': List<dynamic> membersNeedingHelp,
        'accommodation_description': String accommodationDescription,
      } =>
        HouseholdInfo(
          hasPet: hasPet,
          petDescription: petDescription,
          isSmoker: isSmoker,
          moreThanOneResidence: moreThanOneResidence,
          absentMembersExplanation: absentMembersExplanation,
          absentMembers:
              absentMembers.map((m) => FamilyMember.fromJson(m)).toList(),
          compositionChanges: compositionChanges,
          compositionExplanation: compositionExplanation,
          custody: custody,
          custodyExplanation: custodyExplanation,
          elderlyEligibility: elderlyEligibility,
          disabledEligibility: disabledEligibility,
          receivedHudJan2010: receivedHudJan2010,
          hudRecipients:
              hudRecipients.map((m) => FamilyMember.fromJson(m)).toList(),
          hudPropertyName: hudPropertyName,
          needsAccessibility: needsAccessibility,
          accessibilityMembers: accessibilityMembers
              .map((m) => FamilyMember.fromJson(m))
              .toList(),
          mobilityAccessible: mobilityAccessible,
          visionAccessible: visionAccessible,
          hearingAccessible: hearingAccessible,
          needsSpecialAccommodations: needsSpecialAccommodations,
          membersNeedingHelp:
              membersNeedingHelp.map((m) => FamilyMember.fromJson(m)).toList(),
          accommodationDescription: accommodationDescription,
        ),
      _ => throw const FormatException('Failed to parse household info json'),
    };
  }
}

enum ResidenceType { rent, own, other }

class ResidenceInfo {
  String? address;
  String? city;
  String? state;
  String? zip;
  String? dateIn;
  String? dateOut;
  String? landlordName;
  String? landlordPhone;
  String? monthlyPayment;
  String? residenceType;
  String? otherResidenceType;
  bool? allReside;
  List<FamilyMember> nonResidingMembers = [];

  ResidenceInfo({
    this.address,
    this.city,
    this.state,
    this.zip,
    this.dateIn,
    this.dateOut,
    this.landlordName,
    this.landlordPhone,
    this.monthlyPayment,
    this.residenceType = 'rent',
    this.otherResidenceType,
    this.allReside = false,
    List<FamilyMember>? nonResidingMembers,
  }) {
    this.nonResidingMembers = nonResidingMembers ?? [];
  }

  Object toJson() {
    return {
      'address': address ?? '',
      'city': city ?? '',
      'state': state ?? '',
      'zip_code': zip ?? '',
      'date_in': dateIn ?? '',
      'date_out': dateOut ?? '',
      'landlord_name': landlordName ?? '',
      'landlord_phone': landlordPhone ?? '',
      'monthly_payment': monthlyPayment ?? '',
      'residence_type': residenceType ?? '',
      'other_residence_type': otherResidenceType ?? '',
      'all_reside': allReside ?? false,
      'non_residing_members':
          nonResidingMembers.map((m) => m.toJson()).toList(),
    };
  }

  factory ResidenceInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'address': String address,
        'city': String city,
        'state': String state,
        'zip_code': String zip,
        'date_in': String dateIn,
        'date_out': String dateOut,
        'landlord_name': String landlordName,
        'landlord_phone': String landlordPhone,
        'monthly_payment': String monthlyPayment,
        'residence_type': String residenceType,
        'other_residence_type': String otherResidenceType,
        'all_reside': bool allReside,
        'non_residing_members': List<dynamic> nonResidingMembers,
      } =>
        ResidenceInfo(
          address: address,
          city: city,
          state: state,
          zip: zip,
          dateIn: dateIn,
          dateOut: dateOut,
          landlordName: landlordName,
          landlordPhone: landlordPhone,
          monthlyPayment: monthlyPayment,
          residenceType: residenceType,
          otherResidenceType: otherResidenceType,
          allReside: allReside,
          nonResidingMembers:
              nonResidingMembers.map((m) => FamilyMember.fromJson(m)).toList(),
        ),
      _ => throw const FormatException('Failed to parse residence info json'),
    };
  }
}

class CrimeEntry {
  FamilyMember? member;
  String year = '';
  String crime = '';
  String city = '';
  String state = '';

  CrimeEntry({
    this.member,
    this.year = '',
    this.crime = '',
    this.city = '',
    this.state = '',
  });

  Object toJson() {
    return {
      'member': member?.toJson() ?? {},
      'year': year,
      'crime': crime,
      'city': city,
      'state': state,
    };
  }

  factory CrimeEntry.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'member': Map<String, dynamic> member,
        'year': String year,
        'crime': String crime,
        'city': String city,
        'state': String state,
      } =>
        CrimeEntry(
          member: member.isNotEmpty ? FamilyMember.fromJson(member) : null,
          year: year,
          crime: crime,
          city: city,
          state: state,
        ),
      _ => throw const FormatException('Failed to parse crime entry json'),
    };
  }
}

class HistoryInfo {
  ResidenceInfo? currentResidence;
  List<ResidenceInfo> previousResidences = [];

  bool? assistanceTerminated;
  String? assistanceExplanation;

  bool? evicted;
  String? evictionExplanation;

  bool? owesMoney;
  String? debtExplanation;

  bool? makingPayments;
  bool? bedBugs;

  bool? isLifetimeSexOffender;
  List<FamilyMember> lifetimeOffenders = [];

  bool? isViolentOffender;
  List<FamilyMember> violentOffenders = [];

  bool? isMethConviction;
  List<FamilyMember> methOffenders = [];

  bool? hasDrugCharges;
  List<FamilyMember> drugOffenders = [];

  List<CrimeEntry> otherCrimes = [];

  HistoryInfo({
    this.currentResidence,
    List<ResidenceInfo>? previousResidences,
    this.assistanceTerminated,
    this.assistanceExplanation,
    this.evicted,
    this.evictionExplanation,
    this.owesMoney,
    this.debtExplanation,
    this.makingPayments,
    this.bedBugs,
    this.isLifetimeSexOffender,
    List<FamilyMember>? lifetimeOffenders,
    this.isViolentOffender,
    List<FamilyMember>? violentOffenders,
    this.isMethConviction,
    List<FamilyMember>? methOffenders,
    this.hasDrugCharges,
    List<FamilyMember>? drugOffenders,
    List<CrimeEntry>? otherCrimes,
  }) {
    this.previousResidences = previousResidences ?? [];
    this.lifetimeOffenders = lifetimeOffenders ?? [];
    this.violentOffenders = violentOffenders ?? [];
    this.methOffenders = methOffenders ?? [];
    this.drugOffenders = drugOffenders ?? [];
    this.otherCrimes = otherCrimes ?? [];
  }

  Object toJson() {
    var json = <String, dynamic>{
      'current_residence': currentResidence?.toJson(),
      'previous_residences': previousResidences.map((r) => r.toJson()).toList(),
      'assistance_terminated': assistanceTerminated ?? false,
      'assistance_explanation': assistanceExplanation ?? '',
      'evicted': evicted ?? false,
      'eviction_explanation': evictionExplanation ?? '',
      'owes_money': owesMoney ?? false,
      'debt_explanation': debtExplanation ?? '',
      'making_payments': makingPayments ?? false,
      'bed_bugs': bedBugs ?? false,
      'is_lifetime_sex_offender': isLifetimeSexOffender ?? false,
      'lifetime_offenders': lifetimeOffenders.map((m) => m.toJson()).toList(),
      'is_violent_offender': isViolentOffender ?? false,
      'violent_offenders': violentOffenders.map((m) => m.toJson()).toList(),
      'is_meth_conviction': isMethConviction ?? false,
      'meth_offenders': methOffenders.map((m) => m.toJson()).toList(),
      'has_drug_charges': hasDrugCharges ?? false,
      'drug_offenders': drugOffenders.map((m) => m.toJson()).toList(),
      'other_crimes': otherCrimes.map((c) => c.toJson()).toList(),
    };
    json.removeWhere((key, value) => value == null);
    return json;
  }

  factory HistoryInfo.fromJson(Map<String, dynamic> json) {
    return HistoryInfo(
      currentResidence: json['current_residence'] != null
          ? ResidenceInfo.fromJson(json['current_residence'])
          : null,
      previousResidences: (json['previous_residences'] as List<dynamic>)
          .map((r) => ResidenceInfo.fromJson(r))
          .toList(),
      assistanceTerminated: json['assistance_terminated'] as bool,
      assistanceExplanation: json['assistance_explanation'] as String,
      evicted: json['evicted'] as bool,
      evictionExplanation: json['eviction_explanation'] as String,
      owesMoney: json['owes_money'] as bool,
      debtExplanation: json['debt_explanation'] as String,
      makingPayments: json['making_payments'] as bool,
      bedBugs: json['bed_bugs'] as bool,
      isLifetimeSexOffender: json['is_lifetime_sex_offender'] as bool,
      lifetimeOffenders: (json['lifetime_offenders'] as List<dynamic>)
          .map((m) => FamilyMember.fromJson(m))
          .toList(),
      isViolentOffender: json['is_violent_offender'] as bool,
      violentOffenders: (json['violent_offenders'] as List<dynamic>)
          .map((m) => FamilyMember.fromJson(m))
          .toList(),
      isMethConviction: json['is_meth_conviction'] as bool,
      methOffenders: (json['meth_offenders'] as List<dynamic>)
          .map((m) => FamilyMember.fromJson(m))
          .toList(),
      hasDrugCharges: json['has_drug_charges'] as bool,
      drugOffenders: (json['drug_offenders'] as List<dynamic>)
          .map((m) => FamilyMember.fromJson(m))
          .toList(),
      otherCrimes: (json['other_crimes'] as List<dynamic>)
          .map((c) => CrimeEntry.fromJson(c))
          .toList(),
    );
  }
}

class IncomeAssetEntry {
  FamilyMember? member;
  String type = 'Income';
  String source = '';
  String amount = '';
  String frequencyOrLocation = '';
  String monthlyOrValue = '';

  IncomeAssetEntry({
    this.member,
    this.type = 'Income',
    this.source = '',
    this.amount = '',
    this.frequencyOrLocation = '',
    this.monthlyOrValue = '',
  });

  Object toJson() {
    return {
      'member': member?.toJson() ?? {},
      'type': type,
      'source': source,
      'amount': amount,
      'frequency_or_location': frequencyOrLocation,
      'monthly_or_value': monthlyOrValue,
    };
  }

  factory IncomeAssetEntry.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'member': Map<String, dynamic> member,
        'type': String type,
        'source': String source,
        'amount': String amount,
        'frequency_or_location': String frequencyOrLocation,
        'monthly_or_value': String monthlyOrValue,
      } =>
        IncomeAssetEntry(
          member: member.isNotEmpty ? FamilyMember.fromJson(member) : null,
          type: type,
          source: source,
          amount: amount,
          frequencyOrLocation: frequencyOrLocation,
          monthlyOrValue: monthlyOrValue,
        ),
      _ =>
        throw const FormatException('Failed to parse income asset entry json'),
    };
  }
}

class IncomeAndAssets {
  List<IncomeAssetEntry> incomeAssetEntries = [];

  bool? receivesGovAssistance;
  String? assistanceProgramName;

  bool? receivesFromCurrentProperty;

  IncomeAndAssets({
    List<IncomeAssetEntry>? incomeAssetEntries,
    this.receivesGovAssistance,
    this.assistanceProgramName,
    this.receivesFromCurrentProperty,
  }) {
    this.incomeAssetEntries = incomeAssetEntries ?? [];
  }

  Object toJson() {
    return {
      'income_asset_entries':
          incomeAssetEntries.map((e) => e.toJson()).toList(),
      'receives_gov_assistance': receivesGovAssistance ?? false,
      'assistance_program_name': assistanceProgramName ?? '',
      'receives_from_current_property': receivesFromCurrentProperty ?? false,
    };
  }

  factory IncomeAndAssets.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'income_asset_entries': List<dynamic> incomeAssetEntries,
        'receives_gov_assistance': bool receivesGovAssistance,
        'assistance_program_name': String assistanceProgramName,
        'receives_from_current_property': bool receivesFromCurrentProperty,
      } =>
        IncomeAndAssets(
          incomeAssetEntries: incomeAssetEntries
              .map((e) => IncomeAssetEntry.fromJson(e))
              .toList(),
          receivesGovAssistance: receivesGovAssistance,
          assistanceProgramName: assistanceProgramName,
          receivesFromCurrentProperty: receivesFromCurrentProperty,
        ),
      _ =>
        throw const FormatException('Failed to parse income and assets json'),
    };
  }
}

class FileUpload {
  String name;
  String path;

  FileUpload({required this.name, required this.path});
}
