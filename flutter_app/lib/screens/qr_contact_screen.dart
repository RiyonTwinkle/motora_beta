import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_top_nav_bar.dart';
import '../widgets/master_top_app_bar.dart';

/// Motoro Ultra-Clean Google Pay / Samsung Pay Style QR Scanner Screen.
class QrContactScreen extends StatefulWidget {
  final VehicleItem? initialVehicle;

  const QrContactScreen({super.key, this.initialVehicle});

  @override
  State<QrContactScreen> createState() => _QrContactScreenState();
}

class _QrContactScreenState extends State<QrContactScreen> with SingleTickerProviderStateMixin {
  VehicleItem? _vehicle;
  List<VehicleItem> _allVehicles = [];
  bool _isLoading = true;

  // Scanner UI Controls
  bool _isSoundFxOn = true;
  bool _isTorchOn = false;
  bool _isTargetAcquired = false;

  // Laser Scan Animation Controller
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.initialVehicle;
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadVehicles();
  }

  @override
  void dispose() {
    _laserController.dispose();
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
        _isLoading = false;
      });
    }
  }

  void _switchVehicle(VehicleItem v) {
    setState(() => _vehicle = v);
  }

  void _triggerSimulatedScan({
    String? plate,
    String? vehicleName,
    String? location,
  }) {
    setState(() => _isTargetAcquired = true);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isTargetAcquired = false);
        _openContactDrawer(
          plate: plate ?? _vehicle?.registrationPlate ?? 'MH 12 RN 2024',
          name: vehicleName ?? _vehicle?.name ?? 'Mahindra XUV700 AX7 L',
          location: location ?? 'Shield Relay Active • Kozhikode',
        );
      }
    });
  }

  void _openContactDrawer({
    required String plate,
    required String name,
    required String location,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnonymousContactDrawerModal(
        plate: plate,
        vehicleName: name,
        location: location,
        onMessageSent: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Message sent to driver of $plate via masked relay!')),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        },
        onInitiateVoipCall: () {
          _showVoipCallModal(plate);
        },
      ),
    );
  }

  void _showVoipCallModal(String plate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SimulatedVoipCallDialog(plate: plate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicle;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            MasterTopAppBar(
              currentVehicle: vehicle,
              vehicles: _allVehicles,
              onVehicleChanged: _switchVehicle,
            ),
            // Floating 6-Tab Navigation Dock
            FloatingTopNavBar(
              currentIndex: 5, // QR Tag tab
              currentVehicle: _vehicle,
            ),
            Expanded(
              child: _isLoading || vehicle == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ambient Camera Viewfinder Backdrop
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFF090D16),
                        ),

                        // Center Google Pay / Samsung Pay Style Scanner
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              // Guidance Chip Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                              ),

                              // Interactive Scanner Viewfinder Box
                              GestureDetector(
                                onTap: _triggerSimulatedScan,
                                child: Container(
                                  width: 270,
                                  height: 270,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isTargetAcquired ? AppColors.success : AppColors.primary).withValues(alpha: 0.28),
                                        blurRadius: 32,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Corner Brackets
                                      CustomPaint(
                                        size: const Size(270, 270),
                                        painter: _ScannerBracketPainter(isTargetAcquired: _isTargetAcquired),
                                      ),

                                      // QR Motif Background
                                      Center(
                                        child: Opacity(
                                          opacity: 0.18,
                                          child: CustomPaint(
                                            size: const Size(140, 140),
                                            painter: _MotoroQrVectorPainter(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Tap to Scan Action CTA Button
                              ElevatedButton.icon(
                                onPressed: _triggerSimulatedScan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 4,
                                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                                ),
                                icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                                label: const Text(
                                  'Tap to Scan QR Code',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Samsung Pay / GPay Style Floating Scanner Quick Controls
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                        color: _isTorchOn ? AppColors.primaryFixed : Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() => _isTorchOn = !_isTorchOn);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(_isTorchOn ? 'Flashlight Enabled' : 'Flashlight Disabled'),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      tooltip: 'Toggle Flashlight',
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: Icon(
                                        _isSoundFxOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                        color: _isSoundFxOn ? AppColors.primaryFixed : Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() => _isSoundFxOn = !_isSoundFxOn);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(_isSoundFxOn ? 'Sound FX Enabled' : 'Sound FX Muted'),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      tooltip: 'Toggle Scan Sound',
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.photo_library_rounded, color: Colors.white70),
                                      onPressed: _triggerSimulatedScan,
                                      tooltip: 'Import from Gallery',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// CUSTOM PAINTER: Corner Brackets matching Samsung Pay camera scanner
// -----------------------------------------------------------------
class _ScannerBracketPainter extends CustomPainter {
  final bool isTargetAcquired;

  _ScannerBracketPainter({this.isTargetAcquired = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isTargetAcquired ? const Color(0xFF10B981) : Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const cornerLen = 24.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerBracketPainter oldDelegate) =>
      oldDelegate.isTargetAcquired != isTargetAcquired;
}

// -----------------------------------------------------------------
// CUSTOM PAINTER: High-Contrast QR Code Vector Motif
// -----------------------------------------------------------------
class _MotoroQrVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blackPaint = Paint()..color = Colors.white;
    final whitePaint = Paint()..color = const Color(0xFF090D16);

    void drawFinderPattern(double x, double y, double s) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, s, s), const Radius.circular(4)),
        blackPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + s * 0.15, y + s * 0.15, s * 0.7, s * 0.7), const Radius.circular(3)),
        whitePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + s * 0.3, y + s * 0.3, s * 0.4, s * 0.4), const Radius.circular(2)),
        blackPaint,
      );
    }

    final finderSize = size.width * 0.28;
    drawFinderPattern(0, 0, finderSize);
    drawFinderPattern(size.width - finderSize, 0, finderSize);
    drawFinderPattern(0, size.height - finderSize, finderSize);

    final dotSize = size.width * 0.055;
    final matrixOffsets = [
      Offset(size.width * 0.35, size.height * 0.08),
      Offset(size.width * 0.45, size.height * 0.08),
      Offset(size.width * 0.55, size.height * 0.08),
      Offset(size.width * 0.35, size.height * 0.18),
      Offset(size.width * 0.55, size.height * 0.18),
      Offset(size.width * 0.08, size.height * 0.35),
      Offset(size.width * 0.18, size.height * 0.35),
      Offset(size.width * 0.08, size.height * 0.45),
      Offset(size.width * 0.08, size.height * 0.55),
      Offset(size.width * 0.38, size.height * 0.65),
      Offset(size.width * 0.48, size.height * 0.65),
      Offset(size.width * 0.60, size.height * 0.65),
      Offset(size.width * 0.72, size.height * 0.65),
      Offset(size.width * 0.85, size.height * 0.65),
      Offset(size.width * 0.65, size.height * 0.78),
      Offset(size.width * 0.76, size.height * 0.78),
      Offset(size.width * 0.88, size.height * 0.78),
      Offset(size.width * 0.42, size.height * 0.88),
      Offset(size.width * 0.56, size.height * 0.88),
    ];

    for (final off in matrixOffsets) {
      canvas.drawRect(Rect.fromLTWH(off.dx, off.dy, dotSize, dotSize), blackPaint);
    }

    final center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.drawCircle(center, size.width * 0.14, whitePaint);
    canvas.drawCircle(center, size.width * 0.12, Paint()..color = AppColors.primary);

    final shieldPath = Path();
    shieldPath.moveTo(center.dx, center.dy - size.width * 0.06);
    shieldPath.lineTo(center.dx + size.width * 0.05, center.dy - size.width * 0.03);
    shieldPath.lineTo(center.dx + size.width * 0.05, center.dy + size.width * 0.02);
    shieldPath.lineTo(center.dx, center.dy + size.width * 0.06);
    shieldPath.lineTo(center.dx - size.width * 0.05, center.dy + size.width * 0.02);
    shieldPath.lineTo(center.dx - size.width * 0.05, center.dy - size.width * 0.03);
    shieldPath.close();
    canvas.drawPath(shieldPath, blackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------
// MODAL 1: Anonymous Contact Drawer (Triggered on QR Scan)
// -----------------------------------------------------------------
class _AnonymousContactDrawerModal extends StatefulWidget {
  final String plate;
  final String vehicleName;
  final String location;
  final ValueChanged<String> onMessageSent;
  final VoidCallback onInitiateVoipCall;

  const _AnonymousContactDrawerModal({
    required this.plate,
    required this.vehicleName,
    required this.location,
    required this.onMessageSent,
    required this.onInitiateVoipCall,
  });

  @override
  State<_AnonymousContactDrawerModal> createState() => _AnonymousContactDrawerModalState();
}

class _AnonymousContactDrawerModalState extends State<_AnonymousContactDrawerModal> {
  final TextEditingController _customMsgController = TextEditingController();

  final List<String> _presets = [
    '🚗 Can you please move your car? It is blocking gate access.',
    '⚠️ Headlights left on (Battery drain risk).',
    '💥 Minor bump or scratch occurred in parking area.',
    '⛔ Vehicle parked in tow-away zone.',
    '🛞 Low tyre pressure / flat tyre observed.',
  ];

  @override
  void dispose() {
    _customMsgController.dispose();
    super.dispose();
  }

  void _sendPreset(String text) {
    Navigator.pop(context);
    widget.onMessageSent(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Vehicle Owner Connect', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('Your personal phone number is 100% masked', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
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

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scanned Vehicle Profile Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.plate,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Verified Owner',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.success),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(widget.vehicleName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(widget.location, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'ONE-TAP QUICK MESSAGES TO DRIVER:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 8),

                  ..._presets.map((msg) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () => _sendPreset(msg),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  msg,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.send_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Custom Message Input
                  const Text(
                    'OR TYPE A CUSTOM NOTE:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customMsgController,
                          maxLength: 140,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'e.g. Parked behind you at lower basement bay...',
                            hintStyle: const TextStyle(fontSize: 11, color: AppColors.outline),
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_customMsgController.text.trim().isNotEmpty) {
                            _sendPreset(_customMsgController.text.trim());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('Send', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Masked Anonymous Call Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onInitiateVoipCall();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text(
                        '📞 Call Owner (Masked VoIP Relay)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Zero exposure: Neither party will see the other\'s real phone number.',
                      style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// MODAL 2: Simulated Masked VoIP Call with Animated Equalizer Bars
// -----------------------------------------------------------------
class _SimulatedVoipCallDialog extends StatefulWidget {
  final String plate;

  const _SimulatedVoipCallDialog({required this.plate});

  @override
  State<_SimulatedVoipCallDialog> createState() => _SimulatedVoipCallDialogState();
}

class _SimulatedVoipCallDialogState extends State<_SimulatedVoipCallDialog> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  int _callSeconds = 0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startCallTimer();
  }

  void _startCallTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _callSeconds++);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _formatTimer() {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF34D399), width: 2),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF34D399), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              widget.plate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: AppColors.primaryFixed,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Motoro 256-bit Encrypted VoIP Bridge',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),

            // Animated Equalizer Waveform Bars
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final h = 10.0 + (18.0 * ((_waveController.value + (i * 0.2)) % 1.0));
                    return Container(
                      width: 4,
                      height: h,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 12),
            Text(
              'Connected to driver • ${_formatTimer()}',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Color(0xFF34D399),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🛡️ Audio relay connected via AWS/Airtel SIP Trunk',
                style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons: Mute, Hangup, Speaker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => setState(() => _isMuted = !_isMuted),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isMuted ? const Color(0xFFDC2626) : const Color(0xFF334155),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio routed to speakerphone.'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFF334155),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
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
