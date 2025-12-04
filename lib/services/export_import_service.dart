import 'dart:convert';
import 'dart:io';
// import 'package:csv/csv.dart'; // Not available
// import 'package:share_plus/share_plus.dart'; // Not available
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../services/category_service.dart';

class ExportImportService {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  final CategoryService _categoryService = CategoryService();

  // Export transactions to CSV
  Future<String> exportTransactionsToCSV({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get transactions
      final transactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: null,
        startDate: startDate,
        endDate: endDate,
        limit: null,
        offset: null,
      );

      // Get accounts and categories for reference
      final accounts = await _accountService.getAccounts();
      final categories = await _categoryService.getCategories();

      // Create CSV data
      List<List<dynamic>> csvData = [
        [
          'ID',
          'Date',
          'Type',
          'Amount',
          'Description',
          'Account',
          'Category',
          'Created At',
        ],
      ];

      for (final transaction in transactions) {
        final account = accounts.firstWhere(
          (acc) => acc.id == transaction.accountId,
          orElse:
              () => Account(
                userId: userId,
                id: transaction.accountId,
                name: 'Unknown',
                balance: 0.0,
                type: 'cash',
              ),
        );

        final category = categories.firstWhere(
          (cat) => cat.id == transaction.categoryId,
          orElse:
              () => Category(
                id: transaction.categoryId,
                name: 'Unknown',
                type: 'expense',
                userId: 'default_user',
              ),
        );

        csvData.add([
          transaction.id ?? '',
          transaction.transactionDate.toIso8601String(),
          transaction.type.toString().split('.').last,
          transaction.amount,
          transaction.description,
          account.name,
          category.name,
          transaction.createdAt.toIso8601String(),
        ]);
      }

      // Convert to CSV string (simple implementation)
      final csvString = csvData.map((row) => row.join(',')).join('\n');

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export transactions: $e');
    }
  }

  // Export all data to JSON
  Future<String> exportAllDataToJSON({String? userId}) async {
    try {
      // Get all data
      final transactions = await _transactionService.getTransactions(
        accountId: null,
        categoryId: null,
        limit: null,
        offset: null,
      );
      final accounts = await _accountService.getAccounts();
      final categories = await _categoryService.getCategories();

      // Create export data
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'data': {
          'accounts': accounts.map((acc) => acc.toMap()).toList(),
          'categories': categories.map((cat) => cat.toMap()).toList(),
          'transactions': transactions.map((txn) => txn.toMap()).toList(),
        },
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'money_manager_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  // Import data from JSON
  Future<void> importDataFromJSON(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);

      if (jsonData['data'] == null) {
        throw Exception('Invalid backup file format');
      }

      final data = jsonData['data'];

      // Import accounts
      if (data['accounts'] != null) {
        for (final accountData in data['accounts']) {
          final account = Account.fromMap(accountData);
          await _accountService.insertAccount(account);
        }
      }

      // Import categories
      if (data['categories'] != null) {
        for (final categoryData in data['categories']) {
          final category = Category.fromMap(categoryData);
          await _categoryService.insertCategory(category);
        }
      }

      // Import transactions
      if (data['transactions'] != null) {
        for (final transactionData in data['transactions']) {
          final transaction = Transaction.fromMap(transactionData);
          await _transactionService.insertTransaction(transaction);
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  // Import transactions from CSV
  Future<void> importTransactionsFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();
      // Simple CSV parsing
      final csvData =
          csvString.split('\n').map((line) => line.split(',')).toList();

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header row
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length < 8) continue; // Skip incomplete rows

        try {
          final transaction = Transaction(
            id: row[0].toString(),
            accountId:
                row[5].toString(), // Account name - need to resolve to ID
            categoryId:
                row[6].toString(), // Category name - need to resolve to ID
            amount: double.tryParse(row[3].toString()) ?? 0.0,
            type: _parseTransactionType(row[2].toString()),
            description: row[4].toString(),
            transactionDate:
                DateTime.tryParse(row[1].toString()) ?? DateTime.now(),
            createdAt: DateTime.tryParse(row[7].toString()) ?? DateTime.now(),
            userId: 'default_user',
          );

          await _transactionService.insertTransaction(transaction);
        } catch (e) {
          debugPrint('Error importing transaction row $i: $e');
          // Continue with next row
        }
      }
    } catch (e) {
      throw Exception('Failed to import transactions: $e');
    }
  }

  // Parse transaction type from string
  TransactionType _parseTransactionType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense; // Default to expense
    }
  }

  // Share file (mock implementation)
  Future<void> shareFile(String filePath) async {
    try {
      // Mock implementation - just print the file path
      debugPrint('Sharing file: $filePath');
      // await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  // Get export file info
  Future<Map<String, dynamic>> getExportFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();

      return {
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified,
        'exists': await file.exists(),
      };
    } catch (e) {
      throw Exception('Failed to get file info: $e');
    }
  }

  // Delete export file
  Future<void> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // List all export files
  Future<List<Map<String, dynamic>>> listExportFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files =
          directory
              .listSync()
              .where(
                (file) =>
                    file is File &&
                    (file.path.endsWith('.csv') || file.path.endsWith('.json')),
              )
              .cast<File>();

      final fileList = <Map<String, dynamic>>[];
      for (final file in files) {
        final stat = await file.stat();
        fileList.add({
          'path': file.path,
          'name': file.path.split('/').last,
          'size': stat.size,
          'modified': stat.modified,
          'type': file.path.endsWith('.csv') ? 'CSV' : 'JSON',
        });
      }

      // Sort by modification date (newest first)
      fileList.sort(
        (a, b) =>
            (b['modified'] as DateTime).compareTo(a['modified'] as DateTime),
      );

      return fileList;
    } catch (e) {
      throw Exception('Failed to list export files: $e');
    }
  }
}
