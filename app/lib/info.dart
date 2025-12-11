import 'package:flutter/material.dart';

class ShowInfoButton extends StatelessWidget {
  const ShowInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info),
      tooltip: 'See app info',
      onPressed: () {
        showInfo(context);
      },
    );
  }
}

void showInfo(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TextStyle textStyle = theme.textTheme.bodyMedium!;
  final List<Widget> aboutBoxChildren = <Widget>[
    const SizedBox(height: 24),
    RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
              style: textStyle,
              text: 'Your journey starts with a QR Code and end with a home.'),
        ],
      ),
    ),
  ];

  showAboutDialog(
    context: context,
    applicationIcon: Icon(Icons.home),
    applicationName: 'QR Home',
    applicationVersion: 'May 2025',
    applicationLegalese: '\u{a9} 2025 Our Path Home Coalition',
    children: aboutBoxChildren,
  );
}
