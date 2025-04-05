import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';

import '../../models/user.dart';
import '../../common/constants.dart';

List elements = attributes.sublist(1, 10);

class SetupScreen extends StatefulWidget {
  final String email;
  final String password;
  const SetupScreen({required this.email, required this.password, super.key});

  @override
  SetupState createState() => SetupState();
}

class SetupState extends State<SetupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _birthday = TextEditingController();
  int? _attribute;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: ResponsiveScreen(
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '命中天定',
                  style: TextStyle(
                    fontFamily: 'Permanent Marker',
                    fontSize: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'less than 20',
                        labelText: '道号',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 20,
                    ),
                    child: TextField(
                      controller: _birthday,
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: '生辰八字',
                        hintText: '2025-01-30',
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _attribute = 1; // TODO
                      });
                    },
                    child: const Text('阴阳五行测灵根'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        attributes[(_attribute ?? 0) + 1],
                        style: TextStyle(
                          color: attributeColors[(_attribute??0) +1],
                          fontSize: 40,
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 5.0,
                    children:
                        List<Widget>.generate(5, (int index) {
                          return ChoiceChip(
                            label: Text(elements[index]),
                            selected: _attribute == index,
                            onSelected: (bool selected) {
                              setState(() {
                                _attribute = selected ? index : null;
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
                            label: Text(elements[5 + index]),
                            selected: _attribute == 5 + index,
                            onSelected: (bool selected) {
                              setState(() {
                                _attribute = selected ? 5 + index : null;
                              });
                            },
                          );
                        }).toList(),
                  ),
                  Container(
                    // height: 100,
                    padding: EdgeInsets.all(10),
                    child: Text(''),
                  ),
                ],
              ),
            ),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () => _submit(context),
          child: Text(_isLoading ? '准备中' : '开始'),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final int attr = _attribute ?? -1;
    if (_name.text.length > 1 &&
        _name.text.length < 20 &&
        attr >= 0 &&
        attr < 9) {
      if (await context.read<UserModel>().register(
        widget.email,
        widget.password,
        _name.text,
        attr + 1,
      )) {
        if (context.mounted) GoRouter.of(context).go('/play');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
}
