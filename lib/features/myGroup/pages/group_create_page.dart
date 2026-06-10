import 'package:hechi/app/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_create_controller.dart';

class GroupCreatePage extends GetView<GroupCreateController> {
  const GroupCreatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '그룹 만들기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 이미지 등록 영역 (탭하면 갤러리 열림)
                  Obx(() {
                    final bytes = controller.selectedImageBytes.value;
                    return GestureDetector(
                      onTap: controller.pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB0BEC5),
                              image: bytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(bytes),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          if (controller.isUploadingImage.value)
                            const CircularProgressIndicator(color: Colors.white)
                          else if (bytes == null)
                            const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.white),
                                SizedBox(height: 8),
                                Text('그룹 사진 추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('사진 변경', style: TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('그룹 이름'),
                        _buildTextField(
                          hint: '그룹 이름을 입력하세요.',
                          onChanged: (val) => controller.groupName.value = val,
                        ),
                        const SizedBox(height: 24),

                        _buildLabel('그룹 아이디'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                hint: '아이디를 입력하세요.',
                                onChanged: (val) {
                                  controller.groupId.value = val;
                                  controller.idCheckStatus.value = 0;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final status = controller.idCheckStatus.value;
                              final bool hasText = controller.groupId.value.isNotEmpty;
                              final Color btnColor = !hasText
                                  ? AppColors.primaryLight
                                  : status == 1
                                      ? Colors.green
                                      : AppColors.primary;
                              return GestureDetector(
                                onTap: () async => await controller.checkDuplicateId(controller.groupId.value),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: btnColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    '중복 확인',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        Obx(() {
                          if (controller.idCheckStatus.value == 1) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8, left: 8),
                              child: Text('사용가능한 아이디입니다.', style: TextStyle(color: Colors.green, fontSize: 12)),
                            );
                          } else if (controller.idCheckStatus.value == 2) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8, left: 8),
                              child: Text('이미 있는 아이디입니다.', style: TextStyle(color: Colors.red, fontSize: 12)),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel('그룹 최대 인원 수'),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showMemberPicker(context),
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundGrey,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Obx(() => Text(
                                  controller.maxMembers.value == null
                                      ? ''
                                      : '${controller.maxMembers.value}',
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                )),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildLabel('그룹 소개'),
                        _buildTextField(
                          hint: '그룹 소개를 입력하세요. (그룹 소개 및 규칙)',
                          onChanged: (val) => controller.groupDescription.value = val,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel('그룹 비공개 설정'),
                            Obx(() => CupertinoSwitch(
                              value: controller.isPrivate.value,
                              activeColor: AppColors.primary,
                              onChanged: controller.togglePrivate,
                            )),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Obx(() {
                          if (controller.isPrivate.value) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildLabel('비밀번호 설정'),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                                _buildTextField(
                                  hint: '비공개 그룹의 비밀번호를 입력하세요.',
                                  obscureText: true,
                                  onChanged: (val) => controller.password.value = val,
                                ),
                                const SizedBox(height: 24),
                                _buildLabel('비밀번호 확인'),
                                _buildTextField(
                                  hint: '비밀번호를 한 번 더 입력하세요.',
                                  obscureText: true,
                                  onChanged: (val) => controller.passwordConfirm.value = val,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: const BoxDecoration(color: Colors.white),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => controller.createGroup(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  '그룹 생성하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({required String hint, bool obscureText = false, Function(String)? onChanged}) {
    return TextField(
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        filled: true,
        fillColor: AppColors.backgroundGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showMemberPicker(BuildContext context) {
    int tempSelected = controller.maxMembers.value ?? controller.memberOptions[3];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      controller.setMaxMembers(tempSelected);
                      Get.back();
                    },
                    child: const Text('완료', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: controller.memberOptions.indexOf(tempSelected) == -1
                        ? 3
                        : controller.memberOptions.indexOf(tempSelected),
                  ),
                  onSelectedItemChanged: (int index) {
                    tempSelected = controller.memberOptions[index];
                  },
                  children: controller.memberOptions.map((int number) {
                    return Center(
                      child: Text(
                        '$number',
                        style: const TextStyle(fontSize: 20, color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
