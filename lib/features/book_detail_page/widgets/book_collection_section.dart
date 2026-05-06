import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';
import '../../../features/collection/widgets/collection_thumbnail.dart';
import '../../../features/collection/models/collection_list_model.dart';

class BookCollectionSection extends GetView<BookDetailController> {
  const BookCollectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace dummy data with API response
    // GET /collections?book_id={bookId}
    final collections = dummyCollections;

    if (collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 타이틀
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 0.5, color: Color(0xFFABABAB)),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: const Text(
            '이 도서가 담긴 컬렉션',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ── 컬렉션 카드 가로 스크롤
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dummyCollections.map((collection) {
              return GestureDetector(
                onTap: () {
                  // TODO: 컬렉션 상세 페이지로 이동
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: ShapeDecoration(
                    color: const Color(0x4CDADADA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CollectionThumbnail(
                        bookCoverUrls: collection.bookCoverUrls,
                        width: 100,
                        height: 150,
                      ),
                      const SizedBox(height: 10),
                      // 컬렉션 제목
                      Text(
                        collection.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          height: 1.29,
                          letterSpacing: 0.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 좋아요 수
                      const SizedBox(height: 4),
                      Text(
                        '좋아요 ${collection.likeCount}',
                        style: const TextStyle(
                          color: Color(0xFF717171),
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          height: 1.38,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── 모두보기 버튼
        InkWell(
          onTap: () => Get.toNamed('/book_collection_list', arguments: controller.bookId,),
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9).withOpacity(0.3),
              border: const Border(
                top: BorderSide(width: 1, color: Color(0xFFD4D4D4)),
                bottom: BorderSide(width: 1, color: Color(0xFFD4D4D4)),
              ),
            ),
            child: const Text(
              '모두보기',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}