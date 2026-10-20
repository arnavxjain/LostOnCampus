import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/shapes.dart';

/// Filled squircle search box: no outline at rest, teal outline when focused.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    const rest = SquircleInputBorder(radius: 14, borderSide: BorderSide.none);
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.ink6,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Icon(CupertinoIcons.search, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 40),
        border: rest,
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        enabledBorder: rest,
        focusedBorder: const SquircleInputBorder(radius: 14, borderSide: BorderSide(color: AppColors.teal, width: 1.5)),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: AppColors.teal36),
                onPressed: onClear,
              ),
      ),
    );
  }
}
