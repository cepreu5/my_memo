import 'package:flutter/material.dart';

class TagDialogHelper {
  static Color contrast(Color background, Color ifBright, Color ifDark) {
    return background.computeLuminance() > 0.5 ? ifBright : ifDark;
  }

  static void show({
    required BuildContext context,
    required int appColor,
    required String title,
    required List<String> initialTags,
    required List<String> allTags,
    required Function(List<String> updatedTags) onSave,
    String? confirmLabel,
  }) {
    final TextEditingController tagController = TextEditingController();
    List<String> currentSelected = List.from(initialTags);
    List<String> pool = List.from(allTags)..sort();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final Color bgColor = Color(appColor);
            final Color contrastColor = contrast(bgColor, Colors.black, Colors.white);
            final Color secondaryContrast = contrast(bgColor, Colors.black54, Colors.white70);

            return AlertDialog(
              backgroundColor: bgColor,
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: contrastColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pool.isNotEmpty) ...[
                      Text("Избери:", style: TextStyle(fontSize: 12, color: secondaryContrast)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4, runSpacing: 4,
                        children: pool.map((tag) {
                          bool isSelected = currentSelected.contains(tag);
                          return FilterChip(
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                            label: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.black)),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) { if (!currentSelected.contains(tag)) currentSelected.add(tag); } 
                                else { currentSelected.remove(tag); }
                              });
                            },
                            showCheckmark: false,
                            selectedColor: Colors.yellow[700],
                            backgroundColor: Colors.cyan[200],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: isSelected ? const BorderSide(color: Colors.cyan, width: 1) : BorderSide(color: Colors.cyan[400]!),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text("Нов етикет:", style: TextStyle(fontSize: 12, color: secondaryContrast)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagController,
                            style: TextStyle(color: contrastColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Име...", 
                              hintStyle: TextStyle(color: secondaryContrast.withValues(alpha: 0.4), fontSize: 13),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryContrast.withValues(alpha: 0.2))),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty && !currentSelected.contains(val.trim())) {
                                setModalState(() { 
                                  String nt = val.trim();
                                  currentSelected.add(nt); 
                                  if (!pool.contains(nt)) { pool.add(nt); pool.sort(); }
                                });
                                tagController.clear();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 20, color: contrastColor),
                          onPressed: () {
                             final val = tagController.text;
                             if (val.trim().isNotEmpty && !currentSelected.contains(val.trim())) {
                                setModalState(() { 
                                  String nt = val.trim();
                                  currentSelected.add(nt); 
                                  if (!pool.contains(nt)) { pool.add(nt); pool.sort(); }
                                });
                                tagController.clear();
                             }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Отказ", style: TextStyle(color: secondaryContrast))),
                ElevatedButton(
                  onPressed: () {
                    onSave(currentSelected);
                    Navigator.pop(context);
                  },
                  child: Text(confirmLabel ?? 'Запази'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
