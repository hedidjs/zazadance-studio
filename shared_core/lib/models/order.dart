import 'base_model.dart';
import 'cart_item.dart';

/// Order status enumeration
enum OrderStatus {
  pending('pending', 'ממתין'),
  confirmed('confirmed', 'מאושר'),
  processing('processing', 'בטיפול'),
  shipped('shipped', 'נשלח'),
  delivered('delivered', 'נמסר'),
  cancelled('cancelled', 'בוטל'),
  refunded('refunded', 'הוחזר');

  const OrderStatus(this.value, this.displayNameHe);

  final String value;
  final String displayNameHe;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// User profile information embedded in orders
class OrderUserProfile {
  final String? displayName;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  const OrderUserProfile({
    this.displayName,
    this.phone,
    this.email,
    this.avatarUrl,
  });

  factory OrderUserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrderUserProfile();
    
    return OrderUserProfile(
      displayName: json['display_name'],
      phone: json['phone'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }
}

/// Order item with embedded product information
class OrderItem {
  final String id;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? product;
  final Map<String, dynamic>? size;

  const OrderItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.product,
    this.size,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      product: json['products'],
      size: json['product_sizes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'products': product,
      'product_sizes': size,
    };
  }

  String get productNameHe => product?['name_he'] ?? '';
  String? get productImageUrl => product?['image_url'];
  String? get sizeName => size?['name'];
}

/// Complete order model with all embedded data
class Order extends BaseModel {
  final String orderNumber;
  final String userId;
  final OrderStatus status;
  final double totalAmount;
  final String? notes;
  final OrderUserProfile? userProfile;
  final List<OrderItem> items;

  const Order({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.userProfile,
    this.items = const [],
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      orderNumber: json['order_number'] ?? '',
      userId: json['user_id'],
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      notes: json['notes'],
      userProfile: OrderUserProfile.fromJson(json['user_profiles']),
      items: (json['order_items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'order_number': orderNumber,
      'user_id': userId,
      'status': status.value,
      'total_amount': totalAmount,
      'notes': notes,
      'user_profiles': userProfile?.toJson(),
      'order_items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Create a copy of this Order with modified fields
  Order copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? orderNumber,
    String? userId,
    OrderStatus? status,
    double? totalAmount,
    String? notes,
    OrderUserProfile? userProfile,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      userProfile: userProfile ?? this.userProfile,
      items: items ?? this.items,
    );
  }

  /// Get customer display name for UI
  String get customerName => userProfile?.displayName ?? 'לקוח';

  /// Get customer contact information
  String get customerContact {
    final phone = userProfile?.phone;
    final email = userProfile?.email;
    if (phone != null && phone.isNotEmpty) return phone;
    if (email != null && email.isNotEmpty) return email;
    return 'אין מידע';
  }

  /// Get total number of items in order
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if order can be cancelled
  bool get canCancel => [OrderStatus.pending, OrderStatus.confirmed].contains(status);

  /// Check if order is completed
  bool get isCompleted => [OrderStatus.delivered, OrderStatus.cancelled, OrderStatus.refunded].contains(status);

  /// Get status color for UI
  String get statusColorHex {
    switch (status) {
      case OrderStatus.pending:
        return '#FF9800'; // Orange
      case OrderStatus.confirmed:
        return '#2196F3'; // Blue
      case OrderStatus.processing:
        return '#9C27B0'; // Purple
      case OrderStatus.shipped:
        return '#FF5722'; // Deep Orange
      case OrderStatus.delivered:
        return '#4CAF50'; // Green
      case OrderStatus.cancelled:
        return '#F44336'; // Red
      case OrderStatus.refunded:
        return '#607D8B'; // Blue Grey
    }
  }
}