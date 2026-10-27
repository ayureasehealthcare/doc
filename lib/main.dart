import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/features/autopilot/review_queue_screen.dart';
import 'package:doctro/features/consultation/chat/pages/chat_page.dart'
    show ChatPage;
import 'package:doctro/core/navigator_key.dart';
import 'package:doctro/core/config/env.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/utils/logger.dart';
import 'package:doctro/utils/notification.dart' show NotificationHandler;
import 'package:doctro/core/localization/language_localization.dart';
import 'package:doctro/models/setting.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/features/authentication/SignIn.dart';
import 'package:doctro/features/startup_gate.dart';
import 'package:doctro/features/authentication/forgotpassword.dart';
import 'package:doctro/features/notifications/ViewAllNotification.dart';
import 'package:doctro/features/schedule/ScheduleTimings.dart';
import 'package:doctro/features/settings/ChangePassword.dart';
import 'package:doctro/features/settings/Setting.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctro/features/settings/changeLanguage.dart';
import 'package:doctro/features/consultation/videoCall/videocallhistory.dart';
import 'package:doctro/features/authentication/signup.dart';
import 'package:doctro/features/authentication/phoneverification.dart';
import 'package:doctro/features/appointments/cancel_appointment.dart';
import 'package:doctro/features/appointments/appointment_history.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctro/widgets/session_timeout_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:doctro/theme/theme_provider.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/features/consultation/videoCall/VideoCall/overlay_handler.dart';
import 'package:doctro/features/consultation/chat/pages/home_page.dart';
import 'package:doctro/features/consultation/chat/providers/auth_provider.dart'
    as provider;
import 'package:doctro/features/consultation/chat/providers/chat_provider.dart';
import 'package:doctro/features/consultation/chat/providers/home_provider.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/features/shell/app_shell.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/features/profile/profile.dart';
import 'package:doctro/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:doctro/features/dashboard/patient_information.dart';
import 'package:doctro/features/notifications/notifications.dart';
import 'package:doctro/features/review/rate&review.dart';
import 'package:doctro/features/cashfree/payment.dart';
import 'package:doctro/features/errors/error_utility_screen.dart';
import 'package:doctro/features/search/search_screen.dart';

const MethodChannel _secureWindowChannel =
    MethodChannel('doctro/secure_window');

