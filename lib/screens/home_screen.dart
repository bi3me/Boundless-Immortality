import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:js/js.dart';

import 'style/responsive_screen.dart';
import '../models/user.dart';
import '../models/broadcast.dart';
import '../common/constants.dart';
import '../common/auth_http.dart';
import '../common/web3.dart';


@JS('redirectToCheckout')
external void redirectToCheckout(String sessionId, String publishableKey);

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
                  SizedBox(width: 350, child: PlayScreen()),
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
  Timer? _timer;
  bool _showing = false;

  void _startDelayedTask() {
    // 10min settle once
    _timer = Timer(Duration(seconds: 360), () {
      context.read<UserModel>().settle();
    });
  }

  @override
  void initState() {
    super.initState();
    _startDelayedTask();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final broadcasts = context.watch<BroadcastModel>().items;
    if (!_showing && user.newRegister) {
      _showing = true;
      Future.delayed(Duration(seconds: 1), () {
        _showNewRegister();
      });
    }

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
                    _buildExperienceBar(user),
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
          radius: 26,
          backgroundColor: attributeColors[user.attribute],
          child: Text(
            attributes[user.attribute],
            style: TextStyle(
              color: attributeFontColors[user.attribute],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // backgroundImage: AssetImage("assets/icon/icon.jpg"),
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

  Widget _buildExperienceBar(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "当前: ${levels[user.level]}, 修为: ${user.levelNum} / ${levelsNum[user.level]}",
              ),
              TextButton(
                onPressed: () {
                  user.settle();
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return DepositDialog(user);
                    },
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '充值',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: user.levelNum / levelsNum[user.level],
            backgroundColor: Colors.grey[300],
            color: attributeColors[user.attribute],
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
        _buildStatItem("灵石", user.coin),
        Column(
          children: [
            Text(
              attributes[user.attribute],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('灵根'),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label),
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
      ('灵田', 'plant'),
      ('决斗', 'duel'),
      //('好友', 'friend'),
      //('测试', 'mate'),
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
            color: Color(0xBFADA595),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView(
            children: broadcasts.map((b) => Text(b.show())).toList(),
          ),
        ),
      ],
    );
  }

  void _showNewRegister() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('新手介绍'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('开启你的自在修仙之旅！'),
                Text('在这里你可以自由炼制丹药，武器，功法，决斗。自由分配各种技能点！使用 <游历> 功能去探索副本，获取资源！'),
                const SizedBox(height: 10),
                Text('新注册的奖励的灵石和资源已到账！'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.read<UserModel>().closeNewRegister();
                Navigator.of(context).pop();
              },
              child: Text('确认'),
            ),
          ],
        );
      },
    );
  }
}

class DepositDialog extends StatefulWidget {
  final UserModel user;

  const DepositDialog(this.user, {super.key});

  @override
  DepositDialogState createState() => DepositDialogState();
}

class DepositDialogState extends State<DepositDialog> {
  int _dtype = 1;
  int _amount = 2;
  String _info = '';
  bool _loading = false;
  final Map<int, String> _descriptions = {
    1: '支持信用卡，支付宝，微信多种支付方式！',
    2: '加密货币中的 稳定币(USDT, USDC)，只支持 以太坊(Ethereum) 充值。',
  };

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.user.eth));
    setState(() {
      _info = '复制成功！';
    });
  }

  void _confirm() async {
    setState(() {
      _loading = true;
    });

    final balance = await depositCheck(widget.user.eth);
    if (balance == null) {
      setState(() {
        _info = '本地检测失败！正在启动后台检测！';
        AuthHttpClient().post(AuthHttpClient.uri('users/coin'));
      });
      return;
    }
    if (balance < 10) {
      setState(() {
        _info = "当前充值金额太小，为 $balance ！";
        _loading = false;
      });
    } else {
      setState(() {
        _info = "当前充值金额为 $balance ！后台处理中！";
        AuthHttpClient().post(AuthHttpClient.uri('users/coin'));
      });
    }
  }

  void _stripe() async {
    setState(() {
        _info = '';
        _loading = true;
    });

    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/pay'),
      body: AuthHttpClient.form({'amount': _amount}),
    );
    final data = AuthHttpClient.res(response);

    if (data != null) {
      final sessionId = data['session_id'];
      // try redirect
      try {
        // Call the global JavaScript function redirectToCheckout
        // List<String> params = [sessionId, STRIPE_PK];
        redirectToCheckout(sessionId, STRIPE_PK);
        // globalContext.callMethod('redirectToCheckout'.toJS, params.toJS);
      } catch (e) {
        setState(() {
            _info = '自动跳转失败！';
            _loading = false;
        });
      }
    } else {
      setState(() {
          _info = '无法创建订单, 稍后再试！';
          _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('充值方式'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _dtype,
                      onChanged: (int? value) {
                        setState(() {
                          _dtype = value ?? 2;
                        });
                      },
                    ),
                    const Text('线上支付', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(width: 20.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 2,
                      groupValue: _dtype,
                      onChanged: (int? value) {
                        setState(() {
                          _dtype = value ?? 1;
                        });
                      },
                    ),
                    const Text('稳定币', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(_descriptions[_dtype] ?? ''),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text('1 USD = 100 灵石'),
            ),
            if (_dtype == 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text('因手续费，充值金额最小 10 USD'),
            ),
            if (_dtype == 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 2,
                      groupValue: _amount,
                      onChanged: (int? value) {
                        setState(() {
                          _amount = value ?? 2;
                        });
                      },
                    ),
                    const Text('2 USD', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ],
                ),
                const SizedBox(width: 10.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 10,
                      groupValue: _amount,
                      onChanged: (int? value) {
                        setState(() {
                          _amount = value ?? 10;
                        });
                      },
                    ),
                    const Text('10 USD', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ],
                ),
                const SizedBox(width: 10.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 100,
                      groupValue: _amount,
                      onChanged: (int? value) {
                        setState(() {
                          _amount = value ?? 100;
                        });
                      },
                    ),
                    const Text('100 USD', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ],
                ),
              ],
            ),
            if (_dtype == 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.user.eth,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.copy), onPressed: _copy),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(_info, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: Colors.black)),
        ),
        if (_dtype == 1)
        TextButton(
          onPressed: _loading ? null : () => _stripe(),
          child: Text(
            _loading ? '支付中' : '支付',
            style: TextStyle(color: Colors.white),
          ),
        ),
        if (_dtype == 2)
        TextButton(
          onPressed: _loading ? null : () => _confirm(),
          child: Text(
            _loading ? '查询中' : '充值结果查询',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
