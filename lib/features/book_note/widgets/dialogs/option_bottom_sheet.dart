import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/book_note_controller.dart';
import '../overlays/creation_overlay.dart';
import 'group_share_mixin.dart';

class OptionBottomSheet extends StatelessWidget with GroupShareMixin {
  final String type;
  final Map<String, dynamic> data;

  const OptionBottomSheet({
    super.key,
    required this.type,
    required this.data,
  });

  bool get hasMemo {
    final memo = data["memo"];
    return memo != null && memo.toString().trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookNoteController>();

    return _buildBottomSheet(
      title: type == "bookmark" ? "북마크"
          : type == "highlight" ? "하이라이트"
          : "메모",
      items: [
        "삭제",
        "수정",
        "그룹 공유",
      ],
      itemColors: [
        Colors.red.withValues(alpha: 0.7),
        Colors.black87,
        Colors.black87,
      ],
      onSelect: (index) {
        Get.back();
        if (index == 0) {
          _showDeleteDialog(controller);
        } else if (index == 1) {
          _openEditor();
        } else {
          final bookNoteCtrl = Get.find<BookNoteController>();
          if (bookNoteCtrl.preselectedGroupId != null) {
            bookNoteCtrl.onItemSelected?.call(type, data);
            Get.back();
          } else {
            openGroupShareFlow(
              itemType: type,
              itemData: data,
              bookId: Get.find<BookNoteController>().bookId,
            );
          }
        }
      },
    );
  }

  void _openEditor() {
    if (type == "bookmark") {
      Get.bottomSheet(
        CreationOverlay(
          type: "bookmark",
          isEdit: true,
          itemId: data["id"],
          page: data["page"],
          memo: hasMemo ? data["memo"] : "",
        ),
        isScrollControlled: true,
      );
      return;
    }

    if (type == "highlight") {
      Get.bottomSheet(
        CreationOverlay(
          type: "highlight",
          isEdit: true,
          itemId: data["id"],
          page: data['page'],
          sentence: data["sentence"],
          memo: hasMemo ? data["memo"] : "",
          isPublic: data["is_public"] ?? false,
        ),
        isScrollControlled: true,
      );
      return;
    }

    Get.bottomSheet(
      CreationOverlay(
        type: "memo",
        isEdit: true,
        itemId: data["id"],
        content: data["content"],
      ),
      isScrollControlled: true,
    );
  }

  void _showDeleteDialog(BookNoteController controller) {
    final label = type == "bookmark" ? "북마크"
        : type == "highlight" ? "하이라이트"
        : "메모";

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: 200,
          height: 107,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    '$label를 삭제하시겠습니까',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: AppColors.divider),
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                          ),
                          onTap: () {
                            Get.back();
                            if (type == "bookmark") controller.deleteBookmark(data["id"]);
                            else if (type == "highlight") controller.deleteHighlight(data["id"]);
                            else controller.deleteMemo(data["id"]);
                          },
                          child: const Center(
                            child: Text(
                              '네',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppColors.divider),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(10),
                          ),
                          onTap: () => Get.back(),
                          child: const Center(
                            child: Text(
                              '아니오',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet({
    required String title,
    required List<String> items,
    required void Function(int) onSelect,
    List<Color>? itemColors,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      "취소",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            ...items.asMap().entries.map((entry) => InkWell(
              onTap: () => onSelect(entry.key),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 0.5, color: AppColors.border),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: itemColors?[entry.key] ?? AppColors.textDark,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}