import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/dummy_data.dart';
import '../models/menu_item.dart';

class LocalDbService {
  static const String _keyOrders = 'kantin_bu_sari_orders';
  static const String _keyWallet = 'kantin_bu_sari_wallet';
  static const String _keyFavorites = 'kantin_bu_sari_favorites';
  static const String _keyProfile = 'kantin_bu_sari_profile';

  static LocalDbService? _instance;
  static LocalDbService get instance => _instance ??= LocalDbService._();

  LocalDbService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (!_prefs!.containsKey(_keyOrders)) {
      await _seedInitialOrders();
    }
    if (!_prefs!.containsKey(_keyWallet)) {
      await _prefs!.setInt(_keyWallet, 45000);
    }
    if (!_prefs!.containsKey(_keyProfile)) {
      final defaultProfile = UserProfile(
        name: 'Mahasiswa Labkom',
        nim: '2200018123',
        major: 'Teknik Informatika',
        phone: '0812-3456-7890',
        email: 'mahasiswa@labkom.ac.id',
      );
      await _prefs!.setString(_keyProfile, jsonEncode(defaultProfile.toJson()));
    }
  }

  Future<void> _seedInitialOrders() async {
    final list = DummyData.orderHistories.map((o) => o.toJson()).toList();
    await _prefs!.setString(_keyOrders, jsonEncode(list));
  }

  // --- RIWAYAT PESANAN (ORDERS) ---
  Future<List<OrderHistory>> getOrders() async {
    await init();
    final jsonStr = _prefs!.getString(_keyOrders);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => OrderHistory.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return List.from(DummyData.orderHistories);
    }
  }

  Future<void> saveOrder(OrderHistory newOrder) async {
    await init();
    final orders = await getOrders();
    orders.insert(0, newOrder);

    final list = orders.map((o) => o.toJson()).toList();
    await _prefs!.setString(_keyOrders, jsonEncode(list));
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await init();
    final orders = await getOrders();
    final index = orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      orders[index] = orders[index].copyWith(status: newStatus);
      final list = orders.map((o) => o.toJson()).toList();
      await _prefs!.setString(_keyOrders, jsonEncode(list));
    }
  }

  // --- USER PROFILE ---
  Future<UserProfile> getUserProfile() async {
    await init();
    final jsonStr = _prefs!.getString(_keyProfile);
    if (jsonStr == null || jsonStr.isEmpty) {
      return UserProfile(
        name: 'Mahasiswa Labkom',
        nim: '2200018123',
        major: 'Teknik Informatika',
        phone: '0812-3456-7890',
        email: 'mahasiswa@labkom.ac.id',
      );
    }
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromJson(decoded);
    } catch (e) {
      return UserProfile(
        name: 'Mahasiswa Labkom',
        nim: '2200018123',
        major: 'Teknik Informatika',
        phone: '0812-3456-7890',
        email: 'mahasiswa@labkom.ac.id',
      );
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  // --- SALDO LABKOM PAY ---
  Future<int> getWalletBalance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getInt(_keyWallet) ?? 45000;
  }

  Future<void> updateWalletBalance(int newBalance) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_keyWallet, newBalance);
  }

  // --- MENU FAVORIT ---
  Future<Set<String>> getFavorites() async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = _prefs!.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  Future<bool> toggleFavorite(String menuId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final favs = (await getFavorites()).toList();
    bool isNowFav;
    if (favs.contains(menuId)) {
      favs.remove(menuId);
      isNowFav = false;
    } else {
      favs.add(menuId);
      isNowFav = true;
    }
    await _prefs!.setStringList(_keyFavorites, favs);
    return isNowFav;
  }

  Future<bool> isFavorite(String menuId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final favs = _prefs!.getStringList(_keyFavorites) ?? [];
    return favs.contains(menuId);
  }

  // Reset database untuk testing
  Future<void> resetDatabase() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_keyOrders);
    await _prefs!.remove(_keyWallet);
    await _prefs!.remove(_keyFavorites);
    await _prefs!.remove(_keyProfile);
    await _seedInitialOrders();
    await _prefs!.setInt(_keyWallet, 45000);
    final defaultProfile = UserProfile(
      name: 'Mahasiswa Labkom',
      nim: '2200018123',
      major: 'Teknik Informatika',
      phone: '0812-3456-7890',
      email: 'mahasiswa@labkom.ac.id',
    );
    await _prefs!.setString(_keyProfile, jsonEncode(defaultProfile.toJson()));
  }
}
