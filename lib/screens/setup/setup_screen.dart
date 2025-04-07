import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';

import '../../models/user.dart';
import '../../common/constants.dart';

List elements = attributes.sublist(1, 10);

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  SetupState createState() => SetupState();
}

class SetupState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _birthday = TextEditingController();
  int? _attribute;
  bool _isPasswordHidden = true;
  bool _isLoading = false;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        backable: false,
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  '命中天定',
                  style: TextStyle(
                    color: Color(0xBFADA595),
                    fontSize: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xBFADA595),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
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
                                          _isPasswordHidden =
                                              !_isPasswordHidden;
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
                                child: TextFormField(
                                  controller: _name,
                                  decoration: InputDecoration(
                                    border: UnderlineInputBorder(),
                                    hintText: 'less than 20',
                                    labelText: '道号',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Not empty';
                                    }
                                    if (value.length > 20) {
                                      return 'Too long, <= 20';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
                                child: TextField(
                                  controller: _birthday,
                                  decoration: InputDecoration(
                                    border: UnderlineInputBorder(),
                                    labelText: '生辰八字 (不保存)',
                                    hintText: '2025-01-30',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: FilledButton(
                                  onPressed: () {
                                    setState(() {
                                      _attribute = calculateAttribute(
                                        _birthday.text,
                                      );
                                    });
                                  },
                                  child: const Text('生辰测五行灵根'),
                                ),
                              ),
                              Wrap(
                                spacing: 5.0,
                                children:
                                    List<Widget>.generate(5, (int index) {
                                      return ChoiceChip(
                                        backgroundColor: Color(0xBFADA595),
                                        selectedColor: attributeColors[index + 1],
                                        side: BorderSide.none,
                                        label: Text(elements[index]),
                                        selected: _attribute == index,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            _attribute =
                                                selected ? index : null;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 5.0,
                                children:
                                    List<Widget>.generate(4, (int index) {
                                      return ChoiceChip(
                                        backgroundColor: Color(0xBFADA595),
                                        selectedColor: attributeColors[index + 6],
                                        side: BorderSide.none,
                                        label: Text(elements[5 + index]),
                                        selected: _attribute == 5 + index,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            _attribute =
                                                selected ? 5 + index : null;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    attributes[(_attribute ?? -1) + 1],
                                    style: TextStyle(
                                      color:
                                          attributeColors[(_attribute ?? 0) +
                                              1],
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                              ),
                              Text(_error),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        maintainBottomViewPadding: true,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ElevatedButton(
                                  onPressed: () => GoRouter.of(context).pop(),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.home),
                                      Icon(Icons.chevron_left),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _submit(context),
                                  child: Text(_isLoading ? '准备中' : '开始'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final int attr = _attribute ?? -1;
      if (attr < 0 || attr > 8) {
        setState(() {
            _isLoading = false;
            _error = '灵根没有选择！';
        });
      } else {
        if (await context.read<UserModel>().register(
          _email.text,
          _password.text,
          _name.text,
          attr + 1,
        )) {
          if (context.mounted) GoRouter.of(context).go('/play');
        } else {
          setState(() {
            _isLoading = false;
            _error = '邮箱已存在！';
          });
        }
      }
    }
  }
}
