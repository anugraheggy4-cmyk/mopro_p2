import 'dart:async';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';
import '../services/local_db_service.dart';
import '../utils/formatters.dart';
import 'order_success_page.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  String selectedTable = 'Meja 03 (Dekat Jendela)';
  final List<String> tableOptions = [
    'Meja 01 (Depan Kasir)',
    'Meja 02 (Area Tengah)',
    'Meja 03 (Dekat Jendela)',
    'Meja 04 (Area Belakang)',
    'Meja 05 (Outdoor)',
    'Meja 06 (Lesehan)',
  ];

  String paymentMethod = 'QRIS Instant';
  final List<Map<String, dynamic>> paymentOptions = [
    {
      'id': 'QRIS Instant',
      'title': 'QRIS (GoPay, OVO, Dana, ShopeePay, M-Banking)',
      'icon': Icons.qr_code_scanner,
      'badge': 'Otomatis'
    },
    {
      'id': 'Tunai di Kasir',
      'title': 'Bayar Tunai Langsung ke Bu Sari di Gerai',
      'icon': Icons.payments_outlined,
      'badge': 'Manual'
    },
    {
      'id': 'Saldo Mahasiswa',
      'title': 'Kartu Mahasiswa / Labkom Pay (Database Lokal)',
      'icon': Icons.account_balance_wallet,
      'badge': 'Instan'
    },
  ];

  bool isTakeaway = false;
  bool needCutlery = true;
  String discountCode = '';
  int discountAmount = 0;
  final TextEditingController _voucherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    CartService.instance.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onCartUpdated);
    _voucherController.dispose();
    super.dispose();
  }

  void _onCartUpdated() {
    if (mounted) setState(() {});
  }

  List<CartItem> get cartItems => CartService.instance.items;
  int get subtotal => CartService.instance.subtotal;
  int get serviceFee => cartItems.isEmpty ? 0 : 1000;
  int get finalTotal {
    int total = subtotal + serviceFee - discountAmount;
    return total < 0 ? 0 : total;
  }

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (code == 'HEMATKANTIN') {
      setState(() {
        discountAmount = (subtotal * 0.20).round();
        discountCode = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Voucher HEMATKANTIN aktif! Diskon 20% (${formatRupiah(discountAmount)})'),
        ),
      );
    } else if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode voucher terlebih dahulu.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Kode voucher tidak valid atau sudah kedaluwarsa.'),
        ),
      );
    }
  }

  // ALUR SIMULASI PEMBAYARAN NYATA
  Future<void> _handlePaymentFlow() async {
    if (cartItems.isEmpty) return;

    if (paymentMethod == 'QRIS Instant') {
      _showQrisPaymentDialog();
    } else if (paymentMethod == 'Saldo Mahasiswa') {
      _showWalletPaymentDialog();
    } else {
      _showCashPaymentDialog();
    }
  }

  // 1. DIALOG SIMULASI PEMBAYARAN QRIS NYATA
  void _showQrisPaymentDialog() {
    int remainingSeconds = 900; // 15 menit
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (remainingSeconds > 0) {
                setDialogState(() => remainingSeconds--);
              } else {
                t.cancel();
              }
            });

            final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
            final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: const Text(
                      'QRIS',
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Scan QRIS untuk Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selesaikan pembayaran dalam waktu $minutes:$seconds',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),

                    // Kotak QR Code Realistis
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront, size: 16, color: Colors.deepOrange),
                              SizedBox(width: 6),
                              Text(
                                'Kantin Bu Sari - Labkom',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // QR Code Container
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400, width: 1.5),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.qr_code_2, size: 160, color: Colors.black87),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.deepOrange, width: 2),
                                  ),
                                  child: const Icon(Icons.restaurant, size: 20, color: Colors.deepOrange),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'NMID: ID1020268891238',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatRupiah(finalTotal),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Petunjuk e-wallet
                    Text(
                      'Mendukung GoPay, OVO, DANA, ShopeePay, BCA, Mandiri, dll.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Tombol Simulasi Sukses
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          timer?.cancel();
                          Navigator.pop(ctx);
                          _finishOrderSuccess();
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Simulasikan Pembayaran Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. DIALOG PEMBAYARAN SALDO MAHASISWA
  Future<void> _showWalletPaymentDialog() async {
    final currentBal = await LocalDbService.instance.getWalletBalance();

    if (!mounted) return;

    if (currentBal < finalTotal) {
      // Saldo Kurang
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Saldo Tidak Cukup'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo Labkom Pay Anda saat ini: ${formatRupiah(currentBal)}'),
              const SizedBox(height: 6),
              Text('Total tagihan pesanan: ${formatRupiah(finalTotal)}'),
              const SizedBox(height: 12),
              const Text(
                'Silakan pilih metode bayar lain (QRIS / Tunai) atau Top Up saldo di halaman Profil.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ganti Metode Bayar')),
          ],
        ),
      );
      return;
    }

    // Saldo Cukup - Konfirmasi Potong Saldo
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.credit_card, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Konfirmasi Potong Saldo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo awal: ${formatRupiah(currentBal)}'),
            Text('Potongan: ${formatRupiah(finalTotal)}', style: const TextStyle(color: Colors.red)),
            const Divider(height: 16),
            Text(
              'Sisa saldo setelah bayar: ${formatRupiah(currentBal - finalTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalDbService.instance.updateWalletBalance(currentBal - finalTotal);
              _finishOrderSuccess();
            },
            child: const Text('Bayar Sekarang'),
          ),
        ],
      ),
    );
  }

  // 3. DIALOG PEMBAYARAN TUNAI DI KASIR
  void _showCashPaymentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Instruksi Bayar Tunai'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan Anda akan langsung diteruskan ke dapur Bu Sari.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mohon siapkan uang pas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(finalTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.deepOrange)),
                  const SizedBox(height: 6),
                  const Text('Tunjukkan nomor antrean digital ke kasir Bu Sari.', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _finishOrderSuccess();
            },
            child: const Text('Buat Pesanan'),
          ),
        ],
      ),
    );
  }

  // FINALIZE & SAVE ORDER
  Future<void> _finishOrderSuccess() async {
    // Tampilkan loading sebentar
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.deepOrange),
                SizedBox(height: 16),
                Text('Menyimpan ke database lokal laptop...'),
              ],
            ),
          ),
        ),
      ),
    );

    final generatedOrderId = 'BS-${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}';
    final savedItems = List<CartItem>.from(cartItems);
    final savedTotal = finalTotal;
    final savedSubtotal = subtotal;
    final savedDiscountAmount = discountAmount;
    final savedServiceFee = serviceFee;

    final newOrder = OrderHistory(
      orderId: generatedOrderId,
      orderDate: DateTime.now(),
      itemNames: savedItems.map((e) => '${e.quantity}x ${e.menu.name}').toList(),
      totalAmount: savedTotal,
      subtotal: savedSubtotal,
      discountAmount: savedDiscountAmount,
      serviceFee: savedServiceFee,
      status: 'Sedang Dimasak',
      tableNumber: isTakeaway ? 'Bungkus (Takeaway)' : selectedTable,
      paymentMethod: paymentMethod,
      isTakeaway: isTakeaway,
      detailedItems: savedItems.map((e) => {
        'name': e.menu.name,
        'quantity': e.quantity,
        'price': e.itemPrice,
        'spice': e.selectedSpiceLevel,
        'toppings': e.selectedToppings.map((t) => t.name).join(', '),
        'notes': e.specialNotes,
      }).toList(),
    );

    // Simpan ke database lokal SharedPreferences
    await LocalDbService.instance.saveOrder(newOrder);

    // Kosongkan keranjang belanja
    CartService.instance.clearCart();

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSuccessPage(
          items: savedItems,
          tableNumber: selectedTable,
          paymentMethod: paymentMethod,
          isTakeaway: isTakeaway,
          totalAmount: savedTotal,
          orderId: generatedOrderId,
          subtotal: savedSubtotal,
          serviceFee: savedServiceFee,
          discountAmount: savedDiscountAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrWeb = screenWidth >= 850;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Keranjang Belanja & Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                if (cartItems.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () {
                      CartService.instance.clearCart();
                    },
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Kosongkan'),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: cartItems.isEmpty
          // 1. TAMPILAN KERANJANG KOSONG (EMPTY STATE)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.deepOrange.shade300),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Keranjang Belanja Masih Kosong',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kamu belum menambahkan menu makanan atau minuman. Yuk pilih menu lezat di Kantin Bu Sari!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Mulai Pilih Menu Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // 2. TAMPILAN JIKA KERANJANG BERISI
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: isDesktopOrWeb
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kolom Kiri
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTableAndOptionCard(primaryColor),
                                  const SizedBox(height: 16),
                                  _buildPaymentMethodCard(primaryColor),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Kolom Kanan
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCartItemsList(primaryColor),
                                  const SizedBox(height: 16),
                                  _buildVoucherCard(primaryColor),
                                  const SizedBox(height: 16),
                                  _buildSummaryAndCheckout(primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTableAndOptionCard(primaryColor),
                            const SizedBox(height: 16),
                            _buildCartItemsList(primaryColor),
                            const SizedBox(height: 16),
                            _buildVoucherCard(primaryColor),
                            const SizedBox(height: 16),
                            _buildPaymentMethodCard(primaryColor),
                            const SizedBox(height: 16),
                            _buildSummaryAndCheckout(primaryColor),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ),
    );
  }

  Widget _buildTableAndOptionCard(Color primaryColor) {
    return Card(
      elevation: 0.8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.place, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text('Informasi Meja & Tempat Santap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
            if (!isTakeaway) ...[
              const Text('Nomor Meja Kamu di Kantin:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedTable,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: tableOptions.map((table) {
                  return DropdownMenuItem(value: table, child: Text(table, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedTable = val);
                },
              ),
              const SizedBox(height: 12),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: primaryColor,
              title: const Text('Bungkus / Take Away', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Pesanan dikemas kotak untuk dibawa pulang/ke lab', style: TextStyle(fontSize: 12)),
              value: isTakeaway,
              onChanged: (val) => setState(() => isTakeaway = val),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: primaryColor,
              title: const Text('Sertakan Sendok & Sedotan', style: TextStyle(fontSize: 14)),
              value: needCutlery,
              onChanged: (val) => setState(() => needCutlery = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daftar Menu (${cartItems.length} Macam)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${CartService.instance.totalCount} Porsi', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 8),
        ...cartItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0.8,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.menu.imageUrl,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 68,
                        height: 68,
                        color: Colors.deepOrange.shade100,
                        child: const Icon(Icons.fastfood, color: Colors.deepOrange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.menu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (item.selectedSpiceLevel.isNotEmpty)
                          Text('Varian: ${item.selectedSpiceLevel}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        if (item.selectedToppings.isNotEmpty)
                          Text('Topping: ${item.selectedToppings.map((t) => t.name).join(", ")}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        if (item.specialNotes.isNotEmpty)
                          Text('Catatan: "${item.specialNotes}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(formatRupiah(item.itemPrice), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => CartService.instance.removeItem(index),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => CartService.instance.updateQuantity(index, item.quantity - 1),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            InkWell(
                              onTap: () => CartService.instance.updateQuantity(index, item.quantity + 1),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVoucherCard(Color primaryColor) {
    return Card(
      elevation: 0.8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _voucherController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Kode Voucher (Cth: HEMATKANTIN)',
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _applyVoucher,
              child: const Text('Terapkan', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          elevation: 0.8,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: paymentOptions.map((opt) {
              final isSelected = paymentMethod == opt['id'];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? primaryColor.withValues(alpha: 0.05) : null,
                leading: Icon(opt['icon'] as IconData, color: isSelected ? primaryColor : Colors.grey),
                title: Row(
                  children: [
                    Text(
                      opt['id'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        color: isSelected ? primaryColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepOrange.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        opt['badge'] as String,
                        style: TextStyle(fontSize: 10, color: isSelected ? Colors.deepOrange : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(opt['title'] as String, style: const TextStyle(fontSize: 12)),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? primaryColor : Colors.grey,
                ),
                onTap: () => setState(() => paymentMethod = opt['id'] as String),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryAndCheckout(Color primaryColor) {
    return Column(
      children: [
        Card(
          elevation: 0.8,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan Biaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 20),
                _buildCostRow('Subtotal Menu', formatRupiah(subtotal)),
                _buildCostRow('Biaya Layanan Kantin', formatRupiah(serviceFee)),
                if (discountAmount > 0)
                  _buildCostRow('Diskon Voucher ($discountCode)', '- ${formatRupiah(discountAmount)}', textColor: Colors.green),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      formatRupiah(finalTotal),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: _handlePaymentFlow,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              'Konfirmasi & Bayar (${formatRupiah(finalTotal)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String title, String amount, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
