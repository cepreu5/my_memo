import 'package:flutter/material.dart';

class TagScrollFilter extends StatefulWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final Color textColor;
  final Function(List<String>) onSelectionChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? filterColor;
  final bool tasksOnly;
  final bool reverseOrder;
  final bool sortById;
  final Function() onClearAll;
  final Function() onOpenFilterMenu;

  const TagScrollFilter({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onSelectionChanged,
    required this.textColor,
    required this.startDate,
    required this.endDate,
    required this.filterColor,
    required this.tasksOnly,
    required this.reverseOrder,
    required this.sortById,
    required this.onClearAll,
    required this.onOpenFilterMenu,
  });

  @override
  State<TagScrollFilter> createState() => _TagScrollFilterState();
}

class _TagScrollFilterState extends State<TagScrollFilter> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> sortedTags = List.from(widget.allTags);
    sortedTags.sort((a, b) {
      bool aSelected = widget.selectedTags.contains(a);
      bool bSelected = widget.selectedTags.contains(b);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return a.compareTo(b);
    });
    final bool hasSelection = widget.selectedTags.isNotEmpty || widget.startDate != null || widget.filterColor != null || widget.tasksOnly || widget.reverseOrder || widget.sortById;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: widget.textColor.withValues(alpha: 0.1), width: 0.5), bottom: BorderSide(color: widget.textColor.withValues(alpha: 0.1), width: 0.5))),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasSelection ? () {
              widget.onClearAll();
              _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            } : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(hasSelection ? Icons.label_off_outlined : Icons.label_outline, size: 20, color: hasSelection ? Colors.redAccent : widget.textColor.withValues(alpha: 0.6)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: sortedTags.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Center(
                      child: GestureDetector( // бутон в менюто с етикети
                        onTap: widget.onOpenFilterMenu,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24, maxHeight: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.startDate != null && widget.endDate != null)
                                Text("${widget.startDate!.day}.${widget.startDate!.month}-${widget.endDate!.day}.${widget.endDate!.month}", style: const TextStyle(fontSize: 10, color: Colors.black))
                              else if (widget.filterColor == null && !widget.tasksOnly && !widget.reverseOrder && !widget.sortById)
                                 const Icon(Icons.filter_list, size: 12, color: Colors.black87)
                              else ...[
                                  if (widget.filterColor != null) ...[
                                     Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(widget.filterColor!), shape: BoxShape.circle, border: Border.all(color: Colors.black26, width: 0.5))),
                                     const SizedBox(width: 2),
                                  ],
                                  if (widget.tasksOnly) ...[
                                     const Icon(Icons.checklist, size: 14, color: Colors.black87),
                                     const SizedBox(width: 2),
                                  ],
                                  if (widget.reverseOrder) ...[
                                     const Icon(Icons.sort, size: 12, color: Colors.black87),
                                     const SizedBox(width: 2),
                                  ],
                                  if (widget.sortById) ...[
                                     const Icon(Icons.format_list_numbered, size: 12, color: Colors.black87),
                                  ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final tag = sortedTags[index - 1];
                final isSelected = widget.selectedTags.contains(tag);
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
                      List<String> newList = List.from(widget.selectedTags);
                      if (selected) { newList.add(tag); } else { newList.remove(tag); }
                      widget.onSelectionChanged(newList);
                      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
