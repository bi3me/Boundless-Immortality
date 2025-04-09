import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../models/travel.dart';
import '../../models/material.dart';
import '../../common/constants.dart';

class PlayMateScreen extends StatefulWidget {
  const PlayMateScreen({super.key});

  @override
  State<PlayMateScreen> createState() => _PlayMateScreenState();
}

class _PlayMateScreenState extends State<PlayMateScreen>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _fogController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _fogAnimation;
  double _width = 0;
  double _height = 0;

  int _selectedIndex = 0;
  bool _traveling = false;

  final Map<int, Offset> _baseOffsets = {
    0: const Offset(0, 0),
    1: const Offset(0, -150),
    2: const Offset(0, 150),
    3: const Offset(-150, 0),
    4: const Offset(150, 0),
  };

  final Map<int, (String, int)> _addressNames = {
    0: ('我的洞府', 1),
    1: ('火云洞', 0),
    2: ('李逍遥的洞府', 1),
    3: ('坠魔岭', 0),
    4: ('某位道友的洞府', 1),
  };

  late Map<int, Offset> _positions;
  int _currentPosition = 0;
  int _targetPosition = 0;
  bool _showFog = false;

  @override
  void initState() {
    super.initState();
    _positions = Map.from(_baseOffsets);

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fogAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fogController, curve: Curves.easeInOut));

    _moveAnimation =
        Tween<Offset>(
            begin: _positions[_currentPosition]!,
            end: _positions[_targetPosition]!,
          ).animate(
            CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) async {
            if (status == AnimationStatus.completed) {
              setState(() => _showFog = true);
              await _fogController.forward(from: 0);
              _currentPosition = _targetPosition;
              // _recenterPositions();
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 1000));
              setState(() {
                _showFog = false;
                _currentPosition = 0;
                _moveController.reverse();
              });
            }
          });
  }

  void _moveTo(int direction) {
    if (_currentPosition == direction || !_positions.containsKey(direction)) {
      return;
    }

    setState(() {
      _targetPosition = direction;
      _moveAnimation = Tween<Offset>(
        begin: _positions[_currentPosition]!,
        end: _positions[_targetPosition]!,
      ).animate(
        CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
      );
      _moveController.forward(from: 0);
    });
  }

  Widget _buildLocation(int pos, Offset offset) {
    final (name, ttype) = _addressNames[pos]?? ('', 0);
    return Positioned(
      left: _width / 2 + offset.dx - 40,
      top: _height / 2 + offset.dy - 80,
      child: Column(
        children: [
          ttype == 1 ? const Icon(Icons.castle, color: Colors.white)
          : const Icon(Icons.terrain, color: Colors.red),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Color(0xBFADA595),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;
    if (screenWidth > 760) {
      _width = screenWidth - 350; // home page
    } else {
      _width = screenWidth;
    }

    final travel = context.watch<TravelModel>();
    final history = travel.history.values.toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('地图模式')),
                    ButtonSegment(value: 1, label: Text('历史足迹')),
                  ],
                  selected: {_selectedIndex},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedIndex = newSelection.first;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Location markers
                  ..._positions.entries.map(
                    (e) => _buildLocation(e.key, e.value),
                  ),

                  // Character on sword with image
                  Positioned(
                    left: _width / 2 + _moveAnimation.value.dx - 30,
                    top: _height / 2 + _moveAnimation.value.dy - 100,
                    child: Image.asset(
                      'assets/images/flying.png',
                      width: 50,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Cloud transition effect using semi-transparent overlay and text
                  if (_showFog)
                    FadeTransition(
                      opacity: _fogAnimation,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color(0xBFADA595),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Text(
                          '飞行中……',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Control buttons
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                          ),
                          onPressed: () => _moveTo(1),
                          child: Icon(Icons.arrow_upward),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                              ),
                              onPressed: () => _moveTo(3),
                              child: Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                              ),
                              onPressed: () => _moveTo(4),
                              child: Icon(Icons.arrow_forward),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                          ),
                          onPressed: () => _moveTo(2),
                          child: Icon(Icons.arrow_downward),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        rectangularMenuArea: FilledButton(onPressed: null, child: Text('随机游历')),
      ),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _fogController.dispose();
    super.dispose();
  }
}
