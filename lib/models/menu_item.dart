class MenuItemTopping {
  final String id;
  final String name;
  final int price;

  const MenuItemTopping({
    required this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  factory MenuItemTopping.fromJson(Map<String, dynamic> json) => MenuItemTopping(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toInt(),
  );
}

class MenuItem {
  final String id;
  final String name;
  final String category;
  final int price;
  final int? originalPrice;
  final double rating;
  final int reviewCount;
  final int prepTimeMinutes;
  final String description;
  final String imageUrl;
  final bool isPopular;
  final bool isPromo;
  final List<String> spiceLevels;
  final List<MenuItemTopping> availableToppings;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.prepTimeMinutes,
    required this.description,
    required this.imageUrl,
    this.isPopular = false,
    this.isPromo = false,
    this.spiceLevels = const [],
    this.availableToppings = const [],
  });
}

class CartItem {
  final MenuItem menu;
  int quantity;
  String selectedSpiceLevel;
  List<MenuItemTopping> selectedToppings;
  String specialNotes;

  CartItem({
    required this.menu,
    this.quantity = 1,
    this.selectedSpiceLevel = '',
    this.selectedToppings = const [],
    this.specialNotes = '',
  });

  int get itemPrice {
    int toppingsTotal = selectedToppings.fold(0, (sum, t) => sum + t.price);
    return (menu.price + toppingsTotal) * quantity;
  }
}

class OrderHistory {
  final String orderId;
  final DateTime orderDate;
  final List<String> itemNames;
  final int totalAmount;
  final int subtotal;
  final int discountAmount;
  final int serviceFee;
  final String status;
  final String tableNumber;
  final String paymentMethod;
  final bool isTakeaway;
  final List<Map<String, dynamic>> detailedItems;

  const OrderHistory({
    required this.orderId,
    required this.orderDate,
    required this.itemNames,
    required this.totalAmount,
    this.subtotal = 0,
    this.discountAmount = 0,
    this.serviceFee = 1000,
    required this.status,
    required this.tableNumber,
    this.paymentMethod = 'QRIS Instant',
    this.isTakeaway = false,
    this.detailedItems = const [],
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderDate': orderDate.toIso8601String(),
    'itemNames': itemNames,
    'totalAmount': totalAmount,
    'subtotal': subtotal,
    'discountAmount': discountAmount,
    'serviceFee': serviceFee,
    'status': status,
    'tableNumber': tableNumber,
    'paymentMethod': paymentMethod,
    'isTakeaway': isTakeaway,
    'detailedItems': detailedItems,
  };

  factory OrderHistory.fromJson(Map<String, dynamic> json) => OrderHistory(
    orderId: json['orderId'] as String? ?? 'BS-0000',
    orderDate: DateTime.tryParse(json['orderDate'] as String? ?? '') ?? DateTime.now(),
    itemNames: List<String>.from(json['itemNames'] as List? ?? []),
    totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
    subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
    discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
    serviceFee: (json['serviceFee'] as num?)?.toInt() ?? 1000,
    status: json['status'] as String? ?? 'Selesai',
    tableNumber: json['tableNumber'] as String? ?? 'Meja 01',
    paymentMethod: json['paymentMethod'] as String? ?? 'QRIS Instant',
    isTakeaway: json['isTakeaway'] as bool? ?? false,
    detailedItems: List<Map<String, dynamic>>.from(json['detailedItems'] as List? ?? []),
  );

  OrderHistory copyWith({
    String? orderId,
    DateTime? orderDate,
    List<String>? itemNames,
    int? totalAmount,
    int? subtotal,
    int? discountAmount,
    int? serviceFee,
    String? status,
    String? tableNumber,
    String? paymentMethod,
    bool? isTakeaway,
    List<Map<String, dynamic>>? detailedItems,
  }) {
    return OrderHistory(
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      itemNames: itemNames ?? this.itemNames,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      status: status ?? this.status,
      tableNumber: tableNumber ?? this.tableNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isTakeaway: isTakeaway ?? this.isTakeaway,
      detailedItems: detailedItems ?? this.detailedItems,
    );
  }
}

class UserProfile {
  String name;
  String nim;
  String major;
  String phone;
  String email;

  UserProfile({
    required this.name,
    required this.nim,
    required this.major,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'nim': nim,
    'major': major,
    'phone': phone,
    'email': email,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Mahasiswa Labkom',
    nim: json['nim'] as String? ?? '2200018123',
    major: json['major'] as String? ?? 'Teknik Informatika',
    phone: json['phone'] as String? ?? '0812-3456-7890',
    email: json['email'] as String? ?? 'mahasiswa@labkom.ac.id',
  );
}
