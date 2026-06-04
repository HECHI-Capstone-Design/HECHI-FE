import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import '../models/collection_tag_model.dart';

class TagChip extends StatelessWidget {
  final CollectionTag tag;
  final bool isSelected;
  final bool showRemove;
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
    this.showRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: ShapeDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : AppColors.border.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            side: isSelected
                ? const BorderSide(width: 0.5, color: AppColors.primary)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${tag.label}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.75,
              ),
            ),
            if (showRemove && isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 14, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}