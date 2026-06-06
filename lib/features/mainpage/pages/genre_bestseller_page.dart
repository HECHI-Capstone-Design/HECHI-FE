import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/genre_bestseller_controller.dart';
// 기존에 만든 위젯 재사용
import '../widgets/book_list_section.dart';

class GenreBestsellerPage extends StatelessWidget {
  const GenreBestsellerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 주입
    final controller = Get.put(GenreBestsellerController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('장르별 베스트셀러', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.genreSections.isEmpty) return const Center(child: Text("추천할 장르 도서가 없습니다."));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: controller.genreSections.length,
          itemBuilder: (context, index) {
            final section = controller.genreSections[index];
            return Column(
              children: [
                BookListSection(
                  title: section['title'],
                  bookList: section['books'],
                  onHeaderTap: () {},
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        );
      }),
        ),
    );
  }
}