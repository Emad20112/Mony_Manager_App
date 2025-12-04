import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
// import 'firestore_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';

class SyncService {
  static const String _pendingOperationsKey = 'pending_operations';
  static const String _lastSyncKey = 'last_sync';

  final ConnectivityService _connectivityService = ConnectivityService();
  // final FirestoreService _firestoreService = FirestoreService();

  // Add operation to pending queue
  Future<void> _addPendingOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingOps = prefs.getStringList(_pendingOperationsKey) ?? [];

    final operationData = {
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    pendingOps.add(jsonEncode(operationData));
    await prefs.setStringList(_pendingOperationsKey, pendingOps);
  }

  // Get pending operations
  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingOps = prefs.getStringList(_pendingOperationsKey) ?? [];

    return pendingOps.map((op) {
      final decoded = jsonDecode(op) as Map<String, dynamic>;
      return {
        'operation': decoded['operation'] as String,
        'data': decoded['data'] as Map<String, dynamic>,
        'timestamp': decoded['timestamp'] as String,
      };
    }).toList();
  }

  // Clear pending operations
  Future<void> _clearPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOperationsKey);
  }

  // Set last sync timestamp
  Future<void> _setLastSync(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // Sync pending operations when online
  Future<bool> syncPendingOperations() async {
    if (!_connectivityService.isConnected) {
      return false;
    }

    try {
      final pendingOps = await _getPendingOperations();

      for (final op in pendingOps) {
        final success = await _executeOperation(op['operation'], op['data']);
        if (!success) {
          // If any operation fails, stop syncing
          return false;
        }
      }

      // Clear pending operations after successful sync
      await _clearPendingOperations();
      await _setLastSync(DateTime.now());

      return true;
    } catch (e) {
      print('Error syncing pending operations: $e');
      return false;
    }
  }

  // Execute a single operation
  Future<bool> _executeOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'add_transaction':
          // final transaction = Transaction.fromMap(data);
          // await _firestoreService.addTransaction(transaction);
          print('Mock: Adding transaction to Firestore');
          break;
        case 'update_transaction':
          // final transaction = Transaction.fromMap(data);
          // await _firestoreService.updateTransaction(transaction);
          print('Mock: Updating transaction in Firestore');
          break;
        case 'delete_transaction':
          // await _firestoreService.deleteTransaction(data['id'] as String);
          print('Mock: Deleting transaction from Firestore');
          break;
        case 'add_account':
          // final account = Account.fromMap(data);
          // await _firestoreService.addAccount(account);
          print('Mock: Adding account to Firestore');
          break;
        case 'update_account':
          // final account = Account.fromMap(data);
          // await _firestoreService.updateAccount(account);
          print('Mock: Updating account in Firestore');
          break;
        case 'delete_account':
          // await _firestoreService.deleteAccount(data['id'] as String);
          print('Mock: Deleting account from Firestore');
          break;
        case 'add_category':
          // final category = Category.fromMap(data);
          // await _firestoreService.addCategory(category);
          print('Mock: Adding category to Firestore');
          break;
        case 'update_category':
          // final category = Category.fromMap(data);
          // await _firestoreService.updateCategory(category);
          print('Mock: Updating category in Firestore');
          break;
        case 'delete_category':
          // await _firestoreService.deleteCategory(data['id'] as String);
          print('Mock: Deleting category from Firestore');
          break;
        default:
          print('Unknown operation: $operation');
          return false;
      }
      return true;
    } catch (e) {
      print('Error executing operation $operation: $e');
      return false;
    }
  }

  // Queue transaction operations
  Future<void> queueTransactionOperation(
    String operation,
    Transaction transaction,
  ) async {
    await _addPendingOperation('${operation}_transaction', transaction.toMap());
  }

  // Queue account operations
  Future<void> queueAccountOperation(String operation, Account account) async {
    await _addPendingOperation('${operation}_account', account.toMap());
  }

  // Queue category operations
  Future<void> queueCategoryOperation(
    String operation,
    Category category,
  ) async {
    await _addPendingOperation('${operation}_category', category.toMap());
  }

  // Queue delete operations
  Future<void> queueDeleteOperation(String type, String id) async {
    await _addPendingOperation('delete_$type', {'id': id});
  }

  // Check if sync is needed
  Future<bool> isSyncNeeded() async {
    final lastSync = await getLastSync();
    if (lastSync == null) return true;

    // Sync if last sync was more than 1 hour ago
    final now = DateTime.now();
    return now.difference(lastSync).inHours >= 1;
  }

  // Get pending operations count
  Future<int> getPendingOperationsCount() async {
    final pendingOps = await _getPendingOperations();
    return pendingOps.length;
  }

  // Force sync (ignore connectivity)
  Future<bool> forceSync() async {
    try {
      final pendingOps = await _getPendingOperations();

      for (final op in pendingOps) {
        final success = await _executeOperation(op['operation'], op['data']);
        if (!success) {
          return false;
        }
      }

      await _clearPendingOperations();
      await _setLastSync(DateTime.now());

      return true;
    } catch (e) {
      print('Error in force sync: $e');
      return false;
    }
  }

  // Auto sync when connection is restored
  Future<void> startAutoSync() async {
    _connectivityService.connectionStream.listen((isConnected) async {
      if (isConnected) {
        final pendingCount = await getPendingOperationsCount();
        if (pendingCount > 0) {
          print(
            'Connection restored, syncing $pendingCount pending operations',
          );
          await syncPendingOperations();
        }
      }
    });
  }
}
