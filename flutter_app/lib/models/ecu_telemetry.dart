class DtcCode {
  final String code;
  final String system;
  final String description;
  final String severity; // 'critical', 'warning', 'info', 'pass'
  final String timestamp;

  DtcCode({
    required this.code,
    required this.system,
    required this.description,
    required this.severity,
    required this.timestamp,
  });

  factory DtcCode.fromJson(Map<String, dynamic> json) {
    return DtcCode(
      code: json['code'] as String? ?? 'P0000',
      system: json['system'] as String? ?? 'Engine Control Unit',
      description: json['description'] as String? ?? 'System Normal',
      severity: json['severity'] as String? ?? 'pass',
      timestamp: json['timestamp'] as String? ?? 'Just now',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'system': system,
      'description': description,
      'severity': severity,
      'timestamp': timestamp,
    };
  }
}

class EcuTelemetry {
  final String vin;
  final String vehicleName;
  final String engineType;
  final bool isEngineRunning;
  final String ecuStatus;
  
  // Speed & Power
  final int rpm;
  final int maxRpm;
  final double speedKmH;
  final double engineLoadPercent;
  final double throttlePercent;
  final double boostPressureBar;
  final double mafAirflow;
  final double mapPressureKpa;

  // Thermal & Fluid
  final double coolantTempC;
  final double oilTempC;
  final double oilPressureBar;
  final double intakeAirTempC;
  final double transmissionTempC;
  final double exhaustGasTempC;

  // Fuel & Combustion
  final double fuelRailPressureBar;
  final double airFuelRatio;
  final double lambda;
  final double shortTermFuelTrim;
  final double longTermFuelTrim;
  final double instantFuelEconomy;
  final double fuelLevelPercent;
  final double fuelRemainingLitres;

  // Ignition & Timing
  final double ignitionTimingDeg;
  final Map<String, int> cylinderMisfires;
  final double vvtIntakeDeg;
  final double vvtExhaustDeg;

  // Electrical & Emissions
  final double batteryVoltage;
  final double alternatorCurrent;
  final double o2Sensor1Voltage;
  final double o2Sensor2Voltage;
  final double egrValvePercent;
  final double catalyticEfficiencyPercent;
  final double dpfSootLevelPercent;

  // Diagnostics & DTC
  final bool checkEngineLightOn;
  final int activeDtcCount;
  final List<DtcCode> dtcCodes;
  final DateTime lastSync;

  EcuTelemetry({
    required this.vin,
    required this.vehicleName,
    required this.engineType,
    required this.isEngineRunning,
    required this.ecuStatus,
    required this.rpm,
    this.maxRpm = 6800,
    required this.speedKmH,
    required this.engineLoadPercent,
    required this.throttlePercent,
    required this.boostPressureBar,
    required this.mafAirflow,
    required this.mapPressureKpa,
    required this.coolantTempC,
    required this.oilTempC,
    required this.oilPressureBar,
    required this.intakeAirTempC,
    required this.transmissionTempC,
    required this.exhaustGasTempC,
    required this.fuelRailPressureBar,
    required this.airFuelRatio,
    required this.lambda,
    required this.shortTermFuelTrim,
    required this.longTermFuelTrim,
    required this.instantFuelEconomy,
    required this.fuelLevelPercent,
    required this.fuelRemainingLitres,
    required this.ignitionTimingDeg,
    required this.cylinderMisfires,
    required this.vvtIntakeDeg,
    required this.vvtExhaustDeg,
    required this.batteryVoltage,
    required this.alternatorCurrent,
    required this.o2Sensor1Voltage,
    required this.o2Sensor2Voltage,
    required this.egrValvePercent,
    required this.catalyticEfficiencyPercent,
    required this.dpfSootLevelPercent,
    required this.checkEngineLightOn,
    required this.activeDtcCount,
    required this.dtcCodes,
    required this.lastSync,
  });

