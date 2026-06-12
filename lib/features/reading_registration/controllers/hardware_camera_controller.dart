import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../book_note/services/highlight_capture_draft_service.dart';
import '../data/models/reading_library_model.dart';
import 'reading_registration_controller.dart';

enum HardwareCameraConnectionStage {
  disconnected,
  scanning,
  connecting,
  connected,
  downloading,
  error,
}

class HardwareCameraController extends GetxController {
  static final Uuid _serviceUuid = Uuid.parse(
    "7E400001-B5A3-F393-E0A9-E50E24DCCA9E",
  );
  static final Uuid _rxCharacteristicUuid = Uuid.parse(
    "7E400002-B5A3-F393-E0A9-E50E24DCCA9E",
  );
  static final Uuid _txCharacteristicUuid = Uuid.parse(
    "7E400003-B5A3-F393-E0A9-E50E24DCCA9E",
  );

  static const String _preferredDeviceName = "ESP32_HIGHLIGHT_CAMERA";
  static const int _uploadServerPort = 8787;
  static const String _uploadServerPath = "/hardware-camera/upload";

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final stage = HardwareCameraConnectionStage.disconnected.obs;
  final statusMessage = "하이라이트 카메라가 연결되지 않았습니다.".obs;
  final discoveredDevices = <DiscoveredDevice>[].obs;
  final connectedDeviceId = RxnString();
  final connectedDeviceName = RxnString();
  final cameraIp = RxnString();
  final lastEventType = RxnString();
  final lastCaptureId = Rxn<int>();
  final lastEventJson = Rxn<Map<String, dynamic>>();
  final uploadServerUrl = RxnString();
  final uploadServerActive = false.obs;
  final syncedBookId = Rxn<int>();
  final syncedPage = Rxn<int>();

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<HttpRequest>? _uploadServerSubscription;
  Timer? _resubscribeTimer;
  HttpServer? _uploadServer;

  QualifiedCharacteristic? _rxCharacteristic;
  QualifiedCharacteristic? _txCharacteristic;

  String _incomingBuffer = "";
  Future<void>? _activeUpload;
  bool _isRequestingStatus = false;
  int? _reviewSyncBookId;
  int? _reviewSyncPage;
  String? _lastSavedCaptureKey;

