import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_collection_controller.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tag_search_section.dart';
import '../widgets/collection_book_thumbnail.dart';
import 'collection_description_overlay.dart';

class CreateCollectionPage extends GetView<CreateCollectionController> {
  const CreateCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
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
            ),
          ],
        ),
      ),
    );
  }

  // ── 앱바 ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: controller.onCancel,
              child: const Text(
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
            Obx(() => Text(
              controller.isEditMode.value ? '컬렉션 수정' : '새 컬렉션',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                height: 1.75,
              ),
            )),
            GestureDetector(
              onTap: controller.onConfirm,
              child: const Text(
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
        final result = await Get.to<String>(
              () => CollectionDescriptionOverlay(
            initialText: controller.descriptionController.text,
          ),
          transition: Transition.downToUp,
          duration: const Duration(milliseconds: 250),
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
                if (!isEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white],
                        ),
                      ),
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
          // 헤더
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

          // 검색 + 대분류 탭 + 추천 태그
          const TagSearchSection(),

          // 선택된 태그
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
          // 헤더
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
            ],
          )),
          const SizedBox(height: 15),

          // 책 목록 + 추가 버튼
          Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...controller.selectedBooks.map((book) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CollectionBookThumbnail(
                    book: book,
                    onRemove: () => controller.removeBook(book.id),
                  ),
                )),
                AddBookButton(onTap: controller.navigateToBookSearch),
              ],
            ),
          )),
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