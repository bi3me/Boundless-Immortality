import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'common/app_lifecycle/app_lifecycle.dart';
import 'common/audio/audio_controller.dart';

import 'screens/settings/persistence/local_storage_settings_persistence.dart';
import 'screens/settings/persistence/settings_persistence.dart';
import 'screens/settings/settings.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/style/palette.dart';
import 'screens/style/snack_bar.dart';

import 'screens/login/login_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kungfu/kungfu_screen.dart';
import 'screens/weapon/weapon_screen.dart';
import 'screens/bag/bag_screen.dart';
import 'screens/elixir/elixir_screen.dart';
import 'screens/forging/forging_screen.dart';
import 'screens/duel/duel_screen.dart';
import 'screens/friend/friend_screen.dart';
import 'screens/mate/mate_screen.dart';
import 'screens/market/market_screen.dart';
import 'screens/travel/travel_screen.dart';

import 'models/broadcast.dart';
import 'models/duel.dart';
import 'models/elixir.dart';
import 'models/friend.dart';
import 'models/kungfu.dart';
import 'models/market.dart';
import 'models/material.dart';
import 'models/travel.dart';
import 'models/user.dart';
import 'models/weapon.dart';

Future<void> main() async {
  // Subscribe to log messages.
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  WidgetsFlutterBinding.ensureInitialized();

  // TODO: To enable Firebase Crashlytics, uncomment the following line.
  // See the 'Crashlytics' section of the main README.md file for details.

  // if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
  //   try {
  //     await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //
  //     FlutterError.onError = (errorDetails) {
  //       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  //     };
  //
  //     // Pass all uncaught asynchronous errors
  //     // that aren't handled by the Flutter framework to Crashlytics.
  //     PlatformDispatcher.instance.onError = (error, stack) {
  //       FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //       return true;
  //     };
  //   } catch (e) {
  //     debugPrint("Firebase couldn't be initialized: $e");
  //   }
  // }

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // TODO: When ready, uncomment the following lines to enable integrations.
  //       Read the README for more info on each integration.

  // AdsController? adsController;
  // if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
  //   /// Prepare the google_mobile_ads plugin so that the first ad loads
  //   /// faster. This can be done later or with a delay if startup
  //   /// experience suffers.
  //   adsController = AdsController(MobileAds.instance);
  //   adsController.initialize();
  // }

  // InAppPurchaseController? inAppPurchaseController;
  // if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
  //   inAppPurchaseController = InAppPurchaseController(InAppPurchase.instance)
  //     // Subscribing to [InAppPurchase.instance.purchaseStream] as soon
  //     // as possible in order not to miss any updates.
  //     ..subscribe();
  //   // Ask the store what the player has bought already.
  //   inAppPurchaseController.restorePurchases();
  // }

  runApp(
    MyApp(
      settingsPersistence: LocalStorageSettingsPersistence(),
      // inAppPurchaseController: inAppPurchaseController,
      // adsController: adsController,
    ),
  );
}

Logger _log = Logger('main.dart');

class MyApp extends StatelessWidget {
  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(key: Key('login')),
        routes: [
          GoRoute(
            path: 'play',
            builder: (context, state) => const PlayScreen(key: Key('play')),
            routes: [
              GoRoute(
                path: 'kungfu',
                builder: (context, state) {
                  context.read<KungfuModel>().load();
                  return const PlayKungfuScreen(key: Key('play_kungfu'));
                }
              ),
              GoRoute(
                path: 'weapon',
                builder: (context, state) {
                  context.read<WeaponModel>().load();
                  return const PlayWeaponScreen(key: Key('play_weapon'));
                }
              ),
              GoRoute(
                path: 'bag',
                builder: (context, state) {
                  context.read<MaterialModel>().load();
                  return const PlayBagScreen(key: Key('play_bag'));
                }
              ),
              GoRoute(
                path: 'elixir',
                builder: (context, state) {
                  context.read<ElixirModel>().load();
                  return const PlayElixirScreen(key: Key('play_elixir'));
                }
              ),
              GoRoute(
                path: 'forging',
                builder: (context, state) {
                  context.read<WeaponModel>().load();
                  return const PlayForgingScreen(key: Key('play_forging'));
                }
              ),
              GoRoute(
                path: 'duel',
                builder:
                    (context, state) =>
                        const PlayDuelScreen(key: Key('play_duel')),
              ),
              GoRoute(
                path: 'friend',
                builder:
                    (context, state) =>
                        const PlayFriendScreen(key: Key('play_friend')),
              ),
              GoRoute(
                path: 'mate',
                builder:
                    (context, state) =>
                        const PlayMateScreen(key: Key('play_mate')),
              ),
              GoRoute(
                path: 'market',
                builder:
                    (context, state) =>
                        const PlayMarketScreen(key: Key('play_market')),
              ),
              GoRoute(
                path: 'travel',
                builder:
                    (context, state) =>
                        const PlayTravelScreen(key: Key('play_travel')),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            builder:
                (context, state) => const SettingsScreen(key: Key('settings')),
          ),
          GoRoute(
            path: 'setup',
            builder: (context, state) {
              final (email, password) = state.extra as (String, String);
              return SetupScreen(
                email: email,
                password: password,
                key: Key('setup'),
              );
            },
          ),
        ],
      ),
    ],
  );


  final SettingsPersistence settingsPersistence;

  // final InAppPurchaseController? inAppPurchaseController;

  // final AdsController? adsController;

  const MyApp({
    required this.settingsPersistence,
    // required this.inAppPurchaseController,
    // required this.adsController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserModel()),
          ChangeNotifierProvider(create: (context) => BroadcastModel()),
          ChangeNotifierProvider(create: (context) => KungfuModel()),
          ChangeNotifierProvider(create: (context) => ElixirModel()),
          ChangeNotifierProvider(create: (context) => WeaponModel()),
          ChangeNotifierProvider(create: (context) => MaterialModel()),
          // Provider<AdsController?>.value(value: adsController),
          // ChangeNotifierProvider<InAppPurchaseController?>.value(
          //   value: inAppPurchaseController,
          // ),
          Provider<SettingsController>(
            lazy: false,
            create:
                (context) =>
                    SettingsController(persistence: settingsPersistence)
                      ..loadStateFromPersistence(),
          ),
          ProxyProvider2<
            SettingsController,
            ValueNotifier<AppLifecycleState>,
            AudioController
          >(
            // Ensures that the AudioController is created on startup,
            // and not "only when it's needed", as is default behavior.
            // This way, music starts immediately.
            lazy: false,
            create: (context) => AudioController()..initialize(),
            update: (context, settings, lifecycleNotifier, audio) {
              if (audio == null) throw ArgumentError.notNull();
              audio.attachSettings(settings);
              audio.attachLifecycleNotifier(lifecycleNotifier);
              return audio;
            },
            dispose: (context, audio) => audio.dispose(),
          ),
          Provider(create: (context) => Palette()),
        ],
        child: Builder(
          builder: (context) {
            final palette = context.watch<Palette>();

            return MaterialApp.router(
              title: 'Boundless Immortality',
              theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: palette.darkPen,
                  surface: palette.backgroundMain,
                ),
                textTheme: TextTheme(bodyMedium: TextStyle(color: palette.ink)),
              ),
              routeInformationProvider: _router.routeInformationProvider,
              routeInformationParser: _router.routeInformationParser,
              routerDelegate: _router.routerDelegate,
              scaffoldMessengerKey: scaffoldMessengerKey,
            );
          },
        ),
      ),
    );
  }
}
