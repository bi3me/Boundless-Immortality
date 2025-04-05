import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';

class PlayFriendScreen extends StatefulWidget {
  const PlayFriendScreen({super.key});

  @override
  PlayFriendState createState() => PlayFriendState();
}

class PlayFriendState extends State<PlayFriendScreen> {
  final List<String> friends = ["好友A", "好友B", "好友C", "好友D", "好友E"];
  String? selectedFriend;
  Map<String, List<String>> chatMessages = {
    "好友A": [],
    "好友B": [],
    "好友C": [],
    "好友D": [],
    "好友E": [],
  };
  TextEditingController messageController = TextEditingController();

  Map<String, Map<String, String>> friendInfo = {
    "好友A": {"境界": "炼气期", "战力": "500", "功法": "九阳真经", "炼丹等级": "初级", "炼器等级": "无"},
    "好友B": {
      "境界": "筑基期",
      "战力": "1200",
      "功法": "太阴心经",
      "炼丹等级": "中级",
      "炼器等级": "初级",
    },
    "好友C": {"境界": "金丹期", "战力": "3000", "功法": "五雷诀", "炼丹等级": "高级", "炼器等级": "中级"},
    "好友D": {"境界": "元婴期", "战力": "7000", "功法": "赤焰诀", "炼丹等级": "大师", "炼器等级": "高级"},
    "好友E": {
      "境界": "化神期",
      "战力": "15000",
      "功法": "混沌诀",
      "炼丹等级": "宗师",
      "炼器等级": "宗师",
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFriendList(),
            _showFriendInfo("好友A"),
            Expanded(child: _buildChatWindow()),
            _buildMessageInput(),
          ],
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

  Widget _buildFriendList() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFriend = friends[index];
              });
            },
            child: Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              decoration: BoxDecoration(
                color: selectedFriend == friends[index] ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(friends[index], style: TextStyle(fontSize: 16))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatWindow() {
    if (selectedFriend == null) {
      return Center(child: Text("请选择一个好友开始聊天"));
    }
    return GestureDetector(
      onTap: () => _showFriendInfo(selectedFriend!),
      child: Container(
        color: Colors.grey[200],
        padding: EdgeInsets.all(10),
        child: ListView(
          padding: EdgeInsets.all(10),
          children: chatMessages[selectedFriend]!
              .map((message) => _buildMessageBubble(message))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "输入消息...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (selectedFriend != null && messageController.text.isNotEmpty) {
                setState(() {
                  chatMessages[selectedFriend]!.add(messageController.text);
                  messageController.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _showFriendInfo(String friend) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: friendInfo[friend]!.entries
      .map((entry) => Text("${entry.key}: ${entry.value}"))
      .toList()
    );
  }
}
