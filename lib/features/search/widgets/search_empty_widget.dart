import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class SearchEmptyWidget extends StatelessWidget {
  const SearchEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 412,
      padding: const EdgeInsets.only(top: 150, bottom: 2),
      child: const Center(
        child: Text(
          '최근 검색어가 없습니다.\n도서를 검색해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}