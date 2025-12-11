import 'package:flutter/material.dart';
import 'helpers.dart';
import 'classes.dart';

class HistoryForm extends StatefulWidget {
  final ApplicationData data;
  final bool isReadOnly;
  final Map<int, FamilyMember> familyMembers = {};

  HistoryForm({
    super.key,
    required this.data,
    required this.isReadOnly,
    required List<FamilyMember> familyMembers,
  }) {
    for (var member in familyMembers) {
      this.familyMembers[member.id] = member;
    }
  }

  @override
  _HistoryFormState createState() => _HistoryFormState();
}

class _HistoryFormState extends State<HistoryForm> {
  late HistoryInfo history;
  late bool isReadOnly;

  @override
  void initState() {
    super.initState();
    setState(() {
      history = widget.data.history;
      isReadOnly = widget.isReadOnly;
    });
  }

  Widget crimeEntry(int index) {
    final entry = history.otherCrimes[index];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: entry.member?.id,
              items: widget.familyMembers.values
                  .map<DropdownMenuItem<int>>((member) {
                return DropdownMenuItem<int>(
                  value: member.id,
                  child: Text('${member.firstName} ${member.lastName}'),
                );
              }).toList(),
              onChanged: isReadOnly
                  ? null
                  : (val) => setState(() => entry.member =
                      val == null ? null : widget.familyMembers[val]),
              decoration: InputDecoration(
                labelText: "Name",
              ),
              disabledHint: entry.member == null
                  ? Text("No selection")
                  : Text(
                      '${entry.member!.firstName} ${entry.member!.lastName}',
                    ),
            ),
            TextFormField(
              readOnly: isReadOnly,
              decoration: InputDecoration(labelText: "Year"),
              initialValue: entry.year,
              onChanged: (val) => entry.year = val,
            ),
            TextFormField(
              readOnly: isReadOnly,
              decoration: InputDecoration(labelText: "Crime"),
              initialValue: entry.crime,
              onChanged: (val) => entry.crime = val,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: isReadOnly,
                    decoration: InputDecoration(labelText: "City"),
                    initialValue: entry.city,
                    onChanged: (val) => entry.city = val,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    readOnly: isReadOnly,
                    decoration: InputDecoration(labelText: "State"),
                    initialValue: entry.state,
                    onChanged: (val) => entry.state = val,
                  ),
                ),
              ],
            ),
            Builder(builder: (context) {
              if (!isReadOnly) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      "Remove",
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () => setState(
                      () => history.otherCrimes.removeAt(index),
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var current = history.currentResidence;
    if (current == null) {
      current = ResidenceInfo();
      history.currentResidence = current;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Current Residence",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Street Address"),
            initialValue: current.address,
            onChanged: (val) => current!.address = val,
            enabled: !isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "City"),
            initialValue: current.city,
            onChanged: (val) => current!.city = val,
            enabled: !isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "State"),
            initialValue: current.state,
            onChanged: (val) => current!.state = val,
            enabled: !isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Zip"),
            initialValue: current.zip,
            onChanged: (val) => current!.zip = val,
            enabled: !isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Date In"),
            initialValue: current.dateIn,
            onChanged: (val) => current!.dateIn = val,
            enabled: !isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Landlord Name"),
            initialValue: current.landlordName,
            onChanged: (val) => current!.landlordName = val,
            enabled: !isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Landlord Phone Number"),
            initialValue: current.landlordPhone,
            onChanged: (val) => current!.landlordPhone = val,
            enabled: !isReadOnly,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: "Monthly Payment"),
            initialValue: current.monthlyPayment,
            keyboardType: TextInputType.number,
            onChanged: (val) => current!.monthlyPayment = val,
            enabled: !isReadOnly,
          ),

          // Residence Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Residence Type:"),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: "rent",
                        groupValue: current.residenceType,
                        onChanged: isReadOnly
                            ? null
                            : (val) =>
                                setState(() => current!.residenceType = val),
                      ),
                      Text("Rent"),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: "own",
                        groupValue: current.residenceType,
                        onChanged: isReadOnly
                            ? null
                            : (val) =>
                                setState(() => current!.residenceType = val),
                      ),
                      Text("Own"),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: "other",
                        groupValue: current.residenceType,
                        onChanged: isReadOnly
                            ? null
                            : (val) =>
                                setState(() => current!.residenceType = val),
                      ),
                      Text("Other:"),
                      if (current.residenceType == "other")
                        SizedBox(
                          width: 200,
                          child: TextFormField(
                            initialValue: current.otherResidenceType,
                            onChanged: isReadOnly
                                ? null
                                : (val) => current!.otherResidenceType = val,
                            decoration: InputDecoration(hintText: "Type here"),
                            enabled: !isReadOnly,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          BoolRadioRow(
            label: "Do all applicant household members reside here?",
            value: current.allReside,
            onChanged: (val) => setState(() => current!.allReside = val),
            isReadOnly: isReadOnly,
          ),
          if (current.allReside == false && widget.familyMembers.isNotEmpty)
            ChooseFamilyMembersWidget(
              members: widget.familyMembers.values.toList(),
              selectedMembers: current.nonResidingMembers,
              onChanged: (val) =>
                  setState(() => current!.nonResidingMembers = val),
              label: "Who does not reside here?",
              isReadOnly: isReadOnly,
            ),
          SizedBox(height: 20),
          BoolRadioRow(
            label: "Assistance or tenancy terminated in last 3 years?",
            value: history.assistanceTerminated,
            onChanged: (val) =>
                setState(() => history.assistanceTerminated = val),
            isReadOnly: isReadOnly,
          ),
          if (history.assistanceTerminated == true)
            TextFormField(
              decoration: InputDecoration(labelText: "If yes, please explain"),
              initialValue: history.assistanceExplanation,
              onChanged: (val) => history.assistanceExplanation = val,
              enabled: !isReadOnly,
            ),
          BoolRadioRow(
            label: "Evicted for drug/criminal activity in last 3 years?",
            value: history.evicted,
            onChanged: (val) => setState(() => history.evicted = val),
            isReadOnly: isReadOnly,
          ),
          if (history.evicted == true)
            TextFormField(
              decoration: InputDecoration(labelText: "If yes, please explain"),
              initialValue: history.evictionExplanation,
              onChanged: (val) => history.evictionExplanation = val,
              enabled: !isReadOnly,
            ),
          BoolRadioRow(
            label: "Do you owe money to HUD, landlord, or utility company?",
            value: history.owesMoney,
            onChanged: (val) => setState(() => history.owesMoney = val),
            isReadOnly: isReadOnly,
          ),
          if (history.owesMoney == true)
            TextFormField(
              decoration: InputDecoration(labelText: "If yes, please explain"),
              initialValue: history.debtExplanation,
              onChanged: (val) => history.debtExplanation = val,
              enabled: !isReadOnly,
            ),
          BoolRadioRow(
            label: "Are you making payments on what you owe?",
            value: history.makingPayments,
            onChanged: (val) => setState(() => history.makingPayments = val),
            isReadOnly: isReadOnly,
          ),
          BoolRadioRow(
            label:
                "Have you had bed bugs in your current dwelling in the last six months?",
            value: history.bedBugs,
            onChanged: (val) => setState(() => history.bedBugs = val),
            isReadOnly: isReadOnly,
          ),
          SizedBox(height: 20),
          Text(
            "Criminal History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          BoolRadioRow(
            label:
                "Is any member subject to lifetime sex offender registration?",
            value: history.isLifetimeSexOffender,
            onChanged: (val) =>
                setState(() => history.isLifetimeSexOffender = val),
            isReadOnly: isReadOnly,
          ),
          if (history.isLifetimeSexOffender == true)
            ChooseFamilyMembersWidget(
              members: widget.familyMembers.values.toList(),
              selectedMembers: history.lifetimeOffenders,
              onChanged: (val) =>
                  setState(() => history.lifetimeOffenders = val),
              label: "Who?",
              isReadOnly: isReadOnly,
            ),
          BoolRadioRow(
            label:
                "Is any member subject to sex or violent offender registration?",
            value: history.isViolentOffender,
            onChanged: (val) => setState(() => history.isViolentOffender = val),
            isReadOnly: isReadOnly,
          ),
          if (history.isViolentOffender == true)
            ChooseFamilyMembersWidget(
              members: widget.familyMembers.values.toList(),
              selectedMembers: history.violentOffenders,
              onChanged: (val) =>
                  setState(() => history.violentOffenders = val),
              label: "Who?",
              isReadOnly: isReadOnly,
            ),
          BoolRadioRow(
            label: "Has any member been convicted for meth manufacturing?",
            value: history.isMethConviction,
            onChanged: (val) => setState(() => history.isMethConviction = val),
            isReadOnly: isReadOnly,
          ),
          if (history.isMethConviction == true)
            ChooseFamilyMembersWidget(
              members: widget.familyMembers.values.toList(),
              selectedMembers: history.methOffenders,
              onChanged: (val) => setState(() => history.methOffenders = val),
              label: "Who?",
              isReadOnly: isReadOnly,
            ),
          BoolRadioRow(
            label:
                "Is any member currently involved with illegal drug activity or facing charges?",
            value: history.hasDrugCharges,
            onChanged: (val) => setState(() => history.hasDrugCharges = val),
            isReadOnly: isReadOnly,
          ),
          if (history.hasDrugCharges == true)
            ChooseFamilyMembersWidget(
              members: widget.familyMembers.values.toList(),
              selectedMembers: history.drugOffenders,
              onChanged: (val) => setState(() => history.drugOffenders = val),
              label: "Who?",
              isReadOnly: isReadOnly,
            ),
          SizedBox(height: 20),
          Text("Any other criminal convictions not disclosed above?"),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: history.otherCrimes.length,
            itemBuilder: (context, index) {
              return crimeEntry(index);
            },
          ),
          Builder(builder: (context) {
            if (!isReadOnly) {
              return TextButton.icon(
                onPressed: () =>
                    setState(() => history.otherCrimes.add(CrimeEntry())),
                icon: Icon(Icons.add),
                label: Text("Add Crime Entry"),
              );
            } else {
              return SizedBox.shrink();
            }
          }),
        ],
      ),
    );
  }
}
