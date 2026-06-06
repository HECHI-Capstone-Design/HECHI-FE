import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SingleGenreListPage extends StatelessWidget {
  const SingleGenreListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 메인페이지에서 넘겨준 데이터 받기
    final Map<String, dynamic> args = Get.arguments;
    final String title = args['title'];
    final List<Map<String, dynamic>> books = args['books'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // 넘겨받은 장르 이름으로 타이틀 설정 (예: 소설 베스트)
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: books.isEmpty
          ? const Center(child: Text("도서 데이터가 없습니다."))
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              // 책 상세 페이지로 이동
              Get.toNamed('/book_detail_page', arguments: book['id']);
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 책 표지
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    image: DecorationImage(
                      image: NetworkImage(book['imageUrl']),
                      fit: BoxFit.cover,
                      onError: (e, s) {},
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // 책 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book['author']} | 평균 ★ ${book['rating']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}