import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_note_controller.dart';
import '../widgets/book_info_header.dart';
import 'bookmark_tab.dart';
import 'highlight_tab.dart';
import 'memo_tab.dart';
import '../../../core/widgets/bottom_bar.dart';

class BookNotePage extends GetView<BookNoteController> {
  const BookNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. App Bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),

      bottomNavigationBar: const BottomBar(),

      body: Column(
        children: [
          // 2. 책 정보 헤더
          const BookInfoHeader(),

          const Divider(height: 10, color: AppColors.divider),

          // 3. 탭 바
          TabBar(
            controller: controller.tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "북마크"),
              Tab(text: "하이라이트"),
              Tab(text: "메모"),
            ],
          ),

          // 4. 탭 뷰
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: const [
                BookmarkTab(),
                HighlightTab(),
                MemoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}