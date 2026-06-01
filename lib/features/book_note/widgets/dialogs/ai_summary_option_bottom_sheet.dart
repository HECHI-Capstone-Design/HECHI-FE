import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'group_share_mixin.dart';
import '../../controllers/ai_summary_controller.dart';

class AiSummaryOptionBottomSheet extends StatelessWidget with GroupShareMixin {
  final VoidCallback? onDelete;
  final VoidCallback? onShareToGroup;

  const AiSummaryOptionBottomSheet({
    super.key,
    this.onDelete,
    this.onShareToGroup,
  });

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    "AI 메모 요약",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3F3F3F),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      "취소",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4DB56C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
            _buildOption(
              label: "삭제",
              color: Colors.red.withValues(alpha: 0.7),
              onTap: () {
                Get.back();
                _showDeleteDialog();
              },
            ),
            _buildOption(
              label: "그룹 공유",
              onTap: () {
                Get.back();
                // TODO: 그룹 연결
                /*
                openGroupShareFlow(
                  itemType: 'ai_summary',
                  itemData: {'summary': Get.find<AiSummaryController>().summaryText.value},
                );
                 */
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    Color color = Colors.black87,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 0.5, color: Color(0xFFDADADA)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
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
              const Expanded(
                child: Center(
                  child: Text(
                    'AI 요약을 삭제하시겠습니까',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3F3F3F),
                      fontSize: 15,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: const Color(0xFFF3F3F3)),
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
                            onDelete?.call();
                          },
                          child: const Center(
                            child: Text(
                              '네',
                              style: TextStyle(
                                color: Color(0xFF4DB56C),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFF3F3F3)),
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
                                color: Color(0xFF4DB56C),
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
}