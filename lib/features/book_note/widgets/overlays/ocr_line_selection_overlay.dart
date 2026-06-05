import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OcrLineSelectionOverlay extends StatefulWidget {
  const OcrLineSelectionOverlay({super.key, required this.lines});

  final List<String> lines;

  @override
  State<OcrLineSelectionOverlay> createState() =>
      _OcrLineSelectionOverlayState();
}

class _OcrLineSelectionOverlayState extends State<OcrLineSelectionOverlay> {
  final Set<int> _selectedIndexes = <int>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 10, 17, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ),
                    const Text(
                      '문장 선택',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedIndexes.isEmpty
                          ? null
                          : () {
                              final selectedText = _selectedIndexes.toList()
                                ..sort();
                              final merged = selectedText
                                  .map((index) => widget.lines[index].trim())
                                  .where((text) => text.isNotEmpty)
                                  .join(' ');
                              Get.back(result: merged);
                            },
                      child: Text(
                        '적용',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedIndexes.isEmpty
                              ? AppColors.textHint
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.divider,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: const [
                    Icon(
                      Icons.text_snippet_outlined,
                      size: 18,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '촬영한 문장에서 저장할 텍스트를 선택해주세요.',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: widget.lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final line = widget.lines[index];
                    final selected = _selectedIndexes.contains(index);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedIndexes.remove(index);
                          } else {
                            _selectedIndexes.add(index);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primarySurface
                              : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.primary
                                    : Colors.white,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.borderMedium,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
