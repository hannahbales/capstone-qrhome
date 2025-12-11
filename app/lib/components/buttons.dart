import 'package:app/components/text.dart';
import 'package:flutter/material.dart';

enum QFilledButtonStyle {
  kConfirm,
  kCancel,
}

class QFilledButton extends FilledButton {
  final String text;
  final QFilledButtonStyle qStyle;
  final QTextSize qTextSize;

  QFilledButton({
    super.key,
    required void Function() onPressed,
    required this.text,
    this.qTextSize = QTextSize.kMedium,
    this.qStyle = QFilledButtonStyle.kConfirm,
  }) : super(
          onPressed: onPressed,
          child: _constructTextWidget(text, qTextSize),
          style: _buttonStyle(qStyle),
        );

  static Widget _constructTextWidget(String text, QTextSize qSize) {
    return QText(
      text,
      qSize: qSize,
    );
  }

  static ButtonStyle _buttonStyle(QFilledButtonStyle qStyle) {
    // return switch (qStyle) {
    //   QFilledButtonStyle.kConfirm => qConfirmButtonStyle(),
    //   QFilledButtonStyle.kCancel => qCancelButtonStyle(),
    // };
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(
        switch (qStyle) {
          QFilledButtonStyle.kConfirm => Color(0xFF4169E1),
          QFilledButtonStyle.kCancel => Colors.red[400]!,
        },
      ),
      foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      minimumSize: WidgetStatePropertyAll(null),
      // THIS TOOK SO LONG TO FIND: https://github.com/flutter/flutter/issues/96995
      // TLDR: It's borked and they are afraid to fix it.
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
