import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/cs_model.dart';
import '../services/cs_provider.dart';

class CustomerServiceController extends GetxController {
  final CsProvider _provider = Get.put(CsProvider());

  var currentViewIndex = 0.obs;
  var isLoading = false.obs;
  var isAdminMode = false.obs;

  var faqList = <FaqModel>[].obs;
  var myInquiries = <TicketModel>[].obs;
  var adminInquiries = <TicketModel>[].obs;

  var selectedInquiry = Rxn<TicketModel>();
  var selectedFaq = Rxn<FaqModel>();

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final answerController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void fetchData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchFaqs(),
        fetchMyTickets(),
        if (isAdminMode.value) fetchAdminTickets(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFaqs() async {
    final response = await _provider.getFaqs();
    if (!response.status.hasError && response.body != null) {
      final raw = response.body;
      List<dynamic> data;
      if (raw is List) {
        data = raw;
      } else if (raw is Map && raw['items'] != null) {
        data = raw['items'] as List<dynamic>;
      } else {
        return;
      }
      faqList.value = data.map((json) => FaqModel.fromJson(json)).toList();
    }
  }

  Future<void> fetchMyTickets() async {
    final response = await _provider.getMyTickets();
    if (!response.status.hasError && response.body != null) {
      final raw = response.body;
      List<dynamic> data;
      if (raw is List) {
        data = raw;
      } else if (raw is Map && raw['items'] != null) {
        data = raw['items'] as List<dynamic>;
      } else {
        return;
      }
      var list = data.map((json) => TicketModel.fromJson(json)).toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      myInquiries.value = list;
    }
  }

  Future<void> fetchAdminTickets() async {
    final response = await _provider.getAdminTickets();
    if (!response.status.hasError && response.body != null) {
      final raw = response.body;
      List<dynamic> data;
      if (raw is List) {
        data = raw;
      } else if (raw is Map && raw['items'] != null) {
        data = raw['items'] as List<dynamic>;
      } else {
        return;
      }
      adminInquiries.value = data.map((json) => TicketModel.fromJson(json)).toList();
    }
  }

  void toggleAdminMode() {
    isAdminMode.value = !isAdminMode.value;
    fetchData();
    currentViewIndex.value = 0;
  }

  void changeView(int index) {
    if (index == 1) isAdminMode.value ? fetchAdminTickets() : fetchMyTickets();
    currentViewIndex.value = index;
  }

  void viewDetail(TicketModel inquiry) {
    selectedInquiry.value = inquiry;
    changeView(3);
  }

  void viewFaqDetail(FaqModel faq) {
    selectedFaq.value = faq;
    changeView(4);
  }

  Future<void> submitInquiry() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      Get.snackbar('알림', '제목과 내용을 입력해주세요.');
      return;
    }
    isLoading.value = true;
    final response = await _provider.createTicket(titleController.text, contentController.text);
    isLoading.value = false;
    if (!response.status.hasError) {
      Get.snackbar('성공', '문의가 등록되었습니다.');
      titleController.clear();
      contentController.clear();
      await fetchMyTickets();
      changeView(1);
    }
  }

  Future<void> submitAdminAnswer() async {
    if (answerController.text.isEmpty || selectedInquiry.value == null) return;
    isLoading.value = true;
    final response = await _provider.postAdminAnswer(selectedInquiry.value!.id, answerController.text);
    isLoading.value = false;
    if (!response.status.hasError) {
      Get.snackbar('성공', '답변이 등록되었습니다.');
      answerController.clear();
      fetchAdminTickets();
      changeView(1);
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    answerController.dispose();
    super.onClose();
  }
}