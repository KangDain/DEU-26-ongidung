import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _autoLogin = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isPinMode = false;
  final List<String> _pinDigits = [];

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_idController.text.isEmpty || _pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    AppState.instance.login(_idController.text, _pwController.text);
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _addPin(String digit) {
    if (_pinDigits.length < 6) {
      setState(() => _pinDigits.add(digit));
      if (_pinDigits.length == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          AppState.instance.login('user', 'pin');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
      }
    }
  }

  void _removePin() {
    if (_pinDigits.isNotEmpty) setState(() => _pinDigits.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 16),
              Text(
                'PROTECT',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  letterSpacing: 4,
                ),
              ),
              const Text('안전한 생활 돌봄 서비스', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              if (_isPinMode) _buildPinPad() else _buildLoginForm(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  _isPinMode = !_isPinMode;
                  _pinDigits.clear();
                }),
                child: Text(_isPinMode ? '아이디/비밀번호로 로그인' : 'PIN으로 간편 로그인'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('회원가입'),
                  ),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: _showPasswordRecovery,
                    child: const Text('비밀번호 찾기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _idController,
          decoration: InputDecoration(
            labelText: '아이디',
            prefixIcon: const Icon(Icons.person),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pwController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: '비밀번호',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _autoLogin,
              onChanged: (v) => setState(() => _autoLogin = v ?? false),
            ),
            const Text('자동 로그인'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _socialButton(Icons.message, '카카오 로그인', Colors.yellow.shade700)),
            const SizedBox(width: 8),
            Expanded(child: _socialButton(Icons.g_mobiledata, '구글 로그인', Colors.red.shade400)),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, String label, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        const Text('PIN 번호 입력 (6자리)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pinDigits.length ? Colors.blue.shade600 : Colors.grey.shade300,
              border: Border.all(color: Colors.blue.shade600),
            ),
          )),
        ),
        const SizedBox(height: 32),
        for (var row in [['1','2','3'], ['4','5','6'], ['7','8','9'], ['','0','⌫']])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((d) => GestureDetector(
              onTap: () => d == '⌫' ? _removePin() : d.isNotEmpty ? _addPin(d) : null,
              child: Container(
                width: 80,
                height: 64,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: d.isEmpty ? Colors.transparent : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: d.isEmpty ? [] : [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Center(
                  child: Text(d, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }

  void _showPasswordRecovery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('비밀번호 찾기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: '등록된 휴대폰 번호', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('인증번호가 발송되었습니다.')),
                  );
                },
                child: const Text('인증번호 받기'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
