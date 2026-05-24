import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../repositories/admin_repository.dart';

class MembershipBulkUploadScreen extends ConsumerStatefulWidget {
  const MembershipBulkUploadScreen({super.key});

  @override
  ConsumerState<MembershipBulkUploadScreen> createState() => _MembershipBulkUploadScreenState();
}

class _MembershipBulkUploadScreenState extends ConsumerState<MembershipBulkUploadScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _parsedData = [];
  String? _fileName;

  Future<void> _pickAndParseExcel() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _fileName = result.files.single.name;
        });

        final bytes = await File(result.files.single.path!).readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        
        List<Map<String, dynamic>> data = [];
        final sheet = excel.tables.keys.first;
        final table = excel.tables[sheet];
        
        if (table != null) {
          // Assuming row 0 is header: UserId | PaymentDate | Amount
          for (var i = 1; i < table.maxRows; i++) {
            final row = table.rows[i];
            if (row.isEmpty || row[0]?.value == null) continue;

            final String userId = row[0]?.value.toString().trim() ?? '';
            if (userId.isEmpty) continue;

            DateTime? paymentDate;
            double amount = 0.0;
            String rawDateStr = 'Not Found';

            for (int c = 1; c < row.length; c++) {
              final rawVal = row[c]?.value;
              if (rawVal == null) continue;

              if (rawVal is DateCellValue) {
                paymentDate ??= DateTime(rawVal.year, rawVal.month, rawVal.day);
              } else if (rawVal is DateTimeCellValue) {
                paymentDate ??= DateTime(rawVal.year, rawVal.month, rawVal.day, rawVal.hour, rawVal.minute);
              } else if (rawVal is IntCellValue) {
                // Serial dates usually > 30000 (year 1982+)
                if (rawVal.value > 30000 && rawVal.value < 60000 && paymentDate == null) {
                  paymentDate = DateTime(1899, 12, 30).add(Duration(days: rawVal.value));
                } else if (amount == 0.0) {
                  amount = rawVal.value.toDouble();
                }
              } else if (rawVal is DoubleCellValue) {
                if (rawVal.value > 30000 && rawVal.value < 60000 && paymentDate == null) {
                  paymentDate = DateTime(1899, 12, 30).add(Duration(days: rawVal.value.toInt()));
                } else if (amount == 0.0) {
                  amount = rawVal.value;
                }
              } else if (rawVal is TextCellValue) {
                final textStr = rawVal.value.toString().trim();
                
                if (paymentDate == null) {
                  try { paymentDate = DateFormat('dd-MM-yyyy').parse(textStr); } catch (_) {
                    try { paymentDate = DateFormat('dd/MM/yyyy').parse(textStr); } catch (_) {
                      try { paymentDate = DateFormat('yyyy-MM-dd').parse(textStr); } catch (_) {
                        try { paymentDate = DateFormat('MM/dd/yyyy').parse(textStr); } catch (_) {
                          try { paymentDate = DateTime.parse(textStr); } catch (_) {}
                        }
                      }
                    }
                  }
                }
                
                if (amount == 0.0) {
                  final parsedNum = double.tryParse(textStr.replaceAll(RegExp(r'[^0-9.]'), ''));
                  if (parsedNum != null && parsedNum > 0 && parsedNum < 30000) {
                    amount = parsedNum;
                  }
                }

                if (paymentDate == null && textStr.contains('-') || textStr.contains('/')) {
                   rawDateStr = textStr; // Keep track of a string that might be a failed date
                }
              }
            }

            if (userId.isNotEmpty) {
              data.add({
                'UserId': userId,
                'PaymentDate': paymentDate,
                'Amount': amount,
                'RawDate': rawDateStr,
                'status': paymentDate != null ? 'Valid' : 'Invalid Date',
              });
            }
          }
        }

        setState(() {
          _parsedData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error reading file: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _submitData() async {
    if (_parsedData.isEmpty) return;
    
    final validRows = _parsedData.where((row) => row['PaymentDate'] != null).toList();
    if (validRows.isEmpty) {
      _showError('No valid rows found to upload. Please fix date formats (DD-MM-YYYY).');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(adminRepositoryProvider);
      final result = await repo.bulkUploadMembership(validRows);
      
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      if (result['errorCount'] > 0) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Upload Completed with Errors'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Successfully uploaded: ${result['successCount']} users', style: const TextStyle(color: Colors.green)),
                  Text('Failed rows: ${result['errorCount']}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  const Text('Error Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...((result['errors'] as List).map((e) => Text('- $e', style: const TextStyle(fontSize: 12)))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () { Navigator.pop(c); context.pop(); }, child: const Text('OK')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully uploaded ${result['successCount']} records!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      appBar: AppBar(
        title: const Text('Bulk Membership Upload'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.upload_file, size: 48, color: AppColors.primaryMaroon),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload Membership Excel File',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Expected columns: UserId | PaymentDate | Amount\nDate Format: DD-MM-YYYY',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _pickAndParseExcel,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Select .xlsx File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: AppColors.primaryMaroon,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          if (_fileName != null) ...[
                            const SizedBox(height: 12),
                            Text('Selected: $_fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_parsedData.isNotEmpty) ...[
                    Text('Preview (${_parsedData.length} rows)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: _parsedData.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final row = _parsedData[index];
                            final isValid = row['status'] == 'Valid';
                            return ListTile(
                              leading: Icon(
                                isValid ? Icons.check_circle : Icons.error,
                                color: isValid ? Colors.green : Colors.red,
                              ),
                              title: Text('User ID: ${row['UserId']}'),
                              subtitle: Text(
                                'Payment: ${row['PaymentDate'] != null ? DateFormat('dd-MM-yyyy').format(row['PaymentDate']) : "Invalid (${row['RawDate']})"} | Amount: ₹${row['Amount']}',
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitData,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Upload Memberships to Database', style: TextStyle(fontSize: 16)),
                    ),
                  ] else ...[
                    const Spacer(),
                  ]
                ],
              ),
            ),
    );
  }
}