Future<void> main() async {
  // CRITICAL: Ensure Flutter binding is initialized FIRST and ONLY ONCE
  WidgetsFlutterBinding.ensureInitialized();

  // Local development convenience only. A release build must be configured
  // with --dart-define, so this is skipped there to avoid a pointless failed
  // asset load. `.env` is intentionally not bundled; see lib/core/config/env.dart.
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      debugPrint('Config: no .env found - using --dart-define values only.');
    }
  }

  // Initialize SharedPreferences with timeout to prevent blocking
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('SharedPreferences init timeout');
      },
    );
  } catch (e) {
    debugPrint("Prefs init failed: $e");
    prefs = await SharedPreferences.getInstance();
  }

  try {
    await SharedPreferenceHelper.initWithPreferences(prefs);
  } catch (e) {
    debugPrint("SharedPreferenceHelper init failed: $e");
  }

  // `settingRequest()` (GET /api/v1/setting) is a dead legacy endpoint - it
  // 404s against the live Astra backend, so it never populates
  // currency_symbol, and every "${getString(currency_symbol)}$amount" read
  // silently rendered the literal 'N_A' fallback (e.g. wallet balance shown
  // as "N_A0.00"). Seed a real default once so those reads degrade to the
  // app's actual currency instead of a debug sentinel; a future working
  // settingRequest() response still overwrites it via setString.
  if (SharedPreferenceHelper.getStringOrNull(Preferences.currency_symbol) ==
      null) {
    await SharedPreferenceHelper.setString(Preferences.currency_symbol, '₹');
  }

  if (!kIsWeb && Platform.isAndroid) {
    await SharedPreferenceHelper.setString(
        Preferences.device_platform, "Android");
  }

  // Initialize Hive for offline-first capabilities
  try {
    await Hive.initFlutter();
    await Hive.openBox('offlineCache');
  } catch (e) {
    debugPrint("Hive init failed: $e");
  }

  // Initialize Firebase ONLY, don't do anything else here
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw TimeoutException('Firebase init timeout');
    });

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  // Initialize Supabase if credentials exist
  final String supabaseUrl = Env.supabaseUrl;
  final String supabaseAnonKey = Env.supabaseAnonKey;

  // Report configuration gaps once, at startup, rather than letting every
  // caller discover them independently and fail quietly.
  final missing = Env.missingKeys();
  if (missing.isNotEmpty) {
    debugPrint('Config: missing ${missing.join(', ')}. '
        'Pass them with --dart-define (or --dart-define-from-file for local '
        'development). Features that need them are disabled until then.');
  }

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Supabase init timeout');
        },
      );
    } catch (e) {
      debugPrint("Supabase init failed: $e");
    }
  }

  // Subscribe to Firebase topic in background (non-blocking)
  try {
    FirebaseMessaging.instance
        .subscribeToTopic("all")
        .timeout(const Duration(seconds: 5))
        .catchError((e) {
      debugPrint("Firebase topic subscription failed: $e");
    });
  } catch (e) {
    debugPrint("Firebase topic subscription failed: $e");
  }

  // Finally, run the app with guaranteed non-null prefs
  runApp(MyApp(prefs: prefs));
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', 'High Importance Notifications',
    importance: Importance.max,
    showBadge: true,
    playSound: true,
    enableVibration: true);

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  Locale? _locale = const Locale('en', 'US');
  String messageImage = '';
  String messageName = '';
  String messageId = '';
  String userToken = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  String msgId = "";
  String msgName = "";
  String msgImage = "";
  String doctorToken = "";

  Future<void> _initializeApp() async {
    // Initialize local notifications
    await _initializeNotifications();

    // Setup Firebase messaging listeners
    _setupFirebaseMessagingListeners();

    // Request notification permissions
    if (!kIsWeb && Platform.isAndroid) {
      await Permission.notification.request();
    }

    // Handle initial message
    _handleInitialMessage();

    // Implement Screenshot Protection for Enterprise Compliance
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _secureWindowChannel.invokeMethod('enableFlagSecure');
      }
    } catch (_) {
      // Secure-window flag is Android-only polish; failure must not block startup.
    }
  }

  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  void _setupFirebaseMessagingListeners() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) => _handleForegroundMessage(message),
      onError: (error) {
        logger.e(error);
      },
      cancelOnError: false,
    );

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i("Notification tapped: ${message.data}");
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    logger.i(data);

    flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      data['title'] ?? 'Notification',
      data['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: "@mipmap/ic_launcher",
          importance: Importance.max,
          priority: Priority.high,
          actions: data['action_type'] == 'call_notification'
              ? <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    'accept_action',
                    'Accept',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    'decline_action',
                    'Decline',
                  ),
                ]
              : null,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _handleInitialMessage() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        try {
          final Map<String, dynamic> dataValue = message.data;
          msgImage = dataValue['doctorImage']?.toString() ?? '';
          msgName = dataValue['doctorName']?.toString() ?? '';
          msgId = dataValue['doctorId']?.toString() ?? '';
          doctorToken = dataValue['doctorToken']?.toString() ?? '';

          if (msgId.isEmpty) {
            return;
          }

          if (mounted &&
              SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) ==
                  true) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => ChatPage(
                peerId: msgId,
                peerAvatar: msgImage,
                peerNickname: msgName,
                token: doctorToken,
                isNavigate: "",
              ),
            ));
          }
        } catch (e) {
          logger.e(e);
        }
      }
    }).catchError((e) {
      logger.e(e);
    });

    // Setup notification response listener
    NotificationHandler.notificationResponse.addListener(() {
      final response = NotificationHandler.notificationResponse.value;
      if (response != null && mounted) {
        _processNotificationResponse(response);
        NotificationHandler.notificationResponse.value = null;
      }
    });
  }

  void _processNotificationResponse(NotificationResponse payload) async {
    final actionId = payload.actionId;
    logger.i("Notification action: $actionId");
  }

  Future<void> onSelectNotification(NotificationResponse payload) async {
    if (payload.payload == null) return;
    NotificationHandler.handle(payload);
  }

  Future<BaseModel<Setting>> settingRequest() async {
    Setting response;
    try {
      response = await RestClient(RetroApi2().dioData2()).settingRequest();
      if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
        if (response.data!.currencySymbol != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_symbol, response.data!.currencySymbol!);
        }
        if (response.data!.currencyCode != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_code, response.data!.currencyCode!);
        }
        if (response.data!.doctorAppId != null) {
          SharedPreferenceHelper.setString(
              Preferences.doctorAppId, response.data!.doctorAppId!);
          if (mounted) setState(() {});
        }
      }
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  /// Resolves the persisted interface language.
  ///
  /// Never throws: an exception here would escape an unawaited future, so keep
  /// the failure contained and leave the default locale in place.
  Future<void> _loadLocale() async {
    try {
      final local = await getLocale();
      if (!mounted) return;
      setState(() => _locale = local);
    } catch (e) {
      // _locale already defaults to en_US, which is a valid state; leaving it
      // alone is better than replacing the app with an empty widget.
      debugPrint('Config: could not resolve saved locale, using default: $e');
    }
  }

  @override
  void didChangeDependencies() {
    _loadLocale();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive: _locale is non-null from the start, but this branch must never
    // be a bare SizedBox. It has no Material or Directionality ancestor, so
    // such a subtree has no background to paint and shows as a blank screen.
    if (_locale == null) {
      return const ColoredBox(
        color: Color(0xFFE9EEE4),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ChangeNotifierProvider<OverlayHandlerProvider>(
          create: (_) => OverlayHandlerProvider(),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<provider.AuthProvider>(
                create: (_) => provider.AuthProvider(
                  firebaseAuth: FirebaseAuth.instance,
                  prefs: widget.prefs,
                  firebaseFirestore: firebaseFirestore,
                ),
              ),
              Provider<HomeProvider>(
                create: (_) =>
                    HomeProvider(firebaseFirestore: firebaseFirestore),
              ),
              Provider<ChatProvider>(
                create: (_) => ChatProvider(
                  prefs: widget.prefs,
                  firebaseFirestore: firebaseFirestore,
                  firebaseStorage: firebaseStorage,
                ),
              ),
              ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(),
              ),
            ],
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SessionTimeoutHandler(
                  timeout: const Duration(minutes: 15),
                  onTimeout: () {
                    SharedPreferenceHelper.clearPref();
                    if (mounted && navigatorKey.currentState != null) {
                      navigatorKey.currentState!
                          .pushNamedAndRemoveUntil('SignIn', (route) => false);
                    }
                  },
                  child: MaterialApp(
                    themeMode: themeProvider.isDarkMode
                        ? ThemeMode.dark
                        : ThemeMode.light,
                    navigatorKey: navigatorKey,
                    title: "Ayureze",
                    debugShowCheckedModeBanner: false,
                    theme: AyurezeTheme.lightTheme(),
                    darkTheme: AyurezeTheme.darkTheme(),
                    themeAnimationDuration: const Duration(milliseconds: 300),
                    themeAnimationCurve: Curves.easeInOut,
                    home: const StartupGate(),
                    locale: _locale,
                    supportedLocales: supportedLocales,
                    localizationsDelegates: const [
                      LanguageLocalization.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    localeResolutionCallback: (deviceLocal, supportedLocales) {
                      for (var local in supportedLocales) {
                        if (deviceLocal != null &&
                            local.languageCode == deviceLocal.languageCode &&
                            local.countryCode == deviceLocal.countryCode) {
                          return deviceLocal;
                        }
                      }
                      return supportedLocales.first;
                    },
                    routes: {
                      'SignIn': (context) => SignIn(),
                      'signup': (context) => CreateAccount(),
                      'ForgotPasswordScreen': (context) =>
                          ForgotPasswordScreen(),
                      'phoneverification': (context) =>
                          PhoneVerificationScreen(),
                      'loginHome': (context) => const AppShell(),
                      'patientInformation': (context) => PatientDetailsScreen(),
                      'cancelAppoitmentRoutes': (context) =>
                          CancelAppointmentScreen(),
                      'AppointmentHistoryScreen': (context) =>
                          AppointmentHistory(),
                      'rateAndReviewRoutes': (context) =>
                          RateAndReviewRoutesScreen(),
                      'notifications': (context) => NotificationsScreen(),
                      'profile': (context) => ProfileScreen(),
                      'Schedule Timings': (context) => ScheduleTimings(),
                      'Change Password': (context) => ChangePassword(),
                      'Change Language': (context) => ChangeLanguage(),
                      'ViewAllNotification': (context) => ViewAllNotification(),
                      'VideoCallHistory': (context) => VideoCallHistory(),
                      'Settings': (context) => SettingScreen(),
                      'ChatHome': (context) => HomePage(),
                      'payment': (context) => PaymentScreen(),
                      'noInternet': (context) => const ErrorUtilityScreen(
                          kind: ErrorUtilityKind.noInternet),
                      'internalError': (context) => const ErrorUtilityScreen(
                          kind: ErrorUtilityKind.internalError),
                      'maintenance': (context) => const ErrorUtilityScreen(
                          kind: ErrorUtilityKind.maintenance),
                      'notAllowed': (context) => const ErrorUtilityScreen(
                          kind: ErrorUtilityKind.notAllowed),
                      'search': (context) => const SearchScreen(),
                      ReviewQueueScreen.routeName: (context) =>
                          const ReviewQueueScreen(),
                    },
                    onUnknownRoute: (settings) => MaterialPageRoute(
                      builder: (context) => const ErrorUtilityScreen(
                          kind: ErrorUtilityKind.notFound),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    NotificationHandler.notificationResponse.dispose();
    super.dispose();
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationHandler.notificationResponse.value = response;
}
