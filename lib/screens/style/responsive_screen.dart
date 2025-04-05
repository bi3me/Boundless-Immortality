// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A widget that makes it easy to create a screen with a square-ish
/// main area, a smaller menu area, and a small area for a message on top.
/// It works in both orientations on mobile- and tablet-sized screens.
class ResponsiveScreen extends StatelessWidget {
  final bool backable;

  /// This is the "hero" of the screen. It's more or less square, and will
  /// be placed in the visual "center" of the screen.
  final Widget squarishMainArea;

  /// The second-largest area after [squarishMainArea]. It can be narrow
  /// or wide.
  final Widget? rectangularMenuArea;

  /// How much bigger should the [squarishMainArea] be compared to the other
  /// elements.
  final double mainAreaProminence;

  const ResponsiveScreen({
    required this.squarishMainArea,
    this.rectangularMenuArea,
    this.mainAreaProminence = 0.8,
    this.backable = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = false;
    if (screenWidth > 760) {
      isDesktop = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // This widget wants to fill the whole screen.
        final size = constraints.biggest;
        final padding = EdgeInsets.all(size.shortestSide / 30);

        //if (size.width < 760 || size.height >= size.width) {
        // "Portrait" / "mobile" mode.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(bottom: false, child: SizedBox.shrink()),
            Expanded(
              flex: (mainAreaProminence * 100).round(),
              child: SafeArea(
                top: false,
                bottom: false,
                minimum: padding,
                child: squarishMainArea,
              ),
            ),
            SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (backable && !isDesktop)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: const Row(
                            children: [
                              Icon(Icons.home),
                              Icon(Icons.chevron_left),
                            ],
                          ),
                        ),
                      ),
                    if (rectangularMenuArea != null)
                      Expanded(child: rectangularMenuArea ?? SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
