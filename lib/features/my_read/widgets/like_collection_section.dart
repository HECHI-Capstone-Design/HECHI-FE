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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: const Text(
            '좋아요한 컬렉션',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F3F3F),
            ),
          ),
        ),

        // ── 가로 스크롤 카드
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: collections.map((collection) {
              final index = collections.indexOf(collection);
              return GestureDetector(
                onTap: () => Get.toNamed(
                  '/collection_detail',
                  arguments: int.tryParse(collection.id),
                ),
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: index == collections.length - 1 ? 0 : 15.0,
                  ),
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
                      const SizedBox(height: 10),
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

        const SizedBox(height: 20),

        // ── 좋아요한 컬렉션 모두보기 버튼
        Padding(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 12.0,
            bottom: 20.0,
          ),
          child: InkWell(
            onTap: () => Get.toNamed('/like_collection_list'),
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