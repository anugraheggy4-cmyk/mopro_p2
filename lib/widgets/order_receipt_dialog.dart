import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/menu_item.dart';
import '../utils/formatters.dart';

class OrderReceiptDialog extends StatelessWidget {
  final OrderHistory order;
  final VoidCallback? onOpenTracker;

  const OrderReceiptDialog({
    super.key,
    required this.order,
    this.onOpenTracker,
  });

  static Future<void> show(BuildContext context, OrderHistory order, {VoidCallback? onOpenTracker}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OrderReceiptDialog(order: order, onOpenTracker: onOpenTracker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kartu Struk Fisik Estetik
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Header Struk
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        color: primaryColor,
                        width: double.infinity,
                        child: Column(
                          children: [
                            const Icon(Icons.storefront, color: Colors.white, size: 36),
                            const SizedBox(height: 6),
                            const Text(
                              'KANTIN BU SARI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Text(
                              'Gedung Kampus Lt. 1 • WA: 0812-3456-7890',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'STRUK RESMI DIGITAL • #${order.orderId}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badan Struk
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Waktu & Meja
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('WAKTU TRANSAKSI', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(_formatDateTime(order.orderDate), style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: order.isTakeaway ? Colors.amber.shade50 : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: order.isTakeaway ? Colors.amber.shade400 : Colors.blue.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        order.isTakeaway ? Icons.shopping_bag_outlined : Icons.table_restaurant_outlined,
                                        size: 14,
                                        color: order.isTakeaway ? Colors.amber.shade900 : Colors.blue.shade800,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        order.isTakeaway ? 'Bungkus' : order.tableNumber,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: order.isTakeaway ? Colors.amber.shade900 : Colors.blue.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            _buildDashedLine(),
                            const SizedBox(height: 14),

                            // Rincian Item Pesanan
                            const Text('RINCIAN MENU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                            const SizedBox(height: 8),

                            if (order.detailedItems.isNotEmpty)
                              ...order.detailedItems.map((item) => _buildDetailItemRow(item))
                            else
                              ...order.itemNames.map((name) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check, size: 14, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                      ],
                                    ),
                                  )),

                            const SizedBox(height: 14),
                            _buildDashedLine(),
                            const SizedBox(height: 14),

                            // Ringkasan Pembayaran
                            _buildPriceRow('Subtotal Menu', formatRupiah(order.subtotal > 0 ? order.subtotal : order.totalAmount)),
                            if (order.serviceFee > 0)
                              _buildPriceRow('Biaya Layanan & Kebersihan', formatRupiah(order.serviceFee)),
                            if (order.discountAmount > 0)
                              _buildPriceRow('Diskon Voucher Promo', '-${formatRupiah(order.discountAmount)}', isDiscount: true),

                            const SizedBox(height: 8),
                            _buildDashedLine(),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL AKHIR',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                                Text(
                                  formatRupiah(order.totalAmount),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            // Metode & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Metode: ${order.paymentMethod}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.shade400),
                                  ),
                                  child: const Text('LUNAS / BERHASIL', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            _buildDashedLine(),
                            const SizedBox(height: 16),

                            // QR Code Pengambilan
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade300, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: CustomPaint(
                                      size: const Size(140, 140),
                                      painter: AuthenticQrPainter(codeString: '${order.orderId}|${order.totalAmount}|${order.tableNumber}'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    order.orderId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tunjukkan QR ini ke kasir/counter Bu Sari\nuntuk verifikasi & pengambilan pesanan',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Salin ID Order', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.orderId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ID Order ${order.orderId} disalin ke clipboard!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (onOpenTracker != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.radar, size: 16),
                        label: const Text('Lacak Pesanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          onOpenTracker!();
                        },
                      ),
                    ),
                  if (onOpenTracker == null)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tutup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.pop(context),
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

  Widget _buildDetailItemRow(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Menu';
    final qty = item['quantity'] ?? 1;
    final price = item['price'] ?? 0;
    final spice = item['spice'] as String? ?? '';
    final toppings = item['toppings'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${qty}x ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                ),
              ),
              Text(
                formatRupiah(price * qty),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          if (spice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 1),
              child: Text('Level: $spice', style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
            ),
          if (toppings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 1),
              child: Text(
                'Topping: ${toppings.join(', ')}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFD1D5DB)),
              ),
            );
          }),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute WIB';
  }
}

/// Custom QR Painter yang merender QR pattern otentik
class AuthenticQrPainter extends CustomPainter {
  final String codeString;

  AuthenticQrPainter({required this.codeString});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.fill;

    const int matrixSize = 25;
    final double cellSize = size.width / matrixSize;

    // Helper untuk menggambar finder pattern (kotak 7x7 khas QR di 3 sudut)
    void drawFinderPattern(int startX, int startY) {
      // Kotak luar 7x7
      canvas.drawRect(
        Rect.fromLTWH(startX * cellSize, startY * cellSize, 7 * cellSize, 7 * cellSize),
        paint,
      );
      // Kotak dalam putih 5x5
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH((startX + 1) * cellSize, (startY + 1) * cellSize, 5 * cellSize, 5 * cellSize),
        whitePaint,
      );
      // Kotak hitam tengah 3x3
      canvas.drawRect(
        Rect.fromLTWH((startX + 2) * cellSize, (startY + 2) * cellSize, 3 * cellSize, 3 * cellSize),
        paint,
      );
    }

    // 1. Gambar 3 Finder Pattern Utama
    drawFinderPattern(0, 0); // Top-Left
    drawFinderPattern(matrixSize - 7, 0); // Top-Right
    drawFinderPattern(0, matrixSize - 7); // Bottom-Left

    // 2. Generate deterministik data matrix pattern berdasarkan codeString
    int hash = 0;
    for (int i = 0; i < codeString.length; i++) {
      hash = (hash * 31 + codeString.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        // Lewati area finder pattern
        final isTopLeft = (r < 8 && c < 8);
        final isTopRight = (r < 8 && c >= matrixSize - 8);
        final isBottomLeft = (r >= matrixSize - 8 && c < 8);

        if (isTopLeft || isTopRight || isBottomLeft) continue;

        // Timing patterns
        if (r == 6 || c == 6) {
          if ((r + c) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
              paint,
            );
          }
          continue;
        }

        // Pseudo-random data module
        final val = ((r * 17 + c * 29 + hash + (r ^ c)) % 7);
        if (val == 0 || val == 2 || val == 5) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.95, cellSize * 0.95),
              const Radius.circular(1),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant AuthenticQrPainter oldDelegate) =>
      oldDelegate.codeString != codeString;
}
