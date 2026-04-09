Ongidung / Backend

====================

실행 시 (venv)폴더 삭제
python -m venv .venv        # 다시 생성

==================== flutter & python 연동 API 세팅
1. 백엔드 서버 켜기
``` dart
uvicorn main:app --reload
Application startup complete. 시 성공
```

3. 플러터(flutter)에서 요청 보내기
```
flutter pub add http                // http 패키지 설치
```
- dart 파일 상단에 두 줄 추가
```
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 데이터를 다트 언어로 번역해 주는 도구
```

3. dart 파일 안에 버튼 누르는 함수(서버 찌르기)
```
Future<void> fetchItems() async {
  // 1. 내 컴퓨터(localhost)에서 돌고 있는 파이썬 서버 주소로 GET 요청
 final url = Uri.parse('http://127.0.0.1:8000/api/items');
 final response = await http.get(url);

  // 2. 서버가 200(성공)을 외치면 데이터 출력
   if (response.statusCode == 200) {
     // 한글이 안 깨지도록 utf8로 변환해서 출력
     print('서버에서 온 데이터: ${utf8.decode(response.bodyBytes)}'); 
   } else {
     print('에러 상태 코드: ${response.statusCode}');
   }
 }
```
