import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Not used
// import '../providers/language_provider.dart'; // Not used
import '../services/export_import_service.dart';
import '../l10n/app_localizations.dart';

class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({super.key});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen> {
  final ExportImportService _exportImportService = ExportImportService();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _exportFiles = [];

  @override
  void initState() {
    super.initState();
    _loadExportFiles();
  }

  Future<void> _loadExportFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await _exportImportService.listExportFiles();
      setState(() {
        _exportFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filePath = await _exportImportService.exportTransactionsToCSV();
      await _exportImportService.shareFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير المعاملات بنجاح')),
        );
      }
      _loadExportFiles();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filePath = await _exportImportService.exportAllDataToJSON();
      await _exportImportService.shareFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير جميع البيانات بنجاح')),
        );
      }
      _loadExportFiles();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importData(String filePath) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (filePath.endsWith('.json')) {
        await _exportImportService.importDataFromJSON(filePath);
      } else if (filePath.endsWith('.csv')) {
        await _exportImportService.importTransactionsFromCSV(filePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استيراد البيانات بنجاح')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      await _exportImportService.deleteExportFile(filePath);
      _loadExportFiles();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الملف بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل حذف الملف: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.export} / ${l10n.import}')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('خطأ: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadExportFiles,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExportSection(l10n),
                    const SizedBox(height: 24),
                    _buildImportSection(l10n),
                    const SizedBox(height: 24),
                    _buildFilesSection(l10n),
                  ],
                ),
              ),
    );
  }

  Widget _buildExportSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.export, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('تصدير المعاملات (CSV)'),
              subtitle: const Text('تصدير جميع المعاملات إلى ملف CSV'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _exportTransactions,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('تصدير جميع البيانات (JSON)'),
              subtitle: const Text('تصدير جميع البيانات إلى ملف JSON'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _exportAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.import, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('استيراد من ملف'),
              subtitle: const Text('اختر ملف CSV أو JSON للاستيراد'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement file picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ميزة اختيار الملف قيد التطوير'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الملفات المحفوظة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadExportFiles,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_exportFiles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('لا توجد ملفات محفوظة'),
                ),
              )
            else
              ..._exportFiles.map((file) {
                return ListTile(
                  leading: Icon(
                    file['type'] == 'CSV' ? Icons.table_chart : Icons.backup,
                  ),
                  title: Text(file['name'] as String),
                  subtitle: Text(
                    '${_formatFileSize(file['size'] as int)} - ${_formatDate(file['modified'] as DateTime)}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'share') {
                        _exportImportService.shareFile(file['path'] as String);
                      } else if (value == 'import') {
                        _importData(file['path'] as String);
                      } else if (value == 'delete') {
                        _showDeleteDialog(file);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'share',
                            child: Text('مشاركة'),
                          ),
                          const PopupMenuItem(
                            value: 'import',
                            child: Text('استيراد'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف'),
                          ),
                        ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف الملف "${file['name']}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteFile(file['path'] as String);
                },
                child: const Text('حذف'),
              ),
            ],
          ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
