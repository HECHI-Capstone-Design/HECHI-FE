import 'package:hechi/app/colors.dart';
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
        _buildSearchField(),
        if (controller.isTagDropdownOpen.value) _buildDropdown(),
        const SizedBox(height: 12),
        _buildRecommendedTags(),
      ],
    ));
  }

  // ── 검색 필드 ─────────────────────────────────────────────────────────────
  Widget _buildSearchField() {
    final isOpen = controller.isTagDropdownOpen.value;
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.textMedium),
          borderRadius: isOpen
              ? const BorderRadius.vertical(top: Radius.circular(5))
              : BorderRadius.circular(5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.tagSearchController,
              onTap: controller.openTagDropdown,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.87,
              ),
              decoration: const InputDecoration(
                hintText: '#태그 검색',
                hintStyle: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.87,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: isOpen
                ? controller.closeTagDropdown
                : controller.openTagDropdown,
            child: Icon(
              isOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ── 드롭다운 ─────────────────────────────────────────────────────────────
  Widget _buildDropdown() {
    final isFiltering = controller.isTagSearchActive.value;
    final hasSelectedCategory = controller.selectedCategory.value.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(width: 1, color: AppColors.textMedium),
          right: BorderSide(width: 1, color: AppColors.textMedium),
          bottom: BorderSide(width: 1, color: AppColors.textMedium),
        ),
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(5)),
      ),
      child: isFiltering
          ? _buildSearchResults()
          : hasSelectedCategory
          ? _buildSelectedCategoryContent()
          : _buildCategoryList(),
    );
  }

  // ── 검색어 있을 때: 검색 결과 ────────────────────────────────────────────
  Widget _buildSearchResults() {
    final results = controller.filteredSearchTags;

    if (results.isEmpty) {
      return _buildDropdownRow(
        child: const Text(
          '검색 결과가 없습니다',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 14,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            height: 2,
          ),
        ),
      );
    }

    final grouped = <String, List<CollectionTag>>{};
    for (final tag in results) {
      grouped.putIfAbsent(tag.category, () => []).add(tag);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 168,
        minWidth: double.infinity,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.expand((entry) => [
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((tag) {
                  return Obx(() => TagChip(
                    tag: tag,
                    isSelected: controller.isTagSelected(tag),
                    onTap: () {
                      controller.toggleTag(tag);
                      controller.closeTagDropdown();
                    },
                  ));
                }).toList(),
              ),
            ),
          ]).toList(),
        ),
      ),
    );
  }

  // ── 대분류 카테고리 목록 ─────────────────────────────────────
  Widget _buildCategoryList() {
    final visibleCategories = controller.categories;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 165, // 33px * 5개 = 딱 5개 높이로 고정
        minWidth: double.infinity,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visibleCategories.map((category) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.selectCategory(category.name),
              child: _buildDropdownRow(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── 대분류 선택 시 태그 목록 ────────────────────────────────────
  Widget _buildSelectedCategoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: AppColors.primarySurface,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => controller.selectedCategory.value = '',
                child: const Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                controller.selectedCategory.value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  height: 2,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 0.5, color: AppColors.border),

        // 해당 카테고리 태그 목록
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 170,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            physics: const ClampingScrollPhysics(),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.currentCategoryTags.map((tag) {
                return Obx(() => TagChip(
                  tag: tag,
                  isSelected: controller.isTagSelected(tag),
                  onTap: () {
                    controller.toggleTag(tag);
                    controller.closeTagDropdown();
                  },
                ));
              }).toList(),
            ),
          ),
        ),
      ],
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

  // ── 추천 태그 (항상 표시) ─────────────────────────────────────────────────
  Widget _buildRecommendedTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 태그',
          style: TextStyle(
            color: AppColors.textMedium,
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
          children: controller.popularTags.map((tag) {
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
          c.closeTagDropdown();
        },
        child: Container(
          width: double.infinity,
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          child: Row(
            children: [
              Text(
                tag.label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 2,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      );
    });
  }
}