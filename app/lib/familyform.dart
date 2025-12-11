import 'package:app/api/family.dart';
import 'package:app/form/classes.dart';
import 'package:flutter/material.dart';

const List<String> _kRelationships = ['Spouse', 'Child', 'Parent', 'Other'];

class FamilyMembersForm extends StatefulWidget {
  final bool isReadOnly;
  final String? clientEmail;

  const FamilyMembersForm({
    super.key,
    this.isReadOnly = false,
    this.clientEmail,
  });

  @override
  // ignore: library_private_types_in_public_api
  _FamilyMembersFormState createState() => _FamilyMembersFormState();
}

class _FamilyMembersFormState extends State<FamilyMembersForm> {
  final List<FamilyMember> _familyMembers = [];

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  void _removeMember(int index) async {
    final member = _familyMembers[index];
    if (member.id == 0) {
      print('Tried to delete member with ID 0');
      return;
    }

    final res = await deleteFamilyMember(member.id);

    if (res) {
      if (mounted) {
        setState(() {
          _familyMembers.removeAt(index);
        });
      }
    } else {
      print('Failed to remove member');
    }
  }

  void _addMember(FamilyMember member) async {
    final res = await addFamilyMember(member);

    if (res) {
      if (member.id == 0) {
        print('Member ID is still 0 after creation');
        return;
      }

      if (mounted) {
        setState(() {
          _familyMembers.add(member);
        });
      }
    } else {
      print('Failed to add member');
    }
  }

  void _updateMember(FamilyMember member, int index) async {
    if (member.id == 0) {
      print('Tried to update member with ID 0');
      return;
    }

    final res = await updateFamilyMember(member);

    if (res) {
      if (mounted) {
        setState(() {
          _familyMembers[index] = member;
        });
      }
    } else {
      print('Failed to update member');
    }
  }

  void _showMemberForm({FamilyMember? member, int? index}) {
    final formKey = GlobalKey<FormState>();

    // Local state (or you could lift these to class if you prefer)
    final firstNameController = TextEditingController(
      text: member?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: member?.lastName ?? '',
    );
    final ssnController = TextEditingController(text: member?.ssn ?? '');
    DateTime? selectedBirthday = member?.birthday;
    String selectedGender = member?.gender ?? 'Male';
    String selectedRelationship = member?.relationship ?? 'Spouse';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickBirthday() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    selectedBirthday ?? now.subtract(Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (picked != null) {
                setModalState(() {
                  selectedBirthday = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Text(
                        member == null
                            ? 'Add Family Member'
                            : 'Edit Family Member',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(labelText: 'First Name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'First name is required'
                                : null,
                      ),
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(labelText: 'Last Name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Last name is required'
                                : null,
                      ),
                      GestureDetector(
                        onTap: pickBirthday,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Birthday'),
                            controller: TextEditingController(
                              text: selectedBirthday == null
                                  ? ''
                                  : '${selectedBirthday!.month}/${selectedBirthday!.day}/${selectedBirthday!.year}',
                            ),
                            validator: (_) => selectedBirthday == null
                                ? 'Birthday is required'
                                : null,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: ssnController,
                        decoration: InputDecoration(labelText: 'SSN'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'SSN is required';
                          } else if (!RegExp(r'^\d{9}$').hasMatch(value)) {
                            return 'Enter a valid 9-digit SSN';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        items: [
                          'Male',
                          'Female',
                          'Non-Binary',
                          'Prefer not to say',
                          'Other',
                        ]
                            .map(
                              (gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedGender = value);
                          }
                        },
                        decoration: InputDecoration(labelText: 'Gender'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Gender is required'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedRelationship,
                        items: _kRelationships
                            .map(
                              (rel) => DropdownMenuItem(
                                value: rel,
                                child: Text(rel),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedRelationship = value);
                          }
                        },
                        decoration: InputDecoration(labelText: 'Relationship'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Relationship is required'
                            : null,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final updated = FamilyMember(
                              id: member?.id ?? 0,
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              birthday: selectedBirthday!,
                              ssn: ssnController.text.trim(),
                              gender: selectedGender,
                              relationship: selectedRelationship,
                            );
                            setState(() {
                              if (index != null) {
                                _updateMember(updated, index);
                              } else {
                                _addMember(updated);
                              }
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          member == null ? 'Add Member' : 'Save Changes',
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    Future(() async {
      final members = await getFamilyMembers(widget.clientEmail);
      if (mounted) {
        setState(() {
          _familyMembers.clear();
          _familyMembers.addAll(members);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Family'),
        automaticallyImplyLeading: false, // Hides back button
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // "You" card
            Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('You'),
                subtitle: Text('Primary Applicant'),
              ),
            ),

            SizedBox(height: 16),

            if (!widget.isReadOnly)
              ElevatedButton.icon(
                onPressed: _showMemberForm,
                icon: Icon(Icons.add),
                label: Text('Add Family Member'),
              ),

            SizedBox(height: 24),

            // List of added members
            Expanded(
              child: _familyMembers.isEmpty
                  ? Center(child: Text('No family members added yet.'))
                  : ListView.builder(
                      itemCount: _familyMembers.length,
                      itemBuilder: (context, index) {
                        final member = _familyMembers[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${member.firstName} ${member.lastName}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Relationship: ${member.relationship}'),
                                Text(
                                  'Birthday: ${member.birthday.month}/${member.birthday.day}/${member.birthday.year}',
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: widget.isReadOnly
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () => _showMemberForm(
                                          member: member,
                                          index: index,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () => _removeMember(index),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void showFamilyBottomSheet(
  BuildContext context,
  bool isReadOnly,
  String? clientEmail,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close (X) button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Edit Family",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Form content scrolls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: FamilyMembersForm(
                          isReadOnly: isReadOnly,
                          clientEmail: clientEmail,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
