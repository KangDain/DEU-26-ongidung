import 'package:flutter/material.dart';
import '../models/user_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0;
  UserType _selectedType = UserType.elderly;

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
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _submitSignup();
          }
        },
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
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white),
                child: Text(_currentStep == 2 ? '가입 완료' : '다음'),
              ),
              const SizedBox(width: 8),
              TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(_currentStep == 0 ? '취소' : '이전')),
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

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        _field(_nameCtrl, '이름', Icons.person,
            validator: (v) => v!.isEmpty ? '이름을 입력하세요' : null),
        const SizedBox(height: 12),
        _field(_birthCtrl, '생년월일 (예: 1950-03-15)', Icons.cake,
            hint: 'YYYY-MM-DD'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _field(_phoneCtrl, '연락처', Icons.phone)),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => setState(() => _phoneVerified = true),
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
                    Text(t.$2,
                        style: const TextStyle(fontWeight: FontWeight.bold))
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
        _field(_idCtrl, '아이디', Icons.account_circle),
        const SizedBox(height: 12),
        TextField(
          controller: _pwCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '비밀번호',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pw2Ctrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '비밀번호 확인',
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
              const Text('입력 정보 확인',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('이름: ${_nameCtrl.text}'),
              Text('연락처: ${_phoneCtrl.text}'),
              Text(
                  '사용자 유형: ${_selectedType == UserType.elderly ? "독거노인" : _selectedType == UserType.child ? "아동" : _selectedType == UserType.guardian ? "보호자" : "일반"}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {String? hint, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _submitSignup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('회원가입이 완료되었습니다! 로그인해주세요.'),
          backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }
}
