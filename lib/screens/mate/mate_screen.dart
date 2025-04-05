import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';

class PlayMateScreen extends StatefulWidget {
  const PlayMateScreen({super.key});

  @override
  PlayMateState createState() => PlayMateState();
}

class PlayMateState extends State<PlayMateScreen> {
  @override
  Widget build(BuildContext context) {
    List<String> otherSkills = ["张三", "李四", "王二毛"];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              otherSkills.map((skill) {
                return ListTile(
                  title: Text(skill),
                  subtitle: Text('战力 10000, 攻击 1000, 防御 10000, 闪避 10000, 暴击 1000'),
                  trailing: ElevatedButton(onPressed: () {}, child: Text("挑战")),
                );
              }).toList(),
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            GoRouter.of(context).go('/play');
          },
          child: const Text('Action'),
        ),
      ),
    );
  }
}
