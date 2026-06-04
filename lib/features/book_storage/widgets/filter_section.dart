import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import '../models/library_book_model.dart';

class BookGridItem extends StatelessWidget {
  final LibraryBookModel book;

  const BookGridItem({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 책 표지 이미지
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 0.5),
              image: DecorationImage(
                image: NetworkImage(book.thumbnail),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 2. 책 제목
        Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),

      ],
    );
  }
}