// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../common/in_app_purchase/in_app_purchase.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';
import 'settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _gap = SizedBox(height: 60);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final palette = context.watch<Palette>();

    return Scaffold(
      backgroundColor: palette.backgroundSettings,
      body: ResponsiveScreen(
        backable: false,
        squarishMainArea: Column(
          children: [
            _gap,
            const Text(
              '设置',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 55, height: 1),
            ),
            _gap,
            ValueListenableBuilder<bool>(
              valueListenable: settings.soundsOn,
              builder:
                  (context, soundsOn, child) => _SettingsLine(
                    '按键声音',
                    Icon(soundsOn ? Icons.graphic_eq : Icons.volume_off),
                    onSelected: () => settings.toggleSoundsOn(),
                  ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: settings.musicOn,
              builder:
                  (context, musicOn, child) => _SettingsLine(
                    '背景音乐',
                    Icon(musicOn ? Icons.music_note : Icons.music_off),
                    onSelected: () => settings.toggleMusicOn(),
                  ),
            ),
            Consumer<InAppPurchaseController?>(
              builder: (context, inAppPurchase, child) {
                if (inAppPurchase == null) {
                  // In-app purchases are not supported yet.
                  // Go to lib/main.dart and uncomment the lines that create
                  // the InAppPurchaseController.
                  return const SizedBox.shrink();
                }

                Widget icon;
                VoidCallback? callback;
                if (inAppPurchase.adRemoval.active) {
                  icon = const Icon(Icons.check);
                } else if (inAppPurchase.adRemoval.pending) {
                  icon = const CircularProgressIndicator();
                } else {
                  icon = const Icon(Icons.ad_units);
                  callback = () {
                    inAppPurchase.buy();
                  };
                }
                return _SettingsLine('Remove ads', icon, onSelected: callback);
              },
            ),
            _gap,
            Spacer(),
            ListTile(
              title: Center(child: Text('退出当前账号', style: TextStyle(color: Colors.red[500]))),
              onTap: () {
                GoRouter.of(context).go('/');
            })
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            GoRouter.of(context).pop();
          },
          child: const Text('Back'),
        ),
      ),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  final String title;

  final Widget icon;

  final VoidCallback? onSelected;

  const _SettingsLine(this.title, this.icon, {this.onSelected});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      highlightShape: BoxShape.rectangle,
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: 30,
                ),
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
