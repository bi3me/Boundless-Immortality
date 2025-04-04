import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';
import '../../models/weapon.dart';
import '../../models/user.dart';
import '../../common/constants.dart';

class PlayWeaponScreen extends StatefulWidget {
  const PlayWeaponScreen({super.key});

  @override
  PlayWeaponState createState() => PlayWeaponState();
}

class PlayWeaponState extends State<PlayWeaponScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final user = context.read<UserModel>();
    final weapon = context.watch<WeaponModel>();

    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        squarishMainArea: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(8, (index) {
              final pos = index + 1;
              final posList = weapon.poses[pos] ?? [0];
              final first = weapon.items[posList[0]];
              final isWorking = first?.working ?? false;
              final firstname = isWorking ? first?.name : '';
              return ExpansionTile(
                title: Text("${weaponPos[pos]}: $firstname"),
                trailing: Text(levels[first?.level ?? 0]),
                children: _buildOtherSkills(posList, weapon, user),
              );
            }),
          ),
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

  List<Widget> _buildOtherSkills(
    List<int> list,
    WeaponModel weapon,
    UserModel user,
  ) {
    return list.map((index) {
      final item = weapon.items[index];
      final id = item?.weaponId ?? 0;
      final pos = item?.pos ?? 0;
      final working = item?.working ?? false;
      final hp = item?.powerHp ?? 0;
      final attack = item?.powerAttack ?? 0;
      final defense = item?.powerDefense ?? 0;
      final hit = item?.powerHit ?? 0;
      final dodge = item?.powerDodge ?? 0;

      return ListTile(
        title: Text(item?.name ?? ''),
        subtitle: item != null ? Text('生命+$hp, 攻击+$attack, 防御+$defense, 暴击+$hit, 闪避+$dodge') : null,
        trailing:
            item != null && !working
                ? ElevatedButton(
                  onPressed: () async {
                    await weapon.change(pos, id, user);
                  },
                  child: Text("穿戴"),
                )
                : null,
      );
    }).toList();
  }
}
