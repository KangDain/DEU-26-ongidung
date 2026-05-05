import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/app_state.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _position;
  String? _errorMsg;
  bool _isSharing = true;
  bool _isLoading = true;
  DateTime? _lastUpdate;
  StreamSubscription<Position>? _positionSub;
  List<Map<String, dynamic>> _history = [];
  Timer? _dbSaveTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadHistory();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _dbSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMsg = '위치 서비스가 비활성화되어 있습니다.\n기기 설정에서 위치를 켜주세요.';
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMsg = '위치 권한이 거부되었습니다.\n설정 > 앱 > 위치 접근 권한을 허용해주세요.';
        _isLoading = false;
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _onPosition(pos);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = '현재 위치를 가져올 수 없습니다.';
          _isLoading = false;
        });
      }
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen(_onPosition, onError: (_) {});
  }

  void _onPosition(Position pos) {
    if (!mounted) return;
    setState(() {
      _position = pos;
      _lastUpdate = DateTime.now();
      _isLoading = false;
      _errorMsg = null;
    });
    if (_isSharing) _saveToDb(pos);
  }

  Future<void> _saveToDb(Position pos) async {
    final userId = AppState.instance.currentUserId;
    if (userId == null) return;
    await ApiService.updateLocation(userId, {
      'latitude': '${pos.latitude}',
      'longitude': '${pos.longitude}',
      'address':
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}', // lat,lng as address placeholder
      'place_name': '현재 위치',
    });
  }

  Future<void> _loadHistory() async {
    final userId = AppState.instance.currentUserId;
    if (userId == null) return;
    final result = await ApiService.getLocationHistory(userId);
    if (!mounted) return;
    if (result.data != null) {
      setState(() => _history = result.data!.take(10).toList());
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isGuardian =
        AppState.instance.currentUser?.userType == UserType.guardian;

    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 확인'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _initLocation();
              _loadHistory();
            },
          ),
        ],
      ),
      body: isGuardian ? _guardianView() : _selfView(),
    );
  }

  // ─── 일반 사용자: 본인 GPS 위치 ──────────────────────────────────────────────

  Widget _selfView() {
    return Column(
      children: [
        Expanded(flex: 3, child: _mapArea()),
        Expanded(flex: 2, child: _infoPanel()),
      ],
    );
  }

  Widget _mapArea() {
    return Container(
      color: Colors.grey.shade200,
      child: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : _errorMsg != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_errorMsg!,
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            _position != null
                                ? '${_position!.latitude.toStringAsFixed(5)},\n${_position!.longitude.toStringAsFixed(5)}'
                                : '위치 로딩 중...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
          ),
          if (_position != null)
            const Center(
              child: Icon(Icons.location_pin, size: 48, color: Colors.red),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle,
                      size: 10,
                      color: _isSharing ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(_isSharing ? '위치 공유 중' : '공유 중지',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPanel() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text('현재 위치',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          _lastUpdate != null
                              ? '${_formatTime(_lastUpdate!)}'
                              : '-',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _position != null
                          ? 'GPS: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                          : (AppState.instance.currentUser?.address.isNotEmpty == true
                              ? AppState.instance.currentUser!.address
                              : '위치 정보 없음'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_position != null)
                      Text(
                          '정확도: ±${_position!.accuracy.toStringAsFixed(0)}m',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isSharing,
              onChanged: (v) => setState(() => _isSharing = v),
              title: const Text('보호자와 위치 공유',
                  style: TextStyle(fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('최근 위치 기록',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              ..._history.take(5).map((loc) {
                final timeStr = loc['created_at']?.toString() ?? '';
                final label = timeStr.length >= 16
                    ? timeStr.substring(11, 16)
                    : '기록';
                final addr = loc['address'] as String? ?? '-';
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on,
                      color: Colors.blue.shade600, size: 20),
                  title: Text(addr,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(label,
                      style: const TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ─── 보호자: 피보호자 위치 목록 ───────────────────────────────────────────────

  Widget _guardianView() {
    final recipients = AppState.instance.guardianUsers;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
              const SizedBox(width: 8),
              const Text(
                '보호 대상자들의 최근 등록 위치를 표시합니다.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: recipients.isEmpty
              ? const Center(
                  child: Text('연결된 보호 대상자가 없습니다.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipients.length,
                  itemBuilder: (_, i) {
                    final u = recipients[i];
                    final name = u['name'] as String? ?? '보호 대상자';
                    final location = u['location'] as String? ?? '-';
                    final status = u['status'] as String? ?? '안전';
                    final hasAlert = u['hasAlert'] == true;
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: hasAlert ? Colors.red.shade50 : null,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: hasAlert
                                      ? Colors.red.shade100
                                      : Colors.blue.shade100,
                                  child: Icon(Icons.person,
                                      color: hasAlert
                                          ? Colors.red
                                          : Colors.blue.shade700),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == '안전'
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(status,
                                      style: TextStyle(
                                          color: status == '안전'
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Colors.blue.shade600, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(location,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '마지막 업데이트: ${u['lastUpdate'] ?? '-'}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
