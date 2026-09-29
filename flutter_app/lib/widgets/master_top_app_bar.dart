import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../screens/account_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// Unified Master Top App Bar for MOTORO.
/// Features:
/// - Brand logo with Outfit typography (clean, modern, no Bharat badge).
/// - Responsive vehicle switcher dropdown pill with live telemetry status dot.
/// - Profile avatar (VS) leading to AccountScreen.
/// - Logout icon button leading to LoginScreen.
/// - Auto-aligned for smartphone screens with zero overflow.
class MasterTopAppBar extends StatelessWidget {
  final VehicleItem? currentVehicle;
  final List<VehicleItem> vehicles;
  final ValueChanged<VehicleItem>? onVehicleChanged;
  final VoidCallback? onLogoTap;

  const MasterTopAppBar({
    super.key,
    this.currentVehicle,
    this.vehicles = const [],
    this.onVehicleChanged,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Brand Logo & Title (without Bharat badge)
            InkWell(
              onTap: onLogoTap ??
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(initialVin: currentVehicle?.vin),
                      ),
                    );
                  },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.toll_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MOTORO',
                    style: AppTypography.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Profile Avatar & Logout
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Avatar (VS)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'VS',
                        style: AppTypography.heading(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Logout Icon Button
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
