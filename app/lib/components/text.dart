import 'package:flutter/material.dart';

enum QTextSize {
  kSmall,
  kMedium,
  kLarge,
}

double _textSize(QTextSize qSize) {
  return switch (qSize) {
    QTextSize.kSmall => 16.0,
    QTextSize.kMedium => 20.0,
    QTextSize.kLarge => 24.0,
  };
}

class QText extends Text {
  final QTextSize qSize;

  QText(
    super.data, {
    super.key,
    this.qSize = QTextSize.kSmall,
  }) : super(
          style: _textStyle(qSize),
        );

  static TextStyle _textStyle(QTextSize qSize) {
    return TextStyle(
      fontSize: _textSize(qSize),
    );
  }
}

class QTextSpan extends TextSpan {
  final QTextSize qSize;

  QTextSpan({
    super.text,
    this.qSize = QTextSize.kSmall,
  }) : super(
          style: _textSpanStyle(qSize),
        );

  static TextStyle _textSpanStyle(QTextSize qSize) {
    return TextStyle(
      fontSize: _textSize(qSize),
    );
  }
}
