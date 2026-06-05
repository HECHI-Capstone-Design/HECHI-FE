import 'package:hechi/app/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../collection/models/collection_list_model.dart';
import '../../collection/widgets/collection_thumbnail.dart';

class SeeAllLikeCollectionPage extends StatefulWidget {
  const SeeAllLikeCollectionPage({super.key});

  @override
  State<SeeAllLikeCollectionPage> createState() => _SeeAllLikeCollectionPageState();
}

class _SeeAllLikeCollectionPageState extends State<SeeAllLikeCollectionPage> {
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
  }

  Future<void> _loadCollections() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/me/likes/collections'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        if (mounted) setState(() => collections = list);
      } else {
        print('❌ loadCollections 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ loadCollections error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '좋아요한 컬렉션',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.5, color: AppColors.border),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : collections.isEmpty
          ? const Center(
        child: Text(
          '좋아요한 컬렉션이 없습니다.',
          style: TextStyle(color: AppColors.textMedium, fontSize: 15),
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 2;
          const crossAxisSpacing = 15.0;
          const padding = 17.0;
          const itemPadding = 15.0;

          final itemWidth = (constraints.maxWidth - padding * 2 - crossAxisSpacing) / crossAxisCount;
          final thumbnailWidth = itemWidth - itemPadding * 2;
          final thumbnailHeight = thumbnailWidth * 3 / 2;
          const textHeight = 10 + 36 + 10 + 18 + 10;
          final itemHeight = thumbnailHeight + textHeight + itemPadding * 2;
          final childAspectRatio = itemWidth / itemHeight;

          return GridView.builder(
            padding: const EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: 15,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return GestureDetector(
                onTap: () async {
                  final result = await Get.toNamed(
                    '/collection_detail',
                    arguments: int.tryParse(collection.id),
                  );
                  if (result != null && result is Map<String, dynamic> && result['updated'] == true) {
                    _loadCollections();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(itemPadding),
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
                        width: thumbnailWidth,
                        height: thumbnailHeight,
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
            },
          );
        },
      ),
    );
  }
}