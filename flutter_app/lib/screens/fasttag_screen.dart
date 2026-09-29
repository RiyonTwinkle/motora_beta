import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_top_nav_bar.dart';
import '../widgets/master_top_app_bar.dart';
import 'payment_gateway_screen.dart';

class FastTagScreen extends StatefulWidget {
  final VehicleItem? initialVehicle;

  const FastTagScreen({
    super.key,
    this.initialVehicle,
  });

  @override
  State<FastTagScreen> createState() => _FastTagScreenState();
}

class _FastTagScreenState extends State<FastTagScreen> {
  VehicleItem? _vehicle;
  List<VehicleItem> _allVehicles = [];
  bool _isLoading = true;

  // FASTag State
  double _balance = 3450.00;
  String _tagSerial = 'NETC-3416-8901-2290';
  String _partnerBank = 'ICICI BANK PARTNER';

  // Recharge Mode & Selection
  String _rechargeMode = 'wallet'; // 'wallet' or 'pass'
  double _selectedAmount = 1000.00;
  String _selectedPassTitle = 'Instant Wallet Balance Credit';
  final TextEditingController _customAmountCtrl = TextEditingController(text: '1000');

  // Success Banner state
  bool _showSuccessBanner = false;
  String _lastTxnId = 'NETC8921739';
  double _lastCreditedAmount = 1000.00;

  // Transaction Log Filter
  String _txnFilter = 'all';

  // Toll Activity List
  final List<Map<String, dynamic>> _allTransactions = [
    {
      'plaza': 'Khalapur Plaza (Mumbai-Pune Exp)',
      'subtitle': 'MSRDC Tollway Km 32.4',
      'plate': 'MH 12 RN 2024',
      'lane': 'LANE-04 / FASTAG-RFID',
      'time': 'Today, 04:12 PM',
      'amount': -110.00,
      'status': 'Cleared',
      'isCredit': false,
      'isPass': false,
    },
    {
      'plaza': 'Bandra-Worli Sea Link Toll',
      'subtitle': 'Monthly Pass Pass-Through',
      'plate': 'MH 12 RN 2024',
      'lane': 'LANE-02 / PASS-VERIFIED',
      'time': 'Yesterday, 09:30 AM',
      'amount': 0.00,
      'status': 'Pass Valid',
      'isCredit': false,
      'isPass': true,
    },
    {
      'plaza': 'UPI Wallet Top-Up (GPay)',
      'subtitle': 'Txn: NETC7781023 • ICICI Netc',
      'plate': 'MH 12 RN 2024',
      'lane': 'BBPS-UPI-PAYMENT',
      'time': '02 Sep, 11:15 AM',
      'amount': 2000.00,
      'status': 'Success',
      'isCredit': true,
      'isPass': false,
    },
    {
      'plaza': 'Khedshivapur Plaza (NH48)',
      'subtitle': 'NHAI National Toll Lane 01',
      'plate': 'MH 12 RN 2024',
      'lane': 'LANE-01 / FASTAG-AUTO',
      'time': '28 Aug, 07:45 PM',
      'amount': -105.00,
      'status': 'Cleared',
      'isCredit': false,
      'isPass': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _vehicle = widget.initialVehicle;
    _loadData();
  }

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summary = await ApiService.getFleetSummary();
    final vehicles = await ApiService.getVehicles();
    if (mounted) {
      setState(() {
        _allVehicles = vehicles;
        _balance = summary.tollWalletBalance > 0 ? summary.tollWalletBalance : 3450.00;
        if (_vehicle == null && vehicles.isNotEmpty) {
          _vehicle = vehicles.firstWhere((v) => v.isSelected, orElse: () => vehicles.first);
        } else if (_vehicle != null) {
          _vehicle = vehicles.firstWhere((v) => v.vin == _vehicle!.vin, orElse: () => _vehicle!);
        }
        if (_vehicle != null) {
          _tagSerial = _vehicle!.fastTagId.isNotEmpty ? _vehicle!.fastTagId : 'NETC-3416-8901-2290';
          if (_vehicle!.name.contains('Nexon')) {
            _partnerBank = 'HDFC BANK PARTNER';
          } else if (_vehicle!.name.contains('Thar')) {
            _partnerBank = 'SBI FASTAG PARTNER';
          } else {
            _partnerBank = 'ICICI BANK PARTNER';
          }
        }
        _isLoading = false;
      });
    }
  }

