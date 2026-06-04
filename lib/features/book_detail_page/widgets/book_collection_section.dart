import 'package:hechi/app/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../controllers/book_detail_controller.dart';
import '../../../features/collection/widgets/collection_thumbnail.dart';
import '../../../features/collection/models/collection_list_model.dart';

class BookCollectionSection extends StatefulWidget {
  const BookCollectionSection({super.key});

  @override
  State<BookCollectionSection> createState() => _BookCollectionSectionState();
}

class _BookCollectionSectionState extends State<BookCollectionSection> {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  List<CollectionListItem> collections = [];
  bool isLoading = true;

  String? get _token => box.read('access_token');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  void initState() {
    super.initState();
    _loadCollections();
    ever(Get
        .find<BookDetailController>()
        .collectionRefreshTrigger, (_) {
      _loadCollections();
    });
  }

  Future<void> _loadCollections() async {
    final controller = Get.find<BookDetailController>();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/${controller.bookId}/collections'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        if (mounted) {
          setState(() {
            collections = list;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ BookCollectionSection error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    if (collections.isEmpty) return const SizedBox.shrink();

    final controller = Get.find<BookDetailController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 타이틀
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 0.5, color: AppColors.textHint),
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
            children: collections.map((collection) {
              return GestureDetector(
                onTap: () async {
                  await Get.toNamed(
                    '/collection_detail',
                    arguments: int.tryParse(collection.id),
                  );
                  Get.find<BookDetailController>().collectionRefreshTrigger.value++;
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: ShapeDecoration(
                    color: AppColors.border.withOpacity(0.3),
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
                      Text(
                        '좋아요 ${collection.likeCount}',
                        style: const TextStyle(
                          color: AppColors.textMedium,
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
          onTap: () => Get.toNamed(
            '/book_collection_list',
            arguments: controller.bookId,
          ),
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              border: const Border(
                top: BorderSide(width: 1, color: AppColors.borderMedium),
                bottom: BorderSide(width: 1, color: AppColors.borderMedium),
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