import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_top_nav_bar.dart';
import '../widgets/master_top_app_bar.dart';
import '../widgets/enroll_vehicle_modal.dart';
import 'service_screen.dart';
import 'fasttag_screen.dart';

class GarageScreen extends StatefulWidget {
  final VehicleItem? initialVehicle;

  const GarageScreen({
    super.key,
    this.initialVehicle,
  });

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  VehicleItem? _selectedVehicle;
  List<VehicleItem> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.initialVehicle;
    _loadGarageData();
  }

  Future<void> _loadGarageData() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getVehicles();
    if (mounted) {
      setState(() {
        _vehicles = list;
        if (_selectedVehicle == null && list.isNotEmpty) {
          _selectedVehicle = list.firstWhere((v) => v.isSelected, orElse: () => list.first);
        } else if (_selectedVehicle != null) {
          _selectedVehicle = list.firstWhere((v) => v.vin == _selectedVehicle!.vin, orElse: () => list.first);
        }
        _isLoading = false;
      });
    }
  }

  void _selectVehicle(VehicleItem vehicle) async {
    setState(() {
      _selectedVehicle = vehicle;
      for (var v in _vehicles) {
        v.isSelected = (v.vin == vehicle.vin);
      }
    });
    await ApiService.selectVehicle(vehicle.vin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1800),
        content: Text('Switched garage fleet to ${vehicle.name} (${vehicle.registrationPlate})'),
      ),
    );
  }

  void _showEnrollVehicleModal() {
    EnrollVehicleModal.show(
      context,
      onVehicleEnrolled: (newVehicle) {
        setState(() {
          for (var v in _vehicles) {
            v.isSelected = false;
          }
          _vehicles.add(newVehicle);
          _selectedVehicle = newVehicle;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // MASTER TOP APP BAR
            MasterTopAppBar(
              currentVehicle: _selectedVehicle,
              vehicles: _vehicles,
              onVehicleChanged: _selectVehicle,
            ),

            // SECONDARY 5-PILL DOCK
            _buildSecondaryNavDock(),

            // MAIN SCROLLABLE CONTENT
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PAGE TITLE & ACTION BANNER
                          _buildHeaderBanner(),
                          const SizedBox(height: 16),

                          // FLEET DOSSIER VEHICLE CARDS
                          ..._vehicles.map((car) => _buildFleetVehicleCard(car)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. SECONDARY ICON-ONLY NAVIGATION DOCK (CENTRALIZED ACTIVE SLIDE)
  Widget _buildSecondaryNavDock() {
    return FloatingTopNavBar(
      currentIndex: 0,
      currentVehicle: _selectedVehicle,
    );
  }

  // 3. PAGE HEADER & TITLE BANNER
  Widget _buildHeaderBanner() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.garage_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Garage Fleet',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${_vehicles.length}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showEnrollVehicleModal,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Enroll', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // 4. FLEET DOSSIER VEHICLE CARD (SMARTPHONE AUTO-ALIGNED, MINIMAL TEXT, ICON-FORWARD)
  Widget _buildFleetVehicleCard(VehicleItem car) {
    final isSelected = car.vin == _selectedVehicle?.vin;
    final isElectric = car.fuelType.toLowerCase().contains('electric') || car.fuelType.toLowerCase().contains('ev');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image Container with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  width: double.infinity,
                  height: 130,
                  child: Image.network(
                    car.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.directions_car_rounded, size: 40, color: AppColors.secondary),
                      ),
                    ),
                  ),
                ),
              ),

              // Top Status Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.success
                              : (isElectric ? Colors.cyanAccent : Colors.amberAccent),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSelected ? 'ACTIVE' : 'STANDBY',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom-Right HSRP Plate Tag
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    car.registrationPlate,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: AppColors.primaryFixed,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Model Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        car.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isElectric
                            ? Colors.teal.shade50
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        car.fuelType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isElectric ? Colors.teal.shade800 : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4-Metric Glanceable Icon Grid
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Fuel / Battery
                      _buildMetricTile(
                        icon: isElectric
                            ? Icons.battery_charging_full_rounded
                            : Icons.local_gas_station_rounded,
                        value: isElectric
                            ? '${car.fuelCapacityLitres.toInt()} kWh'
                            : '${car.fuelCapacityLitres.toInt()} L',
                        color: isElectric ? Colors.teal : AppColors.primary,
                      ),
                      _buildMetricDivider(),
                      // Odometer
                      _buildMetricTile(
                        icon: Icons.speed_rounded,
                        value: '${car.odometerKm} km',
                        color: AppColors.secondary,
                      ),
                      _buildMetricDivider(),
                      // Service
                      _buildMetricTile(
                        icon: Icons.build_circle_rounded,
                        value: car.serviceDueKm != null ? '${car.serviceDueKm} km' : '680 km',
                        color: Colors.amber.shade800,
                      ),
                      _buildMetricDivider(),
                      // FASTag
                      _buildMetricTile(
                        icon: Icons.toll_rounded,
                        value: 'Active',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Action Buttons Row
                Row(
                  children: [
                    if (isSelected) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => GarageScreen(initialVehicle: car)),
                            );
                          },
                          icon: const Icon(Icons.analytics_rounded, size: 16),
                          label: const Text('Telemetry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => ServiceScreen(initialVehicle: car)),
                            );
                          },
                          icon: const Icon(Icons.build_rounded, size: 16),
                          label: const Text('Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectVehicle(car),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: const Text('Select', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => FastTagScreen(initialVehicle: car)),
                            );
                          },
                          icon: const Icon(Icons.toll_rounded, size: 16),
                          label: const Text('FASTag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.grey.shade300,
    );
  }
}
