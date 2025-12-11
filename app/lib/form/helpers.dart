import 'package:app/form/classes.dart';
import 'package:flutter/material.dart';

// Family Member Dropdown
class ChooseFamilyMembersWidget extends StatelessWidget {
  final List<FamilyMember> members;
  final List<FamilyMember> selectedMembers;
  final Function(List<FamilyMember>) onChanged;
  final bool isReadOnly;
  final String label;

  const ChooseFamilyMembersWidget({
    Key? key,
    required this.members,
    required this.selectedMembers,
    required this.onChanged,
    required this.isReadOnly,
    this.label = "Select Family Member(s)",
  }) : super(key: key);

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )),
        SizedBox(height: 6),
        IgnorePointer(
          ignoring: isReadOnly,
          child: GestureDetector(
            onTap: isReadOnly
                ? null
                : () async {
                    final overlayContext =
                        Navigator.of(context, rootNavigator: true).context;
                    final List<FamilyMember>? results =
                        await showDialog<List<FamilyMember>>(
                      context: overlayContext,
                      barrierDismissible: false,
                      builder: (dialogContext) {
                        List<FamilyMember> tempSelected =
                            List.from(selectedMembers);

                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return AlertDialog(
                              title: Text(label),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: members.map((member) {
                                    final isSelected =
                                        tempSelected.contains(member);
                                    return CheckboxListTile(
                                      value: isSelected,
                                      title: Text(
                                          '${member.firstName} ${member.lastName} (${member.relationship})'),
                                      onChanged: (checked) {
                                        setModalState(() {
                                          if (checked == true) {
                                            tempSelected.add(member);
                                          } else {
                                            tempSelected.remove(member);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(null),
                                  child: Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(dialogContext)
                                      .pop(tempSelected),
                                  child: Text("Done"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );

                    if (results != null) {
                      onChanged(results);
                    }
                  },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isReadOnly ? Colors.grey.shade100 : null,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: selectedMembers.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedMembers
                          .map((m) => Chip(
                                label: Text(
                                    '${m.firstName} ${m.lastName} (${m.relationship})'),
                              ))
                          .toList(),
                    )
                  : Text(
                      isReadOnly ? 'No members selected' : 'Tap to select...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// boolean radio
class BoolRadioRow extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final bool isReadOnly;
  final bool allowNA; // Optional third option

  const BoolRadioRow({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isReadOnly,
    this.allowNA = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Radio<bool?>(
                value: true,
                groupValue: value,
                onChanged: isReadOnly ? null : onChanged,
              ),
              Text("Yes"),
              Radio<bool?>(
                value: false,
                groupValue: value,
                onChanged: isReadOnly ? null : onChanged,
              ),
              Text("No"),
              if (allowNA) ...[
                Radio<bool?>(
                  value: null,
                  groupValue: value,
                  onChanged: isReadOnly ? null : onChanged,
                ),
                Text("N/A"),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
