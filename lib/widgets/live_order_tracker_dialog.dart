import 'dart:async';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/local_db_service.dart';
import 'order_receipt_dialog.dart';

class LiveOrderTrackerDialog extends StatefulWidget {
  final OrderHistory order;
  final VoidCallback? onStatusChanged;

  const LiveOrderTrackerDialog({
    super.key,
    required this.order,
    this.onStatusChanged,
  });

  static Future<void> show(BuildContext context, OrderHistory order, {VoidCallback? onStatusChanged}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LiveOrderTrackerDialog(
        order: order,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  @override
  State<LiveOrderTrackerDialog> createState() => _LiveOrderTrackerDialogState();
}

class _LiveOrderTrackerDialogState extends State<LiveOrderTrackerDialog> with SingleTickerProviderStateMixin {
  late String _currentStatus;
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _remainingSeconds = 420; // 7 menit estimasi

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Pesanan Diterima',
      'subtitle': 'Sistem kasir Bu Sari telah mengonfirmasi pesanan Anda',
      'icon': Icons.receipt_long,
      'statusKey': 'Diterima',
    },
    {
      'title': 'Sedang Dimasak di Dapur 🍳',
      'subtitle': 'Ayam digeprek & sambal diracik segar oleh Bu Sari',
      'icon': Icons.soup_kitchen,
      'statusKey': 'Sedang Dimasak',
    },
    {
      'title': 'Siap Diambil / Diantar 🔔',
      'subtitle': 'Makanan siap di etalase counter atau siap diantar ke meja',
      'icon': Icons.notifications_active,
      'statusKey': 'Siap Diambil',
    },
    {
      'title': 'Pesanan Selesai 🎉',
      'subtitle': 'Selamat menikmati santapan lezat khas Bu Sari!',
      'icon': Icons.check_circle,
      'statusKey': 'Selesai',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startCountdown();
  }

  void _startCountdown() {
    if (_currentStatus == 'Selesai') {
      _remainingSeconds = 0;
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  int get _currentStepIndex {
    switch (_currentStatus.toLowerCase()) {
      case 'diterima':
        return 0;
      case 'sedang dimasak':
        return 1;
      case 'siap diambil':
        return 2;
      case 'selesai':
        return 3;
      default:
        return 1;
    }
  }

  Future<void> _advanceStatus() async {
    final nextIdx = (_currentStepIndex + 1);
    if (nextIdx < _steps.length) {
      final newStatus = _steps[nextIdx]['statusKey'] as String;
      setState(() {
        _currentStatus = newStatus;
        if (newStatus == 'Selesai') _remainingSeconds = 0;
      });

      await LocalDbService.instance.updateOrderStatus(widget.order.orderId, newStatus);
      widget.onStatusChanged?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pesanan diupdate: $newStatus!'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.deepOrange,
        ),
      );
    }
  }

  Future<void> _resetToStart() async {
    const newStatus = 'Sedang Dimasak';
    setState(() {
      _currentStatus = newStatus;
      _remainingSeconds = 420;
    });
    await LocalDbService.instance.updateOrderStatus(widget.order.orderId, newStatus);
    widget.onStatusChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeFormatted = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.radar, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Order Tracker',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Order #${widget.order.orderId}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Banner Estimasi Waktu Masak
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.15).animate(_pulseController),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentStepIndex == 3 ? Icons.celebration : Icons.timer,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentStepIndex == 3
                                ? 'Pesanan Selesai!'
                                : 'Estimasi Siap: $timeFormatted Menit',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _currentStepIndex == 3
                                ? 'Terima kasih telah makan di Kantin Bu Sari'
                                : (widget.order.isTakeaway
                                    ? 'Akan dipanggil di counter pengambilan'
                                    : 'Akan diantar ke ${widget.order.tableNumber}'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Daftar Item yang sedang disiapkan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.order.itemNames.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      widget.order.isTakeaway ? 'Bungkus' : widget.order.tableNumber,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Timeline Stepper Visual
              const Text(
                'STATUS PERJALANAN PESANAN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              ...List.generate(_steps.length, (index) {
                final isDone = index < _currentStepIndex;
                final isCurrent = index == _currentStepIndex;
                final isFuture = index > _currentStepIndex;
                final step = _steps[index];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom Icon & Line
                    Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? Colors.green
                                : (isCurrent ? primaryColor : (isDark ? Colors.grey[800] : Colors.grey[200])),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            isDone ? Icons.check : step['icon'] as IconData,
                            size: 18,
                            color: (isDone || isCurrent) ? Colors.white : Colors.grey[500],
                          ),
                        ),
                        if (index < _steps.length - 1)
                          Container(
                            width: 2,
                            height: 36,
                            color: isDone ? Colors.green : (isDark ? Colors.grey[800] : Colors.grey[300]),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Kolom Deskripsi
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  step['title'] as String,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                    color: isCurrent
                                        ? primaryColor
                                        : (isDone ? (isDark ? Colors.white : Colors.black87) : Colors.grey),
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 20),

              // Tombol Interaktif Simulasi & Struk
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('E-Receipt / QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        OrderReceiptDialog.show(
                          context,
                          widget.order.copyWith(status: _currentStatus),
                          onOpenTracker: () => LiveOrderTrackerDialog.show(
                            context,
                            widget.order.copyWith(status: _currentStatus),
                            onStatusChanged: widget.onStatusChanged,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(
                        _currentStepIndex >= 3 ? Icons.refresh : Icons.fast_forward,
                        size: 16,
                      ),
                      label: Text(
                        _currentStepIndex >= 3 ? 'Reset Uji Coba' : 'Update Dapur',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _currentStepIndex >= 3 ? _resetToStart : _advanceStatus,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
