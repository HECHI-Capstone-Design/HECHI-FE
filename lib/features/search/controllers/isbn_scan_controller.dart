import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/search_repository.dart';
import '../../book_detail_page/pages/book_detail_page.dart';
import '../../book_detail_page/bindings/book_detail_binding.dart';

class IsbnScanController extends GetxController {
  // 1. 실제 카메라 컨트롤러
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    autoStart: true,
    formats: const [BarcodeFormat.ean13],
  );

  final SearchRepository _repository = SearchRepository();
  final RxBool isScanning = false.obs;

  @override
  void onClose() {
    try {
      cameraController.dispose();
    } catch (e) {
      print("카메라 종료 에러 무시: $e");
    }
    super.onClose();
  }

  // 2. [안드로이드용] 실제 바코드 감지 함수
  Future<void> onBarcodeDetect(BarcodeCapture capture) async {
    if (isScanning.value) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        print("📸 스캔 감지됨! 값: [$code], 길이: ${code.length}");

        if (code.length == 10 || code.length == 13) {
          print("✅ 유효한 ISBN입니다. 처리 시작.");
          await _processIsbn(code);
          break;
        } else {
          print("⚠️ ISBN 형식이 아님 (길이 불일치)");
        }
      }
    }
  }

  // 3. [공통 로직] ISBN으로 API 호출 및 이동
  Future<void> _processIsbn(String isbn) async {
    isScanning.value = true;

    try {
      final book = await _repository.searchByBarcode(isbn);

      if (book != null) {
        Get.back();
        print("📖 스캔 성공: ${book.title} (ID: ${book.id})");

        Get.off(
          () => const BookDetailPage(),
          binding: BookDetailBinding(),
          arguments: book.id,
        );
      } else {
        Get.snackbar("알림", "책 정보를 찾을 수 없습니다.");
        await Future.delayed(const Duration(seconds: 2));
        isScanning.value = false;
      }
    } catch (e) {
      print("API 에러: $e");
      Get.snackbar("오류", "서버 연결에 실패했습니다.");
      isScanning.value = false;
    }
  }
}