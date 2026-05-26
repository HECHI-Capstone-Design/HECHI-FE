import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart';

class SearchHeaderWidget extends GetView<BookSearchController> {
  const SearchHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 412,
          height: 62,
          padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
          decoration: const BoxDecoration(color: Colors.white),
          child: Container(
            height: 30,
            decoration: ShapeDecoration(
              color: const Color(0xFFF4F4F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Obx(() => TextField(
              controller: controller.searchTextController,
              focusNode: controller.searchFocusNode,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) =>
                  controller.onSubmit(controller.searchTextController.text),
              decoration: InputDecoration(
                prefixIcon: controller.selectedSearchTags.isEmpty
                    ? const Icon(Icons.search, color: Color(0xFF3F3F3F))
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      ...controller.selectedSearchTags.map((tag) =>
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: ShapeDecoration(
                              color: const Color(0x7FD1ECD9),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                    width: 0.5,
                                    color: Color(0xFF4DB56C)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '#${tag['name']}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    height: 1.75,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () =>
                                      controller.removeSearchTag(tag),
                                  child: const Icon(Icons.close,
                                      size: 14,
                                      color: Color(0xFF4DB56C)),
                                ),
                              ],
                            ),
                          )).toList(),
                    ],
                  ),
                ),
                hintText: controller.selectedSearchTags.isEmpty ? '검색' : '',
                hintStyle: const TextStyle(
                  color: Color(0xFF3F3F3F),
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )),
          ),
        ),

        // ── 태그 드롭다운
        Obx(() {
          if (!controller.isTagDropdownVisible.value) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDADADA)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() {
              // [레이어 A] 카테고리 선택 → 세부 태그 칩
              if (controller.selectedTagCategory.value.isNotEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: controller.clearTagCategory,
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFFF0FAF3),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back_ios,
                                size: 14, color: Color(0xFF4DB56C)),
                            const SizedBox(width: 4),
                            Text(
                              controller.selectedTagCategory.value,
                              style: const TextStyle(
                                  color: Color(0xFF4DB56C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 170),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        physics: const ClampingScrollPhysics(),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: controller.currentCategoryTags.map((tag) {
                            return GestureDetector(
                              onTap: () => controller.selectTag(tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: ShapeDecoration(
                                  color: const Color(0x7FDADADA),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                                child: Text('#${tag['name'] ?? ''}',
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 14)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // [레이어 B] 태그 검색 결과
              if (controller.tagDropdownResults.isNotEmpty) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 165),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    itemCount: controller.tagDropdownResults.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
                    itemBuilder: (context, index) {
                      final tag = controller.tagDropdownResults[index];
                      return InkWell(
                        onTap: () => controller.selectTag(tag),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Text('#',
                                  style: TextStyle(
                                      color: Color(0xFF4DB56C),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Text(tag['name'] ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFF3F3F3F), fontSize: 15)),
                              const Spacer(),
                              Text(tag['categoryName'] ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFFABABAB), fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              // [레이어 C] # 만 입력 → 카테고리 목록
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 185),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  itemCount: controller.tagCategories.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
                  itemBuilder: (context, index) {
                    final category = controller.tagCategories[index];
                    return InkWell(
                      onTap: () => controller.selectTagCategory(category),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(category['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 15)),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Color(0xFFABABAB)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}