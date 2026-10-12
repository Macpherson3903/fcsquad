import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'my_squad_screen.dart';
import 'generate_screen.dart';
import 'vault_history_screen.dart';
import '../providers/storage_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';
import '../utils/platform_ui.dart';
import '../services/onboarding_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shell widget that hosts the three main tabs.
///
/// Uses an [IndexedStack] so all screens remain alive in memory — this keeps
/// scroll positions and state intact when switching tabs.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  DateTime? _lastBackPressTime;
  bool _onboardingScheduled = false;

  final List<Widget> _screens = [
    const MySquadScreen(),
    const GenerateScreen(),
    const VaultHistoryScreen(),
  ];


  Widget _icon(IconData material, IconData cupertino) {
    return PlatformUi.platformIcon(material, cupertino);
  }

  @override
  Widget build(BuildContext context) {
    final storageStatus = ref.watch(storageInitializerProvider);

    if (storageStatus.isLoading) {
      return PlatformScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              PlatformProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'PREPARING SQUAD...',
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (storageStatus.hasError) {
      return PlatformScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlatformUi.platformIcon(
                  Icons.error_outline,
                  CupertinoIcons.exclamationmark_circle,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'STORAGE ERROR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${storageStatus.error}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PlatformUi.isCupertino
                    ? CupertinoButton.filled(
                        onPressed: () =>
                            ref.invalidate(storageInitializerProvider),
                        child: const Text('RETRY'),
                      )
                    : ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(storageInitializerProvider),
                        child: const Text('RETRY'),
                      ),
              ],
            ),
          ),
        ),
      );
    }

    final currentIndex = ref.watch(navigationProvider);
    if (!_onboardingScheduled) {
      _onboardingScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        OnboardingService.maybeShowOnboarding(context);
      });
    }
    final shell = Column(
      children: [
        Expanded(child: IndexedStack(index: currentIndex, children: _screens)),
        _buildTabBar(currentIndex),
      ],
    );

    if (PlatformUi.isCupertino) {
      return Material(type: MaterialType.transparency, child: shell);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBackProgress,
      child: Scaffold(body: shell),
    );
  }

  Widget _buildTabBar(int currentIndex) {
    void onTap(int index) =>
        ref.read(navigationProvider.notifier).setTab(index);

    if (PlatformUi.isCupertino) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: AppColors.backgroundDark,
        activeColor: AppColors.primaryYellow,
        inactiveColor: AppColors.textGray,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              key: OnboardingService.squadNavKey,
              child: _icon(Icons.people_alt_outlined, CupertinoIcons.person_2),
            ),
            activeIcon: _icon(Icons.people, CupertinoIcons.person_2_fill),
            label: 'MY SQUAD',
          ),
          BottomNavigationBarItem(
            icon: Container(
              key: OnboardingService.generateNavKey,
              child: _icon(Icons.bolt_outlined, CupertinoIcons.bolt),
            ),
            activeIcon: _icon(Icons.bolt, CupertinoIcons.bolt_fill),
            label: 'GENERATE',
          ),
          BottomNavigationBarItem(
            icon: Container(
              key: OnboardingService.statsNavKey,
              child: _icon(Icons.archive_outlined, CupertinoIcons.archivebox),
            ),
            activeIcon: _icon(Icons.archive, CupertinoIcons.archivebox_fill),
            label: 'STATS',
          ),
        ],
      );
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: Container(
            key: OnboardingService.squadNavKey,
            child: _icon(Icons.people_alt_outlined, CupertinoIcons.person_2),
          ),
          activeIcon: _icon(Icons.people, CupertinoIcons.person_2_fill),
          label: 'MY SQUAD',
        ),
        BottomNavigationBarItem(
          icon: Container(
            key: OnboardingService.generateNavKey,
            child: _icon(Icons.bolt_outlined, CupertinoIcons.bolt),
          ),
          activeIcon: _icon(Icons.bolt, CupertinoIcons.bolt_fill),
          label: 'GENERATE',
        ),
        BottomNavigationBarItem(
          icon: Container(
            key: OnboardingService.statsNavKey,
            child: _icon(Icons.archive_outlined, CupertinoIcons.archivebox),
          ),
          activeIcon: _icon(Icons.archive, CupertinoIcons.archivebox_fill),
          label: 'STATS',
        ),
      ],
    );
  }

  void _handleBackProgress(bool didPop, dynamic result) {
    if (didPop || PlatformUi.isCupertino) return;

    final now = DateTime.now();
    final backButtonHasNotBeenPressedRecently =
        _lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedRecently) {
      _lastBackPressTime = now;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'PRESS BACK AGAIN TO EXIT',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          backgroundColor: Color(0xFF1E88E5),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }
}
