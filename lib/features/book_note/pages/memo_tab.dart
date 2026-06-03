import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_note_controller.dart';
import '../widgets/memo_item.dart';
import '../widgets/dialogs/sort_bottom_sheet.dart';
import '../widgets/overlays/creation_overlay.dart';

class MemoTab extends GetView<BookNoteController> {
  const MemoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlBar(context),

        Expanded(
          child: Obx(() {
            if (controller.isLoadingNotes.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.notes.isEmpty) {
              return const Center(
                child: Text("저장된 메모가 없습니다.", style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: controller.notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final item = controller.notes[index];
                return MemoItem(data: item);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildControlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.bottomSheet(
              const SortBottomSheet(type: "memo"),
              backgroundColor: Colors.transparent,
            ),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Obx(() => Text(
                  controller.sortTextMemo.value,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.bottomSheet(
                const CreationOverlay(
                  type: "memo",
                  isEdit: false,
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            child: const Icon(Icons.edit, color: Colors.grey, size: 24),
          ),
        ],
      ),
    );
  }
}
