import 'package:flutter/material.dart';

class TagScrollFilter extends StatelessWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final Color textColor;
  final Function(List<String>) onSelectionChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;

  const TagScrollFilter({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onSelectionChanged,
    required this.textColor,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> sortedTags = List.from(allTags);
    sortedTags.sort((a, b) {
      bool aSelected = selectedTags.contains(a);
      bool bSelected = selectedTags.contains(b);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return a.compareTo(b);
    });
    final bool hasSelection = selectedTags.isNotEmpty || startDate != null;
    
    String dateLabel = "дата";
    if (startDate != null && endDate != null) {
      dateLabel = "${startDate!.day}.${startDate!.month.toString().padLeft(2, '0')}-${endDate!.day}.${endDate!.month.toString().padLeft(2, '0')}";
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.1), width: 0.5), bottom: BorderSide(color: textColor.withValues(alpha: 0.1), width: 0.5))),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasSelection ? () { onSelectionChanged([]); onDateRangeChanged(null, null); } : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(hasSelection ? Icons.label_off_outlined : Icons.label_outline, size: 20, color: hasSelection ? Colors.redAccent : textColor.withValues(alpha: 0.6)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedTags.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isDateActive = startDate != null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: FilterChip(
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      label: Text(dateLabel, style: const TextStyle(fontSize: 10, color: Colors.black)),
                      selected: isDateActive,
                      onSelected: (_) async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: (startDate != null && endDate != null) ? DateTimeRange(start: startDate!, end: endDate!) : null,
                        );
                        if (picked != null) { onDateRangeChanged(picked.start, picked.end); }
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      showCheckmark: false,
                      selectedColor: Colors.yellow[700],
                      backgroundColor: Colors.grey[300],
                      side: isDateActive ? const BorderSide(color: Colors.orange, width: 1) : BorderSide(color: Colors.grey[400]!),
                    ),
                  );
                }

                final tag = sortedTags[index - 1];
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
                    backgroundColor: Colors.cyan[200],
                    side: isSelected ? const BorderSide(color: Colors.cyan, width: 1) : BorderSide(color: Colors.cyan[400]!),
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
