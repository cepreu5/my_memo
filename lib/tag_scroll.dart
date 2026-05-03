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

    return Container(
      height: 40, // Намалена височина за повече компактност
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.label_outline, size: 18, color: Colors.black54),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedTags.length,
              itemBuilder: (context, index) {
                final tag = sortedTags[index];
                final isSelected = selectedTags.contains(tag);

                return Padding(
                  padding: const EdgeInsets.only(right: 4.0), // По-малко разстояние между чиповете
                  child: FilterChip(
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4), // Максимална плътност
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Премахва излишното място за докосване
                    label: Text(
                      tag, 
                      style: TextStyle(
                        fontSize: 10, // По-малък шрифт
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
                    showCheckmark: false, // Премахваме отметката според изискването
                    selectedColor: Colors.blueAccent, // Изразен цвят за маркиране
                    backgroundColor: Colors.black.withValues(alpha: 0.05),
                    side: BorderSide.none, // Премахва рамката за по-изчистен вид
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