import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../screens/garage_screen.dart';
import '../screens/service_screen.dart';
import '../screens/telemetry_screen.dart';
import '../screens/fuel_odo_screen.dart';
import '../screens/fasttag_screen.dart';
import '../screens/qr_contact_screen.dart';

/// Motoro Unified Floating Icon-Only Navigation Dock.
class FloatingTopNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final VehicleItem? currentVehicle;
  final bool hasServiceAlert;

  const FloatingTopNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
    this.currentVehicle,
    this.hasServiceAlert = false,
  });

  static const List<_NavTabItem> _tabs = [
    _NavTabItem(
      icon: Icons.directions_car_filled_rounded,
      tooltip: 'Fleet Garage',
      semanticsLabel: 'Garage Screen',
    ),
    _NavTabItem(
      icon: Icons.build_circle_rounded,
      tooltip: 'Service & Maintenance',
      semanticsLabel: 'Services Screen',
      hasAlertBadge: true,
    ),
    _NavTabItem(
      icon: Icons.speed_rounded,
      tooltip: 'IC Engine ECU Telemetry',
      semanticsLabel: 'Telemetry Screen',
    ),
    _NavTabItem(
      icon: Icons.local_gas_station_rounded,
      tooltip: 'Fuel & Odometer Log',
      semanticsLabel: 'Fuel and Odometer Screen',
    ),
    _NavTabItem(
      icon: Icons.toll_rounded,
      tooltip: 'FASTag Toll Wallet',
      semanticsLabel: 'FastTag Screen',
    ),
    _NavTabItem(
      icon: Icons.qr_code_scanner_rounded,
      tooltip: 'Smart Vehicle QR Tag',
      semanticsLabel: 'QR Contact Tag Screen',
    ),
  ];

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    Widget destination;
    switch (index) {
      case 0:
        destination = GarageScreen(initialVehicle: currentVehicle);
        break;
      case 1:
        destination = ServiceScreen(initialVehicle: currentVehicle);
        break;
      case 2:
        destination = TelemetryScreen(initialVehicle: currentVehicle);
        break;
      case 3:
        destination = FuelOdoScreen(initialVehicle: currentVehicle);
        break;
      case 4:
        destination = FastTagScreen(initialVehicle: currentVehicle);
        break;
      case 5:
        destination = QrContactScreen(initialVehicle: currentVehicle);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double dockHeight = 52.0;
    const double pillHeight = 40.0;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: dockHeight,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 1.5,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double totalWidth = constraints.maxWidth;
                  final double slotWidth = totalWidth / _tabs.length;
                  final double pillWidth = math.min(slotWidth - 8.0, 56.0);
                  final double leftOffset =
                      (currentIndex * slotWidth) + ((slotWidth - pillWidth) / 2.0);

                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Smooth Animated Sliding Active Pill
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        left: leftOffset,
                        top: (constraints.maxHeight - pillHeight) / 2.0,
                        width: pillWidth,
                        height: pillHeight,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: AppColors.electric.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.38),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: AppColors.electric.withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            // Automotive HUD telemetry glowing pip matching Fuel & Odo screen
                            Positioned(
                              bottom: 3.5,
                              child: Container(
                                width: 12,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: AppColors.electric,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.electric.withValues(alpha: 0.9),
                                      blurRadius: 5,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Interactive Icon Buttons Row
                      Row(
                        children: List.generate(_tabs.length, (index) {
                          final tab = _tabs[index];
                          final isSelected = index == currentIndex;

                          return Expanded(
                            child: Tooltip(
                              message: tab.tooltip,
                              waitDuration: const Duration(milliseconds: 350),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.onSurface.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Semantics(
                                label: tab.semanticsLabel,
                                selected: isSelected,
                                button: true,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _handleTap(context, index),
                                    borderRadius: BorderRadius.circular(22),
                                    splashColor: AppColors.primary.withValues(alpha: 0.15),
                                    highlightColor: Colors.transparent,
                                    child: Center(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          AnimatedScale(
                                            scale: isSelected ? 1.08 : 1.0,
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOutBack,
                                            child: Icon(
                                              tab.icon,
                                              size: isSelected ? 21 : 19,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.secondary,
                                            ),
                                          ),

                                          // Alert Badge indicator
                                          if (tab.hasAlertBadge &&
                                              hasServiceAlert &&
                                              !isSelected)
                                            Positioned(
                                              top: -3,
                                              right: -4,
                                              child: Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: AppColors.error,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.error
                                                          .withValues(alpha: 0.4),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem {
  final IconData icon;
  final String tooltip;
  final String semanticsLabel;
  final bool hasAlertBadge;

  const _NavTabItem({
    required this.icon,
    required this.tooltip,
    required this.semanticsLabel,
    this.hasAlertBadge = false,
  });
}
