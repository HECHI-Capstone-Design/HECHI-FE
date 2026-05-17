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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          '작품들',
          style: TextStyle(
            color: Color(0xFF3F3F3F),
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            height: 1.75,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Center(
            child: Text(
              '취소',
              style: TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.87,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: GestureDetector(
              onTap: controller.onConfirm,
              child: const Center(
                child: Text(
                  '확인',
                  style: TextStyle(
                    color: Color(0xFF4DB56C),
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    height: 1.87,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
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
    if (controller.isSearchLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4DB56C)),
      );
    }

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

  // ── 현재 도서 리스트 ───────────────────────────────────────────────────
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
      buildDefaultDragHandles: false,
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(width: 0.5, color: Color(0xFFD4D4D4)),
          ),
        ),
        padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 90,
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
                  ? const Icon(Icons.book, size: 24, color: Color(0xFFABABAB))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
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
          ],
        ),
      ),
    );
  }
}

// ── 도서 리스트 아이템 ───────────────────────────────────────
class _BookListItem extends StatefulWidget {
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
  State<_BookListItem> createState() => _BookListItemState();
}

class _BookListItemState extends State<_BookListItem> {
  bool _isRevealed = false;
  static const double _deleteWidth = 80;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            setState(() => _isRevealed = true);
          } else if (details.primaryVelocity! > 100) {
            setState(() => _isRevealed = false);
          }
        }
      },
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _deleteWidth,
            child: GestureDetector(
              onTap: () {
                setState(() => _isRevealed = false);
                widget.onDelete();
              },
              child: Container(
                color: const Color(0xB2D4D4D4),
                alignment: Alignment.center,
                child: const Text(
                  '삭제',
                  style: TextStyle(
                    color: Color(0xFFEA1717),
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.11,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ),
          ),

          // 콘텐츠
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(
              _isRevealed ? -_deleteWidth : 0,
              0,
              0,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 0.5, color: Color(0xFFD4D4D4)),
              ),
            ),
            padding: const EdgeInsets.only(
                top: 15, left: 20, right: 20, bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 90,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEEEEEE),
                    image: widget.book.coverUrl != null
                        ? DecorationImage(
                      image: NetworkImage(widget.book.coverUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                          width: 0.5, color: Color(0xFFD4D4D4)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: widget.book.coverUrl == null
                      ? const Icon(Icons.book,
                      size: 24, color: Color(0xFFABABAB))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.11,
                          letterSpacing: 0.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.book.author,
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
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(
                    Icons.menu,
                    size: 24,
                    color: Color(0xFFABABAB),
                  ),
                ),
              ],
            ),
          ),

          if (_isRevealed)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isRevealed = false),
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
      ),
    );
  }
}