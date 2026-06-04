import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';

class CollectionTopImages extends StatelessWidget {
  final CollectionDetailController controller;

  const CollectionTopImages({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      const int maxCovers = 5;
      final covers = controller.thumbnailCovers.take(maxCovers).toList();
      while (covers.length < maxCovers) covers.add('');

      return LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double thumbnailHeight = totalWidth * 200 / 378;
          final double bookHeight = thumbnailHeight;
          final double bookWidth = bookHeight * 2 / 3;
          final double remainWidth = totalWidth - bookWidth;
          final double step = remainWidth / 4;

          return Stack(
            children: [
              // ── 책 커버들
              SizedBox(
                width: totalWidth,
                height: thumbnailHeight,
                child: Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    for (int i = maxCovers - 1; i >= 1; i--)
                      Positioned(
                        right: (maxCovers - 1 - i) * step,
                        top: 0,
                        child: _buildCover(covers[i], bookWidth, bookHeight),
                      ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: _buildCover(covers[0], bookWidth, bookHeight),
                    ),
                    // ── 그라데이션 오버레이
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black54,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildCover(String url, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        image: url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
    );
  }
}