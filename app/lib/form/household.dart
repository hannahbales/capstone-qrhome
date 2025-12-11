import 'package:flutter/material.dart';
import 'helpers.dart';
import 'classes.dart';

class HouseholdForm extends StatefulWidget {
  final ApplicationData data;
  final bool isReadOnly;
  final List<FamilyMember> familyMembers;

  const HouseholdForm({
    Key? key,
    required this.data,
    required this.isReadOnly,
    required this.familyMembers,
  }) : super(key: key);

  @override
  _HouseholdFormState createState() => _HouseholdFormState();
}

class _HouseholdFormState extends State<HouseholdForm> {
  late HouseholdInfo household;
  late bool isReadOnly;

  @override
  void initState() {
    super.initState();
    household = widget.data.household;
    isReadOnly = widget.isReadOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Household Information",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          "Please exit the form and edit your family if you haven't already.",
        ),
        // Pets
        BoolRadioRow(
          label: "Do you plan to have a pet?",
          value: household.hasPet,
          onChanged: (val) => setState(() => household.hasPet = val),
          isReadOnly: isReadOnly,
        ),
        if (household.hasPet == true)
          TextFormField(
            decoration: InputDecoration(labelText: "Describe your pet(s)"),
            initialValue: household.petDescription,
            onChanged: (val) => household.petDescription = val,
            enabled: !isReadOnly,
          ),

        // Smoking
        BoolRadioRow(
          label: "Do you smoke?",
          value: household.isSmoker,
          onChanged: (val) => setState(() => household.isSmoker = val),
          isReadOnly: isReadOnly,
        ),

        // Multiple residences
        BoolRadioRow(
          label: "Will your household have more than one residence?",
          value: household.moreThanOneResidence,
          onChanged: (val) =>
              setState(() => household.moreThanOneResidence = val),
          isReadOnly: isReadOnly,
        ),
        if (household.moreThanOneResidence == true)
          TextFormField(
            decoration: InputDecoration(labelText: "If yes, explain"),
            initialValue: household.absentMembersExplanation,
            onChanged: (val) => household.absentMembersExplanation = val,
            enabled: !isReadOnly,
          ),

        // Composition change
        BoolRadioRow(
          label: "Any household composition changes in 12 months?",
          value: household.compositionChanges,
          onChanged: (val) =>
              setState(() => household.compositionChanges = val),
          isReadOnly: isReadOnly,
        ),
        if (household.compositionChanges == true)
          TextFormField(
            decoration: InputDecoration(labelText: "If yes, explain"),
            initialValue: household.compositionExplanation,
            onChanged: (val) => household.compositionExplanation = val,
            enabled: !isReadOnly,
          ),

        // Custody
        BoolRadioRow(
          label: "Do you have custody of minor children?",
          value: household.custody,
          allowNA: true,
          onChanged: (val) => setState(() => household.custody = val),
          isReadOnly: isReadOnly,
        ),
        if (household.custody == false)
          TextFormField(
            decoration: InputDecoration(
              labelText: "If no, what % of time are they with you?",
            ),
            initialValue: household.custodyExplanation,
            onChanged: (val) => household.custodyExplanation = val,
            enabled: !isReadOnly,
          ),

        // Eligibility
        BoolRadioRow(
          label: "Are you claiming eligibility as an elderly person?",
          value: household.elderlyEligibility,
          onChanged: (val) =>
              setState(() => household.elderlyEligibility = val),
          isReadOnly: isReadOnly,
        ),

        BoolRadioRow(
          label: "Are you claiming eligibility as a disabled person?",
          value: household.disabledEligibility,
          onChanged: (val) =>
              setState(() => household.disabledEligibility = val),
          isReadOnly: isReadOnly,
        ),

        // HUD on Jan 31, 2010
        BoolRadioRow(
          label: "Were any household members receiving HUD on Jan 31, 2010?",
          value: household.receivedHudJan2010,
          onChanged: (val) =>
              setState(() => household.receivedHudJan2010 = val),
          isReadOnly: isReadOnly,
        ),
        if (household.receivedHudJan2010 == true) ...[
          ChooseFamilyMembersWidget(
            members: widget.familyMembers,
            selectedMembers: household.hudRecipients,
            onChanged: (val) => setState(() => household.hudRecipients = val),
            label: "Which member received HUD?",
            isReadOnly: isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Property Name"),
            initialValue: household.hudPropertyName,
            onChanged: (val) => household.hudPropertyName = val,
            enabled: !isReadOnly,
          ),
        ],

        SizedBox(height: 24),
        Text(
          "Reasonable Accommodations/Modifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        // Accessibility
        BoolRadioRow(
          label: "Do you or a household member need accessibility features?",
          value: household.needsAccessibility,
          onChanged: (val) =>
              setState(() => household.needsAccessibility = val),
          isReadOnly: isReadOnly,
        ),
        if (household.needsAccessibility == true) ...[
          ChooseFamilyMembersWidget(
            members: widget.familyMembers,
            selectedMembers: household.accessibilityMembers,
            onChanged: (val) =>
                setState(() => household.accessibilityMembers = val),
            label: "Who needs accessibility features?",
            isReadOnly: isReadOnly,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Mobility Accessible"),
            value: household.mobilityAccessible,
            onChanged: (val) =>
                setState(() => household.mobilityAccessible = val ?? false),
            enabled: !isReadOnly,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Vision Accessible"),
            value: household.visionAccessible,
            onChanged: (val) =>
                setState(() => household.visionAccessible = val ?? false),
            enabled: !isReadOnly,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Hearing Accessible"),
            value: household.hearingAccessible,
            onChanged: (val) =>
                setState(() => household.hearingAccessible = val ?? false),
            enabled: !isReadOnly,
          ),
        ],

        // Reasonable accommodations
        BoolRadioRow(
          label: "Do you or a member need any accommodations to live here?",
          value: household.needsSpecialAccommodations,
          onChanged: (val) =>
              setState(() => household.needsSpecialAccommodations = val),
          isReadOnly: isReadOnly,
        ),
        if (household.needsSpecialAccommodations == true) ...[
          ChooseFamilyMembersWidget(
            members: widget.familyMembers,
            selectedMembers: household.membersNeedingHelp,
            onChanged: (val) =>
                setState(() => household.membersNeedingHelp = val),
            label: "Who needs accommodations?",
            isReadOnly: isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Describe What Is Needed"),
            maxLines: 3,
            initialValue: household.accommodationDescription,
            onChanged: (val) => household.accommodationDescription = val,
            enabled: !isReadOnly,
          ),
        ],
      ],
    );
  }
}
