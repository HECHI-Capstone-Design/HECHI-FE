import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_collection_controller.dart';
import '../models/collection_tag_model.dart';
import 'tag_chip.dart';

class TagSearchSection extends GetView<CreateCollectionController> {
  const TagSearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 검색 필드 ────────────────────────────────────────────────
        _buildSearchField(),

        // ── 검색 중: 드롭다운 결과 ───────────────────────────────────
        if (controller.isTagSearchActive.value) ...[
          const SizedBox(height: 4),
          _buildSearchDropdown(),
        ],

        // ── 검색 아닐 때: 대분류 탭 + 추천 태그 ─────────────────────
        if (!controller.isTagSearchActive.value) ...[
          const SizedBox(height: 12),
          _buildCategoryTabs(),
          const SizedBox(height: 10),
          _buildSuggestedTags(),
        ],
      ],
    ));
  }

  // ── 검색 필드 ─────────────────────────────────────────────────────────────
  Widget _buildSearchField() {
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF717171)),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.tagSearchController,
              style: const TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                hintText: '#태그 검색',
                hintStyle: TextStyle(
                  color: Color(0xFF717171),
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.isTagSearchActive.value)
            GestureDetector(
              onTap: controller.clearTagSearch,
              child: const Icon(Icons.close, size: 16, color: Color(0xFF717171)),
            ),
        ],
      ),
    );
  }

  // ── 검색 드롭다운 ─────────────────────────────────────────────────────────
  Widget _buildSearchDropdown() {
    final results = controller.filteredSearchTags;

    if (results.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 1, color: const Color(0xFF717171)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownRow(
              child: const Text(
                '추천 태그',
                style: TextStyle(
                  color: Color(0xFF717171),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 2,
                ),
              ),
            ),
            _buildDropdownRow(
              child: const Text(
                '검색 결과가 없어요',
                style: TextStyle(
                  color: Color(0xFFABABAB),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<CollectionTag>>{};
    for (final tag in results) {
      grouped.putIfAbsent(tag.category, () => []).add(tag);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1, color: const Color(0xFF717171)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownRow(
            child: const Text(
              '추천 태그',
              style: TextStyle(
                color: Color(0xFF717171),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 2,
              ),
            ),
          ),
          ...grouped.entries.expand((entry) => [
            _buildDropdownRow(
              child: Text(
                entry.key,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 2,
                ),
              ),
            ),
            ...entry.value.map((tag) => _SearchResultItem(tag: tag)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

    // ── 대분류 탭 ─────────────────────────────────────────────────────────────
  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: controller.categories.map((category) {
          final isActive = controller.selectedCategory.value == category.name;
          return GestureDetector(
            onTap: () => controller.selectCategory(category.name),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: ShapeDecoration(
                color: isActive ? const Color(0xFF4DB56C) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: isActive
                        ? const Color(0xFF4DB56C)
                        : const Color(0xFFDADADA),
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF717171),
                  fontSize: 13,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 추천 태그 (현재 대분류 기준) ──────────────────────────────────────────
  Widget _buildSuggestedTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 태그',
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
          children: controller.currentCategoryTags.map((tag) {
            return TagChip(
              tag: tag,
              isSelected: controller.isTagSelected(tag),
              onTap: () => controller.toggleTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── 검색 결과 아이템 ──────────────────────────────────────────────────────────
class _SearchResultItem extends StatelessWidget {
  final CollectionTag tag;
  const _SearchResultItem({required this.tag});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CreateCollectionController>();
    return Obx(() {
      final isSelected = c.isTagSelected(tag);
      return GestureDetector(
        onTap: () {
          c.toggleTag(tag);
          c.clearTagSearch();
        },
        child: Container(
          width: double.infinity,
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: isSelected ? const Color(0xFFF0FAF3) : Colors.transparent,
          child: Row(
            children: [
              Text(
                tag.label,
                style: const TextStyle(
                  color: Color(0xFF3F3F3F),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 2,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check, size: 16, color: Color(0xFF4DB56C)),
            ],
          ),
        ),
      );
    });
  }
}