import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart' as app_models;
import '../models/account.dart';
import '../models/category.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصول على معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  // إنشاء المجموعات الأساسية للمستخدم
  Future<void> initializeUserData(String userId) async {
    try {
      print('FirestoreService: Initializing user data for user ID: $userId');
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        print('FirestoreService: User document does not exist, creating it');
        await userDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('FirestoreService: User document created successfully');

        // Create subcollections with placeholder documents
        print('FirestoreService: Creating accounts collection');
        final accountsCollection = userDoc.collection('accounts');
        await accountsCollection.doc('placeholder').set({
          'placeholder': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('FirestoreService: Creating categories collection');
        final categoriesCollection = userDoc.collection('categories');
        await categoriesCollection.doc('placeholder').set({
          'placeholder': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('FirestoreService: Creating transactions collection');
        final transactionsCollection = userDoc.collection('transactions');
        await transactionsCollection.doc('placeholder').set({
          'placeholder': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // إنشاء فئات افتراضية
        print('FirestoreService: Creating default categories');
        await _createDefaultCategories(userId);
      } else {
        print('FirestoreService: User document exists, updating lastLogin');
        await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
      }
      print('FirestoreService: User data initialization complete');
    } catch (e) {
      print('FirestoreService: Error initializing user data: $e');
      if (e is FirebaseException) {
        print('FirestoreService: Firebase error code: ${e.code}');
        print('FirestoreService: Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // إضافة الفئات الافتراضية
  Future<void> _createDefaultCategories(String userId) async {
    final defaultCategories = [
      {
        'name': 'راتب',
        'type': 'income',
        'icon': Icons.work.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'مدخرات وأمنيات',
        'type': 'expense',
        'icon': Icons.savings.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'طعام',
        'type': 'expense',
        'icon': Icons.restaurant.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'مواصلات',
        'type': 'expense',
        'icon': Icons.directions_car.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'تسوق',
        'type': 'expense',
        'icon': Icons.shopping_cart.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    final batch = _firestore.batch();
    final categoriesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories');

    for (var category in defaultCategories) {
      final docRef = categoriesRef.doc();
      batch.set(docRef, category);
    }

    await batch.commit();
  }

  // حفظ الحساب
  Future<void> saveAccount(Account account) async {
    if (currentUserId == null) {
      print('FirestoreService: Cannot save account - user not logged in');
      return;
    }

    try {
      print(
        'FirestoreService: Saving account: ${account.name} (ID: ${account.id})',
      );
      final accountData = account.toFirestore();
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('accounts')
          .doc(account.id?.toString());

      if (account.id != null) {
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          print(
            'FirestoreService: Updating existing account with ID: ${account.id}',
          );
          await docRef.update(accountData);
          print('FirestoreService: Account updated successfully');
        } else {
          print('FirestoreService: Account does not exist, creating with set');
          await docRef.set(accountData);
          print('FirestoreService: Account created with set');
        }
      } else {
        print('FirestoreService: Creating new account');
        final doc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('accounts')
            .add(accountData);
        print('FirestoreService: New account created with ID: ${doc.id}');
      }
    } catch (e) {
      print('FirestoreService: Error saving account: $e');
      if (e is FirebaseException) {
        print('FirestoreService: Firebase error code: ${e.code}');
        print('FirestoreService: Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // حفظ الفئة
  Future<void> saveCategory(Category category) async {
    if (currentUserId == null) {
      print('FirestoreService: Cannot save category - user not logged in');
      return;
    }

    try {
      print(
        'FirestoreService: Saving category: ${category.name} (ID: ${category.id})',
      );
      final categoryData = category.toFirestore();
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('categories')
          .doc(category.id?.toString());

      if (category.id != null) {
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          print(
            'FirestoreService: Updating existing category with ID: ${category.id}',
          );
          await docRef.update(categoryData);
          print('FirestoreService: Category updated successfully');
        } else {
          print('FirestoreService: Category does not exist, creating with set');
          await docRef.set(categoryData);
          print('FirestoreService: Category created with set');
        }
      } else {
        print('FirestoreService: Creating new category');
        final doc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('categories')
            .add(categoryData);
        print('FirestoreService: New category created with ID: ${doc.id}');
      }
    } catch (e) {
      print('FirestoreService: Error saving category: $e');
      if (e is FirebaseException) {
        print('FirestoreService: Firebase error code: ${e.code}');
        print('FirestoreService: Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // حفظ المعاملة
  Future<void> saveTransaction(app_models.Transaction transaction) async {
    if (currentUserId == null) {
      print('FirestoreService: Cannot save transaction - user not logged in');
      return;
    }

    try {
      print('FirestoreService: Saving transaction ID: ${transaction.id}');
      final transactionData = transaction.toFirestore();
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('transactions')
          .doc(transaction.id?.toString());

      if (transaction.id != null) {
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          print(
            'FirestoreService: Updating existing transaction with ID: ${transaction.id}',
          );
          await docRef.update(transactionData);
          print('FirestoreService: Transaction updated successfully');
        } else {
          print(
            'FirestoreService: Transaction does not exist, creating with set',
          );
          await docRef.set(transactionData);
          print('FirestoreService: Transaction created with set');
        }
      } else {
        print('FirestoreService: Creating new transaction');
        final doc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('transactions')
            .add(transactionData);
        print('FirestoreService: New transaction created with ID: ${doc.id}');
      }
    } catch (e) {
      print('FirestoreService: Error saving transaction: $e');
      if (e is FirebaseException) {
        print('FirestoreService: Firebase error code: ${e.code}');
        print('FirestoreService: Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // جلب الحسابات
  Stream<List<Account>> getAccounts() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Account.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // جلب الفئات
  Stream<List<Category>> getCategories({String? type}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    var query =
        _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('categories')
            as Query;

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // جلب المعاملات
  Stream<List<app_models.Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    var query =
        _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('transactions')
            as Query;

    if (startDate != null) {
      query = query.where(
        'transactionDate',
        isGreaterThanOrEqualTo: startDate.toIso8601String(),
      );
    }

    if (endDate != null) {
      query = query.where(
        'transactionDate',
        isLessThanOrEqualTo: endDate.toIso8601String(),
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return app_models.Transaction.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // حذف حساب
  Future<void> deleteAccount(String accountId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  // حذف فئة
  Future<void> deleteCategory(String categoryId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // حذف معاملة
  Future<void> deleteTransaction(String transactionId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }
}
