import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlayWeaponScreen extends StatefulWidget {
  const PlayWeaponScreen({super.key});

  @override
  PlayWeaponState createState() => PlayWeaponState();
}

class PlayWeaponState extends State<PlayWeaponScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      appBar: AppBar(title: const Text('法宝')),
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              title: Text('手拿：天皇宝剑'),
              subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
              trailing: Text('元婴'),
              children: _buildOtherSkills(),
            ),
            ExpansionTile(
              title: Text('头戴：天皇宝盖'),
              subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
              trailing: Text('元婴'),
              children: _buildOtherSkills(),
            ),
            ExpansionTile(
              title: Text('身穿：天皇宝甲'),
              subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
              trailing: Text('元婴'),
              children: _buildOtherSkills(),
            ),
            ExpansionTile(
              title: Text('左臂：天皇手具'),
              subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
              trailing: Text('元婴'),
              children: _buildOtherSkills(),
            ),
            ExpansionTile(
              title: Text('右臂：地皇手具'),
              subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
              trailing: Text('金丹'),
              children: _buildOtherSkills(),
            ),
            ExpansionTile(
              title: Text('左腿：地皇手具'),
              subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
              trailing: Text('金丹'),
              children: _buildOtherSkills(),
            ),
            ExpansionTile(
              title: Text('右腿：地皇手具'),
              subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
              trailing: Text('金丹'),
              children: _buildOtherSkills(),
            ),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            GoRouter.of(context).go('/play');
          },
          child: const Text('生成形象（付费）'),
        ),
      ),
    );
  }

  List<Widget> _buildOtherSkills() {
    List<String> otherSkills = ["玄天剑诀", "九阳真经", "混元功"];

    return otherSkills.map((skill) {
      return ListTile(
        title: Text(skill),
        subtitle: Text('攻击+10, 防御+10, 闪避+10, 暴击+10'),
        trailing: ElevatedButton(onPressed: () {}, child: Text("穿戴"))
      );
    }).toList();
  }
}
