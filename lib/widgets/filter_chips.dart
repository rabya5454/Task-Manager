// filter chips
import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;
  final List<String> labels;
  final List<IconData>? icons;

  const FilterChips({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.labels,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                labels[index],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              avatar: icons != null
                  ? Icon(
                icons![index],
                size: 18,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              )
                  : null,
              onSelected: (_) => onChanged(index),
              selectedColor: colorScheme.secondaryContainer,
              checkmarkColor: colorScheme.onSecondaryContainer,
            ),
          );
        }),
      ),
    );
  }
}