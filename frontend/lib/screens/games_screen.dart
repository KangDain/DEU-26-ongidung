import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _totalPoints = 0;
  List<Map<String, dynamic>> _missions = [];
  bool _loadingMissions = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    final userId = AppState.instance.currentUserId;
    if (userId == null) {
      setState(() => _loadingMissions = false);
      return;
    }
    final result = await ApiService.getMissions(userId);
    if (!mounted) return;
    setState(() {
      _loadingMissions = false;
      if (result.data != null) {
        _missions = result.data!;
        _totalPoints = _missions
            .where((m) => m['is_completed'] == true)
            .fold(0, (sum, m) => sum + (m['points'] as int? ?? 0));
      }
    });
  }

  Future<void> _completeMission(Map<String, dynamic> mission) async {
    final missionId = mission['mission_id'] as int?;
    final userId = AppState.instance.currentUserId;
    if (missionId == null || userId == null) return;

    final result = await ApiService.completeMission(userId, missionId);
    if (!mounted) return;
    if (result.data != null) {
      setState(() {
        mission['is_completed'] = true;
        _totalPoints += mission['points'] as int? ?? 0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? '미션 완료 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('건강 게임'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.yellow),
                const SizedBox(width: 4),
                Text('$_totalPoints pts',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _pointsCard(),
          const SizedBox(height: 16),
          const Text('오늘의 미션',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loadingMissions)
            const Center(child: CircularProgressIndicator())
          else if (_missions.isEmpty)
            const Text('등록된 미션이 없습니다.',
                style: TextStyle(color: Colors.grey))
          else
            ..._missions.map((m) => _missionCard(m)),
          const SizedBox(height: 20),
          const Text('미니게임',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _gameCard(
            '뇌 활성화 퀴즈',
            '건강 상식 퀴즈로 뇌를 자극해보세요!',
            Icons.psychology,
            Colors.indigo,
            '최대 40 pts',
            () async {
              final pts = await Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (_) => const HealthQuizGame()),
              );
              if (!mounted) return;
              if (pts != null && pts > 0) {
                setState(() => _totalPoints += pts);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('+$pts 포인트 획득!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          _gameCard(
            '안전 교육 퀴즈',
            '안전한 생활을 위한 퀴즈',
            Icons.security,
            Colors.red,
            '최대 30 pts',
            () async {
              final pts = await Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (_) => const SafetyQuizGame()),
              );
              if (!mounted) return;
              if (pts != null && pts > 0) {
                setState(() => _totalPoints += pts);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('+$pts 포인트 획득!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          _gameCard(
            '기억력 카드 게임',
            '카드를 뒤집어 짝을 맞춰보세요',
            Icons.grid_view,
            Colors.purple,
            '최대 40 pts',
            () async {
              final pts = await Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (_) => const MemoryCardGame()),
              );
              if (!mounted) return;
              if (pts != null && pts > 0) {
                setState(() => _totalPoints += pts);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('+$pts 포인트 획득!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          const Text('보상 스토어',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _rewardCard('건강 쿠폰 (50% 할인)', 200),
          _rewardCard('가족 영상통화 배경화면', 100),
          _rewardCard('건강 응원 배지', 50),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _pointsCard() {
    final completed = _missions.where((m) => m['is_completed'] == true).length;
    final total = _missions.length;
    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('내 건강 포인트',
                    style: TextStyle(color: Colors.grey)),
                Text('$_totalPoints 포인트',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple)),
                if (total > 0)
                  Text('미션 $completed/$total 완료',
                      style:
                          const TextStyle(color: Colors.green, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _missionCard(Map<String, dynamic> mission) {
    final done = mission['is_completed'] == true;
    final pts = mission['points'] as int? ?? 0;
    final type = mission['mission_type'] as String? ?? 'health';
    final color = type == 'safety'
        ? Colors.red
        : type == 'activity'
            ? Colors.green
            : Colors.teal;
    final icon = type == 'safety'
        ? Icons.security
        : type == 'activity'
            ? Icons.directions_walk
            : Icons.medication;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(mission['title'] as String? ?? '미션',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? Colors.grey : null)),
        subtitle: Text('${_missionTypeLabel(type)} · $pts pts',
            style: const TextStyle(fontSize: 12)),
        trailing: done
            ? Chip(
                label: Text('+$pts pts'),
                backgroundColor: Colors.green.shade100,
                labelStyle:
                    const TextStyle(color: Colors.green, fontSize: 12))
            : OutlinedButton(
                onPressed: () => _completeMission(mission),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: Text('+$pts pts'),
              ),
      ),
    );
  }

  String _missionTypeLabel(String type) {
    switch (type) {
      case 'safety':
        return '안전';
      case 'activity':
        return '활동';
      default:
        return '건강';
    }
  }

  Widget _gameCard(String title, String desc, IconData icon, Color color,
      String reward, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(desc,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Chip(
                        label: Text(reward),
                        backgroundColor: Colors.amber.shade50,
                        labelStyle: const TextStyle(
                            fontSize: 12, color: Colors.amber)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle, color: Colors.grey, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardCard(String title, int cost) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.card_giftcard, color: Colors.amber),
        title: Text(title),
        trailing: ElevatedButton(
          onPressed: _totalPoints >= cost
              ? () => setState(() => _totalPoints -= cost)
              : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Text('$cost pts'),
        ),
      ),
    );
  }
}

// ─── 건강 퀴즈 게임 ────────────────────────────────────────────────────────────

class HealthQuizGame extends StatefulWidget {
  const HealthQuizGame({super.key});

  @override
  State<HealthQuizGame> createState() => _HealthQuizGameState();
}

class _HealthQuizGameState extends State<HealthQuizGame> {
  int _current = 0;
  int _score = 0;
  String? _selected;

  final List<Map<String, dynamic>> _questions = [
    {
      'q': '하루 권장 물 섭취량은?',
      'opts': ['500ml', '1L', '1.5~2L', '3L 이상'],
      'ans': '1.5~2L'
    },
    {
      'q': '정상 혈압 범위는?',
      'opts': ['90/60 미만', '120/80 미만', '140/90 미만', '160/100 미만'],
      'ans': '120/80 미만'
    },
    {
      'q': '규칙적인 운동의 권장 횟수는?',
      'opts': ['주 1회', '주 2회', '주 3~5회', '매일 2시간'],
      'ans': '주 3~5회'
    },
    {
      'q': '낙상 예방에 가장 좋은 운동은?',
      'opts': ['수영', '균형 훈련', '달리기', '웨이트'],
      'ans': '균형 훈련'
    },
  ];

  int get _earnedPoints => _score * 10;

  @override
  Widget build(BuildContext context) {
    if (_current >= _questions.length) return _resultScreen();
    final q = _questions[_current];
    return Scaffold(
      appBar: AppBar(
          title: Text('건강 퀴즈 (${_current + 1}/${_questions.length})'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            LinearProgressIndicator(
                value: _current / _questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.indigo)),
            const SizedBox(height: 32),
            Text(q['q'],
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ...(q['opts'] as List<String>).map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selected != null
                          ? null
                          : () {
                              setState(() {
                                _selected = opt;
                                if (opt == q['ans']) _score++;
                              });
                              Future.delayed(
                                  const Duration(milliseconds: 800), () {
                                setState(() {
                                  _current++;
                                  _selected = null;
                                });
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == null
                            ? Colors.white
                            : opt == q['ans']
                                ? Colors.green
                                : opt == _selected
                                    ? Colors.red
                                    : Colors.white,
                        foregroundColor: _selected != null &&
                                (opt == q['ans'] || opt == _selected)
                            ? Colors.white
                            : Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          Text(opt, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _resultScreen() {
    return Scaffold(
      appBar: AppBar(
          title: const Text('결과'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_score >= 3 ? Icons.emoji_events : Icons.sentiment_satisfied,
                size: 80, color: _score >= 3 ? Colors.amber : Colors.blue),
            const SizedBox(height: 16),
            Text('$_score / ${_questions.length}',
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.bold)),
            Text(_score >= 3 ? '훌륭해요! 건강 박사!' : '잘 하셨어요!',
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            Chip(
                label: Text('+$_earnedPoints 포인트 획득!'),
                backgroundColor: Colors.amber.shade100),
            const SizedBox(height: 32),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, _earnedPoints),
                child: const Text('완료 (포인트 저장)')),
            TextButton(
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('취소')),
          ],
        ),
      ),
    );
  }
}

// ─── 안전 교육 퀴즈 ───────────────────────────────────────────────────────────

class SafetyQuizGame extends StatefulWidget {
  const SafetyQuizGame({super.key});

  @override
  State<SafetyQuizGame> createState() => _SafetyQuizGameState();
}

class _SafetyQuizGameState extends State<SafetyQuizGame> {
  int _current = 0;
  int _score = 0;
  String? _selected;

  final List<Map<String, dynamic>> _questions = [
    {
      'q': '낙상 예방을 위해 가정에서 해야 할 일은?',
      'opts': ['두꺼운 카펫 설치', '미끄럼 방지 매트 사용', '높은 가구 배치', '조명 줄이기'],
      'ans': '미끄럼 방지 매트 사용'
    },
    {
      'q': '화재 시 올바른 대피 방법은?',
      'opts': ['엘리베이터 이용', '창문으로 탈출', '계단 이용', '연기가 없으면 방에서 대기'],
      'ans': '계단 이용'
    },
    {
      'q': '응급 상황 시 먼저 해야 할 일은?',
      'opts': ['인터넷 검색', '119 신고', '이웃에게 알리기', '환자 이동'],
      'ans': '119 신고'
    },
    {
      'q': '약을 복용할 때 주의사항은?',
      'opts': [
        '다른 사람의 약도 같이 복용',
        '처방된 용량만 복용',
        '증상이 나으면 바로 중단',
        '음식과 무관하게 복용'
      ],
      'ans': '처방된 용량만 복용'
    },
    {
      'q': '연기가 발생한 방에서 이동할 때 올바른 자세는?',
      'opts': ['서서 이동', '뛰어서 이동', '낮게 엎드려 이동', '제자리에서 대기'],
      'ans': '낮게 엎드려 이동'
    },
    {
      'q': 'SOS 버튼을 누르면 자동으로 연락되는 곳은?',
      'opts': ['병원', '경찰서', '보호자', '모두 맞음'],
      'ans': '보호자'
    },
  ];

  int get _earnedPoints => _score * 5;

  @override
  Widget build(BuildContext context) {
    if (_current >= _questions.length) return _resultScreen();
    final q = _questions[_current];
    return Scaffold(
      appBar: AppBar(
          title: Text('안전 교육 퀴즈 (${_current + 1}/${_questions.length})'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            LinearProgressIndicator(
                value: _current / _questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.red)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q['q'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...(q['opts'] as List<String>).map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selected != null
                          ? null
                          : () {
                              setState(() {
                                _selected = opt;
                                if (opt == q['ans']) _score++;
                              });
                              Future.delayed(
                                  const Duration(milliseconds: 800), () {
                                setState(() {
                                  _current++;
                                  _selected = null;
                                });
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == null
                            ? Colors.white
                            : opt == q['ans']
                                ? Colors.green
                                : opt == _selected
                                    ? Colors.red
                                    : Colors.white,
                        foregroundColor: _selected != null &&
                                (opt == q['ans'] || opt == _selected)
                            ? Colors.white
                            : Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child:
                          Text(opt, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _resultScreen() {
    return Scaffold(
      appBar: AppBar(
          title: const Text('결과'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                _score >= 4 ? Icons.emoji_events : Icons.shield,
                size: 80,
                color: _score >= 4 ? Colors.amber : Colors.red),
            const SizedBox(height: 16),
            Text('$_score / ${_questions.length}',
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.bold)),
            Text(_score >= 4 ? '안전 전문가!' : '더 공부해봐요!',
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            Chip(
                label: Text('+$_earnedPoints 포인트 획득!'),
                backgroundColor: Colors.red.shade100),
            const SizedBox(height: 32),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, _earnedPoints),
                child: const Text('완료 (포인트 저장)')),
            TextButton(
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('취소')),
          ],
        ),
      ),
    );
  }
}

// ─── 기억력 카드 게임 ──────────────────────────────────────────────────────────

class MemoryCardGame extends StatefulWidget {
  const MemoryCardGame({super.key});

  @override
  State<MemoryCardGame> createState() => _MemoryCardGameState();
}

class _MemoryCardGameState extends State<MemoryCardGame> {
  static const _icons = [
    Icons.favorite,
    Icons.star,
    Icons.bolt,
    Icons.eco,
    Icons.music_note,
    Icons.pets
  ];
  late List<int> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  int? _firstFlipped;
  bool _canFlip = true;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _cards = [...List.generate(6, (i) => i), ...List.generate(6, (i) => i)]
      ..shuffle(Random());
    _flipped = List.filled(12, false);
    _matched = List.filled(12, false);
    _firstFlipped = null;
    _moves = 0;
    _canFlip = true;
  }

  void _flip(int i) {
    if (!_canFlip || _flipped[i] || _matched[i]) return;
    setState(() => _flipped[i] = true);
    if (_firstFlipped == null) {
      _firstFlipped = i;
    } else {
      _moves++;
      _canFlip = false;
      if (_cards[_firstFlipped!] == _cards[i]) {
        setState(() {
          _matched[_firstFlipped!] = true;
          _matched[i] = true;
          _firstFlipped = null;
          _canFlip = true;
        });
      } else {
        final first = _firstFlipped!;
        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() {
            _flipped[first] = false;
            _flipped[i] = false;
            _firstFlipped = null;
            _canFlip = true;
          });
        });
      }
    }
  }

  bool get _isWon => _matched.every((m) => m);

  int get _earnedPoints {
    if (_moves <= 8) return 40;
    if (_moves <= 12) return 30;
    if (_moves <= 18) return 20;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('기억력 게임 | 시도: $_moves'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(_initGame)),
        ],
      ),
      body: _isWon
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text('완성!',
                      style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('$_moves번 만에 완성했어요!',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text('+$_earnedPoints pts'),
                    backgroundColor: Colors.amber.shade100,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.emoji_events),
                    label: Text('완료 (+$_earnedPoints pts)'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(context, _earnedPoints),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: () => setState(_initGame),
                      child: const Text('다시 하기')),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10),
              itemCount: 12,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _flip(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _matched[i]
                        ? Colors.green.shade100
                        : _flipped[i]
                            ? Colors.purple.shade100
                            : Colors.purple.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Center(
                    child: _flipped[i] || _matched[i]
                        ? Icon(_icons[_cards[i]],
                            color:
                                _matched[i] ? Colors.green : Colors.purple,
                            size: 32)
                        : const Icon(Icons.help_outline,
                            color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
    );
  }
}
