import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../repositories/admin_repository.dart';

class AdminMembershipTableScreen extends ConsumerStatefulWidget {
  const AdminMembershipTableScreen({super.key});

  @override
  ConsumerState<AdminMembershipTableScreen> createState() => _AdminMembershipTableScreenState();
}

class _AdminMembershipTableScreenState extends ConsumerState<AdminMembershipTableScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final users = await repo.getAllUsersWithMembership();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _filterData(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final uidMatch = user.uid.toLowerCase().contains(lowerQuery);
        final legacyMatch = (user.legacyUserId ?? '').toLowerCase().contains(lowerQuery);
        final emailMatch = (user.email ?? '').toLowerCase().contains(lowerQuery);
        final nameMatch = (user.displayName ?? '').toLowerCase().contains(lowerQuery);
        return uidMatch || legacyMatch || emailMatch || nameMatch;
      }).toList();
    });
  }

  void _toggleSelection(String uid, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(uid);
      } else {
        _selectedIds.remove(uid);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Membership Records'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} selected record(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminRepositoryProvider).deleteUsers(_selectedIds.toList());
      _clearSelection();
      _fetchData();
    }
  }

  Future<void> _deleteSingle(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Membership Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminRepositoryProvider).deleteUser(uid);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E6),
      appBar: AppBar(
        title: Text(_selectedIds.isNotEmpty ? '${_selectedIds.length} Selected' : 'Membership Records'),
        backgroundColor: _selectedIds.isNotEmpty ? Colors.redAccent : AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        leading: _selectedIds.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
            : null,
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchData,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by User ID, Name, or Email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterData('');
                  },
                ),
              ),
              onChanged: _filterData,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No membership records found.'))
                    : Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: _selectedIds.isNotEmpty,
                              headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey.shade200),
                              columns: const [
                                DataColumn(label: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Name/Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Renewal Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _filteredUsers.map((user) {
                                final mem = user.membership!;
                                final isExpired = mem.renewalDate.isBefore(DateTime.now());
                                
                                return DataRow(
                                  selected: _selectedIds.contains(user.uid),
                                  onSelectChanged: _selectedIds.isNotEmpty
                                      ? (selected) => _toggleSelection(user.uid, selected)
                                      : null,
                                  onLongPress: () {
                                    if (_selectedIds.isEmpty) {
                                      _toggleSelection(user.uid, true);
                                    }
                                  },
                                  cells: [
                                    DataCell(Text(user.legacyUserId ?? user.uid)),
                                    DataCell(Text(user.displayName ?? user.email ?? 'Unknown')),
                                    DataCell(Text(DateFormat('dd-MM-yyyy').format(mem.paymentDate))),
                                    DataCell(Text(DateFormat('dd-MM-yyyy').format(mem.renewalDate))),
                                    DataCell(Text(mem.amount.toStringAsFixed(0))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isExpired ? 'Expired' : 'Active',
                                          style: TextStyle(
                                            color: isExpired ? Colors.red.shade900 : Colors.green.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () => _deleteSingle(user.uid),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
