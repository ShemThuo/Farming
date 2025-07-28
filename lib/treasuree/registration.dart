// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../farm/notify.dart';

class RegistrationFeePage extends StatefulWidget {
  const RegistrationFeePage({super.key});

  @override
  State<RegistrationFeePage> createState() => _RegistrationFeePageState();
}

class _RegistrationFeePageState extends State<RegistrationFeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountPayableController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime? _selectedDate;
  String _searchQuery = '';
  bool _isSubmitting = false;

  DocumentSnapshot? _editingDoc;

  double get balance {
    final payable = double.tryParse(_amountPayableController.text) ?? 0;
    final paid = double.tryParse(_amountPaidController.text) ?? 0;
    return payable - paid;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameController.text.trim(),
      'amount_payable': double.parse(_amountPayableController.text),
      'amount_paid': double.parse(_amountPaidController.text),
      'balance': balance,
      'payment_date': _selectedDate ?? DateTime.now(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_editingDoc != null) {
        // Update
        await FirebaseFirestore.instance
            .collection('registration_fees')
            .doc(_editingDoc!.id)
            .update(data);
        NotificationBar.show(
          context: context,
          message: '✔ Registration fee updated',
          isError: false,
        );
      } else {
        // Create
        await FirebaseFirestore.instance
            .collection('registration_fees')
            .add(data);
        NotificationBar.show(
          context: context,
          message: '✔ Registration fee added',
          isError: false,
        );
      }

      _resetForm();
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error: $e',
        isError: true,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _amountPayableController.clear();
    _amountPaidController.clear();
    _selectedDate = null;
    _editingDoc = null;
    setState(() {});
  }

  void _startEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingDoc = doc;
      _nameController.text = data['name'];
      _amountPayableController.text = data['amount_payable'].toString();
      _amountPaidController.text = data['amount_paid'].toString();
      _selectedDate = (data['payment_date'] as Timestamp).toDate();
    });
  }

  Future<void> _deleteRecord(String id) async {
    await FirebaseFirestore.instance
        .collection('registration_fees')
        .doc(id)
        .delete();
    NotificationBar.show(
      context: context,
      message: '🗑️ Record deleted',
      isError: false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountPayableController.dispose();
    _amountPaidController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Member Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Colors.lightBlue),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter member name' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _amountPayableController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount Payable (KES)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.monetization_on,
                        color: Colors.lightBlue,
                      ),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter amount payable' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount Paid (KES)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.lightBlue,
                          width: 1,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.monetization_on,
                        color: Colors.lightBlue,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter amount paid' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'No date selected'
                              : 'Payment Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Pick Date'),
                        onPressed: () => _pickDate(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Balance: KES ${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: Icon(_editingDoc == null ? Icons.add : Icons.update),
                    label: Text(_editingDoc == null ? 'Submit' : 'Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),

                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '📋 Payment Records',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('registration_fees')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text(data['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payable: KES ${data['amount_payable']} | Paid: KES ${data['amount_paid']}',
                            ),
                            Text(
                              'Balance: KES ${data['balance']}',
                              style: TextStyle(
                                color: (data['balance'] > 0)
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () => _startEdit(docs[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecord(docId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
