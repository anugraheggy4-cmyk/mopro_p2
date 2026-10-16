import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';
import '../services/local_db_service.dart';
import '../utils/formatters.dart';

class MenuDetailPage extends StatefulWidget {
  final MenuItem? menu;

  const MenuDetailPage({super.key, this.menu});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  late MenuItem item;
  int quantity = 1;
  String selectedSpice = '';
  final Set<String> selectedToppingIds = {};
  final TextEditingController _notesController = TextEditingController();
  bool isFavorite = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MenuItem) {
      item = args;
    } else if (widget.menu != null) {
      item = widget.menu!;
    } else {
      item = DummyData.menuList.first;
    }

    if (selectedSpice.isEmpty && item.spiceLevels.isNotEmpty) {
      selectedSpice = item.spiceLevels.first;
    }

    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final fav = await LocalDbService.instance.isFavorite(item.id);
    if (mounted) setState(() => isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    final newFav = await LocalDbService.instance.toggleFavorite(item.id);
    if (!mounted) return;
    setState(() => isFavorite = newFav);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          isFavorite ? '${item.name} disimpan ke favorit!' : 'Dihapus dari favorit',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get calculatedTotal {
    int toppingsTotal = item.availableToppings
        .where((t) => selectedToppingIds.contains(t.id))
        .fold(0, (sum, t) => sum + t.price);
    return (item.price + toppingsTotal) * quantity;
  }

  void _addToCartOnly() {
    final selectedToppingsList = item.availableToppings
        .where((t) => selectedToppingIds.contains(t.id))
        .toList();

    CartService.instance.addItem(
      menu: item,
      quantity: quantity,
      selectedSpiceLevel: selectedSpice,
      selectedToppings: selectedToppingsList,
      specialNotes: _notesController.text.trim(),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: Colors.deepOrange,
        content: Text('$quantity porsi ${item.name} masuk ke keranjang!'),
      ),
    );
  }

  void _proceedToOrder() {
    _addToCartOnly();
    Navigator.pushNamed(context, '/pesan');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrWeb = screenWidth >= 800;

    if (isDesktopOrWeb) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(item.name),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom Kiri
                  Expanded(
                    flex: 5,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(
                            item.imageUrl,
                            height: 320,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 320,
                              color: Colors.deepOrange.shade100,
                              child: const Icon(Icons.fastfood, size: 80, color: Colors.deepOrange),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      formatRupiah(item.price),
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Chip(
                                      avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
                                      label: Text('${item.rating} (${item.reviewCount} ulasan)'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.description,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Kolom Kanan
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomizationOptions(primaryColor),
                        const SizedBox(height: 20),
                        _buildDesktopBottomBar(primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tampilan Mobile
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.deepOrange.shade100,
                      child: const Center(
                        child: Icon(Icons.fastfood, size: 80, color: Colors.deepOrange),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black45, Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : Colors.white,
                ),
                tooltip: 'Simpan ke Favorit',
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formatRupiah(item.price),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      if (item.originalPrice != null)
                        Text(
                          formatRupiah(item.originalPrice!),
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                      const Spacer(),
                      if (item.isPromo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade400),
                          ),
                          child: const Text(
                            'PROMO KANTIN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(avatar: const Icon(Icons.star, color: Colors.amber, size: 18), label: Text('${item.rating} (${item.reviewCount})')),
                      Chip(avatar: const Icon(Icons.timer_outlined, size: 18), label: Text('± ${item.prepTimeMinutes} Mnt')),
                      Chip(avatar: const Icon(Icons.restaurant, size: 18), label: Text(item.category)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildCustomizationOptions(primaryColor),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildMobileBottomBar(primaryColor),
    );
  }

  Widget _buildCustomizationOptions(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.spiceLevels.isNotEmpty) ...[
          const Text('Pilihan Level Pedas / Varian:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: item.spiceLevels.map((lvl) {
              final isSelected = selectedSpice == lvl;
              return ChoiceChip(
                label: Text(lvl),
                selected: isSelected,
                selectedColor: primaryColor.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => selectedSpice = lvl);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (item.availableToppings.isNotEmpty) ...[
          const Text('Topping Tambahan:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            elevation: 0.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: item.availableToppings.map((topping) {
                final isChecked = selectedToppingIds.contains(topping.id);
                return CheckboxListTile(
                  dense: true,
                  activeColor: primaryColor,
                  title: Text(topping.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '+ ${formatRupiah(topping.price)}',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  value: isChecked,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedToppingIds.add(topping.id);
                      } else {
                        selectedToppingIds.remove(topping.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Catatan Pesanan:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Cth: kuah dipisah, jangan pakai timun...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBottomBar(Color primaryColor) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah Porsi:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Harga', style: TextStyle(fontSize: 14)),
                Text(
                  formatRupiah(calculatedTotal),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _addToCartOnly,
                    child: const Text('+ Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _proceedToOrder,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Beli Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBottomBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => setState(() => quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _proceedToOrder,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pesan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(formatRupiah(calculatedTotal), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
