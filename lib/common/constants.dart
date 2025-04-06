import 'package:flutter/material.dart';

const String domain = 'https://bi3.me';
// const String domain = 'http://127.0.0.1:9000';

const List<String> levels = [
  '',
  '炼气',
  '筑基',
  '结丹',
  '元婴',
  '化神',
  '炼虚',
  '合体',
  '大乘',
];

const List<int> levelsNum = [
  0,
  100,
  10000,
  1000000,
  100000000,
  10000000000,
  1000000000000,
  100000000000000,
  10000000000000000,
];

const List<String> attributes = [
  '',
  '金',
  '木',
  '水',
  '火',
  '土',
  '风',
  '雷',
  '光',
  '暗',
];

const List<String> weaponPos = [
  '',
  '法宝',
  '头戴',
  '身躯',
  '左臂',
  '右臂',
  '左腿',
  '右腿',
  '脚穿',
];

const List<Color> attributeColors = [
  Color(0xFFCCCCD6), // ''
  Color(0xFFFBDA41), // '金',
  Color(0xFF1BA784), // '木',
  Color(0xFF2775b6), // '水',
  Color(0xFFC04851), // '火',
  Color(0xFF856D72), // '土',
  Color(0xFF92B3A5), // '风',
  Color(0xFFFBA414), // '雷',
  Color(0xFFF8F4ED), // '光',
  Color(0xFF310F1B), // '暗',
];

const List<Color> attributeFontColors = [
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.black,
  Colors.white,
];

int? calculateAttribute(String input) {
  final RegExp dateRegExp = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  if (!dateRegExp.hasMatch(input)) {
    return null;
  }

  final match = dateRegExp.firstMatch(input)!;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  // verfy datetime
  try {
    DateTime(year, month, day);
  } catch (e) {
    return null;
  }

  int sum = year + month + day;
  int attribute = sum % 5;
  if (attribute == 0) attribute = 5;
  return attribute;
}
