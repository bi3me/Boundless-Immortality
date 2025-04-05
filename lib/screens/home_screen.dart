import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'style/responsive_screen.dart';
import '../models/user.dart';
import '../models/broadcast.dart';
import '../common/constants.dart';

class HomeScreen extends StatelessWidget {
  bool _isDesktop = false;

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 760) {
      _isDesktop = true;
    } else {
      _isDesktop = false;
    }

    final user = context.watch<UserModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
          _isDesktop
              ? Row(
                children: [
                  SizedBox(width: 400, child: PlayScreen()),
                  Expanded(child: user.detailPage),
                ],
              )
              : PlayScreen(),
    );
  }
}

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  PlayState createState() => PlayState();
}

class PlayState extends State<PlayScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final broadcasts = context.watch<BroadcastModel>().items;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        backable: false,
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 10),
                    _buildExperienceBar(user.level, user.levelNum),
                    const SizedBox(height: 10),
                    _buildStatsRow(user),
                    const SizedBox(height: 20),
                    _buildActionButtons(user),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SafeArea(child: _buildMessages(broadcasts)),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            user.router(context, '/play/travel');
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
          user.name,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Spacer(),
        IconButton(
          onPressed: () {
            GoRouter.of(context).push('/settings');
          },
          icon: Icon(Icons.tune),
          color: attributeColors[user.attribute],
        ),
      ],
    );
  }

  Widget _buildExperienceBar(int level, int levelNum) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("当前: ${levels[level]}, 修为: $levelNum / ${levelsNum[level]}"),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: levelNum / levelsNum[level],
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("加速", user.levelUp),
        _buildStatItem("战力", user.power),
        _buildStatItem("仙石", user.coin),
        Column(
          children: [
            Text(
              attributes[user.attribute],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('灵根', style: TextStyle(color: Colors.grey)),
          ],
        ),
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

  Widget _buildActionButtons(UserModel user) {
    List<(String, String)> actions = [
      ('功法', 'kungfu'),
      ('法宝', 'weapon'),
      ('储物', 'bag'),
      ('炼丹', 'elixir'),
      ('炼器', 'forging'),
      ('决斗', 'duel'),
      //('好友', 'friend'),
      //('道侣', 'mate'),
      ('坊市', 'market'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        var (name, route) = actions[index];
        return ElevatedButton(
          onPressed: () {
            user.router(context, '/play/$route');
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
            color: Color(0xBFCCCCD6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView(
            children: broadcasts.map((b) => Text(b.show())).toList(),
          ),
        ),
      ],
    );
  }
}
