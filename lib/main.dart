import 'dart:developer' as dev;

import 'package:boundless_immortality/common/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'common/app_lifecycle/app_lifecycle.dart';
import 'common/audio/audio_controller.dart';
import 'common/token.dart';
import 'common/auth_http.dart';

import 'screens/settings/persistence/local_storage_settings_persistence.dart';
import 'screens/settings/persistence/settings_persistence.dart';
import 'screens/settings/settings.dart';
import 'screens/settings/settings_screen.dart';
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
// import 'models/friend.dart';
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

Future<(String, Map<String, dynamic>)> _getInitialRoute() async {
  final res = await TokenManager.getToken();
  if (res != null) {
    final response = await AuthHttpClient().get(AuthHttpClient.uri('users'));

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return ('/login', {'': 1});
    } else {
      return ('/play', data);
    }
  }
  return ('/login', {'': 1});
}

class MyApp extends StatelessWidget {
  static get routers => [
    GoRoute(
      path: '/splash',
      builder: (context, state) => SplashScreen(future: _getInitialRoute()),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginScreen(key: Key('login'));
      },
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) {
        final (email, password) = state.extra as (String, String);
        return SetupScreen(email: email, password: password, key: Key('setup'));
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(key: Key('settings')),
    ),
    GoRoute(
      path: '/play',
      builder: (context, state) => HomeScreen(key: Key('play')),
    ),
    GoRoute(
      path: '/play/kungfu',
      builder: (context, state) {
        context.read<KungfuModel>().load();
        return const PlayKungfuScreen(key: Key('play_kungfu'));
      },
    ),
    GoRoute(
      path: '/play/weapon',
      builder: (context, state) {
        context.read<WeaponModel>().load();
        return const PlayWeaponScreen(key: Key('play_weapon'));
      },
    ),
    GoRoute(
      path: '/play/bag',
      builder: (context, state) {
        context.read<MaterialModel>().load();
        return const PlayBagScreen(key: Key('play_bag'));
      },
    ),
    GoRoute(
      path: '/play/elixir',
      builder: (context, state) {
        context.read<ElixirModel>().load();
        return const PlayElixirScreen(key: Key('play_elixir'));
      },
    ),
    GoRoute(
      path: '/play/forging',
      builder: (context, state) {
        context.read<WeaponModel>().load();
        return const PlayForgingScreen(key: Key('play_forging'));
      },
    ),
    GoRoute(
      path: '/play/duel',
      builder: (context, state) {
        context.read<DuelModel>().load();
        return const PlayDuelScreen(key: Key('play_duel'));
      },
    ),
    GoRoute(
      path: '/play/market',
      builder: (context, state) {
        context.read<MarketModel>().load();
        return const PlayMarketScreen(key: Key('play_market'));
      },
    ),
    GoRoute(
      path: '/play/travel',
      builder: (context, state) {
        context.read<TravelModel>().load();
        return const PlayTravelScreen(key: Key('play_travel'));
      },
    ),
    GoRoute(
      path: '/play/friend',
      builder:
          (context, state) => const PlayFriendScreen(key: Key('play_friend')),
    ),
    GoRoute(
      path: '/play/mate',
      builder: (context, state) => const PlayMateScreen(key: Key('play_mate')),
    ),
  ];

  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: routers,
  );

  final SettingsPersistence settingsPersistence;

  // final InAppPurchaseController? inAppPurchaseController;

  // final AdsController? adsController;

  MyApp({
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
          ChangeNotifierProvider(create: (context) => DuelModel()),
          ChangeNotifierProvider(create: (context) => MarketModel()),
          ChangeNotifierProvider(create: (context) => TravelModel()),
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
        ],
        child: Builder(
          builder: (context) {
            final attribute = context.watch<UserModel>().attribute;

            return MaterialApp.router(
              routerConfig: _router,
              title: 'Boundless Immortality',
              builder:
                  (context, child) => Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/background.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      child ?? const SizedBox.shrink(),
                    ],
                  ),
              theme: ThemeData(
                textTheme: TextTheme(
                  bodyMedium: TextStyle(color: Colors.black),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xBFADA595),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    ),
                  ),
                ),
                dialogTheme: DialogTheme(
                  backgroundColor: Color(0xBFADA595),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  ),
                ),
                cardTheme: CardTheme(
                  color: Color(0xBFADA595),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Color(0xBFADA595)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      attributeColors[attribute],
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      attributeFontColors[attribute],
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
              ),
              scaffoldMessengerKey: scaffoldMessengerKey,
            );
          },
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final Future<(String, Map<String, dynamic>)> future;

  const SplashScreen({required this.future, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String, Map<String, dynamic>)>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final (route, data) = snapshot.data!;
          context.read<UserModel>().fromNetwork(data);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(route);
          });
        }
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
