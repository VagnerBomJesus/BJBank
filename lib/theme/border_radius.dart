import 'package:flutter/material.dart';

/// BJBank Design System Border Radius
class BJBankBorderRadius {
  BJBankBorderRadius._();

  // Raw values
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 28.0;
  static const double full = 9999.0;

  // Component-specific
  static const double button = 20.0;
  static const double card = 12.0;
  static const double chip = 8.0;
  static const double dialog = 28.0;
  static const double input = 4.0;
  static const double searchBar = 28.0;

  // Pre-built BorderRadius objects
  static final BorderRadius noneRadius = BorderRadius.zero;
  static final BorderRadius xsRadius = BorderRadius.circular(xs);
  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius mdRadius = BorderRadius.circular(md);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
  static final BorderRadius xlRadius = BorderRadius.circular(xl);
  static final BorderRadius fullRadius = BorderRadius.circular(full);

  // Component-specific BorderRadius
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius chipRadius = BorderRadius.circular(chip);
  static final BorderRadius dialogRadius = BorderRadius.circular(dialog);
  static final BorderRadius inputRadius = BorderRadius.circular(input);
  static final BorderRadius searchBarRadius = BorderRadius.circular(searchBar);
}
