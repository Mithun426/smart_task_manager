import 'package:flutter/material.dart';

class StyledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<String> items;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final bool openUpward;

  const StyledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.isDark,
    required this.onChanged,
    this.openUpward = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final accentColor = theme.colorScheme.primary;
    final yOffset = openUpward ? -(items.length * 48.0) - 8 : 48.0;

    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: Offset(0, yOffset),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: bgColor,
      elevation: 4,
      constraints: const BoxConstraints(minWidth: 160),
      itemBuilder: (context) => items.map((item) {
        final isSelected = item == value;
        return PopupMenuItem<String>(
          value: item,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: isSelected ? accentColor : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text(
                item,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? accentColor : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(openUpward ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
