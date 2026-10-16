import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';
import '../services/local_db_service.dart';
import '../utils/formatters.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  String selectedCategory = 'Semua';
  String searchQuery = '';
  bool isGridView = true;
  String _sortBy = 'popular'; // 'popular', 'rating', 'price_asc', 'price_desc', 'prep_time'
  bool _onlyPromo = false;
  bool _onlyFavorite = false;
  bool _onlySpicy = false;

  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPromoIndex = 0;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    CartService.instance.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onCartUpdated);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onCartUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFavorites() async {
    final favs = await LocalDbService.instance.getFavorites();
    if (mounted) {
      setState(() => _favoriteIds = favs);
    }
  }

  Future<void> _toggleFavorite(MenuItem item) async {
    final isFav = await LocalDbService.instance.toggleFavorite(item.id);
    await _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          isFav ? '${item.name} disimpan ke favorit!' : 'Dihapus dari favorit',
        ),
      ),
    );
  }

  List<MenuItem> get filteredMenu {
    var list = DummyData.menuList.where((item) {
      final matchesCategory =
          selectedCategory == 'Semua' || item.category == selectedCategory;
      final matchesSearch =
          item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesPromo = !_onlyPromo || (item.isPromo || item.originalPrice != null);
      final matchesFav = !_onlyFavorite || _favoriteIds.contains(item.id);
      final matchesSpicy = !_onlySpicy || item.spiceLevels.isNotEmpty;

      return matchesCategory && matchesSearch && matchesPromo && matchesFav && matchesSpicy;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'prep_time':
        list.sort((a, b) => a.prepTimeMinutes.compareTo(b.prepTimeMinutes));
        break;
      case 'popular':
      default:
        list.sort((a, b) {
          if (a.isPopular && !b.isPopular) return -1;
          if (!a.isPopular && b.isPopular) return 1;
          return b.reviewCount.compareTo(a.reviewCount);
        });
        break;
    }
    return list;
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'rating':
        return 'Rating Tertinggi';
      case 'price_asc':
        return 'Harga Termurah';
      case 'price_desc':
        return 'Harga Tertinggi';
      case 'prep_time':
        return 'Waktu Tercepat';
      case 'popular':
      default:
        return 'Paling Populer';
    }
  }

  bool get _hasActiveFilters =>
      selectedCategory != 'Semua' ||
      searchQuery.isNotEmpty ||
      _onlyPromo ||
      _onlyFavorite ||
      _onlySpicy ||
      _sortBy != 'popular';

  void _resetAllFilters() {
    setState(() {
      selectedCategory = 'Semua';
      searchQuery = '';
      _searchController.clear();
      _onlyPromo = false;
      _onlyFavorite = false;
      _onlySpicy = false;
      _sortBy = 'popular';
    });
  }

  void _addToCart(MenuItem item) {
    CartService.instance.addItem(
      menu: item,
      quantity: 1,
      selectedSpiceLevel: item.spiceLevels.isNotEmpty ? item.spiceLevels.first : '',
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1600),
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text('${item.name} ditambahkan ke keranjang!'),
        action: SnackBarAction(
          label: 'LIHAT KERANJANG',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/pesan'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth >= 800;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cartCount = CartService.instance.totalCount;

    int crossAxisCount;
    double childAspectRatio;
    if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.68;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.72;
    } else if (screenWidth < 1200) {
      crossAxisCount = 4;
      childAspectRatio = 0.75;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 0.78;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Hanya tampilkan AppBar jika di mobile
      appBar: isWeb
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kantin Bu Sari',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Gedung Labkom • Buka (07.30 - 16.30)',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Riwayat Pesanan',
                  onPressed: () => Navigator.pushNamed(context, '/riwayat'),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      tooltip: 'Keranjang Pesanan',
                      onPressed: () => Navigator.pushNamed(context, '/pesan'),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.brown,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            slivers: [
              // 1. Search Bar & Status Header
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(isWeb ? 20 : 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (isWeb) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang di Kantin Bu Sari!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pesan makanan & minuman khas kantin kampus langsung dari laptop atau smartphone.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade400),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.green, size: 8),
                                  SizedBox(width: 6),
                                  Text(
                                    'Dapur Siap Menerima Order',
                                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Cari menu makanan, minuman, cemilan favorit...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: primaryColor),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (val) {
                            setState(() => searchQuery = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Banner Promo Carousel
              if (searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: isWeb ? 150 : 130,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: DummyData.promoBanners.length,
                          onPageChanged: (idx) => setState(() => _currentPromoIndex = idx),
                          itemBuilder: (context, index) {
                            final banner = DummyData.promoBanners[index];
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(banner['color'] as int),
                                    primaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'KODE VOUCHER: ${banner['code']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          banner['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          banner['subtitle'] as String,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.local_fire_department, color: Colors.amber, size: 52),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          DummyData.promoBanners.length,
                          (idx) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPromoIndex == idx ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPromoIndex == idx ? primaryColor : Colors.grey[400],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Category Filter Chips & Smart Filter/Sort Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isWeb ? 20 : 16, 20, isWeb ? 20 : 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Kategori & Sort + View Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kategori Menu Kantin',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              // Tombol Sorting Popup
                              PopupMenuButton<String>(
                                tooltip: 'Urutkan Menu',
                                initialValue: _sortBy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (val) => setState(() => _sortBy = val),
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'popular',
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_fire_department, size: 18, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('Paling Populer'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rating',
                                    child: Row(
                                      children: [
                                        Icon(Icons.star, size: 18, color: Colors.amber),
                                        SizedBox(width: 8),
                                        Text('Rating Tertinggi'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'price_asc',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_downward, size: 18, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Harga: Termurah'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'price_desc',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_upward, size: 18, color: Colors.deepOrange),
                                        SizedBox(width: 8),
                                        Text('Harga: Tertinggi'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'prep_time',
                                    child: Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 18, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Waktu Masak Tercepat'),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.swap_vert, size: 16, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _sortLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Toggle List / Grid
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  isGridView ? Icons.view_list : Icons.grid_view,
                                  color: primaryColor,
                                ),
                                tooltip: isGridView ? 'Tampilan List' : 'Tampilan Grid',
                                onPressed: () => setState(() => isGridView = !isGridView),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Kategori Utama Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: DummyData.categories.map((category) {
                            final isSelected = selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                selectedColor: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.grey[300] : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                onSelected: (selected) {
                                  if (selected) setState(() => selectedCategory = category);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Smart Quick Filter Chips Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              avatar: Icon(Icons.local_offer, size: 14, color: _onlyPromo ? Colors.white : Colors.amber.shade800),
                              label: const Text('Promo Diskon'),
                              selected: _onlyPromo,
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: _onlyPromo ? FontWeight.bold : FontWeight.normal,
                                color: _onlyPromo ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                              ),
                              onSelected: (val) => setState(() => _onlyPromo = val),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              avatar: Icon(Icons.favorite, size: 14, color: _onlyFavorite ? Colors.white : Colors.redAccent),
                              label: const Text('Favorit Saya'),
                              selected: _onlyFavorite,
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: _onlyFavorite ? FontWeight.bold : FontWeight.normal,
                                color: _onlyFavorite ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                              ),
                              onSelected: (val) => setState(() => _onlyFavorite = val),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              avatar: Icon(Icons.whatshot, size: 14, color: _onlySpicy ? Colors.white : Colors.deepOrange),
                              label: const Text('Aneka Pedas'),
                              selected: _onlySpicy,
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: _onlySpicy ? FontWeight.bold : FontWeight.normal,
                                color: _onlySpicy ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                              ),
                              onSelected: (val) => setState(() => _onlySpicy = val),
                            ),
                            if (_hasActiveFilters) ...[
                              const SizedBox(width: 8),
                              ActionChip(
                                avatar: const Icon(Icons.refresh, size: 14, color: Colors.redAccent),
                                label: const Text('Reset Filter', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                onPressed: _resetAllFilters,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Menampilkan ${filteredMenu.length} menu:',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          const Spacer(),
                          Text(
                            'Urutan: $_sortLabel',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Menu Items
              if (filteredMenu.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Menu "$searchQuery" tidak ditemukan'
                                : 'Tidak ada menu dengan kombinasi filter ini',
                            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Coba ubah kata kunci pencarian atau reset filter aktif Anda.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset Semua Filter'),
                            onPressed: _resetAllFilters,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (isGridView)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(isWeb ? 20 : 16, 4, isWeb ? 20 : 16, 90),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredMenu[index];
                        final isFav = _favoriteIds.contains(item.id);
                        return _buildGridCard(item, primaryColor, isFav, isDark);
                      },
                      childCount: filteredMenu.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(isWeb ? 20 : 16, 4, isWeb ? 20 : 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredMenu[index];
                        final isFav = _favoriteIds.contains(item.id);
                        return _buildListCard(item, primaryColor, isFav, isDark);
                      },
                      childCount: filteredMenu.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(MenuItem item, Color primaryColor, bool isFav, bool isDark) {
    return Card(
      elevation: 1,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, '/detail', arguments: item);
          _loadFavorites();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: primaryColor.withValues(alpha: 0.15),
                      child: Center(
                        child: Icon(Icons.fastfood, size: 40, color: primaryColor),
                      ),
                    ),
                  ),
                  if (item.isPopular)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BEST SELLER',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _toggleFavorite(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${item.rating}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• ${item.prepTimeMinutes}m',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatRupiah(item.price),
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _addToCart(item),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(MenuItem item, Color primaryColor, bool isFav, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.8,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.pushNamed(context, '/detail', arguments: item);
          _loadFavorites();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.imageUrl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 84,
                    height: 84,
                    color: primaryColor.withValues(alpha: 0.15),
                    child: Icon(Icons.fastfood, color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _toggleFavorite(item),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatRupiah(item.price),
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              '${item.rating} (${item.reviewCount})',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _addToCart(item),
                          child: const Text('+ Pesan', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