  void _switchVehicle(VehicleItem v) async {
    setState(() {
      _vehicle = v;
      for (var car in _allVehicles) {
        car.isSelected = (car.vin == v.vin);
      }
      _tagSerial = v.fastTagId.isNotEmpty ? v.fastTagId : 'NETC-3416-8901-2290';
      if (v.name.contains('Nexon')) {
        _partnerBank = 'HDFC BANK PARTNER';
      } else if (v.name.contains('Thar')) {
        _partnerBank = 'SBI FASTAG PARTNER';
      } else {
        _partnerBank = 'ICICI BANK PARTNER';
      }
    });
    await ApiService.selectVehicle(v.vin);
  }

  void _refreshBalance() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _balance += 50.0;
      _isLoading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('FASTag balance synchronized with IHMCL NETC Gateway.'),
      ),
    );
  }

  void _onRechargeSuccess(double amt) {
    final txn = 'NETC${math.Random().nextInt(9000000) + 1000000}';
    setState(() {
      _balance += amt;
      _lastTxnId = txn;
      _lastCreditedAmount = amt;
      _showSuccessBanner = true;
      _allTransactions.insert(0, {
        'plaza': 'UPI Wallet Top-Up (Payment Gateway)',
        'subtitle': 'Txn: $txn • $_partnerBank',
        'plate': _vehicle?.registrationPlate ?? 'MH 12 RN 2024',
        'lane': 'BBPS-UPI-PAYMENT',
        'time': 'Just Now',
        'amount': amt,
        'status': 'Success',
        'isCredit': true,
        'isPass': false,
      });
    });
  }

  void _proceedToPaymentGateway() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentGatewayScreen(
          amount: _selectedAmount,
          itemTitle: 'FastTag Recharge: $_selectedPassTitle',
          itemSubtitle: 'Vehicle: ${_vehicle?.registrationPlate ?? 'MH 12 RN 2024'} ($_tagSerial)',
          onPaymentSuccess: () => _onRechargeSuccess(_selectedAmount),
        ),
      ),
    );
  }

  void _showReceiptModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.verified_rounded, color: AppColors.emerald, size: 22),
                const SizedBox(width: 8),
                const Text('NETC FASTag Tax Invoice', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Transaction Status:', 'PAID & CREDITED', isStatus: true),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Transaction ID:', _lastTxnId, isMono: true),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Vehicle Number:', _vehicle?.registrationPlate ?? 'MH 12 RN 2024', isMono: true),
                  const SizedBox(height: 6),
                  _buildReceiptRow('FastTag Serial:', _tagSerial, isMono: true),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Payment Method:', 'UPI (BHIM / Bharat BillPay)'),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Timestamp:', '04 Sep 2026, 09:32 PM'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount Paid:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                Text(
                  '₹${_lastCreditedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Outfit', color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isMono = false, bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald)),
              )
            : Text(
                value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: isMono ? 'monospace' : null, color: AppColors.onSurface),
              ),
      ],
    );
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_txnFilter == 'toll') {
      return _allTransactions.where((t) => !(t['isCredit'] as bool)).toList();
    } else if (_txnFilter == 'recharge') {
      return _allTransactions.where((t) => t['isCredit'] as bool).toList();
    }
    return _allTransactions;
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
              currentVehicle: _vehicle,
              vehicles: _allVehicles,
              onVehicleChanged: _switchVehicle,
            ),

            // SECONDARY 5-PILL NAVIGATION DOCK
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
                          // SUCCESS BANNER (Shown upon recharge)
                          if (_showSuccessBanner) _buildSuccessBanner(),

                          // SECTION 1: HOLOGRAPHIC FASTAG PASS CARD & LIVE WALLET SUMMARY
                          _buildSection1PassCardAndWallet(),
                          const SizedBox(height: 18),

                          // SECTION 2: QUICK RECHARGE & PLAZA PASS SELECTION
                          _buildSection2RechargeAndPasses(),
                          const SizedBox(height: 18),

                          // SECTION 3: RECENT TOLL CROSSINGS & ACTIVITY
                          _buildSection3TollActivity(),
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
      currentIndex: 4, // FastTag tab
      currentVehicle: _vehicle,
    );
  }

  // SUCCESS NOTIFICATION BANNER
  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('FastTag Recharge Successful!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.emerald)),
                    const SizedBox(width: 6),
                    Text('• NPCI NETC Verified', style: TextStyle(fontSize: 10, color: AppColors.emerald, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_lastCreditedAmount.toStringAsFixed(2)} credited to $_tagSerial. Txn ID: $_lastTxnId',
                  style: TextStyle(fontSize: 11, color: AppColors.emerald),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showReceiptModal,
            child: Text('Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.emerald)),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: AppColors.emerald),
            onPressed: () => setState(() => _showSuccessBanner = false),
          ),
        ],
      ),
    );
  }

  // SECTION 1: HOLOGRAPHIC FASTAG PASS CARD & LIVE WALLET SUMMARY
  Widget _buildSection1PassCardAndWallet() {
    return Column(
      children: [
        // Holographic FASTag Pass Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF013837),
                Color(0xFF00605E),
                Color(0xFF006A68),
                Color(0xFF189895),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Metallic Chip, Contactless Waves, NETC Issuer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Metallic Chip
                      Container(
                        width: 36,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFFAE69E), Color(0xFFB8860B)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 14,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.wifi_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                        child: const Text('RFID PASS', style: TextStyle(color: AppColors.primaryFixed, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Row(
                        children: [
                          Text('NETC ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('FASTag', style: TextStyle(color: AppColors.primaryFixed, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      Text(_partnerBank, style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Middle: Tag Serial Number & Barcode Simulation
              const Text('RFID TAG SERIAL NO.', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryFixedDim, letterSpacing: 1.0)),
              const SizedBox(height: 2),
              Text(
                _tagSerial,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.white, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),

              // Barcode Visualizer
              Container(
                height: 10,
                width: 180,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                child: Row(
                  children: List.generate(
                    20,
                    (i) => Expanded(
                      flex: (i % 3 == 0) ? 2 : 1,
                      child: Container(color: (i % 2 == 0) ? Colors.white : Colors.transparent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),

              // Bottom Row: HSRP Plate, Vehicle Model, KYC Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // HSRP Plate Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black87),
                        ),
                        child: Row(
                          children: [
                            const Text('IND ', style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.w900)),
                            Text(
                              _vehicle?.registrationPlate ?? 'MH 12 RN 2024',
                              style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(_vehicle?.name ?? 'Mahindra XUV700 AX7 L', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                        const SizedBox(width: 4),
                        const Text('KYC Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Balance Card & 3 Metrics
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('NETC WALLET AVAILABLE BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                          const SizedBox(width: 6),
                          CircleAvatar(radius: 3, backgroundColor: AppColors.emerald),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Outfit', color: AppColors.onSurface),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('Sufficient for ~28 Tolls', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.emerald)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _refreshBalance,
                    icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
                    tooltip: 'Sync IHMCL NETC',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 3 Quick Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildWalletMetricTile('MONTHLY TOLLS', '₹1,840', '16 Crossings', Icons.trending_up_rounded, AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildWalletMetricTile('LOW BAL ALERT', '₹200', 'Threshold Safe', Icons.notifications_active_rounded, Colors.amber.shade700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildWalletMetricTile('BLACKLIST STATUS', 'Clean', '0 Violations', Icons.verified_rounded, AppColors.emerald),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bandra-Worli Sea Link Monthly Pass Active Strip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_police_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Bandra-Worli Sea Link Pass', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _rechargeMode = 'pass';
                          _selectedAmount = 3000.0;
                          _selectedPassTitle = 'Bandra-Worli Sea Link (50 Trips Pass)';
                        });
                      },
                      child: const Row(
                        children: [
                          Text('Renew', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletMetricTile(String label, String val, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppColors.onSurface)),
        ],
      ),
    );
  }

  // SECTION 2: QUICK RECHARGE & PLAZA PASS SELECTION
  Widget _buildSection2RechargeAndPasses() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text('Quick FastTag Recharge', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildModeToggleBtn('Wallet Top-Up', 'wallet'),
                    _buildModeToggleBtn('Toll Pass', 'pass'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Content based on Mode
          if (_rechargeMode == 'wallet') ...[
            // 6 Quick Amount Chips
            const Text('SELECT QUICK RECHARGE AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRechargeChip('Quick Top', 250),
                _buildRechargeChip('Standard', 500),
                _buildRechargeChip('Popular', 1000),
                _buildRechargeChip('Expressway', 2000),
                _buildRechargeChip('Fleet Pack', 3000),
                _buildRechargeChip('Pro Max', 5000),
              ],
            ),
            const SizedBox(height: 14),

            // Custom Amount Input
            TextField(
              controller: _customAmountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final amt = double.tryParse(val);
                if (amt != null) {
                  setState(() {
                    _selectedAmount = amt;
                    _selectedPassTitle = 'Custom FastTag Recharge';
                  });
                }
              },
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'Or Enter Custom Amount (₹100 - ₹50,000)',
                prefixText: '₹ ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _customAmountCtrl.clear();
                    setState(() => _selectedAmount = 0.0);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQuickAddBtn(500),
                const SizedBox(width: 8),
                _buildQuickAddBtn(1000),
                const SizedBox(width: 8),
                _buildQuickAddBtn(2000),
              ],
            ),
          ] else ...[
            // Toll Plaza Pass Mode
            const Text('SELECT INDIAN EXPRESSWAY / TOLL PLAZA PASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            const SizedBox(height: 10),
            _buildPassOptionTile('Bandra-Worli Sea Link', 'Mumbai MEPL Toll • 50 Trips / 1 Month', 3000, 'Saves ₹1,250 vs Single'),
            const SizedBox(height: 8),
            _buildPassOptionTile('Mumbai-Pune Expressway', 'Khalapur & Talegaon Plazas • Unlimited', 4200, 'NHAI Pass • 30 Days'),
            const SizedBox(height: 8),
            _buildPassOptionTile('Delhi-Gurgaon Kherki Daula', 'Kherki Daula Plaza • Monthly Pass', 800, 'Resident Scheme • 30 Days'),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Billing Summary & Proceed Button
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recharge Target:', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                    Text('${_vehicle?.registrationPlate ?? 'MH 12 RN 2024'} ($_tagSerial)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mode / Package:', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                    Text(_selectedPassTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Convenience Fee:', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                    Text('₹0.00 (Zero Fee via BBPS & UPI)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emerald)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount Payable:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                    Text(
                      '₹${_selectedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Outfit', color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _selectedAmount > 0 ? _proceedToPaymentGateway : null,
              icon: const Icon(Icons.lock_rounded, size: 18),
              label: Text('Proceed to Payment Gateway (₹${_selectedAmount.toStringAsFixed(0)}) →', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 12, color: AppColors.emerald),
                const SizedBox(width: 4),
                const Text('256-Bit SSL • NPCI NETC Certified • Instant FastTag Sync', style: TextStyle(fontSize: 9, color: AppColors.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleBtn(String title, String mode) {
    final isActive = _rechargeMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _rechargeMode = mode;
          if (mode == 'wallet') {
            _selectedAmount = 1000.0;
            _selectedPassTitle = 'Instant Wallet Balance Credit';
            _customAmountCtrl.text = '1000';
          } else {
            _selectedAmount = 3000.0;
            _selectedPassTitle = 'Bandra-Worli Sea Link (50 Trips Pass)';
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppColors.secondary),
        ),
      ),
    );
  }

  Widget _buildRechargeChip(String label, double amount) {
    final isSelected = _selectedAmount == amount;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAmount = amount;
          _selectedPassTitle = 'Instant Wallet Balance Credit';
          _customAmountCtrl.text = amount.toInt().toString();
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: isSelected ? AppColors.primaryFixed : AppColors.secondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              '₹${amount.toInt()}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: isSelected ? Colors.white : AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddBtn(int add) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          final curr = double.tryParse(_customAmountCtrl.text) ?? 0.0;
          final next = curr + add;
          setState(() {
            _selectedAmount = next;
            _customAmountCtrl.text = next.toInt().toString();
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text('+₹$add', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
      ),
    );
  }

  Widget _buildPassOptionTile(String title, String subtitle, double cost, String tag) {
    final isSelected = _selectedAmount == cost && _selectedPassTitle.contains(title);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAmount = cost;
          _selectedPassTitle = '$title Pass';
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text(tag, style: const TextStyle(fontSize: 8, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            Text('₹${cost.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  // SECTION 3: RECENT TOLL CROSSINGS & ACTIVITY
  Widget _buildSection3TollActivity() {
    final filtered = _filteredTransactions;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Toll Crossings & Pass Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  Text(' ', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                ],
              ),
              DropdownButton<String>(
                value: _txnFilter,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Events')),
                  DropdownMenuItem(value: 'toll', child: Text('Tolls Only')),
                  DropdownMenuItem(value: 'recharge', child: Text('Recharges')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _txnFilter = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Activity Items
          ...filtered.map((t) => _buildTollActivityTile(t)),
        ],
      ),
    );
  }

  Widget _buildTollActivityTile(Map<String, dynamic> item) {
    final isCredit = item['isCredit'] as bool;
    final isPass = item['isPass'] as bool;
    final amt = item['amount'] as double;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isCredit
                      ? Colors.blue.withValues(alpha: 0.1)
                      : (isPass ? AppColors.primary.withValues(alpha: 0.1) : AppColors.emerald.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCredit ? Icons.account_balance_wallet_rounded : Icons.toll_rounded,
                  color: isCredit ? Colors.blue : (isPass ? AppColors.primary : AppColors.emerald),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['plaza'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  Text('${item['subtitle']} • ${item['time']}', style: const TextStyle(fontSize: 9, color: AppColors.secondary)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCredit
                    ? '+₹${amt.toStringAsFixed(2)}'
                    : (isPass ? '₹0.00 (Pass)' : '-₹${amt.abs().toStringAsFixed(2)}'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isCredit ? AppColors.emerald : (isPass ? AppColors.primary : AppColors.onSurface),
                ),
              ),
              Text(
                item['status'] as String,
                style: TextStyle(fontSize: 9, color: isCredit || isPass ? AppColors.emerald : AppColors.secondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
