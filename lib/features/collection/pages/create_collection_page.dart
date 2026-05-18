import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_collection_controller.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tag_search_section.dart';
import '../widgets/collection_book_thumbnail.dart';
import '../widgets/overlay/collection_description_overlay.dart';

class CreateCollectionPage extends GetView<CreateCollectionController> {
  const CreateCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Obx(() => Text(
          controller.isEditMode.value ? '컬렉션 수정' : '새 컬렉션',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF3F3F3F),
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            height: 1.75,
          ),
        )),
        leading: GestureDetector(
          onTap: controller.onCancel,
          child: const Center(
            child: Text(
              '취소',
              style: TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.87,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: GestureDetector(
              onTap: controller.onConfirm,
              child: const Center(
                child: Text(
                  '확인',
                  style: TextStyle(
                    color: Color(0xFF4DB56C),
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    height: 1.87,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            _buildDivider(),
            _buildDescriptionField(),
            _buildDivider(),
            _buildPrivacyToggle(),
            _buildDivider(),
            _buildTagSection(),
            _buildDivider(),
            _buildBookSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── 구분선 ────────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFDADADA)),
    );
  }

  // ── 제목 입력 ─────────────────────────────────────────────────────────────
  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: TextField(
        controller: controller.titleController,
        style: const TextStyle(
          color: Color(0xFF3F3F3F),
          fontSize: 15,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          height: 1.87,
        ),
        decoration: const InputDecoration(
          hintText: '컬렉션 제목',
          hintStyle: TextStyle(
            color: Color(0xFF717171),
            fontSize: 15,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            height: 1.87,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        maxLines: 1,
      ),
    );
  }

  // ── 설명 입력 ─────────────────────────────────────────────────────────────
  Widget _buildDescriptionField() {
    return GestureDetector(
      onTap: () async {
        final result = await Get.bottomSheet<String>(
          CollectionDescriptionOverlay(
            initialText: controller.descriptionController.text,
          ),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        );
        if (result != null) {
          controller.descriptionController.text = result;
          controller.description.value = result;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Obx(() {
          final text = controller.description.value;
          final isEmpty = text.isEmpty;
          const lineHeight = 1.87;
          const fontSize = 15.0;
          const maxLines = 4;

          return SizedBox(
            height: fontSize * lineHeight * maxLines,
            child: Stack(
              children: [
                Text(
                  isEmpty ? '설명 입력하기' : text,
                  maxLines: maxLines,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: isEmpty
                        ? const Color(0xFF717171)
                        : const Color(0xFF3F3F3F),
                    fontSize: fontSize,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: lineHeight,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── 비공개 토글 ───────────────────────────────────────────────────────────
  Widget _buildPrivacyToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '컬렉션 비공개 설정',
            style: TextStyle(
              color: Color(0xFF717171),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 2,
            ),
          ),
          Obx(() => _CustomSwitch(
            value: controller.isPrivate.value,
            onTap: () => controller.isPrivate.toggle(),
          )),
        ],
      ),
    );
  }

  // ── 태그 섹션 ─────────────────────────────────────────────────────────────
  Widget _buildTagSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '태그',
            style: TextStyle(
              color: Color(0xFF3F3F3F),
              fontSize: 17,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 12),
          const TagSearchSection(),
          Obx(() {
            if (controller.selectedTags.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  '선택된 태그',
                  style: TextStyle(
                    color: Color(0xFF717171),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.selectedTags.map((tag) {
                    return TagChip(
                      tag: tag,
                      isSelected: true,
                      showRemove: true,
                      onTap: () => controller.removeTag(tag),
                    );
                  }).toList(),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── 작품 섹션 ─────────────────────────────────────────────────────────────
  Widget _buildBookSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Row(
            children: [
              const Text(
                '작품들',
                style: TextStyle(
                  color: Color(0xFF3F3F3F),
                  fontSize: 17,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  height: 1.65,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${controller.selectedBooks.length}',
                style: const TextStyle(
                  color: Color(0xFF717171),
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.navigateToBookSearch,
                child: const Text(
                  '수정하기',
                  style: TextStyle(
                    color: Color(0xFF4DB56C),
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.87,
                  ),
                ),
              ),
            ],
          )),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12 * 2) / 3;
              final itemHeight = itemWidth * 3 / 2;

              return Obx(() => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: AddBookButton(
                      onTap: controller.navigateToBookSearch,
                    ),
                  ),
                  ...controller.selectedBooks.map((book) => SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: CollectionBookThumbnail(
                      book: book,
                      onRemove: () => controller.removeBook(book.id),
                    ),
                  )),
                ],
              ));
            },
          ),
        ],
      ),
    );
  }
}

// ── 커스텀 스위치 ─────────────────────────────────────────────────────────────
class _CustomSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;

  const _CustomSwitch({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 49,
        height: 22,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF4DB56C) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(50),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2.5),
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFE8E9E9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(2, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}