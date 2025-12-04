import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart' as app_models;
import '../database/database_helper.dart';
import 'firestore_service.dart';

class BackupService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is signed in
  bool get isUserSignedIn => _auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Backup all data to Firebase
  Future<bool> backupToFirebase(BuildContext context) async {
    if (!isUserSignedIn) {
      throw 'يرجى تسجيل الدخول أولاً لعمل نسخة احتياطية';
    }

    try {
      print('BackupService: Starting backup to Firebase');
      print('BackupService: Current user ID: $currentUserId');

      final Database db = await _databaseHelper.database;
      print('BackupService: Database connection established');

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('جاري النسخ الاحتياطي...'),
                ],
              ),
            ),
      );

      // Step 1: Backup accounts
      print('BackupService: Starting account backup');
      try {
        await _backupAccounts(db);
        print('BackupService: Account backup completed');
      } catch (e) {
        print('BackupService: Error backing up accounts: $e');
        throw 'فشل في نسخ الحسابات: ${_formatFirestoreError(e)}';
      }

      // Step 2: Backup categories
      print('BackupService: Starting category backup');
      try {
        await _backupCategories(db);
        print('BackupService: Category backup completed');
      } catch (e) {
        print('BackupService: Error backing up categories: $e');
        throw 'فشل في نسخ الفئات: ${_formatFirestoreError(e)}';
      }

      // Step 3: Backup transactions
      print('BackupService: Starting transaction backup');
      try {
        await _backupTransactions(db);
        print('BackupService: Transaction backup completed');
      } catch (e) {
        print('BackupService: Error backing up transactions: $e');
        throw 'فشل في نسخ المعاملات: ${_formatFirestoreError(e)}';
      }

      // Close dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('BackupService: Backup completed successfully');
      return true;
    } catch (e) {
      print('BackupService: Backup failed with error: $e');

      // Close dialog if open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (e is FirebaseException) {
        throw 'فشل النسخ الاحتياطي: ${_formatFirestoreError(e)}';
      } else {
        throw 'فشل النسخ الاحتياطي: ${e.toString()}';
      }
    }
  }

  // Helper method to format Firestore errors
  String _formatFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'not-found':
          return '[cloud_firestore/not-found] المستند المطلوب غير موجود';
        case 'permission-denied':
          return 'ليس لديك صلاحية للوصول لهذا المستند';
        case 'unauthenticated':
          return 'يجب تسجيل الدخول أولاً';
        case 'unavailable':
          return 'الخدمة غير متاحة حالياً، تحقق من اتصالك بالإنترنت';
        case 'cancelled':
          return 'تم إلغاء العملية';
        default:
          return '[${error.code}] ${error.message}';
      }
    }
    return error.toString();
  }

  // Restore data from Firebase
  Future<bool> restoreFromFirebase(BuildContext context) async {
    if (!isUserSignedIn) {
      throw 'يرجى تسجيل الدخول أولاً لاستعادة البيانات';
    }

    try {
      print('BackupService: Starting restore from Firebase');
      print('BackupService: Current user ID: $currentUserId');

      final Database db = await _databaseHelper.database;
      print('BackupService: Database connection established');

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('جاري استعادة البيانات...'),
                ],
              ),
            ),
      );

      // Begin transaction
      await db.transaction((txn) async {
        // Step 1: Clear local data
        print('BackupService: Clearing local data');
        await txn.delete('accounts');
        await txn.delete('categories');
        await txn.delete('transactions');

        // Step 2: Get data from Firebase
        try {
          // Step 2.1: Get accounts
          print('BackupService: Getting accounts from Firebase');
          final accounts = await _getFirebaseAccounts();
          print('BackupService: Found ${accounts.length} accounts');
          for (var account in accounts) {
            await txn.insert('accounts', account.toMap());
          }

          // Step 2.2: Get categories
          print('BackupService: Getting categories from Firebase');
          final categories = await _getFirebaseCategories();
          print('BackupService: Found ${categories.length} categories');
          for (var category in categories) {
            await txn.insert('categories', category.toMap());
          }

          // Step 2.3: Get transactions
          print('BackupService: Getting transactions from Firebase');
          final transactions = await _getFirebaseTransactions();
          print('BackupService: Found ${transactions.length} transactions');
          for (var transaction in transactions) {
            await txn.insert('transactions', transaction.toMap());
          }
        } catch (e) {
          print('BackupService: Error during restore: $e');
          throw 'فشل في استعادة البيانات: ${_formatFirestoreError(e)}';
        }
      });

      // Close dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('BackupService: Restore completed successfully');
      return true;
    } catch (e) {
      print('BackupService: Restore failed with error: $e');

      // Close dialog if open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (e is FirebaseException) {
        throw 'فشل استعادة البيانات: ${_formatFirestoreError(e)}';
      } else {
        throw 'فشل استعادة البيانات: ${e.toString()}';
      }
    }
  }

  // Backup accounts
  Future<void> _backupAccounts(Database db) async {
    final accounts = await db.query('accounts');
    print('BackupService: Found ${accounts.length} accounts to backup');

    for (var accountMap in accounts) {
      final account = Account.fromMap(accountMap);
      print(
        'BackupService: Backing up account: ${account.name} (ID: ${account.id})',
      );
      await _firestoreService.saveAccount(account);
    }
  }

  // Backup categories
  Future<void> _backupCategories(Database db) async {
    final categories = await db.query('categories');
    print('BackupService: Found ${categories.length} categories to backup');

    for (var categoryMap in categories) {
      final category = Category.fromMap(categoryMap);
      print(
        'BackupService: Backing up category: ${category.name} (ID: ${category.id})',
      );
      await _firestoreService.saveCategory(category);
    }
  }

  // Backup transactions
  Future<void> _backupTransactions(Database db) async {
    final transactions = await db.query('transactions');
    print('BackupService: Found ${transactions.length} transactions to backup');

    for (var transactionMap in transactions) {
      final transaction = app_models.Transaction.fromMap(transactionMap);
      print('BackupService: Backing up transaction ID: ${transaction.id}');
      await _firestoreService.saveTransaction(transaction);
    }
  }

  // Get accounts from Firebase
  Future<List<Account>> _getFirebaseAccounts() async {
    print('BackupService: Getting accounts stream from Firebase');
    final accountsStream = _firestoreService.getAccounts();
    print('BackupService: Waiting for first accounts data');
    final accounts = await accountsStream.first;
    print('BackupService: Received accounts from Firebase');
    return accounts;
  }

  // Get categories from Firebase
  Future<List<Category>> _getFirebaseCategories() async {
    print('BackupService: Getting categories stream from Firebase');
    final categoriesStream = _firestoreService.getCategories();
    print('BackupService: Waiting for first categories data');
    final categories = await categoriesStream.first;
    print('BackupService: Received categories from Firebase');
    return categories;
  }

  // Get transactions from Firebase
  Future<List<app_models.Transaction>> _getFirebaseTransactions() async {
    print('BackupService: Getting transactions stream from Firebase');
    final transactionsStream = _firestoreService.getTransactions();
    print('BackupService: Waiting for first transactions data');
    final transactions = await transactionsStream.first;
    print('BackupService: Received transactions from Firebase');
    return transactions;
  }
}