  factory EcuTelemetry.fromJson(Map<String, dynamic> json) {
    final misfiresJson = json['cylinder_misfires'] as Map<String, dynamic>?;
    final Map<String, int> misfires = misfiresJson != null
        ? misfiresJson.map((k, v) => MapEntry(k, (v as num).toInt()))
        : {'Cyl 1': 0, 'Cyl 2': 0, 'Cyl 3': 0, 'Cyl 4': 0};

    final dtcList = (json['dtc_codes'] as List<dynamic>?)
            ?.map((e) => DtcCode.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return EcuTelemetry(
      vin: json['vin'] as String? ?? '',
      vehicleName: json['vehicle_name'] as String? ?? 'IC Engine Vehicle',
      engineType: json['engine_type'] as String? ?? '2.2L mHawk Turbocharged Diesel',
      isEngineRunning: json['is_engine_running'] as bool? ?? true,
      ecuStatus: json['ecu_status'] as String? ?? 'Online • OBD-II CAN Bus Active',
      rpm: (json['rpm'] as num?)?.toInt() ?? 2450,
      maxRpm: (json['max_rpm'] as num?)?.toInt() ?? 6800,
      speedKmH: (json['speed_kmh'] as num?)?.toDouble() ?? 78.5,
      engineLoadPercent: (json['engine_load_percent'] as num?)?.toDouble() ?? 42.5,
      throttlePercent: (json['throttle_percent'] as num?)?.toDouble() ?? 34.0,
      boostPressureBar: (json['boost_pressure_bar'] as num?)?.toDouble() ?? 1.25,
      mafAirflow: (json['maf_airflow'] as num?)?.toDouble() ?? 48.2,
      mapPressureKpa: (json['map_pressure_kpa'] as num?)?.toDouble() ?? 145.0,
      coolantTempC: (json['coolant_temp_c'] as num?)?.toDouble() ?? 91.0,
      oilTempC: (json['oil_temp_c'] as num?)?.toDouble() ?? 96.5,
      oilPressureBar: (json['oil_pressure_bar'] as num?)?.toDouble() ?? 4.2,
      intakeAirTempC: (json['intake_air_temp_c'] as num?)?.toDouble() ?? 28.0,
      transmissionTempC: (json['transmission_temp_c'] as num?)?.toDouble() ?? 84.0,
      exhaustGasTempC: (json['exhaust_gas_temp_c'] as num?)?.toDouble() ?? 520.0,
      fuelRailPressureBar: (json['fuel_rail_pressure_bar'] as num?)?.toDouble() ?? 1350.0,
      airFuelRatio: (json['air_fuel_ratio'] as num?)?.toDouble() ?? 14.7,
      lambda: (json['lambda'] as num?)?.toDouble() ?? 1.00,
      shortTermFuelTrim: (json['short_term_fuel_trim'] as num?)?.toDouble() ?? 1.2,
      longTermFuelTrim: (json['long_term_fuel_trim'] as num?)?.toDouble() ?? -0.8,
      instantFuelEconomy: (json['instant_fuel_economy'] as num?)?.toDouble() ?? 15.6,
      fuelLevelPercent: (json['fuel_level_percent'] as num?)?.toDouble() ?? 78.0,
      fuelRemainingLitres: (json['fuel_remaining_litres'] as num?)?.toDouble() ?? 46.8,
      ignitionTimingDeg: (json['ignition_timing_deg'] as num?)?.toDouble() ?? 14.5,
      cylinderMisfires: misfires,
      vvtIntakeDeg: (json['vvt_intake_deg'] as num?)?.toDouble() ?? 12.0,
      vvtExhaustDeg: (json['vvt_exhaust_deg'] as num?)?.toDouble() ?? 8.0,
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble() ?? 13.8,
      alternatorCurrent: (json['alternator_current'] as num?)?.toDouble() ?? 45.0,
      o2Sensor1Voltage: (json['o2_sensor1_voltage'] as num?)?.toDouble() ?? 0.85,
      o2Sensor2Voltage: (json['o2_sensor2_voltage'] as num?)?.toDouble() ?? 0.45,
      egrValvePercent: (json['egr_valve_percent'] as num?)?.toDouble() ?? 18.0,
      catalyticEfficiencyPercent: (json['catalytic_efficiency_percent'] as num?)?.toDouble() ?? 98.5,
      dpfSootLevelPercent: (json['dpf_soot_level_percent'] as num?)?.toDouble() ?? 12.0,
      checkEngineLightOn: json['check_engine_light_on'] as bool? ?? false,
      activeDtcCount: (json['active_dtc_count'] as num?)?.toInt() ?? 0,
      dtcCodes: dtcList,
      lastSync: json['last_sync'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['last_sync'] as num).toInt() * 1000)
          : DateTime.now(),
    );
  }

