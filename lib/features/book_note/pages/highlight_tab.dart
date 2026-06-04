import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_note_controller.dart';
import '../widgets/highlight_item.dart';
import '../widgets/dialogs/sort_bottom_sheet.dart';
import '../widgets/overlays/creation_overlay.dart';

class HighlightTab extends GetView<BookNoteController> {
  const HighlightTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookNoteController>();
    _maybeOpenCreationOverlay(context, controller);

    return Column(
      children: [
        _buildControlBar(context),

        Expanded(
          child: Obx(() {
            if (controller.isLoadingHighlights.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.highlights.isEmpty) {
              return const Center(
                child: Text("저장된 하이라이트가 없습니다.", style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: controller.highlights.length,
              itemBuilder: (context, index) {
                final item = controller.highlights[index];
                return HighlightItem(data: item);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 0),
            );
          }),
        ),
      ],
    );
  }

  void _maybeOpenCreationOverlay(
    BuildContext context,
    BookNoteController controller,
  ) {
    if (controller.tabController.index != 1) return;

    final request = controller.consumeHighlightCreationRequest();
    if (request == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (Get.isBottomSheetOpen == true) return;

      Get.bottomSheet(
        CreationOverlay(
          type: "highlight",
          isEdit: false,
          page: request['page'] as int?,
          autoStartOcr: request['autoStartOcr'] == true,
          closeParentPageOnCreate: request['closeParentPageOnSave'] == true,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    });
  }

  Widget _buildControlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.backgroundGrey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.bottomSheet(
              const SortBottomSheet(type: "highlight"),
              backgroundColor: Colors.transparent,
            ),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Obx(() => Text(
                  controller.sortTextHighlight.value,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              /*
              Get.bottomSheet(
                HighlightCreationOverlay(isEdit: false,),
                isScrollControlled: true,
                backgroundColor: Colors.white,
              );
               */
              Get.bottomSheet(
                CreationOverlay(
                  type: "highlight",
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
