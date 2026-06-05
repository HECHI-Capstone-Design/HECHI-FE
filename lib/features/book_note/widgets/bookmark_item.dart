import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/dialogs/option_bottom_sheet.dart';
import '../widgets/overlays/creation_overlay.dart';

class BookmarkItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isReadOnly;
  final bool isPreview;

  const BookmarkItem({
    super.key,
    required this.data,
    this.isReadOnly = false,
    this.isPreview = false,
  });

  @override
  State<BookmarkItem> createState() => _BookmarkItemState();
}

class _BookmarkItemState extends State<BookmarkItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final memo = widget.data["memo"] ?? "";
    final hasMemo = memo.toString().isNotEmpty;

    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border, size: 16, color: AppColors.primary),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "p. ${widget.data["page"]}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    if (!widget.isReadOnly)
                      GestureDetector(
                        onTap: () => Get.bottomSheet(
                          OptionBottomSheet(type: "bookmark", data: widget.data),
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Icon(Icons.more_horiz, size: 20, color: AppColors.border),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  _formatDate(widget.data["created_date"]),
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),

                if (hasMemo) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      if (widget.isPreview) {
                        setState(() => _expanded = !_expanded);
                      } else {
                        Get.bottomSheet(
                          CreationOverlay(
                            type: "bookmark",
                            isEdit: true,
                            isReadOnly: true,
                            itemId: widget.data['id'],
                            page: widget.data['page'],
                            memo: widget.data['memo'],
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
                            color: AppColors.primary.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        memo,
                        maxLines: widget.isPreview
                            ? (_expanded ? null : 3)
                            : 5,
                        overflow: widget.isPreview && !_expanded
                            ? TextOverflow.ellipsis
                            : TextOverflow.clip,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
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