import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlayElixirScreen extends StatefulWidget {
  // const PlayKungfuScreen({Key? key}) : super(key: key);
  const PlayElixirScreen({super.key});

  @override
  PlayElixirState createState() => PlayElixirState();
}

class PlayElixirState extends State<PlayElixirScreen> {
  final List<String> ingredients = List.generate(
    20,
    (index) => "材料 ${index + 1}",
  );
  List<String> selectedIngredients = [];
  int alchemistLevel = 3; // 炼丹师等级，决定可用格子
  int experience = 50; // 当前经验值
  int nextLevelExp = 100; // 下一级经验值

  // 预定义丹方
  final Map<String, List<String>> recipes = {
    "回春丹": ["材料 1", "材料 3", "材料 5"],
    "聚灵丹": ["材料 2", "材料 4", "材料 6", "材料 8"],
    "玄元丹": ["材料 7", "材料 9", "材料 11", "材料 13", "材料 15"],
  };
  String? selectedRecipe;


  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      appBar: AppBar(title: const Text('炼丹')),
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExperienceBar(),
            _buildRecipeSelection(),
            _buildAlchemyGrid(),
            SizedBox(height: 20),
            _buildIngredientSelection(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedIngredients.isNotEmpty ? _startAlchemy : null,
              child: Text("开始炼丹"),
            ),
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

   Widget _buildExperienceBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("当前: $alchemistLevel 级, 经验值: $experience / $nextLevelExp"),
          LinearProgressIndicator(
            value: experience / nextLevelExp,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSelection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text("选择丹方"),
          value: selectedRecipe,
          onChanged: (newRecipe) {
            setState(() {
              selectedRecipe = newRecipe;
              selectedIngredients = List.from(recipes[newRecipe!] ?? []);
            });
          },
          items:
              recipes.keys.map((recipe) {
                return DropdownMenuItem<String>(
                  value: recipe,
                  child: Text(recipe.isEmpty ? "无" : recipe),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlchemyGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          bool isUnlocked = index < alchemistLevel + 2; // 可用格子数量取决于炼丹师等级
          return GestureDetector(
            onTap: isUnlocked && index < selectedIngredients.length
                ? () => setState(() => selectedIngredients.removeAt(index))
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: isUnlocked
                    ? (index < selectedIngredients.length ? Colors.green[200] : Colors.white)
                    : Colors.grey[400],
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                index < selectedIngredients.length ? selectedIngredients[index] : (isUnlocked ? "可放置" : "锁定"),
                style: TextStyle(fontSize: 14),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIngredientSelection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: ingredients.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: selectedIngredients.length < alchemistLevel + 2
                  ? () => setState(() => selectedIngredients.add(ingredients[index]))
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(ingredients[index], style: TextStyle(fontSize: 14)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startAlchemy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("炼丹成功！"),
          content: Text("你使用了 ${selectedIngredients.join(", ")} 进行炼丹。"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => selectedIngredients.clear());
                Navigator.of(context).pop();
              },
              child: Text("关闭"),
            ),
          ],
        );
      },
    );
  }
}
