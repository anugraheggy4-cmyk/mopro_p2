import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/local_db_service.dart';
import '../services/theme_service.dart';
import '../utils/formatters.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool pushNotifications = true;
  bool saveReceiptAutomatically = true;
  int walletBalance = 45000;
  int orderCount = 0;
  bool isLoading = true;

  UserProfile userProfile = UserProfile(
    name: 'Mahasiswa Labkom',
    nim: '2200018123',
    major: 'Teknik Informatika',
    phone: '0812-3456-7890',
    email: 'mahasiswa@labkom.ac.id',
  );

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    final balance = await LocalDbService.instance.getWalletBalance();
    final orders = await LocalDbService.instance.getOrders();
    final profile = await LocalDbService.instance.getUserProfile();
    if (mounted) {
      setState(() {
        walletBalance = balance;
        orderCount = orders.length;
        userProfile = profile;
        isLoading = false;
      });
    }
  }

  // DIALOG EDIT PROFIL
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userProfile.name);
    final nimController = TextEditingController(text: userProfile.nim);
    final majorController = TextEditingController(text: userProfile.major);
    final phoneController = TextEditingController(text: userProfile.phone);
    final emailController = TextEditingController(text: userProfile.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Edit Data Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nimController,
                    decoration: const InputDecoration(
                      labelText: 'NIM Mahasiswa',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'NIM tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: majorController,
                    decoration: const InputDecoration(
                      labelText: 'Program Studi / Jurusan',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Kampus',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updated = UserProfile(
                  name: nameController.text.trim(),
                  nim: nimController.text.trim(),
                  major: majorController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                );
                await LocalDbService.instance.saveUserProfile(updated);
                setState(() => userProfile = updated);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui di database lokal!')),
                );
              }
            },
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }

  // DIALOG TOP UP SALDO
  void _showTopUpDialog() {
    int selectedAmount = 20000;
    final amounts = [10000, 20000, 50000, 100000];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Top Up Saldo Kantin Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih nominal top up yang ingin ditambahkan ke database:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amounts.map((amt) {
                  final isSelected = selectedAmount == amt;
                  return ChoiceChip(
                    label: Text(formatRupiah(amt)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedAmount = amt);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newBal = walletBalance + selectedAmount;
                await LocalDbService.instance.updateWalletBalance(newBal);
                setState(() => walletBalance = newBal);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saldo berhasil ditambah ${formatRupiah(selectedAmount)}!')),
                );
              },
              child: const Text('Top Up Sekarang'),
            ),
          ],
        ),
      ),
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
            child: const Text('Profil & Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Profil Pengguna Card dengan Tombol Edit
                Card(
                  elevation: 1,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: primaryColor.withValues(alpha: 0.15),
                              child: Icon(Icons.person, size: 42, color: primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userProfile.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primaryColor,
                                          side: BorderSide(color: primaryColor),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: _showEditProfileDialog,
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Edit Profil', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'NIM: ${userProfile.nim} • ${userProfile.major}',
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '⭐ Pelanggan Setia Bu Sari',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$orderCount Transaksi',
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.phone_android, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(userProfile.phone, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(userProfile.email, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Saldo Kantin Pay Card (Database Lokal)
                Card(
                  elevation: 1,
                  color: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.storage, size: 14, color: Colors.white70),
                                SizedBox(width: 4),
                                Text(
                                  'Saldo Labkom Pay (Database Lokal)',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(walletBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _showTopUpDialog,
                          icon: const Icon(Icons.add_circle, size: 18),
                          label: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Pengaturan TEMA & DARK MODE (Fitur Keren Baru!)
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
                          children: [
                            Icon(Icons.palette_outlined, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Personalisasi Tema & Mode Tampilan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                        // Switch Dark Mode
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeTrackColor: primaryColor,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: isDark ? Colors.amber : Colors.grey[700],
                              size: 20,
                            ),
                          ),
                          title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            isDark
                                ? 'Tampilan gelap aktif (nyaman di mata & hemat baterai)'
                                : 'Tampilan terang aktif',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          value: isDark,
                          onChanged: (val) {
                            ThemeService.instance.toggleDarkMode(val);
                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'Pilih Warna Aksen Aplikasi:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),

                        // Pilihan Warna Aksen Palet
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: List.generate(ThemeService.availableColors.length, (idx) {
                            final option = ThemeService.availableColors[idx];
                            final isSelected = ThemeService.instance.selectedColorIndex == idx;

                            return InkWell(
                              onTap: () {
                                ThemeService.instance.setColorIndex(idx);
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? option.primaryColor.withValues(alpha: isDark ? 0.3 : 0.15)
                                      : (isDark ? Colors.grey[900] : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? option.primaryColor : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: option.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      option.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? option.primaryColor
                                            : (isDark ? Colors.grey[300] : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Info Kantin Bu Sari
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
                          children: [
                            Icon(Icons.storefront, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Informasi Gerai Kantin Bu Sari',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 20, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                        _buildInfoItem(
                          Icons.schedule,
                          'Jam Operasional',
                          'Senin - Sabtu: 07.30 - 16.30 WIB (Hari Libur Tutup)',
                          isDark,
                        ),
                        _buildInfoItem(
                          Icons.location_on_outlined,
                          'Lokasi Gerai Kampus',
                          'Lantai 1 Gedung Maroon Labkom (Samping Tangga Utama)',
                          isDark,
                        ),
                        _buildInfoItem(
                          Icons.phone_outlined,
                          'WhatsApp Kasir Bu Sari',
                          '+62 812-3456-7890 (Bu Sari)',
                          isDark,
                        ),
                        _buildInfoItem(
                          Icons.verified_outlined,
                          'Jaminan Kualitas Makanan',
                          '100% Halal, Bahan Segar Setiap Hari, Tanpa Pengawet',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Preferensi & Reset
                Card(
                  elevation: 1,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeTrackColor: primaryColor,
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Notifikasi Status Pesanan', style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          'Dapatkan pemberitahuan saat masakan Bu Sari sudah siap',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        value: pushNotifications,
                        onChanged: (val) => setState(() => pushNotifications = val),
                      ),
                      Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                      SwitchListTile(
                        activeTrackColor: primaryColor,
                        secondary: const Icon(Icons.receipt_long_outlined),
                        title: const Text('Simpan Struk Otomatis', style: TextStyle(fontSize: 14)),
                        value: saveReceiptAutomatically,
                        onChanged: (val) => setState(() => saveReceiptAutomatically = val),
                      ),
                      Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                      ListTile(
                        leading: const Icon(Icons.refresh, color: Colors.blue),
                        title: const Text('Reset Data Database Lokal', style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          'Kembalikan data profil, pesanan, dan saldo ke default',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        onTap: () async {
                          await LocalDbService.instance.resetDatabase();
                          await _loadProfileData();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Database lokal berhasil di-reset!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Aplikasi Kantin Bu Sari v2.0.0 (Web & Mobile Responsive)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Text(
                  'Fitur Baru: Live Order Tracker • E-Receipt QR • Dark Mode • Smart Sorting',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
