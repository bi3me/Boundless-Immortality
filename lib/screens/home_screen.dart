import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'style/palette.dart';
import 'style/responsive_screen.dart';
import '../models/user.dart';
import '../models/broadcast.dart';
import '../common/constants.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  PlayState createState() => PlayState();
}

class PlayState extends State<PlayScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final user = context.watch<UserModel>();
    final broadcasts = context.watch<BroadcastModel>().items;

    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            SizedBox(height: 20),
            _buildStatsRow(user),
            SizedBox(height: 20),
            _buildActionButtons(),
            SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildMessages(broadcasts)],
              ),
            ),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            GoRouter.of(context).go('/');
          },
          child: const Text('游历'),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage("assets/icon/icon.jpg"),
          // backgroundImage: AssetImage("assets/logo.png"), // 头像
        ),
        SizedBox(width: 20),
        Text(
          "${levels[user.level]}•${user.name}",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("修为", user.levelNum),
        _buildStatItem("加速", user.levelUp),
        _buildStatItem("战力", user.power),
        _buildStatItem("仙石", user.coin),
      ],
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    List<(String, String)> actions = [
      ('功法', 'kungfu'),
      ('法宝', 'weapon'),
      ('储物', 'bag'),
      ('炼丹', 'elixir'),
      ('炼器', 'forging'),
      ('决斗', 'duel'),
      ('好友', 'friend'),
      ('道侣', 'mate'),
      ('坊市', 'market'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        var (name, route) = actions[index];
        return ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Color(0xffbfc8e3)),
          ),
          onPressed: () {
            GoRouter.of(context).go('/play/$route');
          },
          child: Text(name),
        );
      },
    );
  }

  Widget _buildMessages(List<BroadcastItem> broadcasts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "世界广播",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Container(
          height: 100,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView(
            children: [
              Text("[世界] 仙尊·无名: 今日突破化神境！"),
              Text("[好友] 李白: 兄弟，坊市有新功法！"),
              Text("[世界] 魔道·血影: 谁敢与我一战？"),
            ],
          ),
        ),
      ],
    );
  }
}
