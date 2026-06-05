import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class PreferenceController extends GetxController {
  RxInt currentStep = 0.obs;

  // ✅ UI용: 모든 선택지(소설, 시 + 장르 전부)를 담는 리스트
  RxList<String> allOptions = <String>[].obs;
  // ✅ UI용: 사용자가 클릭해서 선택한 항목들
  RxList<String> selectedOptions = <String>[].obs;

  // 백엔드 API 유지를 위해 원본 데이터는 보이지 않는 곳에 보관
  List<String> _originalCategories = [];
  List<String> _originalGenres = [];

  RxBool isLoading = false.obs;

  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _fetchOptions();
    Future.delayed(const Duration(seconds: 2), () {
      if (currentStep.value == 0) nextStep();
    });
  }

  Future<void> _fetchOptions() async {
    try {
      final url = Uri.parse('$baseUrl/taste/options');
      String? token = box.read('access_token');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        _originalCategories = List<String>.from(data['categories'] ?? []);
        _originalGenres = List<String>.from(data['genres'] ?? []);

        // ✅ 두 리스트를 하나로 뭉쳐서 UI에 제공
        allOptions.value = [..._originalCategories, ..._originalGenres];
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    _originalCategories = ['소설', '시', '에세이', '만화'];
    _originalGenres = [
      '추리', '코미디', '스릴러/공포', 'SF', '판타지', '로맨스',
      '액션', '철학', '인문', '역사', '과학', '사회/정치', '경제/경영', '예술', '자기계발', '여행', '취미'
    ];
    // ✅ 두 리스트를 하나로 뭉침
    allOptions.value = [..._originalCategories, ..._originalGenres];
  }

  void nextStep() {
    // 이제 1단계(통합 페이지) 하나뿐이므로, 바로 완료(submit) 처리
    if (currentStep.value == 1) {
      if (selectedOptions.isEmpty) {
        _showError("장르를 최소 1개 이상 선택해주세요.");
        return;
      }
      submitPreferences();
      return;
    }

    if (currentStep.value < 1) {
      currentStep.value++;
    }
  }

  // ✅ 선택/해제 토글 로직
  void toggleOption(String item) {
    if (selectedOptions.contains(item)) {
      selectedOptions.remove(item);
    } else {
      selectedOptions.add(item);
    }
  }

  void _showError(String msg) {
    Get.snackbar("알림", msg,
        backgroundColor: Colors.black87, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
  }

  Future<void> submitPreferences() async {
    isLoading.value = true;
    String? token = box.read('access_token');

    if (token == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    try {
      // ✅ [핵심] 백엔드 에러가 안 나게, 선택된 항목들을 다시 카테고리와 장르로 똑똑하게 분류합니다.
      List<String> finalCategories = selectedOptions.where((e) => _originalCategories.contains(e)).toList();
      List<String> finalGenres = selectedOptions.where((e) => _originalGenres.contains(e)).toList();

      final url = Uri.parse('$baseUrl/taste/submit');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "categories": finalCategories,
          "genres": finalGenres
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await box.write('is_taste_analyzed_local', true);
        Get.offAllNamed(Routes.initial);
        Get.snackbar("환영합니다!", "취향 분석이 완료되었습니다.",
            backgroundColor: AppColors.primary, colorText: Colors.white);
      } else {
        _showError("저장에 실패했습니다. (${response.statusCode})");
      }
    } catch (e) {
      _showError("서버와 연결할 수 없습니다.");
    } finally {
      isLoading.value = false;
    }
  }
}