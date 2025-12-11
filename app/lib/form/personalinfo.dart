import 'package:flutter/material.dart';
import 'helpers.dart';
import 'classes.dart';

final _kGenderOptions = [
  'Male',
  'Female',
  'Non-Binary',
  'Prefer not to say',
  'Other',
];

class PersonalInfoForm extends StatefulWidget {
  final ApplicationData data;
  final bool isReadOnly;

  const PersonalInfoForm({
    Key? key,
    required this.data,
    required this.isReadOnly,
  }) : super(key: key);

  @override
  _PersonalInfoFormState createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  @override
  Widget build(BuildContext context) {
    final info = widget.data.personalInfo;
    final isReadOnly = widget.isReadOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(labelText: "First Name"),
          initialValue: info.firstName,
          onChanged: (val) => info.firstName = val,
          enabled: !isReadOnly,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: "Last Name"),
          initialValue: info.lastName,
          onChanged: (val) => info.lastName = val,
          enabled: !isReadOnly,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: "Email Address"),
          initialValue: info.email,
          onChanged: (val) => info.email = val,
          enabled: !isReadOnly,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: "Date of Birth"),
          keyboardType: TextInputType.datetime,
          initialValue: info.dob,
          onChanged: (val) => info.dob = val,
          enabled: !isReadOnly,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: "Phone Number"),
          keyboardType: TextInputType.phone,
          initialValue: info.phone,
          onChanged: (val) => info.phone = val,
          enabled: !isReadOnly,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: "Social Security Number"),
          keyboardType: TextInputType.number,
          initialValue: info.ssn,
          onChanged: (val) => info.ssn = val,
          enabled: !isReadOnly,
        ),
        TextFormField(
          decoration: InputDecoration(labelText: "Mailing Address"),
          initialValue: info.address,
          onChanged: (val) => info.address = val,
          enabled: !isReadOnly,
        ),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "Gender",
            filled: isReadOnly,
            fillColor: isReadOnly ? Colors.grey.shade200 : null,
          ),
          value:
              _kGenderOptions.any((x) => x == info.gender)
                  ? info.gender
                  : _kGenderOptions.first,
          items:
              _kGenderOptions.map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
          onChanged:
              isReadOnly ? null : (val) => setState(() => info.gender = val),
        ),

        // Are you a student?
        BoolRadioRow(
          label: "Are you a student?",
          value: info.isStudent,
          onChanged: (val) => setState(() => info.isStudent = val),
          isReadOnly: isReadOnly,
        ),

        // Are you a veteran?
        BoolRadioRow(
          label: "Are you a veteran?",
          value: info.isVeteran,
          onChanged: (val) => setState(() => info.isVeteran = val),
          isReadOnly: isReadOnly,
        ),

        // Do you have a disability?
        BoolRadioRow(
          label: "Do you have a disability?",
          value: info.hasDisability,
          onChanged: (val) => setState(() => info.hasDisability = val),
          isReadOnly: isReadOnly,
        ),
      ],
    );
  }
}
