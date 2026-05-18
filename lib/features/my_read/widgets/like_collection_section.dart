import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hechi/app/routes.dart';
import '../../collection/models/collection_list_model.dart';
import '../../collection/widgets/collection_thumbnail.dart';

class LikeCollectionSection extends StatefulWidget {
  const LikeCollectionSection({super.key});

  @override
  State<LikeCollectionSection> createState() => _MyCollectionSectionState();
}

class _MyCollectionSectionState extends State<LikeCollectionSection> {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  List<CollectionListItem> collections = [];
  bool isLoading = true;

  String? get _token => box.read('access_token');

  @override
  void initState() {
    super.initState();
    _fetchLikedCollections();
  }

  Future<void> _fetchLikedCollections() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/me/likes/collections'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
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
      print('❌ _fetchLikedCollections error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    if (collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 타이틀
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            '좋아요한 컬렉션',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F3F3F),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 가로 스크롤 카드
        SizedBox(
          height: 210,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            scrollDirection: Axis.horizontal,
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return GestureDetector(
                onTap: () => Get.toNamed(
                  Routes.collectionDetail,
                  arguments: int.tryParse(collection.id),
                ),
                child: Container(
                  width: 140,
                  margin: EdgeInsets.only(
                    right: index == collections.length - 1 ? 0 : 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 썸네일
                      CollectionThumbnail(
                        bookCoverUrls: collection.bookCoverUrls,
                        width: 140,
                        height: 140,
                      ),
                      const SizedBox(height: 8),
                      // ── 제목
                      Text(
                        collection.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // ── 작성자
                      Text(
                        '컬렉션 · ${collection.authorName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9E9E),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // ── 좋아요한 컬렉션 모두보기 버튼
        // TODO: 좋아요한 컬렉션 전체 목록 페이지 만들기
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: InkWell(
            onTap: () {}, // TODO: Routes.likedCollectionList
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '좋아요한 컬렉션 모두보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}