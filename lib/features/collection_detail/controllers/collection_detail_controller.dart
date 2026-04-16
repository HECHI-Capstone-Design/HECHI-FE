import 'package:get/get.dart';

class CollectionDetailController extends GetxController {

  // 1. 컬렉션 기본 정보
  final String collectionTitle = "이런 소설만 읽을 수 있다면";
  final String collectionDesc = "조금 더 행복하게 살 수 있을 것 같아 (소장 도서로만 컬렉션을 꾸립니다)";
  final String creatorName = "Josee";
  final String creatorProfileImg = "https://picsum.photos/100/100"; // 가짜 프사
  final List<String> tags = ["#소설", "#인생책"];

  // 2. 좋아요 및 상태
  RxInt likeCount = 2641.obs;
  RxBool isLiked = false.obs;
  RxBool isMine = true.obs; // 내 컬렉션인지 여부 (수정하기 버튼 노출용)

  // 3. 상단 3개 책 표지 이미지 (배경 꾸미기용)
  final List<String> topCoverImages = [
    "https://picsum.photos/200/300?1",
    "https://picsum.photos/200/300?2",
    "https://picsum.photos/200/300?3",
  ];

  // 4. 컬렉션에 포함된 책 리스트 (피그마 디자인 기준)
  final RxList<Map<String, String>> books = [
    {"title": "절창", "author": "구병모", "cover": "https://picsum.photos/150/220?11"},
    {"title": "나의 완벽한 장례식", "author": "조현선", "cover": "https://picsum.photos/150/220?12"},
    {"title": "자몽 살구 클럽", "author": "한로로", "cover": "https://picsum.photos/150/220?13"},
    {"title": "모순", "author": "양귀자", "cover": "https://picsum.photos/150/220?14"},
    {"title": "혼모노", "author": "성해나", "cover": "https://picsum.photos/150/220?15"},
    {"title": "브람스를 좋아하세요", "author": "프랑수아즈 사강", "cover": "https://picsum.photos/150/220?16"},
    {"title": "쾨테는 모든 것을 말했다", "author": "스즈키 유이", "cover": "https://picsum.photos/150/220?17"},
  ].obs;

  // 좋아요 버튼 눌렀을 때 실행되는 함수
  void toggleLike() {
    isLiked.value = !isLiked.value;
    if (isLiked.value) {
      likeCount.value++;
    } else {
      likeCount.value--;
    }
  }

  // 공유 버튼 함수
  void shareCollection() {
    Get.snackbar("공유", "컬렉션 링크가 복사되었습니다.", snackPosition: SnackPosition.BOTTOM);
  }
}