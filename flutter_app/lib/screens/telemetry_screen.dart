import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ecu_telemetry.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_top_nav_bar.dart';
import '../widgets/master_top_app_bar.dart';

class TelemetryScreen extends StatefulWidget {
  final VehicleItem? initialVehicle;

  const TelemetryScreen({
    super.key,
    this.initialVehicle,
  });

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  VehicleItem? _selectedVehicle;
  List<VehicleItem> _vehicles = [];
  EcuTelemetry? _telemetry;
  bool _isLoading = true;
  int _activeCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Overview', 'icon': Icons.dashboard_rounded},
    {'label': 'Engine', 'icon': Icons.engineering_rounded},
    {'label': 'Thermal', 'icon': Icons.thermostat_rounded},
    {'label': 'Fuel', 'icon': Icons.local_gas_station_rounded},
    {'label': 'Electrical', 'icon': Icons.flash_on_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.initialVehicle;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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
      });
      await _fetchTelemetry();
    }
  }

  Future<void> _fetchTelemetry() async {
    if (_selectedVehicle == null) return;
    final data = await ApiService.getEcuTelemetry(_selectedVehicle!.vin);
    if (mounted) {
      setState(() {
        _telemetry = data;
        _isLoading = false;
      });
    }
  }

  void _updateTelemetryMetric({
    int? rpm,
    double? speedKmH,
    double? coolantTempC,
    double? oilPressureBar,
    double? fuelLevelPercent,
    double? batteryVoltage,
  }) {
    if (_telemetry == null) return;
    setState(() {
      _telemetry = EcuTelemetry(
        vin: _telemetry!.vin,
        vehicleName: _telemetry!.vehicleName,
        engineType: _telemetry!.engineType,
        isEngineRunning: _telemetry!.isEngineRunning,
        ecuStatus: 'Manual Telemetry Log',
        rpm: (rpm ?? _telemetry!.rpm).clamp(0, 8000),
        maxRpm: _telemetry!.maxRpm,
        speedKmH: double.parse(((speedKmH ?? _telemetry!.speedKmH).clamp(0.0, 240.0)).toStringAsFixed(1)),
        engineLoadPercent: _telemetry!.engineLoadPercent,
        throttlePercent: _telemetry!.throttlePercent,
        boostPressureBar: _telemetry!.boostPressureBar,
        mafAirflow: _telemetry!.mafAirflow,
        mapPressureKpa: _telemetry!.mapPressureKpa,
        coolantTempC: double.parse(((coolantTempC ?? _telemetry!.coolantTempC).clamp(40.0, 130.0)).toStringAsFixed(1)),
        oilTempC: _telemetry!.oilTempC,
        oilPressureBar: double.parse(((oilPressureBar ?? _telemetry!.oilPressureBar).clamp(0.0, 10.0)).toStringAsFixed(1)),
        intakeAirTempC: _telemetry!.intakeAirTempC,
        transmissionTempC: _telemetry!.transmissionTempC,
        exhaustGasTempC: _telemetry!.exhaustGasTempC,
        fuelRailPressureBar: _telemetry!.fuelRailPressureBar,
        airFuelRatio: _telemetry!.airFuelRatio,
        lambda: _telemetry!.lambda,
        shortTermFuelTrim: _telemetry!.shortTermFuelTrim,
        longTermFuelTrim: _telemetry!.longTermFuelTrim,
        instantFuelEconomy: _telemetry!.instantFuelEconomy,
        fuelLevelPercent: double.parse(((fuelLevelPercent ?? _telemetry!.fuelLevelPercent).clamp(0.0, 100.0)).toStringAsFixed(1)),
        fuelRemainingLitres: _telemetry!.fuelRemainingLitres,
        ignitionTimingDeg: _telemetry!.ignitionTimingDeg,
        cylinderMisfires: _telemetry!.cylinderMisfires,
        vvtIntakeDeg: _telemetry!.vvtIntakeDeg,
        vvtExhaustDeg: _telemetry!.vvtExhaustDeg,
        batteryVoltage: double.parse(((batteryVoltage ?? _telemetry!.batteryVoltage).clamp(8.0, 16.0)).toStringAsFixed(1)),
        alternatorCurrent: _telemetry!.alternatorCurrent,
        o2Sensor1Voltage: _telemetry!.o2Sensor1Voltage,
        o2Sensor2Voltage: _telemetry!.o2Sensor2Voltage,
        egrValvePercent: _telemetry!.egrValvePercent,
        catalyticEfficiencyPercent: _telemetry!.catalyticEfficiencyPercent,
        dpfSootLevelPercent: _telemetry!.dpfSootLevelPercent,
        checkEngineLightOn: _telemetry!.checkEngineLightOn,
        activeDtcCount: _telemetry!.activeDtcCount,
        dtcCodes: _telemetry!.dtcCodes,
        lastSync: DateTime.now(),
      );
    });
  }

  void _onVehicleChanged(VehicleItem vehicle) async {
    setState(() {
      _selectedVehicle = vehicle;
      _isLoading = true;
    });
    await ApiService.selectVehicle(vehicle.vin);
    await _fetchTelemetry();
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
              onVehicleChanged: _onVehicleChanged,
            ),

            // FLOATING TOP NAV DOCK
            FloatingTopNavBar(
              currentIndex: 2,
              currentVehicle: _selectedVehicle,
            ),

            // MAIN SCROLLABLE CONTENT
            Expanded(
              child: _isLoading || _telemetry == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchTelemetry,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. MANUAL TELEMETRY HEADER CARD
                            _buildManualHeaderCard(),
                            const SizedBox(height: 14),

                            // 2. CATEGORY CHIPS
                            _buildCategoryChips(),
                            const SizedBox(height: 14),

                            // 3. TAB CONTENT
                            _buildTabContent(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. MANUAL HEADER CARD ---
  Widget _buildManualHeaderCard() {
    final t = _telemetry!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.onSurface.withValues(alpha: 0.95),
            const Color(0xFF0F2027),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    t.vehicleName,
                    style: AppTypography.heading(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MANUAL TELEMETRY LOG',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStat('${t.rpm} RPM', Icons.speed_rounded),
              _buildHeaderStat('${t.speedKmH.toInt()} km/h', Icons.navigation_rounded),
              _buildHeaderStat('${t.coolantTempC.toInt()} °C', Icons.thermostat_rounded),
              _buildHeaderStat('${t.batteryVoltage} V', Icons.electric_bolt_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ],
    );
  }

  // --- 2. CATEGORY CHIPS ---
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _activeCategoryIndex;
          final cat = _categories[index];
          return ChoiceChip(
            avatar: Icon(
              cat['icon'] as IconData,
              size: 15,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            label: Text(cat['label'] as String),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _activeCategoryIndex = index);
              }
            },
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            elevation: isSelected ? 3 : 0,
          );
        },
      ),
    );
  }

  // --- 3. TAB CONTENT SELECTOR ---
  Widget _buildTabContent() {
    switch (_activeCategoryIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildEnginePowerTab();
      case 2:
        return _buildThermalFluidsTab();
      case 3:
        return _buildFuelAirTab();
      case 4:
        return _buildElectricalTab();
      default:
        return _buildOverviewTab();
    }
  }

  // --- OVERVIEW TAB: MANUAL CONTROLS ---
  Widget _buildOverviewTab() {
    final t = _telemetry!;
    return Column(
      children: [
        // Live RPM & Speed Visual Gauge & Controls
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'MANUAL TELEMETRY INPUT LOG',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          content: const Text('Manual telemetry logs saved.'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SAVE LOG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // RPM Arc Visual
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(120, 120),
                            painter: RpmArcPainter(
                              rpm: t.rpm,
                              maxRpm: t.maxRpm,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${t.rpm}',
                                style: AppTypography.display(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const Text(
                                'RPM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Speed & Boost Card
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        _buildManualInputAdjuster(
                          title: 'Engine Speed (RPM)',
                          value: '${t.rpm}',
                          unit: 'RPM',
                          onDecrement: () => _updateTelemetryMetric(rpm: t.rpm - 100),
                          onIncrement: () => _updateTelemetryMetric(rpm: t.rpm + 100),
                        ),
                        const SizedBox(height: 8),
                        _buildManualInputAdjuster(
                          title: 'Vehicle Speed',
                          value: '${t.speedKmH.toInt()}',
                          unit: 'km/h',
                          onDecrement: () => _updateTelemetryMetric(speedKmH: t.speedKmH - 5.0),
                          onIncrement: () => _updateTelemetryMetric(speedKmH: t.speedKmH + 5.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4 Manual Input Metric Cards Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildInteractiveMetricTile(
              title: 'Coolant Temp',
              value: '${t.coolantTempC.toInt()} °C',
              icon: Icons.thermostat_rounded,
              statusColor: AppColors.primary,
              onDecrement: () => _updateTelemetryMetric(coolantTempC: t.coolantTempC - 1.0),
              onIncrement: () => _updateTelemetryMetric(coolantTempC: t.coolantTempC + 1.0),
            ),
            _buildInteractiveMetricTile(
              title: 'Oil Pressure',
              value: '${t.oilPressureBar.toStringAsFixed(1)} Bar',
              icon: Icons.oil_barrel_rounded,
              statusColor: AppColors.primary,
              onDecrement: () => _updateTelemetryMetric(oilPressureBar: t.oilPressureBar - 0.2),
              onIncrement: () => _updateTelemetryMetric(oilPressureBar: t.oilPressureBar + 0.2),
            ),
            _buildInteractiveMetricTile(
              title: 'Fuel Tank Level',
              value: '${t.fuelLevelPercent.toInt()} %',
              icon: Icons.local_gas_station_rounded,
              statusColor: AppColors.primary,
              onDecrement: () => _updateTelemetryMetric(fuelLevelPercent: t.fuelLevelPercent - 5.0),
              onIncrement: () => _updateTelemetryMetric(fuelLevelPercent: t.fuelLevelPercent + 5.0),
            ),
            _buildInteractiveMetricTile(
              title: 'Battery Voltage',
              value: '${t.batteryVoltage.toStringAsFixed(1)} V',
              icon: Icons.electric_bolt_rounded,
              statusColor: AppColors.primary,
              onDecrement: () => _updateTelemetryMetric(batteryVoltage: t.batteryVoltage - 0.2),
              onIncrement: () => _updateTelemetryMetric(batteryVoltage: t.batteryVoltage + 0.2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualInputAdjuster({
    required String title,
    required String value,
    required String unit,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildStepButton(Icons.remove, onDecrement),
              const SizedBox(width: 4),
              _buildStepButton(Icons.add, onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }

  Widget _buildInteractiveMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color statusColor,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTypography.heading(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              Row(
                children: [
                  _buildStepButton(Icons.remove, onDecrement),
                  const SizedBox(width: 4),
                  _buildStepButton(Icons.add, onIncrement),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ENGINE TAB ---
  Widget _buildEnginePowerTab() {
    final t = _telemetry!;
    return Column(
      children: [
        _buildSectionCard(
          title: 'ENGINE OPERATING PARAMETERS',
          icon: Icons.engineering_rounded,
          children: [
            _buildDetailRow('Engine Speed', '${t.rpm} RPM'),
            _buildDetailRow('Vehicle Speed', '${t.speedKmH} km/h'),
            _buildDetailRow('Engine Load', '${t.engineLoadPercent}%'),
            _buildDetailRow('Throttle Angle', '${t.throttlePercent}%'),
            _buildDetailRow('Mass Airflow', '${t.mafAirflow} g/s'),
            _buildDetailRow('Turbo Boost', '${t.boostPressureBar} Bar'),
          ],
        ),
      ],
    );
  }

  // --- THERMAL TAB ---
  Widget _buildThermalFluidsTab() {
    final t = _telemetry!;
    return Column(
      children: [
        _buildSectionCard(
          title: 'THERMAL & FLUID PARAMETERS',
          icon: Icons.thermostat_rounded,
          children: [
            _buildDetailRow('Coolant Temp', '${t.coolantTempC} °C'),
            _buildDetailRow('Oil Temp', '${t.oilTempC} °C'),
            _buildDetailRow('Oil Pressure', '${t.oilPressureBar} Bar'),
            _buildDetailRow('Intake Air Temp', '${t.intakeAirTempC} °C'),
            _buildDetailRow('Transmission Temp', '${t.transmissionTempC} °C'),
            _buildDetailRow('Exhaust Gas Temp', '${t.exhaustGasTempC} °C'),
          ],
        ),
      ],
    );
  }

  // --- FUEL TAB ---
  Widget _buildFuelAirTab() {
    final t = _telemetry!;
    return Column(
      children: [
        _buildSectionCard(
          title: 'FUEL & COMBUSTION PARAMETERS',
          icon: Icons.local_gas_station_rounded,
          children: [
            _buildDetailRow('Fuel Rail Pressure', '${t.fuelRailPressureBar.toInt()} Bar'),
            _buildDetailRow('Air-Fuel Ratio', '${t.airFuelRatio} : 1'),
            _buildDetailRow('Fuel Tank Level', '${t.fuelLevelPercent}%'),
            _buildDetailRow('Fuel Remaining', '${t.fuelRemainingLitres} L'),
            _buildDetailRow('Instant Economy', '${t.instantFuelEconomy} km/L'),
          ],
        ),
      ],
    );
  }

  // --- ELECTRICAL TAB ---
  Widget _buildElectricalTab() {
    final t = _telemetry!;
    return Column(
      children: [
        _buildSectionCard(
          title: 'ELECTRICAL PARAMETERS',
          icon: Icons.flash_on_rounded,
          children: [
            _buildDetailRow('Battery Voltage', '${t.batteryVoltage} V'),
            _buildDetailRow('Alternator Output', '${t.alternatorCurrent} A'),
            _buildDetailRow('Oxygen Sensor Voltage', '${t.o2Sensor1Voltage} V'),
          ],
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Tachometer RPM Circular Arc
class RpmArcPainter extends CustomPainter {
  final int rpm;
  final int maxRpm;

  RpmArcPainter({required this.rpm, required this.maxRpm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active RPM sweep
    final percent = (rpm / maxRpm).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * percent;

    const activeGradient = LinearGradient(
      colors: [AppColors.primary, AppColors.electric],
    );

    final activePaint = Paint()
      ..shader = activeGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant RpmArcPainter oldDelegate) {
    return oldDelegate.rpm != rpm || oldDelegate.maxRpm != maxRpm;
  }
}
