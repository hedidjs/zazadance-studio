import 'package:supabase_flutter/supabase_flutter.dart';
import 'environment_service.dart';
import '../exceptions/app_exceptions.dart';

/// Centralized Supabase service for managing database connections and queries
class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Initialize Supabase with environment variables
  static Future<void> initialize() async {
    if (_initialized) return;

    final url = EnvironmentService.supabaseUrl;
    final anonKey = EnvironmentService.supabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      throw EnvironmentException(
        'Supabase URL or ANON KEY not found in environment variables',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _client = Supabase.instance.client;
    _initialized = true;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw DatabaseException(
        'Supabase not initialized. Call SupabaseService.initialize() first',
      );
    }
    return _client!;
  }

  /// Get current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException('Failed to sign in: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } catch (e) {
      throw AuthException('Failed to sign up: ${e.toString()}');
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  /// Get data from a table with error handling
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    String? filter,
    String? order,
    int? limit,
  }) async {
    try {
      var query = client.from(table).select(columns);

      if (filter != null) {
        // This is a simple implementation - you might want to parse filters more intelligently
        query = query.filter('id', 'neq', '');
      }

      if (order != null) {
        query = query.order(order);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query;
    } catch (e) {
      throw DatabaseException('Failed to select from $table: ${e.toString()}');
    }
  }

  /// Insert data into a table with error handling
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      return await client.from(table).insert(data).select();
    } catch (e) {
      throw DatabaseException('Failed to insert into $table: ${e.toString()}');
    }
  }

  /// Update data in a table with error handling
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required String id,
  }) async {
    try {
      return await client
          .from(table)
          .update(data)
          .eq('id', id)
          .select();
    } catch (e) {
      throw DatabaseException('Failed to update $table: ${e.toString()}');
    }
  }

  /// Delete data from a table with error handling
  static Future<void> delete(
    String table, {
    required String id,
  }) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      throw DatabaseException('Failed to delete from $table: ${e.toString()}');
    }
  }

  /// Upload file to Supabase Storage
  static Future<String> uploadFile(
    String bucket,
    String path,
    List<int> fileBytes, {
    String? contentType,
  }) async {
    try {
      await client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
            ),
          );

      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw StorageException('Failed to upload file: ${e.toString()}');
    }
  }

  /// Delete file from Supabase Storage
  static Future<void> deleteFile(String bucket, String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw StorageException('Failed to delete file: ${e.toString()}');
    }
  }

  /// Execute a stored procedure/function
  static Future<List<Map<String, dynamic>>> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      return await client.rpc(functionName, params: params ?? {});
    } catch (e) {
      throw DatabaseException('Failed to execute RPC $functionName: ${e.toString()}');
    }
  }

  /// Stream changes from a table
  static RealtimeChannel subscribeToTable(
    String table,
    void Function(List<Map<String, dynamic>>)? onInsert,
    void Function(List<Map<String, dynamic>>)? onUpdate,
    void Function(List<Map<String, dynamic>>)? onDelete,
  ) {
    final channel = client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (payload) {
            if (onInsert != null) {
              onInsert([payload.newRecord]);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          callback: (payload) {
            if (onUpdate != null) {
              onUpdate([payload.newRecord]);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          callback: (payload) {
            if (onDelete != null) {
              onDelete([payload.oldRecord]);
            }
          },
        );

    channel.subscribe();
    return channel;
  }

  /// Unsubscribe from realtime channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}