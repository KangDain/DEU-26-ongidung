import 'package:flutter/material.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isSharing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 추적'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _mapPlaceholder(),
          ),
          Expanded(
            flex: 2,
            child: _locationInfoPanel(),
          ),
        ],
      ),
    );
  }

  Widget _mapPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('지도 영역', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                const SizedBox(height: 4),
                Text('(GPS 추적 활성 중)', style: TextStyle(color: Colors.green.shade600)),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: () {},
                  heroTag: 'zoomin',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () {},
                  heroTag: 'zoomout',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () {},
                  heroTag: 'locate',
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 10, color: _isSharing ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(_isSharing ? '위치 공유 중' : '위치 공유 중지', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.location_pin, size: 48, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _locationInfoPanel() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text('현재 위치', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('업데이트: 방금 전', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('서울특별시 강남구 테헤란로 123', style: TextStyle(fontSize: 15)),
                    const Text('삼성역 2번 출구 근처', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    value: _isSharing,
                    onChanged: (v) => setState(() => _isSharing = v),
                    title: const Text('보호자와 공유', style: TextStyle(fontSize: 14)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('최근 방문 장소', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...[
              ('09:30', '집 (서울 강남구)', Icons.home),
              ('11:00', '마트 (이마트 삼성점)', Icons.shopping_cart),
              ('14:00', '병원 (강남 내과)', Icons.local_hospital),
            ].map((loc) => ListTile(
              dense: true,
              leading: Icon(loc.$3, color: Colors.blue.shade600, size: 20),
              title: Text(loc.$2, style: const TextStyle(fontSize: 13)),
              subtitle: Text(loc.$1, style: const TextStyle(fontSize: 11)),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }
}
