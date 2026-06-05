import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookListSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> bookList;
  final VoidCallback onHeaderTap;

  const BookListSection({
    super.key,
    required this.title,
    required this.bookList,
    required this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onHeaderTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: bookList.isEmpty
              ? const Center(child: Text("데이터가 없습니다."))
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: bookList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              return _buildBookItem(bookList[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookItem(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/book_detail_page', arguments: book['id']);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 118,
            height: 177,
            decoration: BoxDecoration(
              border: Border.all(width: 0.5, color: AppColors.borderMedium),
              borderRadius: BorderRadius.circular(2),
              image: DecorationImage(
                image: NetworkImage(book['imageUrl']),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 118,
            child: Text(
              book['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '평균★${book['rating']}',
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.2,),
          ),
        ],
      ),
    );
  }
}