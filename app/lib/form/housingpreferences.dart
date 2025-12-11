import 'package:flutter/material.dart';
import 'classes.dart';

class HousingPreferencesForm extends StatefulWidget {
  final ApplicationData data;
  final bool isReadOnly;

  const HousingPreferencesForm({Key? key, required this.data, required this.isReadOnly}) : super(key: key);

  @override
  _HousingPreferencesFormState createState() => _HousingPreferencesFormState();
}

class _HousingPreferencesFormState extends State<HousingPreferencesForm> {
  final List<String> housingSizes = [
    "Studio (1–3 person household)",
    "1 Bedroom (1–3 person household)",
    "2 Bedroom (2–5 person household)",
    "3 Bedroom (3–7 person household)",
    "4 Bedroom (4–9 person household)",
  ];

  @override
  Widget build(BuildContext context) {
    final prefs = widget.data.housingPreferences;
    final isReadOnly = widget.isReadOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select the housing size(s) you want to apply for.",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          "Pick your top 3 preferred house sizes by using the dropdown. '1' is your favorite, '2' is second best, and '3' is third. You don’t have to pick all three, but if you don’t pick anything, we’ll pick for you.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        SizedBox(height: 16),

        // Ranking dropdowns
        ...List.generate(housingSizes.length, (index) {
          final size = housingSizes[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: prefs.rankings[size],
                  items: ["", "1", "2", "3"].map((val) {
                    return DropdownMenuItem(value: val, child: Text(val));
                  }).toList(),
                  onChanged: isReadOnly
                      ? null
                      : (val) => setState(() {
                        if (val == "") {
                          prefs.rankings.remove(size);
                        } else {
                          prefs.rankings[size] = val!;
                        }
                  }),
                ),
              ),
              SizedBox(width: 12),
              Flexible(
                flex: 4,
                child: Text(size),
              ),
            ],
          );
        }),

        SizedBox(height: 20),
        TextFormField(
          decoration: InputDecoration(
            labelText: "When you want to move in (e.g., ASAP or date)",
          ),
          initialValue: prefs.desiredMoveInDate,
          onChanged: (val) => prefs.desiredMoveInDate = val,
          enabled: !isReadOnly,
        ),
      ],
    );
  }
}
