import 'package:flutter/material.dart';

class FilterOption<T> {
  const FilterOption(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Horizontally scrolling row of pill-shaped choice chips.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({super.key, required this.options, required this.selected, required this.onSelected});

  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = options[i];
          return ChoiceChip(
            avatar: o.icon == null ? null : Icon(o.icon),
            label: Text(o.label),
            selected: o.value == selected,
            onSelected: (_) => onSelected(o.value),
          );
        },
      ),
    );
  }
}
