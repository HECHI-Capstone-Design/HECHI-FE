import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reading_registration_controller.dart';
import '../widgets/current_reading_book_widget.dart';
import '../widgets/book_carousel_widget.dart';

class ReadingRegistrationView extends GetView<ReadingRegistrationController> {
  const ReadingRegistrationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("독서", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () {
              print("➕ [독서 등록] 우측 상단 책 추가 버튼 클릭됨");
              controller.openHighlightCreationForCurrentBook();
            },
          ),
          const SizedBox(width: 12), // 끝부분 우측 여백 튜닝
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: false,
        child: Obx(() {
        if (controller.isLoading.value && controller.libraryReadingItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const CurrentReadingBookWidget()
                ),

                const SizedBox(height: 40),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "읽는 중 보관함",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "터치하여 독서를 시작하세요.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),

                if (controller.libraryReadingItems.isNotEmpty)
                  BookCarouselWidget(
                    libraryItems: controller.libraryReadingItems,
                    onBookTap: (bookId) {
                      controller.onBookTap(bookId);
                    },
                  )
                else
                  const SizedBox(
                    height: 100,
                    child: Center(child: Text("보관함에 읽고 있는 책이 없습니다.", style: TextStyle(color: Colors.grey))),

                  ),
              ],
            ),
          ),
        );
      }),
        ),
    );
  }
}
