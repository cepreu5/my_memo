import 'package:flutter/material.dart';

class TagScrollFilter extends StatelessWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final Color textColor;
  final Function(List<String>) onSelectionChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  final int? filterColor;
  final bool tasksOnly;
  final bool reverseOrder;
  final Function(int?) onColorChanged;
  final Function(bool) onTasksOnlyChanged;
  final Function(bool) onReverseOrderChanged;
  final Function() onClearAll;

  const TagScrollFilter({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onSelectionChanged,
    required this.textColor,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
    required this.filterColor,
    required this.tasksOnly,
    required this.reverseOrder,
    required this.onColorChanged,
    required this.onTasksOnlyChanged,
    required this.onReverseOrderChanged,
    required this.onClearAll,
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
    final bool hasSelection = selectedTags.isNotEmpty || startDate != null || filterColor != null || tasksOnly || reverseOrder;
    String dateLabel = "Филтри";
    if (startDate != null && endDate != null) {
      dateLabel = "${startDate!.day}.${startDate!.month.toString().padLeft(2, '0')}-${endDate!.day}.${endDate!.month.toString().padLeft(2, '0')}";
    } else if (filterColor != null) {
      dateLabel = "Цвят";
    } else if (tasksOnly) {
      dateLabel = "Задачи";
    }
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.1), width: 0.5), bottom: BorderSide(color: textColor.withValues(alpha: 0.1), width: 0.5))),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasSelection ? onClearAll : null,
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
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: PopupMenuButton<String>(
                      tooltip: "Филтриране и подредба",
                      onSelected: (val) {},
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDateRange: (startDate != null && endDate != null) ? DateTimeRange(start: startDate!, end: endDate!) : null,
                            );
                            if (picked != null) { onDateRangeChanged(picked.start, picked.end); }
                          },
                          child: const Row(children: [Icon(Icons.date_range, size: 18), SizedBox(width: 10), Text("Период")]),
                        ),
                        PopupMenuItem(
                          child: StatefulBuilder(
                            builder: (context, setPopupState) {
                              final List<Color> palette = [
                                Colors.white, const Color(0xFF0A1931), const Color(0xFFFF5E00), 
                                const Color(0xFFFFC93C), const Color(0xFF6A2C70), const Color(0xFFB83B5E), const Color(0xFF005082)
                              ];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [Icon(Icons.palette, size: 18), SizedBox(width: 10), Text("Цвят")]),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4, runSpacing: 4,
                                    children: palette.map((c) {
                                      final isSelected = filterColor == c.toARGB32();
                                      return GestureDetector(
                                        onTap: () {
                                          onColorChanged(isSelected ? null : c.toARGB32());
                                          Navigator.pop(ctx);
                                        },
                                        child: Container(
                                          width: 24, height: 24,
                                          decoration: BoxDecoration(
                                            color: c, shape: BoxShape.circle,
                                            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                          ),
                                          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.blue) : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => onTasksOnlyChanged(!tasksOnly),
                          child: Row(
                            children: [
                              Icon(tasksOnly ? Icons.task_alt : Icons.task_outlined, size: 18, color: tasksOnly ? Colors.blue : null),
                              const SizedBox(width: 10),
                              const Text("Задачи"),
                              const Spacer(),
                              Checkbox(visualDensity: VisualDensity.compact, value: tasksOnly, onChanged: (v) { onTasksOnlyChanged(v ?? false); Navigator.pop(ctx); }),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => onReverseOrderChanged(!reverseOrder),
                          child: Row(
                            children: [
                              Icon(Icons.sort, size: 18, color: reverseOrder ? Colors.blue : null),
                              const SizedBox(width: 10),
                              const Text("Обратен ред"),
                              const Spacer(),
                              Checkbox(visualDensity: VisualDensity.compact, value: reverseOrder, onChanged: (v) { onReverseOrderChanged(v ?? false); Navigator.pop(ctx); }),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (startDate != null || filterColor != null || tasksOnly || reverseOrder) ? Colors.yellow[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: (startDate != null || filterColor != null || tasksOnly || reverseOrder) ? Border.all(color: Colors.orange) : Border.all(color: Colors.grey[400]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(dateLabel, style: const TextStyle(fontSize: 10, color: Colors.black)),
                            const Icon(Icons.arrow_drop_down, size: 14, color: Colors.black54),
                          ],
                        ),
                      ),
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
