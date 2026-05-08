import 'package:flutter/material.dart';

class TagScrollFilter extends StatelessWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final Color textColor;
  final Function(List<String>) onSelectionChanged;

  const TagScrollFilter({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onSelectionChanged,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (allTags.isEmpty) return const SizedBox.shrink();
    final List<String> sortedTags = List.from(allTags);
    sortedTags.sort((a, b) {
      bool aSelected = selectedTags.contains(a);
      bool bSelected = selectedTags.contains(b);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return a.compareTo(b);
    });
    final bool hasSelection = selectedTags.isNotEmpty;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.1), width: 0.5), bottom: BorderSide(color: textColor.withValues(alpha: 0.1), width: 0.5))),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasSelection ? () => onSelectionChanged([]) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(hasSelection ? Icons.label_off_outlined : Icons.label_outline, size: 20, color: hasSelection ? Colors.redAccent : textColor.withValues(alpha: 0.6)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedTags.length,
              itemBuilder: (context, index) {
                final tag = sortedTags[index];
                final isSelected = selectedTags.contains(tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: FilterChip(
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 3.0),
                    label: Text(tag, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.black)),
                    selected: isSelected,
                    onSelected: (selected) {
                      List<String> newList = List.from(selectedTags);
                      if (selected) { newList.add(tag); } else { newList.remove(tag); }
                      onSelectionChanged(newList);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    showCheckmark: false,
                    selectedColor: Colors.yellow[700],
                    backgroundColor: Colors.yellow[200],
                    side: isSelected ? const BorderSide(color: Colors.orange, width: 1) : BorderSide(color: Colors.yellow[400]!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
