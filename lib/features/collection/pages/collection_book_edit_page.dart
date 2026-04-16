import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_book_edit_controller.dart';
import '../models/collection_book_model.dart';

class CollectionBookEditPage extends GetView<CollectionBookEditController> {
  const CollectionBookEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── 앱바 ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 17,
            child: GestureDetector(
              onTap: controller.onBack,
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Color(0xFF3F3F3F),
              ),
            ),
          ),
          const Text(
            '작품들',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF3F3F3F),
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }

  // ── 검색바 ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
      child: Container(
        height: 45,
        decoration: ShapeDecoration(
          color: const Color(0xFFF3F3F3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, size: 22, color: Color(0xFFABABAB)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                style: const TextStyle(
                  color: Color(0xFF3F3F3F),
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  hintText: '검색하여 작품 추가하기',
                  hintStyle: TextStyle(
                    color: Color(0xFFABABAB),
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Obx(() => controller.isSearching.value
                ? GestureDetector(
              onTap: controller.clearSearch,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.cancel,
                    size: 20, color: Color(0xFFABABAB)),
              ),
            )
                : const SizedBox(width: 12)),
          ],
        ),
      ),
    );
  }

  // ── 바디: 검색 결과 or 현재 도서 리스트 ──────────────────────────────────
  Widget _buildBody() {
    return Obx(() {
      if (controller.isSearching.value) return _buildSearchResults();
      return _buildBookList();
    });
  }

  // ── 검색 결과 리스트 ──────────────────────────────────────────────────────
  Widget _buildSearchResults() {
    final results = controller.searchResults;

    if (results.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없어요',
          style: TextStyle(
            color: Color(0xFFABABAB),
            fontSize: 15,
            fontFamily: 'Roboto',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFDADADA),
      ),
      itemBuilder: (context, index) {
        final book = results[index];
        return _SearchResultItem(
          book: book,
          onTap: () => controller.addBook(book),
        );
      },
    );
  }

  // ── 현재 도서 리스트 (드래그 순서 변경 + 스와이프 삭제) ─────────────────
  Widget _buildBookList() {
    if (controller.books.isEmpty) {
      return const Center(
        child: Text(
          '담긴 작품이 없어요',
          style: TextStyle(
            color: Color(0xFFABABAB),
            fontSize: 15,
            fontFamily: 'Roboto',
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: controller.books.length,
      onReorder: controller.reorderBooks,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 4,
        shadowColor: Colors.black26,
        child: child,
      ),
      itemBuilder: (context, index) {
        final book = controller.books[index];
        return _BookListItem(
          key: ValueKey(book.id),
          book: book,
          index: index,
          onDelete: () => controller.removeBook(book.id),
        );
      },
    );
  }
}

// ── 검색 결과 아이템 ───────────────────────────────────────────────────────────
class _SearchResultItem extends StatelessWidget {
  final CollectionBook book;
  final VoidCallback onTap;

  const _SearchResultItem({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // 책 커버
            Container(
              width: 48,
              height: 72,
              decoration: ShapeDecoration(
                color: const Color(0xFFEEEEEE),
                image: book.coverUrl != null
                    ? DecorationImage(
                  image: NetworkImage(book.coverUrl!),
                  fit: BoxFit.cover,
                )
                    : null,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 0.5, color: Color(0xFFD4D4D4)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: book.coverUrl == null
                  ? const Icon(Icons.book, size: 20, color: Color(0xFFABABAB))
                  : null,
            ),
            const SizedBox(width: 14),
            // 제목 / 저자
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.11,
                      letterSpacing: 0.25,
                    ),
                  ),
                  const SizedBox(height: 5),

                  Text(
                    book.author,
                    style: const TextStyle(
                      color: Color(0xFF717171),
                      fontSize: 13,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.54,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add, size: 20, color: Color(0xFF4DB56C)),
          ],
        ),
      ),
    );
  }
}

// ── 도서 리스트 아이템 (스와이프 삭제 + 드래그 핸들) ──────────────────────────
class _BookListItem extends StatelessWidget {
  final CollectionBook book;
  final int index;
  final VoidCallback onDelete;

  const _BookListItem({
    super.key,
    required this.book,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${book.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: const Color(0xB2D4D4D4),
        child: const SizedBox(
          width: 100,
          child: Center(
            child: Text(
              '삭제',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFEA1717),
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.11,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Obx가 리스트를 직접 갱신하므로 false 반환
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(width: 0.5, color: Color(0xFFD4D4D4))
          ),
        ),
        padding: const EdgeInsets.only(top: 15, left: 20, right: 30, bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 책 커버
            Container(
              width: 84,
              height: 126,
              decoration: ShapeDecoration(
                color: const Color(0xFFEEEEEE),
                image: book.coverUrl != null
                    ? DecorationImage(
                  image: NetworkImage(book.coverUrl!),
                  fit: BoxFit.cover,
                )
                    : null,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 0.5, color: Color(0xFFD4D4D4)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: book.coverUrl == null
                  ? const Icon(Icons.book, size: 28, color: Color(0xFFABABAB))
                  : null,
            ),
            const SizedBox(width: 20),
            // 제목 / 저자
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.11,
                      letterSpacing: 0.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    book.author,
                    style: const TextStyle(
                      color: Color(0xFF717171),
                      fontSize: 13,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.54,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
            ),
            // 드래그 핸들 (줄 세 개 아이콘)
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_handle,
                size: 24,
                color: Color(0xFFABABAB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}