  factory EcuTelemetry.mockForVin(String vin, {String? name, String? fuelType}) {
    final isThar = vin.contains('THAR');
    final isXuv = vin.contains('XUV700');
    final String vName = name ?? (isThar ? 'Mahindra Thar 4x4 MT' : (isXuv ? 'Mahindra XUV700 AX7 L' : 'Mahindra IC Engine SUV'));
    final String eType = fuelType ?? (isThar ? '2.2L mHawk 130 Turbo-Diesel' : '2.2L mHawk Direct-Injection Turbo Diesel');

    return EcuTelemetry(
      vin: vin,
      vehicleName: vName,
      engineType: eType,
      isEngineRunning: true,
      ecuStatus: 'Online • Bosch EDC17 CAN-Bus Protocol (500 kbps)',
      rpm: isThar ? 1950 : 2340,
      maxRpm: 5500,
      speedKmH: isThar ? 64.0 : 82.5,
      engineLoadPercent: isThar ? 48.0 : 41.2,
      throttlePercent: isThar ? 38.0 : 32.5,
      boostPressureBar: isThar ? 1.45 : 1.32,
      mafAirflow: isThar ? 52.4 : 46.8,
      mapPressureKpa: isThar ? 162.0 : 148.0,
      coolantTempC: 90.5,
      oilTempC: 94.8,
      oilPressureBar: 4.3,
      intakeAirTempC: 27.5,
      transmissionTempC: 82.0,
      exhaustGasTempC: 495.0,
      fuelRailPressureBar: isThar ? 1420.0 : 1380.0,
      airFuelRatio: 14.7,
      lambda: 1.00,
      shortTermFuelTrim: 0.8,
      longTermFuelTrim: -0.4,
      instantFuelEconomy: isThar ? 13.4 : 16.2,
      fuelLevelPercent: isThar ? 62.0 : 78.0,
      fuelRemainingLitres: isThar ? 35.3 : 46.8,
      ignitionTimingDeg: 14.2,
      cylinderMisfires: {'Cyl 1': 0, 'Cyl 2': 0, 'Cyl 3': 0, 'Cyl 4': 0},
      vvtIntakeDeg: 11.5,
      vvtExhaustDeg: 7.8,
      batteryVoltage: 13.85,
      alternatorCurrent: 48.0,
      o2Sensor1Voltage: 0.84,
      o2Sensor2Voltage: 0.46,
      egrValvePercent: 16.5,
      catalyticEfficiencyPercent: 99.1,
      dpfSootLevelPercent: isThar ? 18.0 : 9.5,
      checkEngineLightOn: false,
      activeDtcCount: 0,
      dtcCodes: [
        DtcCode(
          code: 'P0000',
          system: 'Engine Powertrain Control (ECU)',
          description: 'No diagnostic trouble codes logged. All IC engine sensors operating within optimal specifications.',
          severity: 'pass',
          timestamp: 'Live Active',
        )
      ],
      lastSync: DateTime.now(),
    );
  }
}
