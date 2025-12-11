import 'package:flutter/material.dart';
import 'helpers.dart';
import 'classes.dart';

class IncomeForm extends StatefulWidget {
  final ApplicationData data;
  final bool isReadOnly;
  final List<FamilyMember> familyMembers;

  const IncomeForm({
    super.key,
    required this.data,
    required this.isReadOnly,
    required this.familyMembers,
  });

  @override
  // ignore: library_private_types_in_public_api
  _IncomeFormState createState() => _IncomeFormState();
}

class _IncomeFormState extends State<IncomeForm> {
  late IncomeAndAssets income;
  late Map<int, FamilyMember> familyMembers;
  late bool isReadOnly;

  @override
  void initState() {
    super.initState();
    income = widget.data.income;
    Map<int, FamilyMember> members = {};
    for (var member in widget.familyMembers) {
      members[member.id] = member;
    }
    familyMembers = members;
    isReadOnly = widget.isReadOnly;
  }

  final List<String> frequencies = [
    'Hourly',
    'Weekly',
    'Bi-weekly',
    'Semi-monthly',
    'Monthly',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Income and Asset Information",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text("List all income and assets for each household member."),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: income.incomeAssetEntries.length,
          itemBuilder: (context, index) {
            final entry = income.incomeAssetEntries[index];

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: entry.member?.id,
                      items: familyMembers.values
                          .map<DropdownMenuItem<int>>((member) {
                        return DropdownMenuItem<int>(
                          value: member.id,
                          child: Text('${member.firstName} ${member.lastName}'),
                        );
                      }).toList(),
                      onChanged: isReadOnly
                          ? null
                          : (val) => setState(() => entry.member =
                              val == null ? null : familyMembers[val]),
                      decoration: InputDecoration(
                        labelText: "Household Member",
                      ),
                      disabledHint: entry.member == null
                          ? Text("No selection")
                          : Text(
                              '${entry.member!.firstName} ${entry.member!.lastName}',
                            ),
                    ),
                    DropdownButtonFormField<String>(
                      value: entry.type,
                      items: ['Income', 'Asset'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: isReadOnly
                          ? null
                          : (val) => setState(() {
                                entry.type = val ?? 'Income';
                                entry.source = '';
                                entry.amount = '';
                                entry.frequencyOrLocation = '';
                                entry.monthlyOrValue = '';
                              }),
                      decoration: InputDecoration(labelText: "Entry Type"),
                      disabledHint: Text(entry.type),
                    ),
                    if (entry.type == 'Income')
                      Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Income or Benefit Source",
                            ),
                            initialValue: entry.source,
                            onChanged:
                                isReadOnly ? null : (val) => entry.source = val,
                            enabled: !isReadOnly,
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Amount Received",
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: entry.amount,
                            onChanged:
                                isReadOnly ? null : (val) => entry.amount = val,
                            enabled: !isReadOnly,
                          ),
                          DropdownButtonFormField<String>(
                            value: entry.frequencyOrLocation.isNotEmpty
                                ? entry.frequencyOrLocation
                                : null,
                            items: frequencies.map((freq) {
                              return DropdownMenuItem(
                                value: freq,
                                child: Text(freq),
                              );
                            }).toList(),
                            onChanged: isReadOnly
                                ? null
                                : (val) => setState(
                                      () =>
                                          entry.frequencyOrLocation = val ?? '',
                                    ),
                            decoration: InputDecoration(labelText: "Frequency"),
                            disabledHint: entry.frequencyOrLocation.isNotEmpty
                                ? Text(entry.frequencyOrLocation)
                                : Text("No selection"),
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Total Monthly Income",
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: entry.monthlyOrValue,
                            onChanged: isReadOnly
                                ? null
                                : (val) => entry.monthlyOrValue = val,
                            enabled: !isReadOnly,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Type of Asset",
                            ),
                            initialValue: entry.source,
                            onChanged:
                                isReadOnly ? null : (val) => entry.source = val,
                            enabled: !isReadOnly,
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Current Value",
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: entry.amount,
                            onChanged:
                                isReadOnly ? null : (val) => entry.amount = val,
                            enabled: !isReadOnly,
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Bank Name / Asset Location",
                            ),
                            initialValue: entry.frequencyOrLocation,
                            onChanged: isReadOnly
                                ? null
                                : (val) => entry.frequencyOrLocation = val,
                            enabled: !isReadOnly,
                          ),
                        ],
                      ),
                    if (!isReadOnly && income.incomeAssetEntries.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            "Remove",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () => setState(
                            () => income.incomeAssetEntries.removeAt(index),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 12),
        if (!isReadOnly)
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text("Add Income or Asset"),
            onPressed: () => setState(
                () => income.incomeAssetEntries.add(IncomeAssetEntry())),
          ),
        SizedBox(height: 20),
        Text(
          "Rental Assistance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        BoolRadioRow(
          label:
              "Will your household receive rental assistance from the government?",
          value: income.receivesGovAssistance,
          onChanged: (val) =>
              setState(() => income.receivesGovAssistance = val),
          isReadOnly: isReadOnly,
        ),
        if (income.receivesGovAssistance == true)
          TextFormField(
            decoration: InputDecoration(labelText: "Name of program/agency"),
            initialValue: income.assistanceProgramName,
            onChanged:
                isReadOnly ? null : (val) => income.assistanceProgramName = val,
            enabled: !isReadOnly,
          ),
        BoolRadioRow(
          label:
              "Are you currently receiving rental assistance from the property?",
          value: income.receivesFromCurrentProperty,
          onChanged: (val) =>
              setState(() => income.receivesFromCurrentProperty = val),
          isReadOnly: isReadOnly,
        ),
      ],
    );
  }
}
