import 'package:uuid/uuid.dart';

/// Base model class that provides common functionality for all models
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate a new UUID
  static String generateId() => const Uuid().v4();

  /// Get current timestamp
  static DateTime now() => DateTime.now();

  /// Convert model to JSON
  Map<String, dynamic> toJson();

  /// Create model from JSON
  static T fromJson<T extends BaseModel>(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclasses');
  }

  /// Equality comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType{id: $id}';
}