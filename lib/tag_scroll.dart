import 'package:flutter/material.dart';

class TagScrollFilter extends StatelessWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final Function(List<String>) onSelectionChanged;

  const TagScrollFilter({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (allTags.isEmpty) return const SizedBox.shrink();
    // Сортираме етикетите така, че избраните да са най-отпред
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
      height: 40, // Компактна височина
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Икона, която става бутон за нулиране при наличие на селекция
          GestureDetector(
            onTap: hasSelection ? () => onSelectionChanged([]) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(
                hasSelection ? Icons.label_off_outlined : Icons.label_outline,
                size: 20,
                color: hasSelection ? Colors.blueAccent : Colors.black54,
              ),
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
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    label: Text(
                      tag, 
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      List<String> newList = List.from(selectedTags);
                      if (selected) {
                        newList.add(tag);
                      } else {
                        newList.remove(tag);
                      }
                      onSelectionChanged(newList);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    showCheckmark: false,
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.black.withValues(alpha: 0.05),
                    side: BorderSide.none,
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
