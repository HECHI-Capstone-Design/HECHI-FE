import 'package:flutter/material.dart';
import '../models/collection_book_model.dart';

// ── 책 썸네일 ─────────────────────────────────────────────────────────────────
class CollectionBookThumbnail extends StatelessWidget {
  final CollectionBook book;
  final VoidCallback? onRemove;

  const CollectionBookThumbnail({
    super.key,
    required this.book,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
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
              ? Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book,
                    size: 24, color: Color(0xFFABABAB)),
                const SizedBox(height: 4),
                Text(
                  book.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF717171),
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          )
              : null,
        ),

        // 삭제 버튼
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child:
                const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ── 작품 추가 버튼 ─────────────────────────────────────────────────────────────
class AddBookButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddBookButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFABABAB)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 24, color: Color(0xFF717171)),
            SizedBox(height: 4),
            Text(
              '작품 추가',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF717171),
                fontSize: 13,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 2.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}