  bool get isConnected =>
      stage.value == HardwareCameraConnectionStage.connected;
  bool get isScanning => stage.value == HardwareCameraConnectionStage.scanning;
  bool get isBusy =>
      stage.value == HardwareCameraConnectionStage.connecting ||
      stage.value == HardwareCameraConnectionStage.downloading;

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    _uploadServerSubscription?.cancel();
    _uploadServer?.close(force: true);
    _resubscribeTimer?.cancel();
    super.onClose();
  }

  Future<void> scanForDevices() async {
    if (!await _ensurePermissions()) {
      _setStage(HardwareCameraConnectionStage.error, "블루투스 권한이 필요합니다.");
      return;
    }

    await _scanSubscription?.cancel();
    discoveredDevices.clear();
    _setStage(HardwareCameraConnectionStage.scanning, "하이라이트 카메라를 찾는 중입니다...");

    _scanSubscription = _ble
        .scanForDevices(
          withServices: [_serviceUuid],
          scanMode: ScanMode.lowLatency,
          requireLocationServicesEnabled: false,
        )
        .listen(
          (device) {
            final index = discoveredDevices.indexWhere(
              (d) => d.id == device.id,
            );
            if (index == -1) {
              discoveredDevices.add(device);
            } else {
              discoveredDevices[index] = device;
              discoveredDevices.refresh();
            }

            if (_displayNameFor(device).contains(_preferredDeviceName) &&
                !isConnected) {
              statusMessage.value = "하이라이트 카메라를 찾았습니다. 연결할 수 있어요.";
            }
          },
          onError: (Object error) {
            _setStage(
              HardwareCameraConnectionStage.error,
              "하이라이트 카메라 검색에 실패했습니다: $error",
            );
          },
        );
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (!isConnected) {
      _setStage(
        HardwareCameraConnectionStage.disconnected,
        discoveredDevices.isEmpty
            ? "하이라이트 카메라 검색을 멈췄습니다."
            : "기기를 찾았습니다. 연결할 수 있어요.",
      );
    }
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (!await _ensurePermissions()) {
      _setStage(HardwareCameraConnectionStage.error, "블루투스 권한이 필요합니다.");
      return;
    }

    await _scanSubscription?.cancel();
    await _notifySubscription?.cancel();
    await _connectionSubscription?.cancel();

    connectedDeviceId.value = device.id;
    connectedDeviceName.value = _displayNameFor(device);
    _setStage(
      HardwareCameraConnectionStage.connecting,
      "하이라이트 카메라에 연결하는 중입니다...",
    );

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
                  HardwareCameraConnectionStage.connecting,
                  "하이라이트 카메라에 연결하는 중입니다...",
                );
                break;
              case DeviceConnectionState.connected:
                _setStage(
                  HardwareCameraConnectionStage.connected,
                  "하이라이트 카메라가 연결되었습니다.",
                );
                await _ensureUploadServerForCurrentSession();
                await _requestMtu(device.id);
                await _listenToNotifications();
                await Future<void>.delayed(const Duration(milliseconds: 250));
                await requestStatus();
                await _syncUploadServerConfig();
                break;
              case DeviceConnectionState.disconnecting:
                _setStage(
                  HardwareCameraConnectionStage.connecting,
                  "하이라이트 카메라 연결을 종료하는 중입니다...",
                );
                break;
              case DeviceConnectionState.disconnected:
                _clearConnection("하이라이트 카메라 연결이 해제되었습니다.");
                break;
            }
          },
          onError: (Object error) {
            _clearConnection("하이라이트 카메라 연결에 실패했습니다: $error");
          },
        );
  }

  Future<void> disconnect() async {
    _resubscribeTimer?.cancel();
    await _notifySubscription?.cancel();
    await _connectionSubscription?.cancel();
    _clearConnection("하이라이트 카메라 연결을 종료했습니다.");
  }

  Future<void> startCaptureSession() async {
    _lastSavedCaptureKey = null;
    final url = await _ensureUploadServerStarted();
    if (url == null) return;
    await _syncUploadServerConfig();
  }

  Future<void> stopCaptureSession() async {
    syncedBookId.value = null;
    syncedPage.value = null;
    await _clearUploadServerConfig();
    await _stopUploadServer();
  }

  Future<void> syncCaptureContext({
    required int bookId,
    required int page,
  }) async {
    syncedBookId.value = bookId;
    syncedPage.value = page > 0 ? page : 1;

    if (!isConnected) return;
    try {
      await _sendJson({
        'type': 'SET_CAPTURE_CONTEXT',
        'book_id': syncedBookId.value,
        'page': syncedPage.value,
      });
    } catch (error) {
      print("📷 [하이라이트 카메라] capture context sync failed: $error");
    }
  }

  Future<void> requestStatus() async {
    final characteristic = _txCharacteristic;
    if (characteristic == null || !isConnected || _isRequestingStatus) return;

    try {
      _isRequestingStatus = true;
      await _ensureUploadServerForCurrentSession();
      statusMessage.value = "카메라 상태를 확인하는 중입니다...";
      final bytes = await _ble.readCharacteristic(characteristic);
      _handleNotificationChunk(bytes);
      await _syncUploadServerConfig();
    } catch (error) {
      print("📷 [하이라이트 카메라] requestStatus error: $error");
      final message = error.toString();
      if (_isDisconnectLikeError(message)) {
        _clearConnection("하이라이트 카메라 연결이 해제되었습니다.");
      } else {
        _setStage(
          HardwareCameraConnectionStage.error,
          "카메라 상태를 불러오지 못했습니다: $error",
        );
      }
    } finally {
      _isRequestingStatus = false;
    }
  }

  Future<void> syncPendingCaptureForReview({
    required int bookId,
    required int page,
  }) async {
    _reviewSyncBookId = bookId;
    _reviewSyncPage = page > 0 ? page : 1;

    try {
      final activeUpload = _activeUpload;
      if (activeUpload != null) {
        await activeUpload.timeout(
          const Duration(seconds: 6),
          onTimeout: () => Future<void>.value(),
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        final delayedUpload = _activeUpload;
        if (delayedUpload != null) {
          await delayedUpload.timeout(
            const Duration(seconds: 6),
            onTimeout: () => Future<void>.value(),
          );
        }
      }
    } finally {
      _reviewSyncBookId = null;
      _reviewSyncPage = null;
    }
  }

  Future<void> _listenToNotifications() async {
    final characteristic = _txCharacteristic;
    if (characteristic == null) return;

    await _notifySubscription?.cancel();
    _incomingBuffer = "";

    _notifySubscription = _ble
        .subscribeToCharacteristic(characteristic)
        .listen(
          _handleNotificationChunk,
          onError: (Object error) {
            print("📷 [하이라이트 카메라] notify error: $error");
            final message = error.toString();
            if (_isDisconnectLikeError(message)) {
              _clearConnection("하이라이트 카메라 연결이 해제되었습니다.");
              return;
            }

            statusMessage.value = "카메라 연결을 다시 확인하는 중입니다...";
            _scheduleNotifyResubscribe();
          },
        );
  }

  void _scheduleNotifyResubscribe() {
    _resubscribeTimer?.cancel();
    _resubscribeTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!isConnected || _txCharacteristic == null) return;

      try {
        await _listenToNotifications();
        statusMessage.value = "하이라이트 카메라가 연결되었습니다.";
      } catch (error) {
        print("📷 [하이라이트 카메라] resubscribe failed: $error");
      }
    });
  }

  void _handleNotificationChunk(List<int> chunk) {
    final text = utf8.decode(chunk, allowMalformed: true);
    if (text.isEmpty) return;

    _incomingBuffer += text;
    while (true) {
      final newlineIndex = _incomingBuffer.indexOf('\n');
      if (newlineIndex < 0) break;

      final rawLine = _incomingBuffer.substring(0, newlineIndex).trim();
      _incomingBuffer = _incomingBuffer.substring(newlineIndex + 1);
      if (rawLine.isEmpty) continue;

      try {
        final payload = jsonDecode(rawLine);
        if (payload is! Map<String, dynamic>) continue;
        _handleEvent(payload);
      } catch (_) {
        statusMessage.value = "카메라 메타데이터를 해석하지 못했습니다.";
      }
    }
  }

  void _handleEvent(Map<String, dynamic> payload) {
    final type = payload['type']?.toString() ?? 'UNKNOWN';
    lastEventType.value = type;
    lastEventJson.value = payload;

    if (payload['ip']?.toString().isNotEmpty == true) {
      cameraIp.value = payload['ip'].toString();
    }

    if (payload['id'] is num) {
      lastCaptureId.value = (payload['id'] as num).toInt();
    }

    switch (type) {
      case 'STATUS':
        _handleStatusPayload(payload);
        break;
      case 'CAPTURE_UPLOADED':
        if (payload['id'] is num) {
          lastCaptureId.value = (payload['id'] as num).toInt();
        }
        statusMessage.value = "촬영본 업로드가 완료되었습니다.";
        break;
      case 'CAPTURE_ERROR':
        _setStage(
          HardwareCameraConnectionStage.error,
          "촬영에 실패했습니다: ${payload['reason'] ?? '알 수 없는 오류'}",
        );
        break;
      default:
        statusMessage.value = "최근 카메라 이벤트: $type";
        break;
    }
  }

  void _handleStatusPayload(Map<String, dynamic> payload) {
    final wifi = payload['wifi']?.toString() ?? 'unknown';
    final ready = payload['ready'] == 1;
    final uploadReady = payload['upload_url_set'] == 1;
    final error = payload['error']?.toString();

    if (error != null && error.isNotEmpty) {
      statusMessage.value = "카메라 상태: $wifi ($error)";
    } else if (ready) {
      statusMessage.value = uploadReady
          ? "카메라 준비 완료 (촬영 즉시 업로드 가능)"
          : "카메라 준비 완료 (${wifi == 'connected' ? 'Wi‑Fi 연결됨' : wifi})";
    } else {
      statusMessage.value = "카메라 상태: $wifi";
    }
  }

  Future<String?> _ensureUploadServerStarted() async {
    if (_uploadServer != null && uploadServerUrl.value != null) {
      uploadServerActive.value = true;
      return uploadServerUrl.value;
    }

    final address = await _resolveUploadAddress();
    if (address == null) {
      _setStage(
        HardwareCameraConnectionStage.error,
        "업로드 서버를 열 Wi‑Fi 주소를 찾지 못했습니다.",
      );
      return null;
    }

    try {
      final server = await HttpServer.bind(
        address,
        _uploadServerPort,
        shared: true,
      );
      _uploadServer = server;
      uploadServerUrl.value =
          'http://${address.address}:$_uploadServerPort$_uploadServerPath';
      uploadServerActive.value = true;
      _uploadServerSubscription = server.listen(
        (request) {
          unawaited(_handleUploadRequest(request));
        },
        onError: (Object error) {
          print("📷 [하이라이트 카메라] upload server error: $error");
        },
      );
      final verified = await _verifyUploadServer(address);
      if (!verified) {
        await _stopUploadServer();
        _setStage(
          HardwareCameraConnectionStage.error,
          "업로드 서버를 열었지만 외부에서 접근할 수 없습니다.",
        );
        return null;
      }
      statusMessage.value = "업로드 서버 준비 완료 (${address.address})";
      return uploadServerUrl.value;
    } catch (error) {
      _setStage(
        HardwareCameraConnectionStage.error,
        "업로드 서버를 시작하지 못했습니다: $error",
      );
      return null;
    }
  }

  Future<void> _stopUploadServer() async {
    await _uploadServerSubscription?.cancel();
    _uploadServerSubscription = null;
    await _uploadServer?.close(force: true);
    _uploadServer = null;
    uploadServerActive.value = false;
    uploadServerUrl.value = null;
  }

  Future<void> _handleUploadRequest(HttpRequest request) async {
    if (request.method == 'GET' &&
        request.uri.path == '/hardware-camera/ping') {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true}));
      await request.response.close();
      return;
    }

    if (request.method != 'POST' || request.uri.path != _uploadServerPath) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    if (_activeUpload != null) {
      request.response.statusCode = HttpStatus.tooManyRequests;
      request.response.write('upload_busy');
      await request.response.close();
      return;
    }

    final uploadFuture = _receiveCaptureUpload(request);
    _activeUpload = uploadFuture;
    try {
      await uploadFuture;
    } finally {
      if (identical(_activeUpload, uploadFuture)) {
        _activeUpload = null;
      }
    }
  }

  Future<void> _receiveCaptureUpload(HttpRequest request) async {
    final captureId = int.tryParse(request.headers.value('x-capture-id') ?? '');
    final deviceId = request.headers.value('x-device-id') ?? '';
    final captureKey = captureId != null ? '$deviceId:$captureId' : null;
    final headerBookId = int.tryParse(request.headers.value('x-book-id') ?? '');
    final headerPage = int.tryParse(request.headers.value('x-page') ?? '');

    if (captureKey != null && captureKey == _lastSavedCaptureKey) {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true, 'duplicate': true}));
      await request.response.close();
      return;
    }

    final readingController = Get.find<ReadingRegistrationController>();
    final session = readingController.currentSession.value;
    final targetBookId =
        headerBookId ??
        syncedBookId.value ??
        session?.bookId ??
        _reviewSyncBookId;
    if (targetBookId == null) {
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('reading_session_required');
      await request.response.close();
      statusMessage.value = "독서 중일 때만 하이라이트 카메라를 사용할 수 있어요.";
      return;
    }

    final targetBook = _resolveTargetBook(readingController, targetBookId);
    if (targetBook == null) {
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('book_not_found');
      await request.response.close();
      _setStage(
        HardwareCameraConnectionStage.error,
        "현재 독서 중인 도서 정보를 찾지 못했습니다.",
      );
      return;
    }

    final page =
        headerPage ??
        syncedPage.value ??
        _reviewSyncPage ??
        _resolveCurrentPage(readingController, targetBook);
    _setStage(
      HardwareCameraConnectionStage.downloading,
      "${page}페이지 촬영본을 저장하는 중입니다...",
    );

    try {
      final builder = await request.fold<BytesBuilder>(
        BytesBuilder(copy: false),
        (buffer, data) {
          buffer.add(data);
          return buffer;
        },
      );
      final Uint8List bytes = builder.takeBytes();
      if (bytes.isEmpty) {
        throw const HttpException('empty_upload_body');
      }

      await HighlightCaptureDraftService.instance.saveCaptureBytes(
        bookId: targetBook.book.id,
        bookTitle: targetBook.book.title,
        page: page,
        bytes: bytes,
        fileExtension: 'jpg',
      );

      if (captureKey != null) {
        _lastSavedCaptureKey = captureKey;
      }
      if (captureId != null) {
        lastCaptureId.value = captureId;
      }
      lastEventType.value = 'CAPTURE_UPLOADED';
      lastEventJson.value = {
        'type': 'CAPTURE_UPLOADED',
        'id': captureId,
        'bytes': bytes.length,
      };

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'ok': true,
          'capture_id': captureId,
          'bytes': bytes.length,
        }),
      );
      await request.response.close();

      _setStage(
        HardwareCameraConnectionStage.connected,
        "${page}페이지 촬영본을 저장해 두었습니다.",
      );
      Get.snackbar(
        "저장 완료",
        "${page}페이지 촬영본을 저장해 두었습니다.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (error) {
      print("📷 [하이라이트 카메라] upload receive error: $error");
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('save_failed');
      await request.response.close();
      _setStage(HardwareCameraConnectionStage.error, "촬영본 저장에 실패했습니다: $error");
    }
  }

  Future<void> _syncUploadServerConfig() async {
    if (!isConnected) return;

    final url = uploadServerUrl.value;
    if (url == null || url.isEmpty) {
      return;
    }

    try {
      await _sendJson({'type': 'SET_UPLOAD_URL', 'url': url});
      if (syncedBookId.value != null && syncedPage.value != null) {
        await _sendJson({
          'type': 'SET_CAPTURE_CONTEXT',
          'book_id': syncedBookId.value,
          'page': syncedPage.value,
        });
      }
      statusMessage.value = "하이라이트 카메라 업로드 주소를 동기화했습니다.";
    } catch (error) {
      print("📷 [하이라이트 카메라] upload config sync failed: $error");
    }
  }

  Future<void> _clearUploadServerConfig() async {
    if (!isConnected) return;

    try {
      await _sendJson({'type': 'CLEAR_UPLOAD_URL'});
    } catch (error) {
      print("📷 [하이라이트 카메라] clear upload config failed: $error");
    }
  }

  Future<InternetAddress?> _resolveUploadAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (_isPrivateIpv4(address.address)) {
          return address;
        }
      }
    }

    for (final interface in interfaces) {
      if (interface.addresses.isNotEmpty) {
        return interface.addresses.first;
      }
    }

    return null;
  }

  Future<void> _ensureUploadServerForCurrentSession() async {
    final readingController = Get.find<ReadingRegistrationController>();
    if (readingController.currentSession.value == null) return;
    if (_uploadServer != null && uploadServerUrl.value != null) return;
    await _ensureUploadServerStarted();
  }

  Future<bool> _verifyUploadServer(InternetAddress address) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(
        Uri.parse('http://${address.address}:$_uploadServerPort/hardware-camera/ping'),
      );
      request.headers.set(HttpHeaders.connectionHeader, 'close');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      final ok = response.statusCode == HttpStatus.ok && body.contains('"ok":true');
      print(
        "📷 [하이라이트 카메라] upload server verify "
        "status=${response.statusCode} ok=$ok body=$body",
      );
      return ok;
    } catch (error) {
      print("📷 [하이라이트 카메라] upload server verify failed: $error");
      return false;
    } finally {
      client.close(force: true);
    }
  }

  bool _isPrivateIpv4(String address) {
    return address.startsWith('192.168.') ||
        address.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(address);
  }

  ReadingLibraryItem? _resolveTargetBook(
    ReadingRegistrationController controller,
    int bookId,
  ) {
    final activeBook = controller.currentActiveBook.value;
    if (activeBook != null && activeBook.book.id == bookId) {
      return activeBook;
    }
    return controller.getBookItem(bookId) ?? activeBook;
  }

  int _resolveCurrentPage(
    ReadingRegistrationController controller,
    ReadingLibraryItem targetBook,
  ) {
    final activeBook = controller.currentActiveBook.value;
    if (activeBook != null && activeBook.book.id == targetBook.book.id) {
      return activeBook.currentPage > 0 ? activeBook.currentPage : 1;
    }
    return targetBook.currentPage > 0 ? targetBook.currentPage : 1;
  }

  Future<void> _sendJson(Map<String, dynamic> payload) async {
    final characteristic = _rxCharacteristic;
    if (characteristic == null) {
      throw StateError('하이라이트 카메라가 연결되지 않았습니다.');
    }

    final encoded = utf8.encode('${jsonEncode(payload)}\n');
    await _ble.writeCharacteristicWithResponse(characteristic, value: encoded);
  }

  Future<void> _requestMtu(String deviceId) async {
    try {
      await _ble.requestMtu(deviceId: deviceId, mtu: 185);
    } catch (_) {
      // Keep working with the default MTU when negotiation fails.
    }
  }

  Future<bool> _ensurePermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    return bluetoothScan.isGranted &&
        bluetoothConnect.isGranted &&
        (location.isGranted || location.isLimited);
  }

  String _displayNameFor(DiscoveredDevice device) {
    if (device.name.isNotEmpty) return device.name;
    return "이름 없는 카메라";
  }

  bool _isDisconnectLikeError(String message) {
    return message.contains('BleDisconnectedException') ||
        message.contains('GATT_CONN_TERMINATE_LOCAL_HOST') ||
        message.contains('GATT_CONN_TIMEOUT') ||
        message.contains('status 8') ||
        message.contains('status 22') ||
        message.toLowerCase().contains('disconnected');
  }

  void _clearConnection(String message) {
    stage.value = HardwareCameraConnectionStage.disconnected;
    statusMessage.value = message;
    connectedDeviceId.value = null;
    connectedDeviceName.value = null;
    cameraIp.value = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _incomingBuffer = "";
    _activeUpload = null;
    _resubscribeTimer?.cancel();
  }

  void _setStage(HardwareCameraConnectionStage nextStage, String message) {
    stage.value = nextStage;
    statusMessage.value = message;
  }
}
