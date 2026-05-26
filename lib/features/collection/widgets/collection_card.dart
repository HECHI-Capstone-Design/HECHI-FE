import 'package:flutter/material.dart';
import '../models/collection_list_model.dart';

class CollectionCard extends StatelessWidget {
  final CollectionListItem collection;
  final VoidCallback onTap;
  final VoidCallback? onLikeTap;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFDADADA)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverImage(),
            _buildTitleSection(),
            if (collection.tags.isNotEmpty) _buildTagSection(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 17),
              child: Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── 상단 커버 이미지 영역 ────────────────────────────────────────────────
  Widget _buildCoverImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;

        final double thumbnailHeight = totalWidth * 200 / 378;

        final double bookHeight = thumbnailHeight;
        final double bookWidth = bookHeight * 2 / 3;

        final double remainWidth = totalWidth - bookWidth;
        final double step = remainWidth / 4;

        const int maxCovers = 5;
        final covers = collection.bookCoverUrls.take(maxCovers).toList();
        while (covers.length < maxCovers) {
          covers.add('');
        }

        return SizedBox(
          width: totalWidth,
          height: thumbnailHeight,
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              for (int i = maxCovers - 1; i >= 1; i--)
                Positioned(
                  right: (maxCovers - 1 - i) * step,
                  top: 0,
                  child: _buildCoverItem(
                    coverUrl: covers[i],
                    width: bookWidth,
                    height: bookHeight,
                  ),
                ),

              Positioned(
                left: 0,
                top: 0,
                child: _buildCoverItem(
                  coverUrl: covers[0],
                  width: bookWidth,
                  height: bookHeight,
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00D9D9D9), Color(0xFF737373)],
                    ),
                  ),
                ),
              ),

              // 작성자명
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 17, vertical: 15),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 25,
                          color: Color(0xFF717171),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        collection.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          height: 1.11,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverItem({
    required String coverUrl,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFDDDDDD),
        image: coverUrl.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(coverUrl),
          fit: BoxFit.cover,
        )
            : null,
      ),
    );
  }

  // ── 제목 / 설명 ──────────────────────────────────────────────────────────
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            collection.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              height: 1.11,
              letterSpacing: 0.25,
            ),
          ),
          if (collection.description.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              collection.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: 0.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 태그 ─────────────────────────────────────────────────────────────────
  Widget _buildTagSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 17, right: 17, bottom: 13),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: collection.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: ShapeDecoration(
              color: const Color(0x7FDADADA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.79,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 좋아요 / 도서 수 ───────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좋아요
          GestureDetector(
            onTap: onLikeTap,
            child: Row(
              children: [
                Text(
                  '좋아요',
                  style: TextStyle(
                    color: collection.isLiked
                        ? const Color(0xFF4EB56D)
                        : const Color(0xFF717171),
                    fontSize: 13,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.54,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${collection.likeCount}',
                  style: TextStyle(
                    color: collection.isLiked
                        ? const Color(0xFF4EB56D)
                        : const Color(0xFF717171),
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

          // 구분선 (세로)
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            color: const Color(0xFFDADADA),
          ),

          // 도서 수
          Row(
            children: [
              const Text(
                '도서',
                style: TextStyle(
                  color: Color(0xFF717171),
                  fontSize: 13,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.54,
                  letterSpacing: 0.25,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${collection.bookCount}',
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
        ],
      ),
    );
  }
}