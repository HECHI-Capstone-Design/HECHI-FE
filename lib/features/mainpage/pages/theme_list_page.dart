import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mainpage_controller.dart';

class ThemeListPage extends StatelessWidget {
  const ThemeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainpageController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          '# ${controller.currentThemeTitle.value}',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        )),
        centerTitle: true,
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
        if (controller.isThemeLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.currentThemeBooks.isEmpty) {
          return const Center(child: Text("해당 테마에 도서가 없습니다."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.currentThemeBooks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final book = controller.currentThemeBooks[index];

            return GestureDetector(
              onTap: () {
                Get.toNamed('/book_detail_page', arguments: book['id']);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            style: const TextStyle(fontSize: 12, color: Colors.grey)
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
        ),
    );
  }
}