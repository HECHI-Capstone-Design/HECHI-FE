import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/isbn_scan_controller.dart';

class IsbnScanView extends StatelessWidget {
  const IsbnScanView({super.key});

  @override
  Widget build(BuildContext context) {
    final IsbnScanController controller = Get.put(IsbnScanController());
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scanBoxWidth = (screenWidth * 0.8).clamp(200.0, 300.0);
    final double scanBoxHeight = 180;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller.cameraController,
            onDetect: controller.onBarcodeDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Text(
                  '카메라 오류: ${error.errorCode}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),

          CustomPaint(
            painter: ScannerOverlayPainter(
              scanBoxWidth: scanBoxWidth,
              scanBoxHeight: scanBoxHeight,
            ),
            child: Container(),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HECHI',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                const Expanded(child: SizedBox()),
              ],
            ),
          ),

          // 텍스트: 노란 박스(화면 중앙) 바로 위에 고정
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height / 2 - (scanBoxHeight / 2) - 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '바코드를 영역에 맞춰 보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '원하는 도서를 빠르게 찾을 수 있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          Obx(() => controller.isScanning.value
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox()),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanBoxWidth;
  final double scanBoxHeight;

  ScannerOverlayPainter({required this.scanBoxWidth, required this.scanBoxHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFFFE066)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final double left = (size.width - scanBoxWidth) / 2;
    final double top = (size.height - scanBoxHeight) / 2;

    final Rect scanRect = Rect.fromLTWH(left, top, scanBoxWidth, scanBoxHeight);
    final RRect scanRRect = RRect.fromRectAndRadius(scanRect, const Radius.circular(8));

    final Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path cutoutPath = Path()..addRRect(scanRRect);
    final Path finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, backgroundPaint);
    canvas.drawRRect(scanRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}