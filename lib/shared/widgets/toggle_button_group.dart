import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';

/// A reusable toggle button group used across the app.
///
/// It displays a row of options with identical styling:
///   • Same width/height (determined by padding).
///   • Same font size and weight.
///   • Same border radius and margin between buttons.
///   • Uses the app's [FinanceProvider] theme for colors.
class ToggleButtonGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const ToggleButtonGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
  static const double _fontSize = 10.0;
  static const double _borderRadius = 16.0;
  static const double _marginRight = 4.0;

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final bool isActive = selected == opt;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (!isActive) onSelected(opt);
          },
          child: Container(
            margin: const EdgeInsets.only(right: _marginRight),
            padding: _padding,
            decoration: BoxDecoration(
              color: isActive ? finance.themeAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isActive ? Colors.white : finance.themeTextSub,
                fontWeight: FontWeight.bold,
                fontSize: _fontSize,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
