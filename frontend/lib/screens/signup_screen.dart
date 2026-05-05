import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0;
  UserType _selectedType = UserType.elderly;
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _phoneVerified = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onContinue,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading && _currentStep == 2
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_currentStep == 2 ? '가입 완료' : '다음'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: details.onStepCancel,
                child: Text(_currentStep == 0 ? '취소' : '이전'),
              ),
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('기본 정보'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildBasicInfoStep(),
          ),
          Step(
            title: const Text('사용자 유형'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildUserTypeStep(),
          ),
          Step(
            title: const Text('계정 설정'),
            isActive: _currentStep >= 2,
            content: _buildAccountStep(),
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
        _showSnack('이름과 연락처는 필수 입력 항목입니다.');
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      setState(() => _currentStep++);
    } else {
      _submitSignup();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        _field(_nameCtrl, '이름 *', Icons.person),
        const SizedBox(height: 12),
        _field(_birthCtrl, '생년월일 (예: 1990-01-01)', Icons.cake, hint: 'YYYY-MM-DD'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _field(_phoneCtrl, '연락처 *', Icons.phone)),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_phoneCtrl.text.isEmpty) {
                  _showSnack('연락처를 먼저 입력해주세요.');
                  return;
                }
                setState(() => _phoneVerified = true);
                _showSnack('인증이 완료되었습니다.');
              },
              child: Text(_phoneVerified ? '인증완료 ✓' : '인증'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(_addressCtrl, '주소', Icons.location_on),
        const SizedBox(height: 12),
        _field(_guardianPhoneCtrl, '보호자 연락처', Icons.contact_phone),
      ],
    );
  }

  Widget _buildUserTypeStep() {
    final types = [
      (UserType.elderly, '독거노인', Icons.elderly, '혼자 생활하시는 어르신'),
      (UserType.child, '아동', Icons.child_care, '보호가 필요한 아동'),
      (UserType.guardian, '보호자', Icons.supervisor_account, '가족 또는 보호자'),
      (UserType.general, '일반 사용자', Icons.person, '일반 1인 가구'),
    ];
    return Column(
      children: types
          .map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: _selectedType == t.$1 ? Colors.blue.shade50 : null,
                child: RadioListTile<UserType>(
                  value: t.$1,
                  groupValue: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v!),
                  title: Row(children: [
                    Icon(t.$3, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(t.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  subtitle: Text(t.$4),
                  activeColor: Colors.blue.shade600,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAccountStep() {
    return Column(
      children: [
        _field(_idCtrl, '아이디 *', Icons.account_circle),
        const SizedBox(height: 12),
        TextField(
          controller: _pwCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '비밀번호 *',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pw2Ctrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '비밀번호 확인 *',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('입력 정보 확인', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('이름: ${_nameCtrl.text}'),
              Text('연락처: ${_phoneCtrl.text}'),
              Text('사용자 유형: ${_userTypeLabel(_selectedType)}'),
            ],
          ),
        ),
      ],
    );
  }

  String _userTypeLabel(UserType t) {
    switch (t) {
      case UserType.elderly:
        return '독거노인';
      case UserType.child:
        return '아동';
      case UserType.guardian:
        return '보호자';
      case UserType.general:
        return '일반 사용자';
      default:
        return '';
    }
  }

  String _userTypeToString(UserType t) {
    switch (t) {
      case UserType.elderly:
        return 'ELDERLY';
      case UserType.child:
        return 'CHILD';
      case UserType.guardian:
        return 'GUARDIAN';
      default:
        return 'GENERAL';
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {String? hint}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

  Future<void> _submitSignup() async {
    // 필수값 검증
    if (_idCtrl.text.isEmpty) {
      _showSnack('아이디를 입력해주세요.', isError: true);
      return;
    }
    if (_pwCtrl.text.isEmpty) {
      _showSnack('비밀번호를 입력해주세요.', isError: true);
      return;
    }
    if (_pwCtrl.text != _pw2Ctrl.text) {
      _showSnack('비밀번호가 일치하지 않습니다.', isError: true);
      return;
    }
    if (_pwCtrl.text.length < 6) {
      _showSnack('비밀번호는 6자 이상이어야 합니다.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.signup({
      'login_id': _idCtrl.text,
      'user_pw': _pwCtrl.text,
      'user_name': _nameCtrl.text,
      'user_phone': _phoneCtrl.text,
      'user_birth_date': _birthCtrl.text,
      'user_address': _addressCtrl.text,
      'guardian_phone': _guardianPhoneCtrl.text,
      'user_type': _userTypeToString(_selectedType),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입이 완료되었습니다! 로그인해주세요.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      _showSnack(result.error ?? '회원가입 실패', isError: true);
    }
  }
}
