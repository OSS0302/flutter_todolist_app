import 'package:flutter/material.dart';

class PriorityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const PriorityChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
          selected: isSelected,
          selectedColor: Colors.transparent,
          backgroundColor: Colors.white.withOpacity(0.08),
          avatar: isSelected
              ? const Icon(Icons.check, size: 18, color: Colors.black)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: isSelected
                ? BorderSide(color: gradient.colors.first, width: 2)
                : BorderSide.none,
          ),
          onSelected: (_) => onTap(),
          labelPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }
}
