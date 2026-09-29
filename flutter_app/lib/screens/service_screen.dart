import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_top_nav_bar.dart';
import '../widgets/master_top_app_bar.dart';
import 'payment_gateway_screen.dart';

/// MOTORO Connected Vehicle Fleet & Service Maintenance Hub.
/// Redesigned using UI/UX Pro Max automotive HUD design principles:
/// - Strictly preserves the authentic brand color scheme (Cyan-Teal, Mint, Deep Charcoal).
/// - Professional modular typography pairing (Outfit geometric display + Plus Jakarta Sans + JetBrains Mono).
/// - 44px+ touch targets with fluid spacing and zero horizontal overflow.
/// - Live telemetry diagnostics, interactive canvas service radar, and multi-service scheduling bottom sheet.
class ServiceScreen extends StatefulWidget {
  final VehicleItem? initialVehicle;

  const ServiceScreen({super.key, this.initialVehicle});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> with SingleTickerProviderStateMixin {
  VehicleItem? _vehicle;
  List<VehicleItem> _allVehicles = [];
  bool _isLoading = true;
  String _selectedBrandFilter = 'Mahindra';
  String _currentGpsCity = 'Kozhikode Hub (11.2588° N, 75.7804° E)';
  bool _isGpsRefreshing = false;

  // Pulse animation controller for radar / diagnostic status
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Curated OEM Service Catalog
  final List<Map<String, dynamic>> _recommendedServices = [
    {
      'id': 'oil',
      'title': 'Synthetic Oil & Filter',
      'subtitle': '5W-40 Synthetic • OEM Filter',
      'badge': 'Scheduled',
      'badgeColor': AppColors.primary,
      'duration': '45m',
      'cost': 2850.0,
      'icon': Icons.oil_barrel_rounded,
      'minutes': 45,
    },
    {
      'id': 'brakes',
      'title': 'Brake Pads & Calibration',
      'subtitle': 'Ceramic Friction • Sensor Check',
      'badge': 'Due Soon',
      'badgeColor': AppColors.error,
      'duration': '60m',
      'cost': 1850.0,
      'icon': Icons.disc_full_rounded,
      'minutes': 60,
    },
    {
      'id': 'alignment',
      'title': '3D Alignment & Balancing',
      'subtitle': 'Laser Camber • Dynamic Balance',
      'badge': 'Routine',
      'badgeColor': AppColors.secondary,
      'duration': '30m',
      'cost': 950.0,
      'icon': Icons.tire_repair_rounded,
      'minutes': 30,
    },
    {
      'id': 'filter',
      'title': 'Cabin Air Microfilter',
      'subtitle': 'PM2.5 Activated Carbon • AC Ozone',
      'badge': 'Routine',
      'badgeColor': AppColors.secondary,
      'duration': '20m',
      'cost': 750.0,
      'icon': Icons.air_rounded,
      'minutes': 20,
    },
    {
      'id': 'diag',
      'title': '52-Point OBD Scan',
      'subtitle': 'Full ECU & Drivetrain Diagnostic',
      'badge': 'Care+',
      'badgeColor': AppColors.primaryContainer,
      'duration': '45m',
      'cost': 1200.0,
      'icon': Icons.troubleshoot_rounded,
      'minutes': 45,
    },
  ];

  // Authorized OEM & Certified Service Stations
  final List<Map<String, dynamic>> _serviceCenters = [
    {
      'name': 'Pothens Mahindra Hub',
      'brand': 'Mahindra',
      'distance': '1.4 km',
      'location': 'Thondayad, Kozhikode',
      'rating': 4.9,
      'reviews': 428,
      'bays': 6,
      'phone': '+91 495 243 8900',
      'isOpen': true,
      'features': 'OEM Parts • 24/7 Roadside',
    },
    {
      'name': 'ITL Motors Mahindra Station',
      'brand': 'Mahindra',
      'distance': '2.9 km',
      'location': 'Mini Bypass, Kozhikode',
      'rating': 4.8,
      'reviews': 312,
      'bays': 4,
      'phone': '+91 495 274 1122',
      'isOpen': true,
      'features': 'Master Techs • Quick Lube',
    },
    {
      'name': 'Malayalam Tata & EV Hub',
      'brand': 'Tata',
      'distance': '1.8 km',
      'location': 'Arayidathupalam, Kozhikode',
      'rating': 4.9,
      'reviews': 512,
      'bays': 8,
      'phone': '+91 495 890 1234',
      'isOpen': true,
      'features': '60kW EV Fast Charger',
    },
    {
      'name': 'Marina Motors Tata Workshop',
      'brand': 'Tata',
      'distance': '3.4 km',
      'location': 'Eranhipalam, Kozhikode',
      'rating': 4.7,
      'reviews': 280,
      'bays': 5,
      'phone': '+91 495 276 4400',
      'isOpen': true,
      'features': 'Express Bay • Body Shop',
    },
    {
      'name': 'MOTORO Multi-Brand Hub',
      'brand': 'All',
      'distance': '5.2 km',
      'location': 'Palazhi, Kerala',
      'rating': 4.9,
      'reviews': 650,
      'bays': 8,
      'phone': '+91 495 332 9900',
      'isOpen': true,
      'features': 'All Fleets • EV Scan',
    },
  ];

  // Official Service History Records
  final List<Map<String, dynamic>> _serviceHistory = [
    {
      'date': 'OCT 15, 2025',
      'badge': 'Certified',
      'badgeColor': AppColors.success,
      'odometer': '10,240 km',
      'title': '10,000 km Inspection',
      'subtitle': 'Pothens Mahindra Hub',
      'code': 'SRV-88219',
      'details': '52/52 Safety Points Passed',
      'cost': '₹4,850',
    },
    {
      'date': 'JUL 22, 2025',
      'badge': 'Alignment',
      'badgeColor': AppColors.primary,
      'odometer': '7,890 km',
      'title': 'Wheel Alignment & Balance',
      'subtitle': 'MOTORO Downtown Hub',
      'code': 'SRV-77142',
      'details': 'Laser Calibrated <0.02°',
      'cost': '₹1,200',
    },
    {
      'date': 'MAR 10, 2025',
      'badge': 'Delivery',
      'badgeColor': AppColors.secondary,
      'odometer': '25 km',
      'title': 'Factory Handover & PDI',
      'subtitle': 'Pre-Delivery Certified',
      'code': 'SRV-60012',
      'details': 'PDI Master Tech Approved',
      'cost': '₹0 (Warranty)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _vehicle = widget.initialVehicle;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadVehicles();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    final vehicles = await ApiService.getVehicles();
    if (mounted) {
      setState(() {
        _allVehicles = vehicles;
        if (_vehicle == null && vehicles.isNotEmpty) {
          _vehicle = vehicles.firstWhere(
            (v) => v.isSelected,
            orElse: () => vehicles.first,
          );
        } else if (_vehicle != null) {
          _vehicle = vehicles.firstWhere(
            (v) => v.vin == _vehicle!.vin,
            orElse: () => _vehicle!,
          );
        }
        if (_vehicle?.name.toLowerCase().contains('tata') == true) {
          _selectedBrandFilter = 'Tata';
        } else {
          _selectedBrandFilter = 'Mahindra';
        }
        _isLoading = false;
      });
    }
  }

  void _switchVehicle(VehicleItem v) {
    setState(() {
      _vehicle = v;
      if (v.name.toLowerCase().contains('tata')) {
        _selectedBrandFilter = 'Tata';
      } else {
        _selectedBrandFilter = 'Mahindra';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Switched telemetry to ${v.name} (${v.registrationPlate})',
                style: AppTypography.body(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _refreshGpsLocation() async {
    setState(() => _isGpsRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() {
        _isGpsRefreshing = false;
        _currentGpsCity = 'Kozhikode, Kerala (11.2588° N, 75.7804° E)';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'GPS Precision Locked: Kozhikode Hub (±3m)',
                style: AppTypography.body(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _openBookingModal({String? preselectedServiceTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ServiceBookingBottomSheet(
        vehicle: _vehicle ??
            VehicleItem(
              vin: 'MH12RN2024',
              name: 'Mahindra XUV700 AX7 L',
              edition: 'Diesel mHawk 2.2L • AX7 AWD',
              typeLabel: 'SUV',
              status: 'Optimal',
              isOnline: true,
              fuelLevelPercent: 75.0,
              fuelCapacityLitres: 60.0,
              rangeKm: 580,
              odometerKm: 12450,
              locationName: 'Kozhikode, Kerala',
              imageUrl: '',
              isSelected: true,
              registrationPlate: 'MH 12 RN 2024',
            ),
        allServices: _recommendedServices,
        serviceCenters: _serviceCenters,
        preselectedServiceTitle: preselectedServiceTitle,
        onBookingConfirmed: (ticketData) {
          _showBookingConfirmedDialog(ticketData);
        },
      ),
    );
  }

  void _showBookingConfirmedDialog(Map<String, dynamic> ticketData) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Appointment Confirmed',
                style: AppTypography.heading(fontSize: 21, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Your digital OEM service pass is activated',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(fontSize: 12),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pass Identifier',
                          style: AppTypography.tag(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticketData['code'] ?? 'SRV-77189',
                            style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    _buildTicketRow('Vehicle', ticketData['vehicleName'] ?? 'Mahindra XUV700'),
                    const SizedBox(height: 8),
                    _buildTicketRow('Reserved Slot', '${ticketData['date']} • ${ticketData['time']}'),
                    const SizedBox(height: 8),
                    _buildTicketRow('Service Hub', ticketData['center'] ?? 'Pothens Mahindra Hub'),
                    const SizedBox(height: 8),
                    _buildTicketRow('Estimate', ticketData['price'] ?? '₹4,700 (Care+ Included)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    'Done & Add to Calendar',
                    style: AppTypography.subheading(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(fontSize: 11.5)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.subheading(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicle;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Decorative Mesh
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixedDim.withValues(alpha: 0.16),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electric.withValues(alpha: 0.14),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main View Layout
          SafeArea(
            child: Column(
              children: [
                MasterTopAppBar(
                  currentVehicle: vehicle,
                  vehicles: _allVehicles,
                  onVehicleChanged: _switchVehicle,
                ),
                _buildSecondaryNavDock(),
                Expanded(
                  child: _isLoading || vehicle == null
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadVehicles,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 980),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDiagnosticsStatusBanner(vehicle),
                                    const SizedBox(height: 20),
                                    _buildHeaderAndBookHero(),
                                    const SizedBox(height: 22),
                                    _buildServiceCentersSection(),
                                    const SizedBox(height: 26),
                                    _buildRecommendedAndHistoryGrid(),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Unified Floating Dock
  Widget _buildSecondaryNavDock() {
    return FloatingTopNavBar(
      currentIndex: 1, // Services tab
      currentVehicle: _vehicle,
    );
  }

  // 2. Telemetry Diagnostics Status Banner
  Widget _buildDiagnosticsStatusBanner(VehicleItem vehicle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Vehicle Health Diagnostics',
                            style: AppTypography.heading(fontSize: 16, letterSpacing: -0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '96% Optimal',
                                style: AppTypography.label(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol(Icons.speed_rounded, 'ODOMETER', '${vehicle.odometerKm}', 'km', AppColors.onSurface),
                Container(width: 1, height: 28, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                _buildMetricCol(Icons.local_gas_station_rounded, 'FUEL', '${vehicle.fuelLevelPercent.toInt()}%', '(${vehicle.fuelCapacityLitres.toInt()}L)', AppColors.primary),
                Container(width: 1, height: 28, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                _buildMetricCol(Icons.build_circle_rounded, 'DUE IN', '480', 'km', AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMetricCol(IconData icon, String label, String value, String unit, Color valColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: valColor.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.tag(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTypography.stat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: valColor,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: AppTypography.bodySmall(fontSize: 10.5, color: AppColors.outline),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 3. Section Header & Direct Service CTA
  Widget _buildHeaderAndBookHero() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service & Maintenance',
                style: AppTypography.display(fontSize: 22, letterSpacing: -0.6),
              )
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _openBookingModal(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
          ),
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: Text(
            'Book Service',
            style: AppTypography.subheading(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // 4. Authorized Service Centers with Brand Filters & Interactive Canvas Map
  Widget _buildServiceCentersSection() {
    final filteredCenters = _serviceCenters.where((c) {
      if (_selectedBrandFilter == 'ALL') return true;
      if (_selectedBrandFilter == 'Mahindra') return c['brand'] == 'Mahindra' || c['brand'] == 'All';
      if (_selectedBrandFilter == 'Tata') return c['brand'] == 'Tata' || c['brand'] == 'All';
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & GPS Trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Authorized Centers',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.heading(fontSize: 15, letterSpacing: -0.3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _selectedBrandFilter == 'ALL'
                                      ? 'ALL FLEETS'
                                      : '$_selectedBrandFilter OEM',
                                  style: AppTypography.tag(color: Colors.white, fontSize: 8.5),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // GPS Refresh Trigger
              InkWell(
                onTap: _refreshGpsLocation,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isGpsRefreshing ? 'Locking...' : 'GPS Active',
                        style: AppTypography.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.refresh_rounded,
                        size: 13,
                        color: _isGpsRefreshing ? AppColors.primary : AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stylized Interactive Visual Map Canvas
          Container(
            height: 165,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Vector Map Canvas Painter
                CustomPaint(
                  size: const Size(double.infinity, 165),
                  painter: _ServiceMapCanvasPainter(),
                ),

                // Floating Brand Filter Switcher
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['ALL', 'Mahindra', 'Tata'].map((brand) {
                        final isSel = _selectedBrandFilter == brand;
                        return InkWell(
                          onTap: () => setState(() => _selectedBrandFilter = brand),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              brand == 'Tata' ? 'Tata EV' : brand,
                              style: AppTypography.label(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.secondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Coordinates Status Tag
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location_rounded, size: 12, color: AppColors.primaryFixed),
                        const SizedBox(width: 5),
                        Text(
                          _currentGpsCity,
                          style: AppTypography.mono(fontSize: 10, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Horizontal Carousel of Service Center Cards
          SizedBox(
            height: 155,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filteredCenters.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
              itemBuilder: (ctx, idx) {
                final center = filteredCenters[idx];
                return _buildCenterCard(center);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterCard(Map<String, dynamic> center) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      center['distance'] as String,
                      style: AppTypography.mono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xFFEAB308)),
                      const SizedBox(width: 3),
                      Text(
                        '${center['rating']} (${center['reviews']})',
                        style: AppTypography.subheading(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                center['name'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.heading(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${center['bays']} Bays Active',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => _openBookingModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(60, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Select Bay',
                  style: AppTypography.label(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Two-Column Layout: Recommended Maintenance & Service Records Timeline
  Widget _buildRecommendedAndHistoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildRecommendedServicesColumn(),
              ),
              const SizedBox(width: 22),
              Expanded(
                flex: 6,
                child: _buildServiceRecordsTimelineColumn(),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecommendedServicesColumn(),
              const SizedBox(height: 28),
              _buildServiceRecordsTimelineColumn(),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecommendedServicesColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.build_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Recommended Services',
                  style: AppTypography.heading(fontSize: 16, letterSpacing: -0.3),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '3 Due',
                style: AppTypography.label(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recommendedServices.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final s = _recommendedServices[idx];
            return _buildServiceActionCard(s);
          },
        ),
      ],
    );
  }

  Widget _buildServiceActionCard(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (s['badgeColor'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s['icon'] as IconData, color: s['badgeColor'] as Color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s['title'] as String,
                            style: AppTypography.subheading(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (s['badgeColor'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s['badge'] as String,
                            style: AppTypography.label(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: s['badgeColor'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.25))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${(s['cost'] as double).toInt()} ',
                      style: AppTypography.stat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '· ${s['duration']}',
                      style: AppTypography.bodySmall(fontSize: 10.5),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _openBookingModal(preselectedServiceTitle: s['title'] as String),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Book',
                          style: AppTypography.label(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRecordsTimelineColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Service Records History',
              style: AppTypography.heading(fontSize: 16, letterSpacing: -0.3),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _serviceHistory.length,
          itemBuilder: (ctx, idx) {
            final rec = _serviceHistory[idx];
            return _buildTimelineItem(rec, isLast: idx == _serviceHistory.length - 1);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> rec, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Line Indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: rec['badgeColor'] as Color, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Timeline Record Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rec['date'] as String,
                                style: AppTypography.tag(
                                  color: AppColors.primary,
                                  fontSize: 10.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (rec['badgeColor'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rec['badge'] as String,
                                  style: AppTypography.label(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: rec['badgeColor'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rec['odometer'] as String,
                          style: AppTypography.mono(fontSize: 10.5, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rec['title'] as String,
                      style: AppTypography.subheading(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: AppTypography.label(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            rec['code'] as String,
                            style: AppTypography.mono(fontSize: 10.5, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Map Canvas Painter with futuristic tactical road radar
class _ServiceMapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Road highway paths
    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.65);
    path1.quadraticBezierTo(size.width * 0.4, size.height * 0.55, size.width, size.height * 0.35);
    canvas.drawPath(path1, roadPaint);

    final roadPaint2 = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path2 = Path();
    path2.moveTo(size.width * 0.25, 0);
    path2.lineTo(size.width * 0.35, size.height);
    canvas.drawPath(path2, roadPaint2);

    // Connecting route line (electric teal)
    final routePaint = Paint()
      ..color = AppColors.primaryContainer
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final routePath = Path();
    routePath.moveTo(size.width * 0.28, size.height * 0.62);
    routePath.lineTo(size.width * 0.52, size.height * 0.48);
    routePath.lineTo(size.width * 0.76, size.height * 0.38);
    canvas.drawPath(routePath, routePaint);

    // Center pins
    final pinPaintMahindra = Paint()..color = const Color(0xFF006A68);
    final pinPaintTata = Paint()..color = const Color(0xFF2BB5B2);
    final userPin = Paint()..color = const Color(0xFF00E5C9);

    // User Location Pulse
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.62), 10, Paint()..color = const Color(0x3300E5C9));
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.62), 5, userPin);

    // Pin 1 (Pothens Mahindra Hub)
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.48), 6, pinPaintMahindra);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.48), 2.5, Paint()..color = Colors.white);

    // Pin 2 (Malayalam Tata EV Hub)
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.38), 6, pinPaintTata);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.38), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Multi-Service Booking Bottom Sheet Modal
class _ServiceBookingBottomSheet extends StatefulWidget {
  final VehicleItem vehicle;
  final List<Map<String, dynamic>> allServices;
  final List<Map<String, dynamic>> serviceCenters;
  final String? preselectedServiceTitle;
  final ValueChanged<Map<String, dynamic>> onBookingConfirmed;

  const _ServiceBookingBottomSheet({
    required this.vehicle,
    required this.allServices,
    required this.serviceCenters,
    this.preselectedServiceTitle,
    required this.onBookingConfirmed,
  });

  @override
  State<_ServiceBookingBottomSheet> createState() => _ServiceBookingBottomSheetState();
}

class _ServiceBookingBottomSheetState extends State<_ServiceBookingBottomSheet> {
  final Set<String> _selectedServiceIds = {};
  int _selectedDayIndex = 5; // Sep 05
  String _selectedTimeSlot = '11:30 AM';
  late String _selectedCenter;
  bool _doorstepPickup = false;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _timeSlots = ['09:00 AM', '11:30 AM', '02:00 PM', '04:30 PM'];

  @override
  void initState() {
    super.initState();
    _selectedCenter = widget.serviceCenters.first['name'] as String;

    _selectedServiceIds.add('oil');
    _selectedServiceIds.add('brakes');

    if (widget.preselectedServiceTitle != null) {
      final match = widget.allServices.firstWhere(
        (s) => s['title'] == widget.preselectedServiceTitle,
        orElse: () => widget.allServices.first,
      );
      _selectedServiceIds.add(match['id'] as String);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalEstimate {
    double sum = 0;
    for (final s in widget.allServices) {
      if (_selectedServiceIds.contains(s['id'])) {
        sum += (s['cost'] as double);
      }
    }
    if (_doorstepPickup) sum += 350;
    return sum;
  }

  int get _totalMinutes {
    int sum = 0;
    for (final s in widget.allServices) {
      if (_selectedServiceIds.contains(s['id'])) {
        sum += (s['minutes'] as int);
      }
    }
    return sum;
  }

  void _proceedToCheckoutOrConfirm() {
    final ticketData = {
      'code': 'SRV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'vehicleName': widget.vehicle.name,
      'date': 'Sep 0$_selectedDayIndex, 2026',
      'time': _selectedTimeSlot,
      'center': _selectedCenter,
      'price': '₹${_totalEstimate.toInt()}',
      'pickup': _doorstepPickup,
    };

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Confirm Booking Method',
          style: AppTypography.heading(fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Estimated Service: ₹${_totalEstimate.toInt()}',
              style: AppTypography.stat(fontSize: 15, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'Slot: Sep 0$_selectedDayIndex • $_selectedTimeSlot\n'
              'Center: $_selectedCenter\n\n'
              'Would you like to pay an advance token of ₹500 via UPI/Card, or settle in full at the center upon vehicle collection?',
              style: AppTypography.body(fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBookingConfirmed(ticketData);
            },
            child: Text(
              'Pay at Center',
              style: AppTypography.label(fontSize: 13, color: AppColors.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentGatewayScreen(
                    itemTitle: 'Service Bay Advance Deposit',
                    itemSubtitle: 'Slot at $_selectedCenter • Sep 0$_selectedDayIndex',
                    amount: 500.0,
                    onPaymentSuccess: () {
                      widget.onBookingConfirmed(ticketData);
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Pay ₹500 Advance',
              style: AppTypography.label(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Service Appointment',
                          style: AppTypography.heading(fontSize: 16),
                        ),
                        Text(
                          'Configure OEM services, date & preferred hub',
                          style: AppTypography.bodySmall(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardPadding + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Confirmation Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.vehicle.name,
                                  style: AppTypography.subheading(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  widget.vehicle.registrationPlate,
                                  style: AppTypography.mono(fontSize: 10, color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Care+ Covered',
                            style: AppTypography.label(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 1. Multi-Service Checklist
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECT SERVICES',
                        style: AppTypography.tag(),
                      ),
                      Text(
                        '${_selectedServiceIds.length} Selected • ~${_totalMinutes ~/ 60}h ${_totalMinutes % 60}m',
                        style: AppTypography.label(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.allServices.map((s) {
                    final isChecked = _selectedServiceIds.contains(s['id']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              if (_selectedServiceIds.length > 1) {
                                _selectedServiceIds.remove(s['id']);
                              }
                            } else {
                              _selectedServiceIds.add(s['id'] as String);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isChecked ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surfaceContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isChecked ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedServiceIds.add(s['id'] as String);
                                    } else if (_selectedServiceIds.length > 1) {
                                      _selectedServiceIds.remove(s['id']);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s['title'] as String,
                                      style: AppTypography.subheading(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      s['subtitle'] as String,
                                      style: AppTypography.bodySmall(fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${(s['cost'] as double).toInt()}',
                                style: AppTypography.stat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // 2. Interactive Calendar Date Picker
                  Text(
                    'APPOINTMENT DATE & SLOT',
                    style: AppTypography.tag(),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'September 2026',
                              style: AppTypography.subheading(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Mon - Sun',
                              style: AppTypography.bodySmall(fontSize: 10.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Calendar days row for current week
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (i) {
                            final dayNum = i + 1;
                            final isSel = _selectedDayIndex == dayNum;
                            final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return InkWell(
                              onTap: () => setState(() => _selectedDayIndex = dayNum),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 38,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.4),
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayLabels[i],
                                      style: AppTypography.label(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white.withValues(alpha: 0.85) : AppColors.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '0$dayNum',
                                      style: AppTypography.stat(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white : AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Time Slots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _timeSlots.map((slot) {
                      final isSel = _selectedTimeSlot == slot;
                      return InkWell(
                        onTap: () => setState(() => _selectedTimeSlot = slot),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            slot,
                            style: AppTypography.label(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 3. Service Center Picker Dropdown
                  Text(
                    'SERVICE CENTER',
                    style: AppTypography.tag(),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCenter,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCenter = val);
                        },
                        items: widget.serviceCenters.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['name'] as String,
                            child: Text(
                              '${c['name']} (${c['distance']})',
                              style: AppTypography.body(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Doorstep Valet Pickup Toggle (+₹350)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Doorstep Valet Pickup & Drop',
                                  style: AppTypography.subheading(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Dedicated certified driver collects vehicle (+₹350)',
                                  style: AppTypography.bodySmall(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _doorstepPickup,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _doorstepPickup = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Notes
                  Text(
                    'NOTES (OPTIONAL)',
                    style: AppTypography.tag(),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    style: AppTypography.body(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'e.g. Check slight steering vibration above 80 km/h...',
                      hintStyle: AppTypography.bodySmall(fontSize: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer Checkout Summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ESTIMATED TOTAL',
                      style: AppTypography.tag(color: AppColors.outline),
                    ),
                    Text(
                      '₹${_totalEstimate.toInt()}',
                      style: AppTypography.stat(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _proceedToCheckoutOrConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    'Confirm Booking',
                    style: AppTypography.subheading(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
