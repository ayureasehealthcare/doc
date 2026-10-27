import 'package:flutter/material.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:hugeicons/hugeicons.dart';

class OslerDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final List<List<dynamic>>? prefixIcon;

  const OslerDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(hint, style: TextStyle(color: AyurezeTheme.textSecondary)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AyurezeTheme.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AyurezeTheme.spaceXl, vertical: 18),
            prefixIcon: prefixIcon != null
                ? HugeIcon(
                    icon: prefixIcon!,
                    size: 20,
                    color: AyurezeTheme.iconPrimary)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusLg),
              borderSide:
                  BorderSide(color: AyurezeTheme.healingGreen50, width: 2),
            ),
          ),
          items: items
              .map((String item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
