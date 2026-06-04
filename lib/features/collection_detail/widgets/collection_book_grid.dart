import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';

class CollectionBookGrid extends StatefulWidget {
  final CollectionDetailController controller;

  const CollectionBookGrid({super.key, required this.controller});

  @override
  State<CollectionBookGrid> createState() => _CollectionBookGridState();
}

class _CollectionBookGridState extends State<CollectionBookGrid> {
  int _visibleCount = 15;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더
          Obx(() => Row(
            children: [
              const Text(
                '작품들',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  height: 1.65,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.controller.books.length}',
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.87,
                ),
              ),
            ],
          )),
          const SizedBox(height: 15),

          // ── 작품 그리드
          Obx(() {
            if (widget.controller.books.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    '담긴 작품이 없습니다.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 15),
                  ),
                ),
              );
            }

            final books = widget.controller.books;
            final visibleBooks = books.take(_visibleCount).toList();
            final hasMore = books.length > _visibleCount;

            return Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.45,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: visibleBooks.length,
                  itemBuilder: (context, index) {
                    final book = visibleBooks[index];
                    final coverUrl = book['thumbnail'] as String? ?? '';
                    final title = book['title'] as String? ?? '';
                    final authors = book['authors'];
                    final author = (authors is List && authors.isNotEmpty)
                        ? authors.join(', ')
                        : '';
                    final bookId = int.tryParse(book['bookId']?.toString() ?? '');

                    return GestureDetector(
                      onTap: bookId != null
                          ? () => Get.toNamed('/book_detail_page', arguments: bookId)
                          : null,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 2 / 3,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border, width: 0.5),
                              image: coverUrl.isNotEmpty
                                  ? DecorationImage(
                                image: NetworkImage(coverUrl),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: coverUrl.isEmpty
                                ? const Icon(Icons.book, color: Colors.grey)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ));
                  },
                ),

                // ── 목록 더 불러오기
                if (hasMore) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => setState(() => _visibleCount += 15),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '목록 더 불러오기',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}
