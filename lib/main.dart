// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:aplikasi_keuangan/shared/bottom_sheets/quick_transaction_sheet.dart';
import 'package:aplikasi_keuangan/shared/bottom_sheets/quick_add_wizard_screen.dart';

// 🚀 IMPORT UTILS & CONFIG
import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/core/theme/app_theme.dart';
import 'package:aplikasi_keuangan/services/notification_service.dart';

// 🚀 IMPORT LAYOUT & SCREENS
import 'package:aplikasi_keuangan/shared/layouts/main_layout.dart'; 
import 'package:aplikasi_keuangan/screens/dashboard/dashboard_screen.dart';
import 'package:aplikasi_keuangan/screens/report/report_hub_screen.dart';
import 'package:aplikasi_keuangan/screens/settings/settings_hub_screen.dart'; 
import 'package:aplikasi_keuangan/screens/dashboard/budget/budget_tracker_screen.dart';
import 'package:aplikasi_keuangan/screens/transaction/transaction_form_screen.dart';

// 🟢 FIX: Pastikan nama file dan class konsisten. 
// Kalau filenya login_screen.dart, pastikan class-nya LoginScreen atau LockScreen
import 'package:aplikasi_keuangan/screens/auth/login_screen.dart'; 

// 🚀 IMPORT FITUR KHUSUS
import 'package:aplikasi_keuangan/screens/dashboard/calculator/calculator_hub_screen.dart'; 
import 'package:aplikasi_keuangan/screens/dashboard/debt/debt_tracker_screen.dart'; 
import 'package:aplikasi_keuangan/screens/dashboard/reminder/reminder_hub_screen.dart'; 
import 'package:aplikasi_keuangan/screens/dashboard/savings/savings_tracker_screen.dart'; 
import 'package:aplikasi_keuangan/screens/dashboard/voice_assistant_screen.dart';
import 'package:aplikasi_keuangan/screens/dashboard/wallets/manage_wallets_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); 
  
  // 🚀 Pre-warm SharedPreferences agar isSecurityMounted jadi 0 milidetik
  await SharedPreferences.getInstance();

  // 🚀 Jangan di-await agar tidak memblokir startup screen!
  NotificationService().init();
  NotificationService().requestPermissions();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()..initData()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleLink(initialUri);
    } catch (e) {
      debugPrint("DeepLink Error: $e");
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'duittracker' && uri.host == 'quick_add') {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (navigatorKey.currentContext != null) {
          QuickTransactionSheet.show(navigatorKey.currentContext!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Duit Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: finance.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light().copyWith(scaffoldBackgroundColor: finance.themeBg),
          darkTheme: AppTheme.darkTheme.copyWith(scaffoldBackgroundColor: finance.themeBg),
          home: Scaffold(
            backgroundColor: finance.isDarkMode ? Colors.black : Colors.grey[200], 
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                // 🟢 SESUAIKAN: Panggil nama class yang bener ada di login_screen.dart
                // Kalau class di login_screen.dart namanya LockScreen, pake LockScreen()
                child: const LockScreen(), 
              ),
            ),
          ), 
        );
      }
    );
  }
}

// 🟢 MAIN APP SHELL
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> with WidgetsBindingObserver {
  int _currentScreenIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🚀 Reload data dari memori saat user balik dari Widget / Background
      final finance = Provider.of<FinanceProvider>(context, listen: false);
      finance.reloadDataFromStorage();
    }
  }

  void _handleNavigation(dynamic destination) {
    HapticFeedback.lightImpact();

    if (destination is int) {
      setState(() => _currentScreenIndex = destination);
    } else if (destination is String) {
      if (destination.toLowerCase() == 'report') {
        setState(() => _currentScreenIndex = 2);
        return;
      }

      Widget screenToPush;
      switch (destination.toLowerCase()) { 
        case 'calculator': screenToPush = const CalculatorScreen(); break;
        case 'savings': screenToPush = const SavingsScreen(); break;
        case 'debt': screenToPush = const DebtTrackerScreen(); break;
        case 'reminders': screenToPush = const ReminderScreen(); break;
        case 'wallets': ManageWalletsSheet.show(context); return; 
        default: return; 
      }
      Navigator.push(context, MaterialPageRoute(builder: (context) => screenToPush));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    
    switch (_currentScreenIndex) {
      case 0: currentScreen = DashboardScreen(onNavigate: _handleNavigation); break;
      case 1: currentScreen = const BudgetTrackerScreen(); break;
      case 2: currentScreen = const ReportHubScreen(); break;
      case 3: currentScreen = const SettingsScreen(); break;
      default: currentScreen = DashboardScreen(onNavigate: _handleNavigation);
    }

    return MainLayout(
      currentIndex: _currentScreenIndex,
      onNavigate: _handleNavigation,
      onQuickAdd: () {
        HapticFeedback.lightImpact(); 
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionFormScreen()));
      },
      onVoiceAdd: () => VoiceAssistantSheet.show(context),
      child: currentScreen,
    );
  }
}

// ==========================================
// 🚀 SECONDARY ENTRYPOINT UNTUK OVERLAY WIDGET
// ==========================================
@pragma('vm:entry-point')
void quickAddMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); 
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()..initData()),
      ],
      child: const QuickAddOverlayApp(),
    ),
  );
}

class QuickAddOverlayApp extends StatelessWidget {
  const QuickAddOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: finance.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.transparent),
          darkTheme: AppTheme.darkTheme.copyWith(scaffoldBackgroundColor: Colors.transparent),
          home: const QuickAddWizardScreen(),
        );
      }
    );
  }
}