import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/library_book_model.dart';
import '../data/book_storage_provider.dart';

class BookStorageController extends GetxController {
  final BookStorageProvider provider;
  BookStorageController({required this.provider});

  final RxInt currentTabIndex = 0.obs;
  final RxString currentSort = '최신 순'.obs;
  final RxString currentSortKey = 'latest'.obs;
  final RxList<LibraryBookModel> books = <LibraryBookModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBooks();
  }

  void changeTab(int index) {
    if (currentTabIndex.value == index) return;
    currentTabIndex.value = index;
    fetchBooks();
  }

  String get _currentShelfParam {
    switch (currentTabIndex.value) {
      case 0: return 'reading';
      case 1: return 'completed';
      case 2: return 'rated';
      case 3: return 'wishlist';
      default: return 'reading';
    }
  }

  Future<void> fetchBooks() async {
    isLoading.value = true;
    try {
      final result = await provider.getLibraryBooks(
        shelf: _currentShelfParam,
        sort: currentSortKey.value,
      );

      if (currentSortKey.value == 'latest' &&
          (_currentShelfParam == 'rated')) {
        books.assignAll(result.reversed.toList());
      } else {
        books.assignAll(result);
      }
    } catch (e) {
      books.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void goToBookDetails(int bookId) {
    if (bookId == 0) return;
    Get.toNamed('/reading_detail', arguments: {'bookId': bookId});
  }

  void showSortBottomSheet() {
    Get.bottomSheet(
      Obx(() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('정렬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text('취소', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildSortOption('최신 순', 'latest'),
            _buildSortOption('가나다 순', 'title'),
            const SizedBox(height: 20),
          ],
        ),
      )),
    );
  }

  Widget _buildSortOption(String label, String key) {
    return InkWell(
      onTap: () {
        currentSort.value = label;
        currentSortKey.value = key;
        Get.back();
        fetchBooks();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(
              color: currentSortKey.value == key ? Colors.black : Colors.black87,
              fontWeight: currentSortKey.value == key ? FontWeight.bold : FontWeight.normal,
            )),
            if (currentSortKey.value == key)
              const Icon(Icons.check, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}