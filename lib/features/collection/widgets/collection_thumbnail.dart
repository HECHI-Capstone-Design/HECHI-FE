import 'package:flutter/material.dart';

class CollectionThumbnail extends StatelessWidget {
  final List<String> bookCoverUrls;
  final double width;
  final double height;

  const CollectionThumbnail({
    super.key,
    required this.bookCoverUrls,
    this.width = 84,
    this.height = 126,
  });

  @override
  Widget build(BuildContext context) {
    final covers = bookCoverUrls.take(4).toList();
    while (covers.length < 4) {
      covers.add('');
    }

    final innerWidth = width - 3.0;
    final innerHeight = height - 3.0;
    final cellWidth = innerWidth / 2;
    final cellHeight = innerHeight / 2;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.5, color: Color(0xFFDADADA)),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildCell(covers[0], cellWidth, cellHeight),
              _buildCell(covers[1], cellWidth, cellHeight),
            ],
          ),
          Row(
            children: [
              _buildCell(covers[2], cellWidth, cellHeight),
              _buildCell(covers[3], cellWidth, cellHeight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String url, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        image: url.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: url.isEmpty
          ? const Center(
        child: Icon(Icons.book, size: 16, color: Color(0xFFABABAB)),
      )
          : null,
    );
  }
}