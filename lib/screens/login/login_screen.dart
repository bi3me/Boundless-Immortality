import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../settings/settings.dart';
import '../style/responsive_screen.dart';
import '../../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        backable: false,
        mainAreaProminence: 0.45,
        squarishMainArea: Center(
          child: Transform.rotate(
            angle: -0.1,
            child: const Text(
              '自在修仙！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xBFADA595),
                fontSize: 50,
                height: 1,
              ),
            ),
          ),
        ),
        rectangularMenuArea: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xBFADA595),
                borderRadius: BorderRadius.circular(4),
              ),
              constraints: BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Not empty';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Not email address';
                          }
                          if (value.length > 50) {
                            return 'Too long, <= 50';
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: TextFormField(
                        controller: _password,
                        keyboardType: TextInputType.text,
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Not empty';
                          }
                          if (value.length < 6) {
                            return 'Too smaill, >= 6';
                          }
                          return null;
                        },
                      ),
                    ),
                    _gap,
                    Text(_error, style: TextStyle(color: Colors.red)),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _submit(context),
                              child: Text(_isLoading ? '准备中' : '踏上仙途'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _gap,
            _gap,
            TextButton(
              onPressed: () => GoRouter.of(context).push('/setup'),
              child: const Text('创建新仙籍'),
            ),
            _gap,
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ValueListenableBuilder<bool>(
                valueListenable: settingsController.muted,
                builder: (context, muted, child) {
                  return IconButton(
                    onPressed: () => settingsController.toggleMuted(),
                    icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
                  );
                },
              ),
            ),
            _gap,
            const Text('音乐来自 AI'),
            _gap,
          ],
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 10);

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      if (await context.read<UserModel>().login(_email.text, _password.text)) {
        if (context.mounted) GoRouter.of(context).go('/play');
      } else {
        setState(() {
          _isLoading = false;
          _error = '账号或密码错误！';
        });
      }
    }
  }
}
