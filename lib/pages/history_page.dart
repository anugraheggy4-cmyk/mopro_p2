import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/local_db_service.dart';
import '../utils/formatters.dart';
import '../widgets/live_order_tracker_dialog.dart';
import '../widgets/order_receipt_dialog.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'Semua';
  final List<String> filterTabs = ['Semua', 'Sedang Diproses', 'Selesai'];
  List<OrderHistory> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    final data = await LocalDbService.instance.getOrders();
    if (mounted) {
      setState(() {
        orders = data;
        isLoading = false;
      });
    }
  }

  List<OrderHistory> get filteredOrders {
    if (selectedFilter == 'Semua') return orders;
    if (selectedFilter == 'Sedang Diproses') {
      return orders.where((o) => o.status.toLowerCase() != 'selesai').toList();
    }
    return orders.where((o) => o.status.toLowerCase() == 'selesai').toList();
  }

  void _openLiveTracker(OrderHistory order) {
    LiveOrderTrackerDialog.show(
      context,
      order,
      onStatusChanged: _loadOrders,
    );
  }

  void _openReceipt(OrderHistory order) {
    OrderReceiptDialog.show(
      context,
      order,
      onOpenTracker: () => _openLiveTracker(order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Riwayat & Live Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Segarkan Riwayat',
                  onPressed: _loadOrders,
                ),
              ],
            ),
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // 1. Filter Chips Bar
              Container(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: filterTabs.map((tab) {
                    final isSelected = selectedFilter == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(tab),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : (isDark ? Colors.grey[300] : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setState(() => selectedFilter = tab);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),

              // 2. Daftar Transaksi
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[500]),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada riwayat pesanan',
                                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            color: primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                final isFinished = order.status.toLowerCase() == 'selesai';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  elevation: 1,
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Kartu
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.receipt, size: 18, color: primaryColor),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '#${order.orderId}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: isDark ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isFinished
                                                    ? Colors.green.withValues(alpha: 0.12)
                                                    : primaryColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isFinished ? Colors.green.shade400 : primaryColor.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (!isFinished) ...[
                                                    Icon(Icons.soup_kitchen, size: 12, color: primaryColor),
                                                    const SizedBox(width: 4),
                                                  ],
                                                  Text(
                                                    order.status,
                                                    style: TextStyle(
                                                      color: isFinished ? Colors.green : primaryColor,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${order.isTakeaway ? "Bungkus (Takeaway)" : order.tableNumber} • ${_formatDate(order.orderDate)} • ${order.paymentMethod}',
                                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                        ),
                                        Divider(height: 20, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                                        // List Item Ringkas
                                        ...order.itemNames.map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              children: [
                                                Icon(Icons.circle, size: 6, color: primaryColor),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item,
                                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[200] : Colors.black87),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        Divider(height: 20, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                                        // Total & Tombol Aksi
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Total Bayar', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                                Text(
                                                  formatRupiah(order.totalAmount),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () => _openReceipt(order),
                                                  icon: const Icon(Icons.receipt_long, size: 14),
                                                  label: const Text('E-Receipt & QR', style: TextStyle(fontSize: 11)),
                                                ),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isFinished ? Colors.grey[800] : primaryColor,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    visualDensity: VisualDensity.compact,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () => _openLiveTracker(order),
                                                  icon: Icon(
                                                    isFinished ? Icons.history : Icons.radar,
                                                    size: 14,
                                                  ),
                                                  label: Text(
                                                    isFinished ? 'Lihat Timeline' : 'Lacak Live 🚀',
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
