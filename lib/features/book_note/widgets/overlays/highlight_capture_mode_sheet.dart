import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum HighlightCaptureMode { immediateOcr, saveForLater }

class HighlightCaptureModeSheet extends StatelessWidget {
  const HighlightCaptureModeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "하이라이트 촬영 방식",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "지금 바로 문장을 추출할지, 이미지만 저장해두고 나중에 추출할지 선택할 수 있어요.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            _ModeTile(
              icon: Icons.text_snippet_outlined,
              title: "바로 추출",
              subtitle: "촬영 후 바로 OCR과 문장 선택으로 이어집니다.",
              onTap: () => Get.back(result: HighlightCaptureMode.immediateOcr),
            ),
            const SizedBox(height: 12),
            _ModeTile(
              icon: Icons.photo_library_outlined,
              title: "촬영만 저장",
              subtitle: "이미지만 저장해두고 독서 종료 후 페이지별로 골라 추출합니다.",
              onTap: () => Get.back(result: HighlightCaptureMode.saveForLater),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF4DB56C)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
          ],
        ),
      ),
    );
  }
}
