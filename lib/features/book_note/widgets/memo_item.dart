import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/dialogs/option_bottom_sheet.dart';
import '../widgets/overlays/creation_overlay.dart';

class MemoItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isReadOnly;
  final bool isPreview;

  const MemoItem({
    super.key,
    required this.data,
    this.isReadOnly = false,
    this.isPreview = false,
  });

  @override
  State<MemoItem> createState() => _MemoItemState();
}

class _MemoItemState extends State<MemoItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final String content = widget.data["content"] ?? "";
    final String date = _formatDate(widget.data["created_date"]);

    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.memoBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, size: 16, color: AppColors.error),
            ),
            if (!_expanded)
              Expanded(
                child: Container(
                  width: 1,
                  color: AppColors.divider,
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isReadOnly)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Get.bottomSheet(
                        OptionBottomSheet(type: "memo", data: widget.data),
                        backgroundColor: Colors.transparent,
                      ),
                      child: const Icon(Icons.more_horiz, size: 20, color: AppColors.border),
                    ),
                  ),

                GestureDetector(
                  onTap: () {
                    if (widget.isPreview) {
                      setState(() => _expanded = !_expanded);
                    } else {
                      Get.bottomSheet(
                        CreationOverlay(
                          type: "memo",
                          isEdit: true,
                          isReadOnly: true,
                          itemId: widget.data['id'],
                          content: content,
                        ),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      border: Border(
                        left: BorderSide(
                          color: AppColors.error.withOpacity(0.5),
                          width: 3,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      content,
                      maxLines: widget.isPreview
                          ? (_expanded ? null : 3)
                          : 5,
                      overflow: widget.isPreview && !_expanded
                          ? TextOverflow.ellipsis
                          : TextOverflow.clip,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return widget.isPreview && _expanded
        ? row
        : IntrinsicHeight(child: row);
  }

  String _formatDate(String? raw) {
    if (raw == null) return "";
    try {
      final date = DateTime.parse(raw);
      return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return raw;
    }
  }
}