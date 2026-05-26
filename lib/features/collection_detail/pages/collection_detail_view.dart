import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';
import '../widgets/collection_top_images.dart';
import '../widgets/collection_info_section.dart';
import '../widgets/collection_action_buttons.dart';
import '../widgets/collection_book_grid.dart';
import '../widgets/more_menu.dart';
import '../../../core/widgets/bottom_bar.dart';

class CollectionDetailView extends GetView<CollectionDetailController> {
  const CollectionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    final opacity = 0.0.obs;

    scrollController.addListener(() {
      double offset = scrollController.offset;
      opacity.value = ((offset - 200) / 100).clamp(0.0, 1.0);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomBar(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Obx(() => Container(
          color: Colors.white.withOpacity(opacity.value),
        )),
        title: Obx(() => Opacity(
          opacity: opacity.value,
          child: Text(
            controller.collectionTitle.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
        leading: Obx(() => IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: opacity.value > 0.5 ? Colors.black : Colors.white,
          ),
          onPressed: () => Get.back(
            result: controller.isModified.value ? {'updated': true} : null,
          ),
        )),
        actions: [
          Obx(() => controller.isMine.value
              ? Padding(
            padding: const EdgeInsets.only(right: 17),
            child: GestureDetector(
              onTap: () => CollectionMoreMenu.show(controller),
              child: Icon(
                Icons.more_horiz,
                color: opacity.value > 0.5 ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4DB56C)));
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CollectionTopImages(controller: controller),
              CollectionInfoSection(controller: controller),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              CollectionActionButtons(controller: controller),
              Container(height: 8, color: const Color(0xFFF5F5F5)),
              CollectionBookGrid(controller: controller),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }
}