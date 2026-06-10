import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

import '../../reading_registration/controllers/book_stopper_controller.dart';

class BookStopperConnectionSheet extends GetView<BookStopperController> {
  const BookStopperConnectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "북스토퍼 연결",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.statusMessage.value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _ConnectionStatusCard(controller: controller),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isConnected
                          ? null
                          : (controller.isScanning
                              ? controller.stopScan
                              : controller.scanForDevices),
                      icon: Icon(controller.isScanning ? Icons.stop : Icons.search),
                      label: Text(controller.isScanning ? "검색 중지" : "기기 찾기"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.isConnected && !controller.isBusy
                          ? controller.syncLibraryBooks
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4DB56C),
                      ),
                      icon: const Icon(Icons.sync),
                      label: const Text("책 목록 동기화"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                "주변 북스토퍼",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              if (controller.discoveredDevices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "아직 찾은 기기가 없어요. 북스토퍼 전원을 켠 뒤 기기 찾기를 눌러주세요.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.discoveredDevices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = controller.discoveredDevices[index];
                      return _DeviceTile(
                        device: device,
                        isConnected: controller.connectedDeviceId.value == device.id,
                        isBusy: controller.isBusy,
                        onConnect: () => controller.connectToDevice(device),
                        onDisconnect: controller.disconnect,
                      );
                    },
                  ),
                ),
              if (controller.lastEventType.value != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "최근 이벤트: ${controller.lastEventType.value}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({required this.controller});

  final BookStopperController controller;

  @override
  Widget build(BuildContext context) {
    final connected = controller.isConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFF2FBF4) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: connected ? const Color(0xFFBFE7C9) : const Color(0xFFE6E6E6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: connected ? const Color(0xFF4DB56C) : const Color(0xFF999999),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? (controller.connectedDeviceName.value ?? "북스토퍼")
                      : "연결된 북스토퍼 없음",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? (controller.connectedDeviceId.value ?? "")
                      : "기기 찾기를 눌러 북스토퍼를 연결할 수 있어요.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isConnected,
    required this.isBusy,
    required this.onConnect,
    required this.onDisconnect,
  });

  final DiscoveredDevice device;
  final bool isConnected;
  final bool isBusy;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final name = device.name.isNotEmpty ? device.name : "이름 없는 기기";

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        device.id,
        style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
      ),
      trailing: isConnected
          ? TextButton(
              onPressed: isBusy ? null : onDisconnect,
              child: const Text("연결 해제"),
            )
          : FilledButton(
              onPressed: isBusy ? null : onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4DB56C),
              ),
              child: const Text("연결"),
            ),
    );
  }
}
