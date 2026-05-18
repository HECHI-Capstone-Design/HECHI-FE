import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';

class CollectionActionButtons extends StatelessWidget {
  final CollectionDetailController controller;

  const CollectionActionButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
            "좋아요 ${controller.likeCount.value}",
            style: const TextStyle(fontSize: 14, color: Color(0xFF717171)),
          )),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Obx(() => InkWell(
                  onTap: controller.isMine.value ? null : () => controller.toggleLike(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          controller.isLiked.value ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          color: controller.isLiked.value ? const Color(0xFF4DB56C) : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "좋아요",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: controller.isLiked.value ? const Color(0xFF4DB56C) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ),

              Container(width: 1, height: 20, color: const Color(0xFFE0E0E0)),

              Expanded(
                child: InkWell(
                  onTap: () => controller.shareCollection(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.link, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text("공유", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}