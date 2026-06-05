// lib/features/search/pages/search_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart';
import '../widgets/search_header_widget.dart';
import '../widgets/search_history_list_widget.dart';
import '../widgets/search_result_widget.dart';
import 'package:hechi/features/myGroup/widgets/recommended_group_item_widget.dart';
import 'package:hechi/features/myGroup/models/group_model.dart';
import '../../group_join/pages/group_join_page.dart'; // 💡 상세페이지 이동을 위해 임포트 확인
import '../../group_join/bindings/group_join_binding.dart';
import '../widgets/search_collection_result_widget.dart';

class SearchView extends GetView<BookSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              color: Colors.white,
              child: Obx(() {
                // 현재 상태가 검색 결과(result) 상태인지 확인
                final isResultMode = controller.currentView.value == SearchState.result;

                return Column(
                  children: [
                    // 1. 상단 안전 여백 및 검색창 영역
                    const SizedBox(height: 14.0),
                    const SearchHeaderWidget(),
                    
                    // 2. 동적 탭바 영역: 오직 검색 결과를 띄운 상태(result)일 때만 노출됩니다!
                    if (isResultMode) ...[
                      const SizedBox(height: 10.0),
                      Theme(
                        data: ThemeData(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                        child: TabBar(
                          onTap: (index) {
                            controller.changeTab(index);
                          },
                          indicatorColor: Colors.black,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          tabs: const [
                            Tab(text: '책'),
                            Tab(text: '컬렉션'),
                            Tab(text: '그룹'),
                          ],
                        ),
                      ),
                    ],

                    // 3. 하단 콘텐츠 영역
                    Expanded(
                      child: _buildBody(),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (controller.currentView.value) {
      case SearchState.initial:
        return const SizedBox.shrink();
        
      case SearchState.emptyHistory:
        return const Center(
          child: Text(
            '최근 검색어가 없습니다.\n도서를 검색해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.4, fontSize: 14),
          ),
        );
        
      case SearchState.hasHistory:
        return const SearchHistoryListWidget();
        
      case SearchState.result:
        return TabBarView(
          physics: const NeverScrollableScrollPhysics(), 
          children: [
            // [탭 0] 책 검색 결과
            const SearchResultWidget(), 

            // [탭 1] 컬렉션 검색 결과
            const SearchCollectionResultWidget(),

            // [탭 2] 💡 [수정] 더미 리스트 대신 서버 실시간 데이터를 뿌려주는 위젯 호출!
            _buildRealGroupSearchResultList(),
          ],
        );
    }
  }

  /// 👥 [수정 완료] 서버에서 받아온 실제 그룹 검색 결과를 동적으로 그리는 위젯
  Widget _buildRealGroupSearchResultList() {
    return Obx(() {
      // 1. 서버 로딩 중일 때 인디케이터 가드
      if (controller.isGroupLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black),
        );
      }

      // 2. 검색 결과가 진짜 0개일 때 안내 문구
      if (controller.groupSearchResults.isEmpty) {
        return const Center(
          child: Text(
            '검색 결과와 일치하는 그룹이 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        );
      }

      // 3. 2개 이상 발견 시 실제 데이터 바인딩 리스트뷰 출력!
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        itemCount: controller.groupSearchResults.length,
        itemBuilder: (context, index) {
          final GroupModel realGroup = controller.groupSearchResults[index];
          
          return GestureDetector(
            onTap: () {
              print('🔍 검색된 실전 그룹 클릭됨: ${realGroup.title} (ID: ${realGroup.id})');
              // 카드를 터치하면 전체화면 그룹 가입/탈퇴 상세화면으로 안전하게 다이렉트 슛!
              Get.to(
                () => const GroupJoinPage(),
                arguments: realGroup,
                binding: GroupJoinBinding(),
                transition: Transition.rightToLeft,
              );
            },
            child: RecommendedGroupItemWidget(
              group: realGroup,
              showDescription: true, // 서버에서 온 방 소개글('설명이 없습니다' 등)을 이쁘게 렌더링하기 위해 true
            ),
          );
        },
      );
    });
  }
}