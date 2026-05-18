import 'package:get/get.dart';
import '../models/group_model.dart';

class MyGroupController extends GetxController {
  // TODO: Replace dummy data with API response

  var myGroups = <GroupModel>[].obs;
  var recommendedGroupsMain = <GroupModel>[].obs;
  var recommendedGroupsDetail = <GroupModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDummyData();
  }

  void fetchDummyData() {
    // 내 그룹 더미 데이터
    myGroups.assignAll([
      GroupModel(id: '1', title: 'HECHI', authorName: ''),
      GroupModel(id: '2', title: 'BOOK CLUB', authorName: ''),
      GroupModel(id: '3', title: 'BOOK C...', authorName: ''),
    ]);

    // 메인 화면 그룹 추천 더미 데이터 (10개)
    List<String> authors = ['dal', 'yeoleum', 'summer', '새빈', '성현'];
    List<String> titles = ['BOOK CLUB', 'HECHI!@!!', 'BOOK CLUB', 'BOOK CLUB', 'BOOK CLUB'];

    recommendedGroupsMain.assignAll(
        List.generate(10, (index) => GroupModel(
          id: 'rec_main_$index',
          title: titles[index % titles.length],
          description: '저희 그룹은 ~~ 입니다.',
          authorName: authors[index % authors.length],
        ))
    );

    // 추천 탭(상세 화면) 그룹 추천 더미 데이터 (20개)
    recommendedGroupsDetail.assignAll(
        List.generate(20, (index) => GroupModel(
          id: 'rec_detail_$index',
          title: titles[index % titles.length],
          description: '저희 그룹은 ~~ 입니다.',
          authorName: authors[index % authors.length],
        ))
    );
  }
}