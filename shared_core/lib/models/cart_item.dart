import 'base_model.dart';

class CartItem extends BaseModel {
  final String productId;
  final String? sizeId;
  final int quantity;
  final Map<String, dynamic> product;
  final Map<String, dynamic>? size;

  const CartItem({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.productId,
    this.sizeId,
    required this.quantity,
    required this.product,
    this.size,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      productId: json['product_id'],
      sizeId: json['size_id'],
      quantity: json['quantity'] ?? 1,
      product: json['products'] ?? {},
      size: json['product_sizes'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product_id': productId,
      'size_id': sizeId,
      'quantity': quantity,
      'products': product,
      'product_sizes': size,
    };
  }

  /// Calculate total price for this cart item
  double get totalPrice {
    final price = (product['price'] ?? 0).toDouble();
    return price * quantity;
  }

  /// Get product name in Hebrew
  String get productNameHe => product['name_he'] ?? '';

  /// Get product name in English
  String get productNameEn => product['name_en'] ?? '';

  /// Get product image URL
  String? get imageUrl => product['image_url'];

  /// Get size name if available
  String? get sizeName => size?['name'];

  /// Create a copy of this CartItem with modified fields
  CartItem copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productId,
    String? sizeId,
    int? quantity,
    Map<String, dynamic>? product,
    Map<String, dynamic>? size,
  }) {
    return CartItem(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productId: productId ?? this.productId,
      sizeId: sizeId ?? this.sizeId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
      size: size ?? this.size,
    );
  }

  /// Create a cart item for insertion (without id and timestamps)
  factory CartItem.forInsertion({
    required String productId,
    String? sizeId,
    required int quantity,
    required Map<String, dynamic> product,
    Map<String, dynamic>? size,
  }) {
    final now = BaseModel.now();
    return CartItem(
      id: BaseModel.generateId(),
      createdAt: now,
      updatedAt: now,
      productId: productId,
      sizeId: sizeId,
      quantity: quantity,
      product: product,
      size: size,
    );
  }
}