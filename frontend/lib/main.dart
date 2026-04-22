import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ongidung',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 처음 화면에 띄울 글씨
  String serverData = "버튼을 눌러서 공동구매 데이터를 불러오세요!";

  // 백엔드를 찔러서 데이터를 가져오는 마법의 함수
  Future<void> fetchItems() async {
    try {
      // 내 컴퓨터에서 돌고 있는 파이썬 백엔드 주소로 GET 요청!
      final url = Uri.parse('http://127.0.0.1:8000/api/alerts');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 성공하면 화면(State)을 새로고침해서 데이터 띄우기
        setState(() {
          serverData = utf8.decode(response.bodyBytes); // 한글 안 깨지게 변환
        });
      } else {
        setState(() {
          serverData = "에러 발생 ㅠㅠ 상태 코드: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        serverData = "서버가 꺼져있거나 연결 실패!: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('1인 가구 공동구매 테스트'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                '👇 백엔드(DB)에서 온 데이터 👇',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                serverData,
                style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      // 오른쪽 아래 동그란 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: fetchItems, // 버튼을 누르면 서버를 찌름!
        tooltip: '데이터 가져오기',
        child: const Icon(Icons.download),
      ),
    );
  }
}
