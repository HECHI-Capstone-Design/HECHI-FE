import 'dart:async';
import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/models/reading_library_model.dart';
import 'reading_registration_controller.dart';

enum BookStopperConnectionStage {
  disconnected,
  scanning,
  connecting,
  connected,
  syncing,
  error,
}

class BookStopperController extends GetxController {
  static final Uuid _serviceUuid = Uuid.parse(
    "6E400001-B5A3-F393-E0A9-E50E24DCCA9E",
  );
  static final Uuid _rxCharacteristicUuid = Uuid.parse(
    "6E400002-B5A3-F393-E0A9-E50E24DCCA9E",
  );
  static final Uuid _txCharacteristicUuid = Uuid.parse(
    "6E400003-B5A3-F393-E0A9-E50E24DCCA9E",
  );
  static const String _preferredDeviceName = "ESP32_JSON_BLE";

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final stage = BookStopperConnectionStage.disconnected.obs;
  final statusMessage = "북스토퍼가 연결되지 않았습니다.".obs;
  final discoveredDevices = <DiscoveredDevice>[].obs;
  final connectedDeviceId = RxnString();
  final connectedDeviceName = RxnString();
  final lastEventType = RxnString();
  final lastEventJson = Rxn<Map<String, dynamic>>();

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  QualifiedCharacteristic? _rxCharacteristic;
  QualifiedCharacteristic? _txCharacteristic;
  String _incomingBuffer = "";
  int _negotiatedMtu = 23;

