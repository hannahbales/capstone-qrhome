import 'package:app/api/account.dart';
import 'package:app/api/application.dart';
import 'package:app/api/family.dart';
import 'package:flutter/foundation.dart';
import 'package:app/form/files.dart';
import 'package:flutter/material.dart';
import 'form/personalinfo.dart';
import 'form/housingpreferences.dart';
import 'form/household.dart';
import 'form/history.dart';
import 'form/income.dart';
import 'form/classes.dart';

class ApplicationForm extends StatefulWidget {
  final bool isReadOnly;
  final String? clientEmail;

  ApplicationForm({required this.isReadOnly, this.clientEmail});

  @override
  _ApplicationFormState createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<ApplicationForm> {
  ApplicationData data = ApplicationData.empty();
  List<FamilyMember> familyMembers = [];
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _navScrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // validation

  // Navigation lists
  final List<String> categoryTitles = [
    "Personal Information",
    "Housing Preferences",
    "Household",
    "History",
    "Income",
    "Files"
  ];

  List<Widget>? categorySections;

  final List<GlobalKey> sectionKeys = List.generate(6, (_) => GlobalKey());

  String saveButtonText = "Save";

  /// This function is called when the user scrolls the form sections.
  /// It calculates the closest section to the top of the screen and updates the selected index.
  void _onScroll() {
    double closestDistance = double.infinity;
    int closestIndex = selectedIndex;

    for (int i = 0; i < sectionKeys.length; i++) {
      final context = sectionKeys[i].currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          double position =
              box.localToGlobal(Offset.zero).dy; // Position of section
          double distance = (position - 100).abs(); // Distance from top

          if (distance < closestDistance) {
            closestDistance = distance;
            closestIndex = i;
          }
        }
      }
    }

    if (closestIndex != selectedIndex) {
      setState(() {
        selectedIndex = closestIndex;
      });
    }

    _navScrollController.animateTo(
      closestIndex * 80.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// This function is called after the widget is inserted into the tree.
  /// It adds a listener to the scroll controller to detect when the user scrolls the form sections.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScroll);
      _onScroll();
    });

    Future(() async {
      // TODO: Make this variable for view only or whatever

      final email = widget.clientEmail ?? await getCurrentEmail();
      if (email == null) {
        print("No email found, cannot load application data.");
        return;
      }

      final res = await getApplicationData(email);
      if (res.isError) {
        print("Error getting application data: ${res.error}");
        return;
      }

      familyMembers = await getFamilyMembers(email);

      data = res.value!;
      if (mounted) {
        setState(() {
          categorySections = [
            PersonalInfoForm(data: data, isReadOnly: widget.isReadOnly),
            HousingPreferencesForm(data: data, isReadOnly: widget.isReadOnly),
            HouseholdForm(
                data: data,
                familyMembers: familyMembers,
                isReadOnly: widget.isReadOnly),
            HistoryForm(
                data: data,
                familyMembers: familyMembers,
                isReadOnly: widget.isReadOnly),
            IncomeForm(
                data: data,
                familyMembers: familyMembers,
                isReadOnly: widget.isReadOnly),
          ];
        });
      }
    });
  }

  void _saveForm() async {
    final res = await updateApplicationData(data);
    if (res) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Application data saved successfully!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('Failed to save application data.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save application data."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// This function is called when the widget is removed from the tree.
  /// It removes the listener from the scroll controller to prevent memory leaks.
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _navScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> sections = [];
    if (categorySections == null) {
      sections.add(Center(child: CircularProgressIndicator()));
    } else {
      sections.addAll(List.generate(categorySections!.length, (index) {
        return Section(
          key: sectionKeys[index],
          title: categoryTitles[index],
          child: categorySections![index],
        );
      }));
    }

    return Form(
      key: _formKey,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          // keeps nav bar on top
          children: [
            // Form
            Positioned.fill(
              top: 50, // space for the navbar
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(top: 10, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Sections
                    ...sections,

                    // Save Button - TODO: autosave instead of button maybe. button at the bottom isn't clear
                    if (!widget.isReadOnly) ...{
                      // only show if not read only
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _saveForm();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(saveButtonText,
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    } else
                      SizedBox(height: 50), // space for the bottom
                  ],
                ),
              ),
            ),

            // Navigation Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                child: ListView.builder(
                  controller: _navScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: categorySections?.length ?? 0,
                  itemBuilder: (context, index) {
                    bool isActive = selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });

                        Future.delayed(Duration(milliseconds: 500), () {
                          Scrollable.ensureVisible(
                            sectionKeys[index].currentContext!,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        });

                        _navScrollController.animateTo(
                          index * 80.0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              categoryTitles[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive ? Colors.blue : Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              height: 3,
                              width: isActive ? 30 : 0,
                              decoration: BoxDecoration(
                                color:
                                    isActive ? Colors.blue : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
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
}

// Section Object
class Section extends StatelessWidget {
  final String title;
  final Widget child;
  const Section({Key? key, required this.title, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: child,
          ),
        ],
      ),
    );
  }
}

void showApplicationForm(BuildContext context, bool isReadOnly,
    {String applicantName = "", String? clientEmail}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isReadOnly
                      ? applicantName + "'s Application Form"
                      : "Your Application Form",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: ApplicationForm(
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
