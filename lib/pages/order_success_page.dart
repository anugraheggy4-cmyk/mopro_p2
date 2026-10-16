import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/formatters.dart';
import '../widgets/live_order_tracker_dialog.dart';
import '../widgets/order_receipt_dialog.dart';

class OrderSuccessPage extends StatelessWidget {
  final List<CartItem> items;
  final String tableNumber;
  final String paymentMethod;
  final bool isTakeaway;
  final int totalAmount;
  final String orderId;
  final int subtotal;
  final int serviceFee;
  final int discountAmount;

  const OrderSuccessPage({
    super.key,
    required this.items,
    required this.tableNumber,
    required this.paymentMethod,
    required this.isTakeaway,
    required this.totalAmount,
    this.orderId = 'BS-042',
    this.subtotal = 0,
    this.serviceFee = 0,
    this.discountAmount = 0,
  });

  OrderHistory get _asOrderHistory {
    return OrderHistory(
      orderId: orderId,
      orderDate: DateTime.now(),
      itemNames: items.map((i) => '${i.quantity}x ${i.menu.name}').toList(),
      totalAmount: totalAmount,
      subtotal: subtotal,
      discountAmount: discountAmount,
      serviceFee: serviceFee,
      status: 'Sedang Dimasak',
      tableNumber: tableNumber,
      paymentMethod: paymentMethod,
      isTakeaway: isTakeaway,
      detailedItems: items.map((i) => {
        'name': i.menu.name,
        'quantity': i.quantity,
        'price': i.menu.price,
        'spice': i.selectedSpiceLevel,
        'toppings': i.selectedToppings.map((t) => t.name).toList(),
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final computedSubtotal = subtotal > 0
        ? subtotal
        : items.fold<int>(0, (sum, item) => sum + item.itemPrice);
    final effectiveTotal = totalAmount > 0
        ? totalAmount
        : (computedSubtotal + serviceFee - discountAmount);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: const Text('Struk & Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // 1. Icon Sukses
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade400, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Judul
                Text(
                  'Pembayaran & Pesanan Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Data pesanan sudah tersimpan dan langsung diteruskan ke dapur Bu Sari.',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 3. Card Nomor Antrean
                Card(
                  elevation: 2,
                  color: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    child: Column(
                      children: [
                        const Text(
                          'NOMOR ANTREAN PESANAN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '#$orderId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Estimasi Selesai: ± 7-10 Menit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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

                // 4. Action Buttons (Live Tracker & QR E-Receipt)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.radar, size: 18),
                        label: const Text('Live Tracker 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          LiveOrderTrackerDialog.show(context, _asOrderHistory);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: primaryColor),
                          foregroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('E-Receipt & QR 🧾', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          OrderReceiptDialog.show(context, _asOrderHistory);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Struk Rincian Pesanan
                Card(
                  elevation: 1,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ringkasan Transaksi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Icon(Icons.receipt_long, size: 24, color: primaryColor),
                          ],
                        ),
                        Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                        _buildReceiptRow('Tempat Santap', isTakeaway ? 'Bungkus (Takeaway)' : tableNumber, isDark),
                        _buildReceiptRow('Metode Pembayaran', paymentMethod, isDark),
                        _buildReceiptRow('Status Pembayaran', 'Lunas / Berhasil', isDark, isHighlight: true),
                        _buildReceiptRow('Waktu Transaksi', 'Hari ini, ${TimeOfDay.now().format(context)}', isDark),
                        Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                        Text(
                          'Menu yang Dipesan:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...items.map((cartItem) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${cartItem.quantity}x ${cartItem.menu.name}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[200] : Colors.black87,
                                        ),
                                      ),
                                      if (cartItem.selectedSpiceLevel.isNotEmpty)
                                        Text(
                                          '• Level: ${cartItem.selectedSpiceLevel}',
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.orange[300] : Colors.deepOrange),
                                        ),
                                      if (cartItem.selectedToppings.isNotEmpty)
                                        Text(
                                          '• Topping: ${cartItem.selectedToppings.map((t) => t.name).join(", ")}',
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatRupiah(cartItem.itemPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[200] : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                        if (computedSubtotal > 0)
                          _buildReceiptRow('Subtotal Menu', formatRupiah(computedSubtotal), isDark),
                        if (serviceFee > 0)
                          _buildReceiptRow('Biaya Layanan Kantin', formatRupiah(serviceFee), isDark),
                        if (discountAmount > 0)
                          _buildReceiptRow('Diskon Voucher', '- ${formatRupiah(discountAmount)}', isDark, isHighlight: true),
                        if (computedSubtotal > 0 || serviceFee > 0 || discountAmount > 0)
                          Divider(height: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              formatRupiah(effectiveTotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Tombol Kembali
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Kembali ke Daftar Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isHighlight
                  ? Colors.green
                  : (isDark ? Colors.grey[200] : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