  bool get isConnected => stage.value == BookStopperConnectionStage.connected;
  bool get isScanning => stage.value == BookStopperConnectionStage.scanning;
  bool get isBusy =>
      stage.value == BookStopperConnectionStage.connecting ||
      stage.value == BookStopperConnectionStage.syncing;

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    super.onClose();
  }

  Future<void> scanForDevices() async {
    if (!await _ensurePermissions()) {
      _setStage(BookStopperConnectionStage.error, "블루투스 권한이 필요합니다.");
      return;
    }

    await _scanSubscription?.cancel();
    discoveredDevices.clear();
    _setStage(BookStopperConnectionStage.scanning, "북스토퍼를 찾는 중입니다...");

    _scanSubscription = _ble
        .scanForDevices(
          withServices: [_serviceUuid],
          scanMode: ScanMode.lowLatency,
          requireLocationServicesEnabled: false,
        )
        .listen(
          (device) {
            final index = discoveredDevices.indexWhere((d) => d.id == device.id);
            if (index == -1) {
              discoveredDevices.add(device);
            } else {
              discoveredDevices[index] = device;
              discoveredDevices.refresh();
            }

            if (device.name == _preferredDeviceName && !isConnected) {
              statusMessage.value = "북스토퍼를 찾았습니다. 연결할 수 있어요.";
            }
          },
          onError: (Object error) {
            _setStage(
              BookStopperConnectionStage.error,
              "북스토퍼 검색에 실패했습니다: $error",
            );
          },
        );
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (!await _ensurePermissions()) {
      _setStage(BookStopperConnectionStage.error, "블루투스 권한이 필요합니다.");
      return;
    }

    await _scanSubscription?.cancel();
    await _notifySubscription?.cancel();
    await _connectionSubscription?.cancel();

    connectedDeviceId.value = device.id;
    connectedDeviceName.value = device.name.isNotEmpty ? device.name : "북스토퍼";
    _setStage(BookStopperConnectionStage.connecting, "북스토퍼에 연결하는 중입니다...");

    _rxCharacteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _rxCharacteristicUuid,
      deviceId: device.id,
    );
    _txCharacteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _txCharacteristicUuid,
      deviceId: device.id,
    );

    _connectionSubscription = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 12),
        )
        .listen(
          (update) async {
            switch (update.connectionState) {
              case DeviceConnectionState.connecting:
                _setStage(
                  BookStopperConnectionStage.connecting,
                  "북스토퍼에 연결하는 중입니다...",
                );
                break;
              case DeviceConnectionState.connected:
                _setStage(
                  BookStopperConnectionStage.connected,
                  "북스토퍼가 연결되었습니다.",
                );
                await _requestMtu(device.id);
                _listenToNotifications();
                await Future<void>.delayed(const Duration(milliseconds: 250));
                await syncLibraryBooks();
                break;
              case DeviceConnectionState.disconnecting:
                _setStage(
                  BookStopperConnectionStage.connecting,
                  "북스토퍼 연결을 종료하는 중입니다...",
                );
                break;
              case DeviceConnectionState.disconnected:
                _clearConnection("북스토퍼 연결이 해제되었습니다.");
                break;
            }
          },
          onError: (Object error) {
            _clearConnection("북스토퍼 연결에 실패했습니다: $error");
          },
        );
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (!isConnected) {
      _setStage(
        BookStopperConnectionStage.disconnected,
        discoveredDevices.isEmpty
            ? "북스토퍼 검색을 멈췄습니다."
            : "기기를 찾았습니다. 연결할 수 있어요.",
      );
    }
  }

  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    await _connectionSubscription?.cancel();
    _clearConnection("북스토퍼 연결을 종료했습니다.");
  }

  Future<void> syncLibraryBooks() async {
    if (!isConnected || _rxCharacteristic == null) {
      statusMessage.value = "북스토퍼가 연결된 뒤에 동기화할 수 있습니다.";
      return;
    }

    final readingController = Get.find<ReadingRegistrationController>();
    if (readingController.libraryReadingItems.isEmpty) {
      await readingController.refreshData(showLoading: false);
    }

    final items = readingController.libraryReadingItems
        .where((item) => item.book.id > 0)
        .toList();

    _setStage(BookStopperConnectionStage.syncing, "책 목록을 북스토퍼로 보내는 중입니다...");

    try {
      await _sendJson({"type": "INIT_REGISTER_BOOK"});
      await Future<void>.delayed(const Duration(milliseconds: 80));

      for (final item in items) {
        await _sendJson(_buildRegisterBookPayload(item));
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }

      _setStage(
        BookStopperConnectionStage.connected,
        "${items.length}권을 북스토퍼에 동기화했습니다.",
      );
    } catch (error) {
      _setStage(
        BookStopperConnectionStage.error,
        "책 목록 동기화에 실패했습니다: $error",
      );
    }
  }

  Map<String, dynamic> _buildRegisterBookPayload(ReadingLibraryItem item) {
    final maxPayloadLength = _maxPayloadLength;
    String title = item.book.title;

    Map<String, dynamic> payload() => {
          "type": "REGISTER_BOOK",
          "id": item.book.id,
          "title": title,
          "page": item.currentPage,
        };

    while (_encodedLength(payload()) > maxPayloadLength && title.isNotEmpty) {
      title = title.substring(0, title.length - 1);
    }

    return payload();
  }

  Future<void> _listenToNotifications() async {
    final characteristic = _txCharacteristic;
    if (characteristic == null) return;

    await _notifySubscription?.cancel();
    _incomingBuffer = "";

    _notifySubscription = _ble.subscribeToCharacteristic(characteristic).listen(
      _handleNotificationChunk,
      onError: (Object error) {
        _setStage(
          BookStopperConnectionStage.error,
          "북스토퍼 이벤트 수신 중 오류가 발생했습니다: $error",
        );
      },
    );
  }

  void _handleNotificationChunk(List<int> data) {
    _incomingBuffer += utf8.decode(data, allowMalformed: true);

    while (_incomingBuffer.contains("\n")) {
      final splitIndex = _incomingBuffer.indexOf("\n");
      final line = _incomingBuffer.substring(0, splitIndex).trim();
      _incomingBuffer = _incomingBuffer.substring(splitIndex + 1);

      if (line.isEmpty) continue;

      try {
        final json = jsonDecode(line);
        if (json is Map<String, dynamic>) {
          _handleIncomingEvent(json);
        } else if (json is Map) {
          _handleIncomingEvent(Map<String, dynamic>.from(json));
        }
      } catch (error) {
        statusMessage.value = "북스토퍼 데이터 파싱에 실패했습니다.";
        print("❌ [북스토퍼] JSON 파싱 실패: $error / raw=$line");
      }
    }
  }

  Future<void> _handleIncomingEvent(Map<String, dynamic> json) async {
    final type = json["type"]?.toString() ?? "";
    final bookId = _readInt(json["id"]);
    final page = _readInt(json["page"]);

    lastEventType.value = type;
    lastEventJson.value = json;
    statusMessage.value = "북스토퍼 이벤트: $type";

    final readingController = Get.find<ReadingRegistrationController>();

    switch (type) {
      case "SELECT_BOOK":
        await readingController.syncHardwareSelectedBook(bookId, page: page);
        break;
      case "START":
        await readingController.handleHardwareStart(bookId, page);
        break;
      case "TURN_PAGE":
      case "EDIT_PAGE":
        await readingController.handleHardwarePageUpdate(bookId, page);
        break;
      case "SHORTCUT":
        readingController.handleHardwareShortcut(bookId, page);
        break;
      case "END":
        await readingController.handleHardwareEnd(bookId, page);
        break;
      default:
        print("ℹ️ [북스토퍼] 처리하지 않는 이벤트: $json");
        break;
    }
  }

  Future<void> _sendJson(Map<String, dynamic> json) async {
    final characteristic = _rxCharacteristic;
    if (characteristic == null) {
      throw StateError("북스토퍼 쓰기 채널이 준비되지 않았습니다.");
    }

    final payload = "${jsonEncode(json)}\n";
    if (utf8.encode(payload).length > _maxPayloadLength) {
      throw StateError(
        "북스토퍼 전송 길이(${utf8.encode(payload).length}B)가 MTU 한도($_maxPayloadLength B)를 넘었습니다.",
      );
    }

    await _ble.writeCharacteristicWithResponse(
      characteristic,
      value: utf8.encode(payload),
    );
  }

  Future<void> _requestMtu(String deviceId) async {
    try {
      final mtu = await _ble.requestMtu(deviceId: deviceId, mtu: 185);
      _negotiatedMtu = mtu;
      statusMessage.value = "북스토퍼가 연결되었습니다. (MTU $mtu)";
    } catch (error) {
      _negotiatedMtu = 23;
      statusMessage.value = "북스토퍼가 연결되었습니다. MTU 협상은 건너뛰었어요.";
      print("⚠️ [북스토퍼] MTU 요청 실패: $error");
    }
  }

  Future<bool> _ensurePermissions() async {
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    final result = await permissions.request();
    return result.values.every((status) => status.isGranted || status.isLimited);
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  String _truncateTitle(String title) {
    const maxLength = 24;
    if (title.length <= maxLength) return title;
    return title.substring(0, maxLength);
  }

  int get _maxPayloadLength => (_negotiatedMtu > 3 ? _negotiatedMtu - 3 : 20);

  int _encodedLength(Map<String, dynamic> payload) {
    return utf8.encode("${jsonEncode(payload)}\n").length;
  }

  void _setStage(BookStopperConnectionStage nextStage, String message) {
    stage.value = nextStage;
    statusMessage.value = message;
  }

  void _clearConnection(String message) {
    _notifySubscription?.cancel();
    _notifySubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    connectedDeviceId.value = null;
    connectedDeviceName.value = null;
    _incomingBuffer = "";
    _negotiatedMtu = 23;
    _setStage(BookStopperConnectionStage.disconnected, message);
  }
}
